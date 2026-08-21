package types

import (
	"fmt"
	"strings"

	"github.com/near/borsh-go"
)

const (
	ArgsFreshBackwards borsh.Enum = iota
	ArgsSolve
	ArgsVersion
	ArgsAuthority
	ArgsSolveV2
	ArgsTransferOnly
	ArgsStatement
	ArgsOwner
)

type Asset uint8

const (
	AssetUsdc Asset = iota
	AssetArb
	AssetWeth
)

func AssetFromString(x string) (Asset, error) {
	switch strings.ToUpper(x) {
	case "USDC":
		return AssetUsdc, nil
	case "ARB":
		return AssetArb, nil
	case "WETH":
		return AssetWeth, nil
	default:
		return 0, fmt.Errorf("unknown asset %q", x)
	}
}

type (
	Args struct {
		Enum           borsh.Enum     `borsh_enum:"true" json:"enum"`
		FreshBackwards FreshBackwards `json:"fresh_backwards"`
		Solve          Solve          `json:"solve"`
		Version        Version        `json:"version"`
		Authority      Authority      `json:"authority"`
		SolveV2        SolveV2        `json:"solve_v2"`
		TransferOnly   TransferOnly   `json:"transfer_only"`
		Statement      Statement      `json:"statement"`
		Owner          Owner          `json:"owner"`
	}

	Permit struct {
		Asset    Asset    `json:"asset"`
		Deadline uint64   `json:"deadline"`
		V        uint8    `json:"v"`
		R        [32]byte `json:"r"`
		S        [32]byte `json:"s"`
	}

	FromArgs struct {
		Asset      Asset    `json:"asset"`
		ToTake     [32]byte `json:"to_take"`
		MaxUnspent [32]byte `json:"max_unspent"`
	}

	SolveArgs struct {
		Permit []Permit   `json:"permit"`
		From   []FromArgs `json:"from_args"`
		Target [20]byte   `json:"target"`
		Cd     []byte     `json:"cd"`
		MsTs   [16]byte   `json:"ms_ts"`
	}

	Sig [64]byte

	SolveArgsSigArgs struct {
		Sig  Sig       `json:"sig"`
		Args SolveArgs `json:"args"`
	}

	ArgsAuthorityAddr [20]byte

	FreshBackwards struct {
		Key       [32]byte           `json:"key"`
		EoaAddr   [20]byte           `json:"eoa_addr"`
		V         uint8              `json:"v"`
		R         [32]byte           `json:"r"`
		S         [32]byte           `json:"s"`
		SolveArgs []SolveArgsSigArgs `json:"solve_args"`
		Authority *ArgsAuthorityAddr `json:"authority"`
	}

	Solve struct {
		Args []SolveArgsSigArgs `json:"args"`
	}

	Version struct{}

	Authority struct{}

	SolveV2 struct {
		Args SolveV2Args `json:"args"`
		Sig  Sig         `json:"sig"`
	}

	SolveV2Args struct {
		Args          []SolveArgs `json:"args"`
		PermitOwner   [20]byte    `json:"permit_owner"`
		TransferOwner [20]byte    `json:"transfer_owner"`
	}

	TransferPermit struct {
		Deadline uint64   `json:"deadline"`
		V        uint8    `json:"v"`
		R        [32]byte `json:"r"`
		S        [32]byte `json:"s"`
	}

	Transfer struct {
		From      [20]byte        `json:"from"`
		Asset     Asset           `json:"asset"`
		Recipient [20]byte        `json:"recipient"`
		Amt       [32]byte        `json:"amt"`
		Permit    *TransferPermit `json:"permit"`
	}

	TransferOnlyArgs struct {
		Args []Transfer `json:"args"`
		MsTs [16]byte   `json:"ms_ts"`
	}

	TransferOnly struct {
		Args TransferOnlyArgs `json:"transfer_args"`
		Sig  Sig              `json:"sig"`
	}

	StatementArgs struct {
		Msg  []byte   `json:"msg"`
		MsTs [6]byte  `json:"ms_ts"`
	}

	Statement struct {
		Args StatementArgs `json:"statement_args"`
		Sig  Sig           `json:"sig"`
	}

	Owner struct{}
)