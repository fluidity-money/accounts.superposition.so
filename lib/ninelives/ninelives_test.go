package ninelives

import (
	"testing"

	fuzz "github.com/AdaLogics/go-fuzz-headers"

	"github.com/stretchr/testify/assert"
)

func FuzzNewMint(f *testing.F) {
	f.Fuzz(func(t *testing.T, d []byte) {
		c := fuzz.NewConsumer(d)
		var a struct {
			Outcome             [8]byte
			Value               [32]byte
			Referrer, Recipient [20]byte
		}
		if err := c.GenerateStruct(&a); err != nil {
			return
		}
		o, v, ref, rec, err := UnpackMint(NewMint(a.Outcome, a.Value, a.Referrer, a.Recipient))
		if err != nil {
			panic(err)
		}
		assert.Equal(t, a.Outcome, o)
		assert.Equal(t, a.Value, v)
		assert.Equal(t, a.Referrer, ref)
		assert.Equal(t, a.Recipient, rec)
	})
}
