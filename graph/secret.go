package graph

import (
	"crypto/rand"
	"fmt"
	"math/big"
	"log/slog"

	"golang.org/x/crypto/argon2"
)

//57896044618658097711785492504343953926418782139537452191302581570759080747168
var secpMaxS = new(big.Int).SetBits([]big.Word{
	16134479119472337056,
	6725966010171805725,
	18446744073709551615,
	9223372036854775807,
})

func MakeKey(password, salt []byte) []byte {
	return argon2.IDKey(password, salt, 1, 64*1024, 4, 32)
}

func makeSecrets() (salt []byte, secret []byte, err error) {
	secret = make([]byte, 32)
	if n, err := rand.Read(secret); n != 32 || err != nil {
		slog.Error("error seeding randomness",
			"err", err,
		)
		return nil, nil, fmt.Errorf("error with randomness")
	}
	salt = make([]byte, 16)
	if n, err := rand.Read(salt); n != 16 || err != nil {
		slog.Error("error seeding randomness",
			"err", err,
		)
		return nil, nil, fmt.Errorf("error with randomness")
	}
	return
}
