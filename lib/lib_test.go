package lib

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
