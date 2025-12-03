//go:generate go run github.com/99designs/gqlgen generate

package main

import (
	"crypto/ed25519"
	"database/sql"
	"encoding/hex"
	"log"
	"math/big"
	"net/http"
	"os"

	"github.com/fluidity-money/accounts.superposition.so/graph"

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
)

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
	if accountsFactoryAddrS == "" {
		log.Fatal("accounts factory addr not set")
	}
	accountsFactoryAddr := ethCommon.HexToAddress(accountsFactoryAddrS)
	accPrivKeyB, err := hex.DecodeString(os.Getenv(EnvAccPrivateKey))
	if err != nil {
		log.Fatalf("accounts private key: %v", err)
	}
	dryrun := os.Getenv(EnvDryrun) != ""
	accPrivKey := ed25519.PrivateKey(accPrivKeyB)
	accPubKey, _ := accPrivKey.Public().(ed25519.PublicKey)
	srv := handler.New(graph.NewExecutableSchema(graph.Config{Resolvers: &graph.Resolver{
		Client:              c,
		Db:                  db,
		ChainId:             chainId,
		AccountsFactoryAddr: accountsFactoryAddr,
		AccPrivKey:          accPrivKey,
		AccPubKey:           accPubKey,
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
	http.Handle("/", srv)
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
