package graph

import (
	"crypto/ed25519"
	"database/sql"
	"math/big"

	ethCommon "github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
)

type Resolver struct {
	Client                *ethclient.Client
	Db                    *sql.DB
	ChainId               *big.Int
	PassportAddr ethCommon.Address
	PasPrivKey            ed25519.PrivateKey
	PasPubKey             ed25519.PublicKey
	Fusdc                 [20]byte
}
