package main

import (
	"bytes"
	"encoding/hex"
	"encoding/json"
	"os"
	"strconv"
	"strings"

	ethCrypto "github.com/ethereum/go-ethereum/crypto"
)

func main() {
	p, err := ethCrypto.HexToECDSA(strings.TrimPrefix(os.Args[1], "0x"))
	if err != nil {
		panic(err)
	}
	var buf bytes.Buffer
	if _, err := buf.ReadFrom(os.Stdin); err != nil {
		panic(err)
	}
	d := ethCrypto.Keccak256(
		[]byte("\x19Ethereum Signed Message:\n"),
		[]byte(strconv.Itoa(buf.Len())),
		buf.Bytes(),
	)
	s, err := ethCrypto.Sign(d, p)
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
