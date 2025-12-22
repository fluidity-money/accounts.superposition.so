package graph

import (
	"database/sql"
	"math/big"

	ethCommon "github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
)

type Resolver struct {
	Client                                  *ethclient.Client
	Db                                      *sql.DB
	ChainId                                 *big.Int
	AccountsFactoryAddr, ClaimantHelperAddr ethCommon.Address
	AccPubKey                               [32]byte
	Fusdc                                   [20]byte
}
