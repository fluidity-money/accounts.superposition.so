package graph

import (
	"crypto/ed25519"
	"database/sql"
	"math/big"

	ethCommon "github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
)

type Resolver struct {
	Client              *ethclient.Client
	Db                  *sql.DB
	ChainId             *big.Int
	AccountsFactoryAddr ethCommon.Address
	AccPrivKey          ed25519.PrivateKey
	AccPubKey           ed25519.PublicKey
	Fusdc               [20]byte
	Dryrun              bool
}
