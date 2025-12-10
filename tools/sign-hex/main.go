package main

import (
	"bufio"
	"strings"
	"encoding/hex"
	"encoding/json"
	"os"

	ethCrypto "github.com/ethereum/go-ethereum/crypto"
)

func main() {
	p, err := ethCrypto.HexToECDSA(os.Args[1])
	if err != nil {
		panic(err)
	}
	r := bufio.NewReader(os.Stdin)
	l, _, err := r.ReadLine()
	if err != nil {
		panic(err)
	}
	b, err := hex.DecodeString(strings.TrimPrefix(string(l), "0x"))
	if err != nil {
		panic(err)
	}
	s, err := ethCrypto.Sign(b, p)
	if err != nil {
		panic(err)
	}
	R := s[0:32]
	S := s[32:64]
	v := s[64] + 27
	err = json.NewEncoder(os.Stdout).Encode(struct {
		R string `json:"r"`
		S string `json:"s"`
		V uint8  `json:"v"`
	}{
		R: hex.EncodeToString(R),
		S: hex.EncodeToString(S),
		V: v,
	})
}
