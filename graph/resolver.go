package graph

import (
	"database/sql"
	"math/big"

	ethCommon "github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"

	"github.com/fluidity-money/accounts.superposition.so/lib/ratelimit"
)

type Resolver struct {
	Client                                  *ethclient.Client
	Db                                      *sql.DB
	ChainId, MinimumAmount                  *big.Int
	AccountsFactoryAddr, ClaimantHelperAddr ethCommon.Address
	AccPubKey                               [32]byte
	Fusdc                                   [20]byte
	UrlAlarm                                string
	RateLimiting                            ratelimit.Server
	ClaimDisabled                           bool
}
