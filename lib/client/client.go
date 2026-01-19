package client

import (
	"context"
	"crypto/ecdsa"
	"encoding/hex"
	"fmt"
	"log/slog"
	"math/big"

	"github.com/fluidity-money/accounts.superposition.so/lib/types"

	"github.com/ethereum/go-ethereum"
	ethCommon "github.com/ethereum/go-ethereum/common"
	ethTypes "github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/ethclient"

	"github.com/near/borsh-go"
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
	args types.Args,
	dryrun bool,
) (
	tx *ethCommon.Hash,
	gasLimit uint64,
	err error,
) {
	b, err := borsh.Serialize(args)
	if err != nil {
		return nil, 0, fmt.Errorf("serialising borsh: %v", err)
	}
	gasLimit, err = c.EstimateGas(ctx, ethereum.CallMsg{
		From: from,
		To:   &to,
		Data: b,
	})
	if err != nil {
		return nil, 0, fmt.Errorf(
			"estimate gas: to: %x, from: %x, data %x, %v",
			to,
			from,
			b,
			err,
		)
	}
	gasLimit += uint64(float64(gasLimit) * 0.15)
	header, err := c.HeaderByNumber(context.Background(), nil)
	if err != nil {
		return nil, 0, fmt.Errorf("header: %v", err)
	}
	baseFee := header.BaseFee
	gasTipCap, err := c.SuggestGasTipCap(context.Background())
	if err != nil {
		return nil, 0, fmt.Errorf("gas tip cap: %v", err)
	}
	nonce, err := c.PendingNonceAt(context.Background(), from)
	if err != nil {
		return nil, 0, fmt.Errorf("nonce: %v", err)
	}
	gasFeeCap := new(big.Int).Add(
		gasTipCap,
		new(big.Int).Mul(baseFee, big.NewInt(2)),
	)
	baseTx := ethTypes.DynamicFeeTx{
		ChainID: chainId,
		Nonce:     nonce,
		GasFeeCap: gasFeeCap,
		GasTipCap: gasTipCap,
		Gas:       gasLimit,
		Value:     new(big.Int),
		Data:      b,
		To:        &to,
	}
	unsigned := ethTypes.NewTx(&baseTx)
	signer := ethTypes.NewLondonSigner(chainId)
	signed, err := ethTypes.SignTx(unsigned, signer, privateKey)
	if err != nil {
		return nil, 0, fmt.Errorf("signed: %v", err)
	}
	if dryrun {
		resp, err := c.CallContract(ctx,
			ethereum.CallMsg{
				From: from,
				To:   &to,
				Data: b,
			},
			nil,
		)
		slog.Info("call contract results",
			"resp", hex.EncodeToString(resp),
			"to", to,
			"from", from,
			"cd", hex.EncodeToString(b),
		)
		if err != nil {
			return nil, gasLimit, fmt.Errorf("dryrun simulate: %v", err)
		}
	} else {
		if err = c.SendTransaction(ctx, signed); err != nil {
			return nil, 0, fmt.Errorf("send transaction: %v", err)
		}
	}
	h := signed.Hash()
	return &h, gasLimit, nil
}
