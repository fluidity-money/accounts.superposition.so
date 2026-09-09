package convertor

import (
	"os"
	"path/filepath"
	"reflect"
	"testing"

	ethCommon "github.com/ethereum/go-ethereum/common"
	"github.com/fluidity-money/accounts.superposition.so/lib/types"
)

func TestCreateSolveV2BindsOwnersAndUsesV2Variant(t *testing.T) {
	dir := t.TempDir()
	signer := filepath.Join(dir, "signer")
	if err := os.WriteFile(signer, []byte("#!/bin/sh\nprintf 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'\n"), 0o700); err != nil {
		t.Fatalf("writing signer: %v", err)
	}

	solveArgs := []types.SolveArgs{{MsTs: [16]byte{1}}}
	permitOwner := ethCommon.HexToAddress("0x1111111111111111111111111111111111111111")
	transferOwner := ethCommon.HexToAddress("0x2222222222222222222222222222222222222222")

	got, err := CreateSolveV2(signer, solveArgs, permitOwner, transferOwner)
	if err != nil {
		t.Fatalf("creating solve v2: %v", err)
	}
	if got.Enum != types.ArgsSolveV2 {
		t.Fatalf("variant = %d, want %d", got.Enum, types.ArgsSolveV2)
	}
	if !reflect.DeepEqual(got.SolveV2.Args.Args, solveArgs) {
		t.Fatalf("solve args = %#v, want %#v", got.SolveV2.Args.Args, solveArgs)
	}
	if got.SolveV2.Args.PermitOwner != permitOwner {
		t.Fatalf("permit owner = %x, want %x", got.SolveV2.Args.PermitOwner, permitOwner)
	}
	if got.SolveV2.Args.TransferOwner != transferOwner {
		t.Fatalf("transfer owner = %x, want %x", got.SolveV2.Args.TransferOwner, transferOwner)
	}
	var wantSig types.Sig
	for i := range wantSig {
		wantSig[i] = 'a'
	}
	if got.SolveV2.Sig != wantSig {
		t.Fatalf("signature = %x, want %x", got.SolveV2.Sig, wantSig)
	}
}
