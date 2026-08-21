//go:generate go run github.com/99designs/gqlgen generate

package main

import (
	"context"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"log"
	"log/slog"
	"math/big"
	"math/rand"
	"net/http"
	"os"
	"strings"

	"github.com/fluidity-money/accounts.superposition.so/graph"
	"github.com/fluidity-money/accounts.superposition.so/lib/ratelimit"

	_ "github.com/lib/pq"

	"github.com/99designs/gqlgen/graphql/handler"
	"github.com/99designs/gqlgen/graphql/handler/extension"
	"github.com/99designs/gqlgen/graphql/handler/lru"
	"github.com/99designs/gqlgen/graphql/handler/transport"
	"github.com/99designs/gqlgen/graphql/playground"

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

	// EnvAccPublicKey, set since we feed the Rust code the private key, and
	// it expects a differently sized key, so we can't derive the same key reliably here.
	EnvAccPublicKey = "SPN_ACCOUNTS_PUBLIC_KEY"

	// EnvAdminSecret to use for users to perform administrative actions with.
	EnvAdminSecret = "SPN_ADMIN_SECRET"

	// EnvFusdcAddr to use to work with permit.
	EnvFusdcAddr = "SPN_FUSDC_ADDR"

	// EnvClaimantHelperAddr to use with the ClaimantHelper.
	EnvClaimantHelperAddr = "SPN_CLAIMANT_HELPER"

	// EnvAlarmWebhook that will trigger a soft alarm if called.
	EnvAlarmWebhook = "SPN_ALARM_WEBHOOK"

	// EnvFeatureClaimDisabled is set to anything but "" to prevent
	// people from claiming using the accounts service.
	EnvFeatureClaimDisabled = "SPN_FEATURE_CLAIM_DISABLED"

	// EnvFeatureMintDisabled to prevent minting (in lieu of Rfqhub).
	EnvFeatureMintDisabled = "SPN_FEATURE_MINT_DISABLED"

	// EnvMinimumAmount to use as the deposit feature. If unset, not used, must be base 10.
	EnvMinimumAmount = "SPN_MINIMUM_AMOUNT"
)

type authMiddleware struct {
	db          *sql.DB
	srv         http.Handler
	adminSecret string
}

func (a authMiddleware) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	origin := r.Header.Get("Origin")
	if origin != "" {
		w.Header().Set("Access-Control-Allow-Origin", origin)
		w.Header().Set("Access-Control-Allow-Headers", "*")
		w.Header().Set("Access-Control-Allow-Methods", "*")
		w.Header().Set("Access-Control-Allow-Credentials", "true")
		w.Header().Set("Access-Control-Max-Age", "86400")
		w.Header().Set("Access-Control-Expose-Headers", "*")
	}
	if r.Method == "OPTIONS" {
		w.WriteHeader(204)
		return
	}
	snowflake := rand.Int()
	ctx := context.WithValue(r.Context(), "snowflake", snowflake)
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
		eoaPreferred_ := bearerS[0]
		if !ethCommon.IsHexAddress(eoaPreferred_) {
			slog.Error("not eoa address",
				"eoa", eoaPreferred_,
				"snowflake", snowflake,
			)
			w.WriteHeader(http.StatusBadRequest)
			return
		}
		// Normalise with ethCommon's representation of addresses (which include
		// the 0x):
		eoaPreferred := strings.ToLower(ethCommon.HexToAddress(eoaPreferred_).String())
		_, err := hex.DecodeString(bearerS[1])
		if err != nil {
			slog.Error("error decoding bearer",
				"err", err,
				"bearer", bearerS,
				"snowflake", snowflake,
			)
			w.WriteHeader(http.StatusBadRequest)
			return
		}
		secretX := strings.ToLower(bearerS[1])
		row := a.db.QueryRow(`
SELECT COUNT(1)
FROM accounts_secrets_2
WHERE eoa_addr = $1 AND secret = $2`,
			eoaPreferred,
			secretX,
		)
		var count int
		if err := row.Scan(&count); err != nil {
			w.WriteHeader(http.StatusUnauthorized)
			log.Fatalf("error scanning secrets, snowflake: %v: %v", "snowflake", err)
			writeUnauthorised(w)
			return
		}
		if count == 0 {
			w.WriteHeader(http.StatusUnauthorized)
			slog.Error("no rows found", "snowflake", snowflake)
			writeUnauthorised(w)
			return
		}
		eoa := ethCommon.HexToAddress(eoaPreferred)
		ctx = context.WithValue(context.WithValue(ctx, "authed", true), "eoa", eoa)
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
	minAmt := new(big.Int)
	if s := os.Getenv(EnvMinimumAmount); s != "" {
		_, ok := minAmt.SetString(s, 10)
		if !ok {
			log.Fatalf("bad minimum amount: %v", s)
		}
	}
	accountsFactoryAddrS := os.Getenv(EnvAccountsFactoryAddr)
	if !ethCommon.IsHexAddress(accountsFactoryAddrS) {
		log.Fatal("accounts factory addr not set")
	}
	accountsFactoryAddr := ethCommon.HexToAddress(accountsFactoryAddrS)
	if _, err := hex.DecodeString(os.Getenv(EnvAccPrivateKey)); err != nil {
		log.Fatalf("accounts private key needs to be set: %v", err)
	}
	accPubKeyB, err := hex.DecodeString(os.Getenv(EnvAccPublicKey))
	if err != nil {
		log.Fatalf("accounts public key: %v", err)
	}
	var (
		claimDisabled = os.Getenv(EnvFeatureClaimDisabled) != ""
		mintDisabled = os.Getenv(EnvFeatureMintDisabled) != ""
	)
	alarmWebhook := os.Getenv(EnvAlarmWebhook)
	var accPubKey [32]byte
	copy(accPubKey[:], accPubKeyB)
	adminSecret := os.Getenv(EnvAdminSecret)
	claimantHelper := ethCommon.HexToAddress(os.Getenv(EnvClaimantHelperAddr))
	rateLimiting := ratelimit.Run(db, true)
	srv := handler.New(graph.NewExecutableSchema(graph.Config{Resolvers: &graph.Resolver{
		Client:               c,
		Db:                   db,
		ChainId:              chainId,
		MinimumAmount:        minAmt,
		AccountsFactoryAddr:  accountsFactoryAddr,
		ClaimantHelperAddr:   claimantHelper,
		AccPubKey:            accPubKey,
		UrlAlarm:             alarmWebhook,
		RateLimiting:         rateLimiting,
		FeatureClaimDisabled: claimDisabled,
		FeatureMintDisabled: mintDisabled,
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
	http.Handle("/playground", playground.Handler("GraphQL playground", "/"))
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

func writeUnauthorised(w http.ResponseWriter) {
	_ = json.NewEncoder(w).Encode(struct {
		Error string `json:"error"`
	}{"unauthorised"})
}
