//go:generate go run github.com/99designs/gqlgen generate

package main

import (
	"context"
	"crypto/ed25519"
	"database/sql"
	"encoding/hex"
	"log"
	"log/slog"
	"math/big"
	"net/http"
	"os"
	"strings"

	"github.com/fluidity-money/accounts.superposition.so/graph"

	_ "github.com/lib/pq"

	"github.com/99designs/gqlgen/graphql/handler"
	"github.com/99designs/gqlgen/graphql/handler/extension"
	"github.com/99designs/gqlgen/graphql/handler/lru"
	"github.com/99designs/gqlgen/graphql/handler/transport"

	"github.com/vektah/gqlparser/v2/ast"

	"github.com/aws/aws-lambda-go/lambda"

	"github.com/awslabs/aws-lambda-go-api-proxy/httpadapter"

	ethCommon "github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
)

const (
	// EnvBackendType to use to listen the server with, (http|lambda).
	EnvBackendType = "SPN_LISTEN_BACKEND"

	// EnvListenAddr to listen the HTTP server on.
	EnvListenAddr = "SPN_LISTEN_ADDR"

	// EnvGethAddr to connect to make requests to Superposition.
	EnvGethAddr = "SPN_GETH_URL"

	// EnvTimescaleUri to use as the database for private key loading
	// and authentication key loading.
	EnvTimescaleUri = "SPN_TIMESCALE"

	// EnvChainId to send transactions to.
	EnvChainId = "SPN_CHAIN_ID"

	// EnvAccountsFactoryAddr to derive the addresses to send
	// transactions to when users ask to solve with mint, or to
	// create accounts with.
	EnvAccountsFactoryAddr = "SPN_ACCOUNTS_ADDR"

	// EnvAccPrivateKey to execute transactions on the behalf of users with.
	EnvAccPrivateKey = "SPN_ACCOUNTS_PRIVATE_KEY"

	// EnvDryrun disables the sending of transactions, instead simulating.
	EnvDryrun = "SPN_DRYRUN"

	// EnvAdminSecret to use for users to perform administrative actions with.
	EnvAdminSecret = "SPN_ADMIN_SECRET"

	// EnvFusdcAddr to use to work with permit.
	EnvFusdcAddr = "SPN_FUSDC_ADDR"
)

type authMiddleware struct {
	db          *sql.DB
	srv         http.Handler
	adminSecret string
}

func (a authMiddleware) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Headers", "*")
	switch bearer := r.Header.Get("Authorization"); bearer {
	case "":
		a.srv.ServeHTTP(w, r)
	case a.adminSecret:
		adminSecretEnabled := a.adminSecret != ""
		a.srv.ServeHTTP(w, r.WithContext(context.WithValue(
			r.Context(),
			"is admin",
			adminSecretEnabled,
		)))
	default:
		// Do a serious roundtrip to use the database with sending transactions,
		// since we have an open database storage situation acrouss our
		// monitoring stack. We avoid a roundtrip of the secret this way!
		bearerS := strings.Split(bearer, ":")
		eoaPreferred := bearerS[0]
		if !ethCommon.IsHexAddress(eoaPreferred) {
			w.WriteHeader(http.StatusBadRequest)
			return
		}
		secret, err := hex.DecodeString(bearerS[1])
		if err != nil {
			w.WriteHeader(http.StatusBadRequest)
			return
		}
		row := a.db.QueryRow(`
SELECT salt
FROM accounts_secrets_1
WHERE eoa_addr = $1 AND valid_until > CURRENT_TIMESTAMP`,
			eoaPreferred,
		)
		var salt string
		switch err := row.Scan(&salt); err {
		case nil:
		default:
			w.WriteHeader(http.StatusUnauthorized)
			return
		}
		saltB, err := hex.DecodeString(salt)
		if err != nil {
			slog.Error("error unpacking salt from database", "err", err)
			w.WriteHeader(http.StatusUnauthorized)
			return
		}
		key := graph.MakeKey([]byte(secret), saltB)
		keyS := hex.EncodeToString(key)
		row = a.db.QueryRow(`
SELECT 1
FROM accounts_secrets_1
WHERE priv_key = $1 AND eoa_addr = $2`,
			keyS,
			eoaPreferred,
		)
		var sink int
		switch err := row.Scan(&sink); err {
		case nil:
		default:
			w.WriteHeader(http.StatusUnauthorized)
			return
		}
		eoa := ethCommon.HexToAddress(eoaPreferred)
		ctx := context.WithValue(r.Context(), "authed", true)
		ctx = context.WithValue(ctx, "eoa", eoa)
		a.srv.ServeHTTP(w, r.WithContext(ctx))
	}
}

func main() {
	c, err := ethclient.Dial(os.Getenv(EnvGethAddr))
	if err != nil {
		log.Fatalf("failed to dial out: %v", err)
	}
	defer c.Close()
	db, err := sql.Open("postgres", os.Getenv(EnvTimescaleUri))
	if err != nil {
		log.Fatalf("connect database: %v", err)
	}
	defer db.Close()
	chainId, ok := new(big.Int).SetString(os.Getenv(EnvChainId), 10)
	if !ok {
		log.Fatalf("chain id not set")
	}
	accountsFactoryAddrS := os.Getenv(EnvAccountsFactoryAddr)
	if !ethCommon.IsHexAddress(accountsFactoryAddrS) {
		log.Fatal("accounts factory addr not set")
	}
	accountsFactoryAddr := ethCommon.HexToAddress(accountsFactoryAddrS)
	accPrivKeyB, err := hex.DecodeString(os.Getenv(EnvAccPrivateKey))
	if err != nil {
		log.Fatalf("accounts private key: %v", err)
	}
	adminSecret := os.Getenv(EnvAdminSecret)
	dryrun := os.Getenv(EnvDryrun) != ""
	fusdc := ethCommon.HexToAddress(os.Getenv(EnvFusdcAddr))
	accPrivKey := ed25519.PrivateKey(accPrivKeyB)
	accPubKey, _ := accPrivKey.Public().(ed25519.PublicKey)
	srv := handler.New(graph.NewExecutableSchema(graph.Config{Resolvers: &graph.Resolver{
		Client:              c,
		Db:                  db,
		ChainId:             chainId,
		AccountsFactoryAddr: accountsFactoryAddr,
		AccPrivKey:          accPrivKey,
		AccPubKey:           accPubKey,
		Fusdc:               fusdc,
		Dryrun:              dryrun,
	}}))
	srv.AddTransport(transport.Options{})
	srv.AddTransport(transport.GET{})
	srv.AddTransport(transport.POST{})
	srv.SetQueryCache(lru.New[*ast.QueryDocument](1000))
	srv.Use(extension.Introspection{})
	srv.Use(extension.AutomaticPersistedQuery{
		Cache: lru.New[string](100),
	})
	http.Handle("/", authMiddleware{db, srv, adminSecret})
	switch typ := os.Getenv(EnvBackendType); typ {
	case "lambda":
		lambda.Start(httpadapter.NewV2(http.DefaultServeMux).ProxyWithContext)
	case "http":
		err := http.ListenAndServe(os.Getenv(EnvListenAddr), nil)
		log.Fatalf( // This should only return if there's an error.
			"err listening, %#v not set?: %v",
			EnvListenAddr,
			err,
		)
	default:
		log.Fatalf(
			"unexpected listen type: %#v, use either (lambda|http) for SPN_LISTEN_BACKEND",
			typ,
		)
	}
}
