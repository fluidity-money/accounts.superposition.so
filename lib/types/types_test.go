package types

import (
	"bytes"
	"testing"

	fuzz "github.com/AdaLogics/go-fuzz-headers"

	"github.com/near/borsh-go"
)

func FuzzBorshStructs(f *testing.F) {
	f.Fuzz(func(t *testing.T, d []byte) {
		c := fuzz.NewConsumer(d)
		var (
			a    Args
			sink bytes.Buffer
		)
		if err := c.GenerateStruct(&a); err != nil {
			return
		}
		a.Enum = a.Enum % 3
		if err := borsh.NewEncoder(&sink).Encode(a); err != nil {
			t.Fatalf("encoding: %v", err)
		}
	})
}

func TestSolveV2ArgsBindsOwners(t *testing.T) {
	args := SolveV2Args{
		PermitOwner:   [20]byte{1},
		TransferOwner: [20]byte{2},
	}
	encoded, err := borsh.Serialize(args)
	if err != nil {
		t.Fatalf("encoding SolveV2Args: %v", err)
	}
	changedPermit := args
	changedPermit.PermitOwner = [20]byte{3}
	changedPermitEncoded, err := borsh.Serialize(changedPermit)
	if err != nil {
		t.Fatalf("encoding changed permit owner: %v", err)
	}
	if bytes.Equal(encoded, changedPermitEncoded) {
		t.Fatal("changing permit owner did not change signed bytes")
	}
	changedTransfer := args
	changedTransfer.TransferOwner = [20]byte{3}
	changedTransferEncoded, err := borsh.Serialize(changedTransfer)
	if err != nil {
		t.Fatalf("encoding changed transfer owner: %v", err)
	}
	if bytes.Equal(encoded, changedTransferEncoded) {
		t.Fatal("changing transfer owner did not change signed bytes")
	}
}
