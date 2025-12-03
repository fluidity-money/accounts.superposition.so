package graph

import (
	"crypto/ed25519"
	"encoding/hex"
	"testing"

	"github.com/fluidity-money/accounts.superposition.so/graph/model"
	"github.com/fluidity-money/accounts.superposition.so/lib/ninelives"
	"github.com/fluidity-money/accounts.superposition.so/lib/types"

	fuzz "github.com/AdaLogics/go-fuzz-headers"

	"github.com/stretchr/testify/assert"
)

func FuzzCreateAccountToFreshBackwardsNaive(f *testing.F) {
	f.Fuzz(func(t *testing.T, d []byte) {
		c := fuzz.NewConsumer(d)
		var a struct {
			Key [ed25519.PublicKeySize]byte
			model.CreateAccount
		}
		if err := c.GenerateStruct(&a); err != nil {
			return
		}
		_, _ = CreateAccountToFreshBackwards(a.Key, a.CreateAccount)
	})
}

func h(x []byte) string {
	return hex.EncodeToString(x)
}

func freshBackwardsToCreateAccountAndMint(f types.FreshBackwards) (c model.CreateAccount, m *model.Mint, err error) {
	if len(f.SolveArgs) > 0 {
		s := f.SolveArgs[0]
		outcome, value, referrer, _, err := ninelives.UnpackMint(s.Args.Cd)
		if err != nil {
			return c, nil, err
		}
		m = &model.Mint{
			Market:   h(s.Args.Target[:]),
			Outcome:  h(outcome[:]),
			Amount:   h(value[:]),
			Referrer: h(referrer[:]),
			MsTs:     s.Args.MsTs.String(),
		}
		if len(s.Args.Permit) > 0 {
			permit := s.Args.Permit[0]
			m.Permit = &model.Permit{
				Token:    h(permit.Token[:]),
				Deadline: int32(permit.Deadline),
				PermitV:  int32(permit.V),
				PermitR:  h(permit.R[:]),
				PermitS:  h(permit.S[:]),
			}
		}
	}
	return model.CreateAccount{
		EoaAddr: h(f.EoaAddr[:]),
		SigV:    int32(f.V),
		SigR:    h(f.R[:]),
		SigS:    h(f.S[:]),
	}, m, err
}

func FuzzCreateAccountToFreshBackwardsLegit(f *testing.F) {
	f.Fuzz(func(t *testing.T, d []byte) {
		c := fuzz.NewConsumer(d)
		// It's hard for us to ensure the type is consistent when it comes to the
		// calldata, so we enforce some correctness here by inserting this
		// ourselves:
		var a struct {
			Key [ed25519.PrivateKeySize]byte
			types.FreshBackwards
			Token, Recipient [20]byte
			MintArgs         []struct {
				Outcome  [8]byte
				Sig [64]byte
				Value    [32]byte
				Referrer [20]byte
				types.SolveArgs
			}
		}
		if err := c.GenerateStruct(&a); err != nil {
			return
		}
		recipient := hex.EncodeToString(a.Recipient[:])
		a.FreshBackwards.SolveArgs = nil
		for _, s := range a.MintArgs {
			s.SolveArgs.Cd = ninelives.NewMint(
				s.Outcome,
				s.Value,
				s.Referrer,
				a.Recipient,
			)
			a.FreshBackwards.SolveArgs = append(a.FreshBackwards.SolveArgs, types.SolveArgsSigArgs{
				Sig:  s.Sig,
				Args: s.SolveArgs,
			})
		}
		createAccount, mint, err := freshBackwardsToCreateAccountAndMint(a.FreshBackwards)
		assert.NoError(t, err, "%+v", a.FreshBackwards)
		priv := ed25519.PrivateKey(a.Key[:])
		pub_, ok := priv.Public().(ed25519.PublicKey)
		if !ok {
			t.Fatalf("pub: %T", priv.Public())
		}
		var pub [32]byte
		copy(pub[:], pub_)
		f, err := CreateAccountToFreshBackwards(pub, createAccount)
		assert.NoError(t, err, "%+v", createAccount)
		if mint != nil {
			err = TagFreshBackwardsWithMint(
				f,
				priv,
				a.Token,
				mint.Market,
				mint.Outcome,
				mint.Amount,
				mint.Referrer,
				recipient,
				mint.Permit,
				mint.MsTs,
			)
			assert.NoError(t, err)
		}
	})
}
