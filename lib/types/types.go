package types

import (
	"math/big"

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
		Deadline uint64
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
		Args SolveArgs
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
