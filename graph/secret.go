package graph

import (
	"crypto/rand"
	"fmt"
	"log/slog"

	"golang.org/x/crypto/argon2"
)

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
