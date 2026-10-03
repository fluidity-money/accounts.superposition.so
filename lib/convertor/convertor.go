package convertor

import (
	"crypto/sha512"
	"encoding/hex"
	"fmt"
	"math"
	"math/big"
	"os/exec"
	"strings"

	"github.com/fluidity-money/accounts.superposition.so/graph/model"
	"github.com/fluidity-money/accounts.superposition.so/lib/ninelives"
	"github.com/fluidity-money/accounts.superposition.so/lib/types"

	"github.com/fluidity-money/superposition-assets"

	ethCommon "github.com/ethereum/go-ethereum/common"

	"github.com/near/borsh-go"
)

var MaxBytes32 [32]byte

func CreateSolveV2(
	prog string,
	args []types.SolveArgs,
	permitOwner, transferOwner ethCommon.Address,
) (*types.Args, error) {
	solveArgs := types.SolveV2Args{
		Args:          args,
		PermitOwner:   permitOwner,
		TransferOwner: transferOwner,
	}
	encoded, err := borsh.Serialize(solveArgs)
	if err != nil {
		return nil, fmt.Errorf("making solve v2 digest: %v", err)
	}
	digest := sha512.Sum512(encoded)
	sig, err := exec.Command(prog, hex.EncodeToString(digest[:])).Output()
	if err != nil {
		return nil, fmt.Errorf("invoking dalekph: %v, %v", string(sig), err)
	}
	var signature types.Sig
	copy(signature[:], sig)
	return &types.Args{
		Enum: types.ArgsSolveV2,
		SolveV2: types.SolveV2{
			Args: solveArgs,
			Sig:  signature,
		},
	}, nil
}

func CreateSolveV3(
	prog string,
	args []types.SolveArgs,
	gasToken superposition_assets.Asset,
	gasTokenAmt uint64,
) (*types.Args, error) {
	solveArgs := types.SolveV3Args{
		Args:          args,
		GasToken: gasToken,
		GasTokenAmt: gasTokenAmt,
	}
	encoded, err := borsh.Serialize(solveArgs)
	if err != nil {
		return nil, fmt.Errorf("making solve v2 digest: %v", err)
	}
	digest := sha512.Sum512(encoded)
	sig, err := exec.Command(prog, hex.EncodeToString(digest[:])).Output()
	if err != nil {
		return nil, fmt.Errorf("invoking dalekph: %v, %v", string(sig), err)
	}
	var signature types.Sig
	copy(signature[:], sig)
	return &types.Args{
		Enum: types.ArgsSolveV3,
		SolveV3: types.SolveV3{
			Args: solveArgs,
			Sig:  signature,
		},
	}, nil
}

func strToBytes8(s string) ([8]byte, error) {
	var b [8]byte
	i, err := hex.Decode(b[:], []byte(strings.TrimPrefix(s, "0x")))
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
	if s == "" {
		return b, nil
	}
	i, err := hex.Decode(b[:], []byte(strings.TrimPrefix(s, "0x")))
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
	i, err := hex.Decode(b[:], []byte(strings.TrimPrefix(s, "0x")))
	if err != nil {
		return b, fmt.Errorf("decode str: %v", err)
	}
	if i != 32 {
		return b, fmt.Errorf("decode str len: %v", i)
	}
	return b, nil
}

func CreatePayoffForOtherArgs(
	prog string,
	claimantHelper, eoa ethCommon.Address,
	markets []ethCommon.Address,
	msTs [16]byte,
) (*types.SolveArgsSigArgs, error) {
	cd := ninelives.NewPayoffForOther(markets, eoa)
	solveArgs := types.SolveArgs{
		Target: claimantHelper,
		Cd:     cd,
		MsTs:   msTs,
	}
	solveArgsDigest, err := borsh.Serialize(solveArgs)
	if err != nil {
		return nil, fmt.Errorf("making digest: %v", err)
	}
	var sigArr [64]byte
	d := sha512.Sum512(solveArgsDigest)
	sig, err := exec.Command(prog, hex.EncodeToString(d[:])).Output()
	if err != nil {
		return nil, fmt.Errorf("invoking dalekph: %v, %v", string(sig), err)
	}
	copy(sigArr[:], sig)
	return &types.SolveArgsSigArgs{
		Sig:  sigArr,
		Args: solveArgs,
	}, nil
}

func CreatePayoffForOtherArgsGraph(
	prog string,
	claimantHelper, eoa ethCommon.Address,
	markets_ []string,
	msTs_ string,
) (*types.SolveArgsSigArgs, error) {
	msTsI, ok := new(big.Int).SetString(msTs_, 10)
	if !ok {
		return nil, fmt.Errorf("ms ts: %v", msTs_)
	}
	var msTs [16]byte
	copy(msTs[:], msTsI.Bytes())

	markets := make([]ethCommon.Address, len(markets_))
	for i, m := range markets_ {
		if !ethCommon.IsHexAddress(m) {
			return nil, fmt.Errorf("bad address: %v", m)
		}
		markets[i] = ethCommon.HexToAddress(m)
	}

	return CreatePayoffForOtherArgs(
		prog,
		claimantHelper,
		eoa,
		markets,
		msTs,
	)
}

func CreateAccountToFreshBackwards(
	pubKey [32]byte,
	eoa [20]byte,
	v uint8,
	r, s [32]byte,
	authority *types.ArgsAuthorityAddr,
) *types.FreshBackwards {
	return &types.FreshBackwards{
		Key:       pubKey,
		EoaAddr:   eoa,
		V:         v,
		R:         r,
		S:         s,
		Authority: authority,
	}
}

func CreateAccountToFreshBackwardsGraph(
	pubKey [32]byte,
	createAccount model.CreateAccount,
) (*types.FreshBackwards, error) {
	eoa, err := strToAddr(createAccount.EoaAddr)
	if err != nil {
		return nil, fmt.Errorf("eoa: %v", err)
	}

	var authority *types.ArgsAuthorityAddr
	if a := createAccount.Authority; a != nil {
		x, err := strToAddr(*a)
		if err != nil {
			return nil, fmt.Errorf("authority: %v", err)
		}
		v := types.ArgsAuthorityAddr(x)
		authority = &v
	}

	if createAccount.SigV < 0 || createAccount.SigV > math.MaxUint8 {
		return nil, fmt.Errorf("v exceeds")
	}

	r, err := strToBytes32(createAccount.SigR)
	if err != nil {
		return nil, fmt.Errorf("r: %v", err)
	}

	s, err := strToBytes32(createAccount.SigS)
	if err != nil {
		return nil, fmt.Errorf("s: %v", err)
	}

	return CreateAccountToFreshBackwards(
		pubKey,
		eoa,
		uint8(createAccount.SigV),
		r,
		s,
		authority,
	), nil
}

func NewPermit(
	asset superposition_assets.Asset,
	deadline uint64,
	v uint8,
	r, s [32]byte,
) *types.Permit {
	return &types.Permit{
		Asset:    asset,
		Deadline: deadline,
		V:        v,
		R:        r,
		S:        s,
	}
}

func NewPermitGraph(
	asset superposition_assets.Asset,
	deadline uint64,
	permitV int32,
	permitR, permitS string,
) (*types.Permit, error) {
	if permitV < 0 || permitV > math.MaxUint8 {
		return nil, fmt.Errorf("v exceeds")
	}

	r, err := strToBytes32(permitR)
	if err != nil {
		return nil, fmt.Errorf("permit r: %v", err)
	}

	s, err := strToBytes32(permitS)
	if err != nil {
		return nil, fmt.Errorf("permit s: %v", err)
	}

	return NewPermit(
		asset,
		deadline,
		uint8(permitV),
		r,
		s,
	), nil
}

func CreateSolveArgsSigArgs(
	prog string,
	asset superposition_assets.Asset,
	target ethCommon.Address,
	amount [32]byte,
	cd []byte,
	permit *types.Permit,
	msTs [16]byte,
) (*types.SolveArgsSigArgs, error) {
	solveArgs := types.SolveArgs{
		From: []types.FromArgs{{
			Asset:  asset,
			ToTake: amount,
		}},
		Target: target,
		Cd:     cd,
		MsTs:   msTs,
	}

	if permit != nil {
		solveArgs.Permit = append(solveArgs.Permit, *permit)
	}

	solveArgsDigest, err := borsh.Serialize(solveArgs)
	if err != nil {
		return nil, fmt.Errorf("making digest: %v", err)
	}

	var sigArr [64]byte
	d := sha512.Sum512(solveArgsDigest)
	sig, err := exec.Command(
		prog,
		hex.EncodeToString(d[:]),
	).Output()
	if err != nil {
		return nil, fmt.Errorf("invoking dalekph: %v, %v", string(sig), err)
	}

	copy(sigArr[:], sig)

	return &types.SolveArgsSigArgs{
		Sig:  sigArr,
		Args: solveArgs,
	}, nil
}

func CreateSolveArgsSigArgsGraph(
	prog string,
	asset superposition_assets.Asset,
	target, amount string,
	cd []byte,
	permit *model.Permit,
	msTs_ string,
) (*types.SolveArgsSigArgs, error) {
	a_, ok := new(big.Int).SetString(amount, 10)
	if !ok {
		return nil, fmt.Errorf("amount: %v", amount)
	}
	if len(a_.Bytes()) > 32 {
		return nil, fmt.Errorf("too huge amount: %v", amount)
	}

	var a [32]byte
	copy(a[32-len(a_.Bytes()):], a_.Bytes())

	msTsI, ok := new(big.Int).SetString(msTs_, 10)
	if !ok {
		return nil, fmt.Errorf("ms ts: %v", msTs_)
	}

	var msTs [16]byte
	copy(msTs[:], msTsI.Bytes())

	m, err := strToAddr(target)
	if err != nil {
		return nil, fmt.Errorf("addr: %v", err)
	}

	var p *types.Permit
	if permit != nil {
		if permit.Deadline < 0 {
			return nil, fmt.Errorf("negative deadline")
		}

		p, err = NewPermitGraph(
			asset,
			uint64(permit.Deadline),
			permit.PermitV,
			permit.PermitR,
			permit.PermitS,
		)
		if err != nil {
			return nil, fmt.Errorf("permit: %v", err)
		}
	}

	return CreateSolveArgsSigArgs(
		prog,
		asset,
		ethCommon.Address(m),
		a,
		cd,
		p,
		msTs,
	)
}

func CreateSolveArgsSigArgsMint(
	prog string,
	asset superposition_assets.Asset,
	market ethCommon.Address,
	outcome [8]byte,
	amount [32]byte,
	referrer, recipient ethCommon.Address,
	permit *types.Permit,
	msTs [16]byte,
) (*types.SolveArgsSigArgs, error) {
	cd := ninelives.NewMint(
		outcome,
		amount,
		referrer,
		recipient,
	)

	return CreateSolveArgsSigArgs(
		prog,
		asset,
		market,
		amount,
		cd,
		permit,
		msTs,
	)
}

func CreateSolveArgsSigArgsMintGraph(
	prog string,
	asset superposition_assets.Asset,
	market, outcome, amount, referrer string,
	recipient ethCommon.Address,
	permit *model.Permit,
	msTs_ string,
) (*types.SolveArgsSigArgs, error) {
	o, err := strToBytes8(outcome)
	if err != nil {
		return nil, fmt.Errorf("outcome: %v", err)
	}

	a_, ok := new(big.Int).SetString(amount, 10)
	if !ok {
		return nil, fmt.Errorf("amount: %v", amount)
	}
	if len(a_.Bytes()) > 32 {
		return nil, fmt.Errorf("too huge amount: %v", amount)
	}

	var a [32]byte
	copy(a[32-len(a_.Bytes()):], a_.Bytes())

	m, err := strToAddr(market)
	if err != nil {
		return nil, fmt.Errorf("market: %v", err)
	}

	ref, err := strToAddr(referrer)
	if err != nil {
		return nil, fmt.Errorf("referrer: %v", err)
	}

	msTsI, ok := new(big.Int).SetString(msTs_, 10)
	if !ok {
		return nil, fmt.Errorf("ms ts: %v", msTs_)
	}

	var msTs [16]byte
	copy(msTs[:], msTsI.Bytes())

	var p *types.Permit
	if permit != nil {
		if permit.Deadline < 0 {
			return nil, fmt.Errorf("negative deadline")
		}

		p, err = NewPermitGraph(
			asset,
			uint64(permit.Deadline),
			permit.PermitV,
			permit.PermitR,
			permit.PermitS,
		)
		if err != nil {
			return nil, fmt.Errorf("permit: %v", err)
		}
	}

	return CreateSolveArgsSigArgsMint(
		prog,
		asset,
		ethCommon.Address(m),
		o,
		a,
		ethCommon.Address(ref),
		recipient,
		p,
		msTs,
	)
}

func TagFreshBackwards(
	prog string,
	f *types.FreshBackwards,
	asset superposition_assets.Asset,
	target ethCommon.Address,
	amount [32]byte,
	cd []byte,
	permit *types.Permit,
	msTs [16]byte,
) error {
	m, err := CreateSolveArgsSigArgs(
		prog,
		asset,
		target,
		amount,
		cd,
		permit,
		msTs,
	)
	if err != nil {
		return err
	}

	f.SolveArgs = append(f.SolveArgs, *m)
	return nil
}

func TagFreshBackwardsGraph(
	prog string,
	f *types.FreshBackwards,
	asset superposition_assets.Asset,
	target, amount string,
	cd []byte,
	permit *model.Permit,
	msTs string,
) error {
	m, err := CreateSolveArgsSigArgsGraph(
		prog,
		asset,
		target,
		amount,
		cd,
		permit,
		msTs,
	)
	if err != nil {
		return err
	}

	f.SolveArgs = append(f.SolveArgs, *m)
	return nil
}

func TagFreshBackwardsWithMint(
	prog string,
	f *types.FreshBackwards,
	asset superposition_assets.Asset,
	market ethCommon.Address,
	outcome [8]byte,
	amount [32]byte,
	referrer, recipient ethCommon.Address,
	permit *types.Permit,
	msTs [16]byte,
) error {
	m, err := CreateSolveArgsSigArgsMint(
		prog,
		asset,
		market,
		outcome,
		amount,
		referrer,
		recipient,
		permit,
		msTs,
	)
	if err != nil {
		return err
	}

	f.SolveArgs = append(f.SolveArgs, *m)
	return nil
}

func TagFreshBackwardsWithMintGraph(
	prog string,
	f *types.FreshBackwards,
	asset superposition_assets.Asset,
	market, outcome, amount, referrer string,
	recipient ethCommon.Address,
	permit *model.Permit,
	msTs string,
) error {
	m, err := CreateSolveArgsSigArgsMintGraph(
		prog,
		asset,
		market,
		outcome,
		amount,
		referrer,
		recipient,
		permit,
		msTs,
	)
	if err != nil {
		return err
	}

	f.SolveArgs = append(f.SolveArgs, *m)
	return nil
}