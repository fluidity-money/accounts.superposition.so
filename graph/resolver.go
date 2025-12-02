package graph

import (
	"database/sql"

	"github.com/ethereum/go-ethereum/ethclient"
)

type Resolver struct {
	Client     *ethclient.Client
	Db         *sql.DB
	PrivateKey [64]byte
}
