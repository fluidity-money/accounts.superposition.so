package types

import "github.com/near/borsh-go"

const (
	ArgsFreshBackwards borsh.Enum = iota
	ArgsSolve
	ArgsVersion
	ArgsAuthority
	ArgsSolveV2
)

type (
	Args struct {
		Enum           borsh.Enum     `borsh_enum:"true" json:"enum"`
		FreshBackwards FreshBackwards `json:"fresh_backwards"`
		Solve          Solve          `json:"solve"`
		SolveV2        SolveV2        `json:"solve_v2"`
	}

	Permit struct {
		Token    [20]byte `json:"token"`
		Deadline uint64   `json:"deadline"`
		V        uint8    `json:"v"`
		R        [32]byte `json:"r"`
		S        [32]byte `json:"s"`
	}

	FromArgs struct {
		Token      [20]byte `json:"token"`
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

	SolveArgsSigArgs struct {
		Sig  [64]byte  `json:"sig"`
		Args SolveArgs `json:"args"`
	}

	ArgsAuthority [20]byte

	FreshBackwards struct {
		Key       [32]byte           `json:"key"`
		EoaAddr   [20]byte           `json:"eoa_addr"`
		V         uint8              `json:"v"`
		R         [32]byte           `json:"r"`
		S         [32]byte           `json:"s"`
		SolveArgs []SolveArgsSigArgs `json:"solve_args"`
		Authority *ArgsAuthority     `json:"authority"`
	}

	Solve struct {
		Slot uint32             `json:"slot"`
		Args []SolveArgsSigArgs `json:"args"`
	}

	SolveV2 struct {
		Slot          uint32             `json:"slot"`
		Args          []SolveArgsSigArgs `json:"args"`
		PermitOwner   [20]byte           `json:"permit_owner"`
		TransferOwner [20]byte           `json:"transfer_owner"`
	}
)
