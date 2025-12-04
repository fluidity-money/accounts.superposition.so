package graph

import (
	"crypto/ed25519"
	"encoding/hex"
	"fmt"
	"math"

	"github.com/fluidity-money/accounts.superposition.so/graph/model"
	"github.com/fluidity-money/accounts.superposition.so/lib/ninelives"
	"github.com/fluidity-money/accounts.superposition.so/lib/types"

	"github.com/near/borsh-go"
)

var MaxBytes32 [32]byte

func strToBytes8(s string) ([8]byte, error) {
	var b [8]byte
	i, err := hex.Decode(b[:], []byte(s))
	if err != nil {
		return b, fmt.Errorf("decode str: %v", err)
	}
	if i != 8 {
		return b, fmt.Errorf("decode str len: %v", i)
	}
	return b, nil
}

func strToAddr(s string) ([20]byte, error) {
	var b [20]byte
	i, err := hex.Decode(b[:], []byte(s))
	if err != nil {
		return b, fmt.Errorf("decode str: %v", err)
	}
	if i != 20 {
		return b, fmt.Errorf("decode str len: %v", i)
	}
	return b, nil
}

func strToBytes32(s string) ([32]byte, error) {
	var b [32]byte
	i, err := hex.Decode(b[:], []byte(s))
	if err != nil {
		return b, fmt.Errorf("decode str: %v", err)
	}
	if i != 32 {
		return b, fmt.Errorf("decode str len: %v", i)
	}
	return b, nil
}

// CreateAccountToFreshBackwards without the SolveArgs fields set.
func CreateAccountToFreshBackwards(pubKey [32]byte, createAccount model.CreateAccount) (*types.FreshBackwards, error) {
	eoa, err := strToAddr(createAccount.EoaAddr)
	if err != nil {
		return nil, fmt.Errorf("eoa: %v", err)
	}
	if createAccount.SigV < 0 || createAccount.SigV > math.MaxUint8 {
		return nil, fmt.Errorf("v exceeds")
	}
	v := uint8(createAccount.SigV)
	r, err := strToBytes32(createAccount.SigR)
	if err != nil {
		return nil, fmt.Errorf("r: %v", err)
	}
	s, err := strToBytes32(createAccount.SigS)
	if err != nil {
		return nil, fmt.Errorf("s: %v", err)
	}
	return &types.FreshBackwards{
		Key:     pubKey,
		EoaAddr: eoa,
		V:       v,
		R:       r,
		S:       s,
	}, nil
}

func NewPermit(
	token string,
	deadline uint64,
	permitV int32,
	permitR, permitS string,
) (*types.Permit, error) {
	t, err := strToAddr(token)
	if err != nil {
		return nil, fmt.Errorf("addr: %v", err)
	}
	if permitV < 0 || permitV > math.MaxUint8 {
		return nil, fmt.Errorf("v exceeds")
	}
	v := uint8(permitV)
	r, err := strToBytes32(permitR)
	if err != nil {
		return nil, fmt.Errorf("permit r: %v", err)
	}
	s, err := strToBytes32(permitS)
	if err != nil {
		return nil, fmt.Errorf("permit s: %v", err)
	}
	return &types.Permit{
		Token:    t,
		Deadline: deadline,
		V:        v,
		R:        r,
		S:        s,
	}, nil
}

func CreateSolveArgsSigArgs(
	priv ed25519.PrivateKey,
	token [20]byte,
	market, outcome, amount, referrer, recipient string,
	permit *model.Permit,
	msTs string,
) (*types.SolveArgsSigArgs, error) {
	m, err := strToAddr(market)
	if err != nil {
		return nil, fmt.Errorf("addr: %v", err)
	}
	o, err := strToBytes8(outcome)
	if err != nil {
		return nil, fmt.Errorf("outcome: %v", err)
	}
	a, err := strToBytes32(amount)
	if err != nil {
		return nil, fmt.Errorf("amount: %v", err)
	}
	ref, err := strToAddr(referrer)
	if err != nil {
		return nil, fmt.Errorf("referrer: %v", err)
	}
	rec, err := strToAddr(recipient)
	if err != nil {
		return nil, fmt.Errorf("sender: %v", err)
	}
	cd := ninelives.NewMint(o, a, ref, rec)
	solveArgs := types.SolveArgs{
		From: []types.FromArgs{{
			Token:      token,
			ToTake:     a,
			MaxUnspent: MaxBytes32,
		}},
		Target: m,
		Cd:     cd,
	}
	if permit != nil {
		if permit.Deadline < 0 {
			return nil, fmt.Errorf("negative deadline")
		}
		d := uint64(permit.Deadline)
		p, err := NewPermit(
			permit.Token,
			d,
			permit.PermitV,
			permit.PermitR,
			permit.PermitS,
		)
		if err != nil {
			return nil, fmt.Errorf("permit: %v", err)
		}
		solveArgs.Permit = append(solveArgs.Permit, *p)
	}
	solveArgsDigest, err := borsh.Serialize(solveArgs)
	if err != nil {
		return nil, fmt.Errorf("making digest: %v", err)
	}
	var sigArr [64]byte
	sig := ed25519.Sign(priv, solveArgsDigest)
	copy(sigArr[:], sig)
	return &types.SolveArgsSigArgs{
		Sig:  sigArr,
		Args: solveArgs,
	}, nil
}

func TagFreshBackwardsWithMint(
	f *types.FreshBackwards,
	priv ed25519.PrivateKey,
	token [20]byte,
	market, outcome, amount, referrer, recipient string,
	permit *model.Permit,
	msTs string,
) error {
	m, err := CreateSolveArgsSigArgs(
		priv,
		token,
		market, outcome, amount, referrer, recipient,
		permit,
		msTs,
	)
	if err != nil {
		return err
	}
	f.SolveArgs = append(f.SolveArgs, *m)
	return nil
}

func init() {
	for i := 0; i < 32; i++ {
		MaxBytes32[i] = math.MaxUint8
	}
}
