package graph

import "golang.org/x/crypto/argon2"

func MakeKey(password, salt []byte) []byte {
	return argon2.IDKey(password, salt, 1, 64*1024, 4, 32)
}
