// lib: Helpers to invoke the accounts contract.

package lib

import (
	"context"
	"fmt"
	"crypto/ecdsa"
	"math/big"

	"github.com/ethereum/go-ethereum/ethclient"
	ethCommon "github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum"
	ethTypes "github.com/ethereum/go-ethereum/core/types"

	"github.com/near/borsh-go"
)

const (
	ArgsFresh borsh.Enum = iota
	ArgsFreshBackwards
	ArgsSolve
)

type (
	Args struct {
		Enum borsh.Enum `borsh_enum:"true"`
		Fresh
		FreshBackwards
		Solve
	}

	Permit struct {
		Token    [20]byte
		Deadline [32]byte
		V        uint8
		R        [32]byte
		S        [32]byte
	}

	FromArgs struct {
		Token      [20]byte
		ToTake     [32]byte
		MaxUnspent [32]byte
	}

	SolveArgs struct {
		Permit []Permit
		From   []FromArgs
		Target [20]byte
		Cd     []byte
		MsTs   *big.Int
	}

	SolveArgsSigArgs struct {
		Sig [64]byte
		SolveArgs
	}

	Fresh struct {
		Key       [32]byte
		SolveArgs []SolveArgsSigArgs
	}

	FreshBackwards struct {
		Key       [32]byte
		EoaAddr   [20]byte
		V         uint8
		R         [32]byte
		S         [32]byte
		SolveArgs []SolveArgsSigArgs
	}

	Solve struct {
		Slot uint32
		Args []SolveArgsSigArgs
	}
)

// SendArguments by estimating the gas of the execution, then send with
// the private key. Simulates using an anonymous sender, and uses the nonce
// from the sender when sending.
func SendArguments(
	ctx context.Context,
	c *ethclient.Client,
	chainId *big.Int,
	privateKey *ecdsa.PrivateKey,
	from, to ethCommon.Address,
	args Args,
) (*ethCommon.Hash, error) {
	b, err := borsh.Serialize(args)
	if err != nil {
		return nil, fmt.Errorf("serialising borsh: %v", err)
	}
	gasLimit, err := c.EstimateGas(ctx, ethereum.CallMsg{
		From: from,
		To:   &to,
		Data: b,
	})
	if err != nil {
		return nil, fmt.Errorf("estimate gas: %v", err)
	}
	gasLimit += uint64(float64(gasLimit) * 0.15)
	header, err := c.HeaderByNumber(context.Background(), nil)
	if err != nil {
		return nil, fmt.Errorf("header: %v", err)
	}
	baseFee := header.BaseFee
	gasTipCap, err := c.SuggestGasTipCap(context.Background())
	if err != nil {
		return nil, fmt.Errorf("gas tip cap: %v", err)
	}
	nonce, err := c.PendingNonceAt(context.Background(), from)
	if err != nil {
		return nil, fmt.Errorf("nonce: %v", err)
	}
	gasFeeCap := new(big.Int).Add(
		gasTipCap,
		new(big.Int).Mul(baseFee, big.NewInt(2)),
	)
	baseTx := ethTypes.DynamicFeeTx{
		Nonce:     nonce,
		GasFeeCap: gasFeeCap,
		GasTipCap: gasTipCap,
		Gas:       gasLimit,
		Value:     new(big.Int),
		Data:      b,
	}
	unsigned := ethTypes.NewTx(&baseTx)
	signer := ethTypes.NewLondonSigner(chainId)
	signed, err := ethTypes.SignTx(unsigned, signer, privateKey)
	if err != nil {
		return nil, fmt.Errorf("signed: %v", err)
	}
	if err = c.SendTransaction(ctx, signed); err != nil {
		return nil, fmt.Errorf("send transaction: %v", err)
	}
	h := signed.Hash()
	return &h, nil
}
