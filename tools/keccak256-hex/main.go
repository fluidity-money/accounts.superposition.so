package main

import (
	"bufio"
	"encoding/hex"
	"os"

	ethCrypto "github.com/ethereum/go-ethereum/crypto"
)

func main() {
	r := bufio.NewReader(os.Stdin)
	l, _, err := r.ReadLine()
	if err != nil {
		panic(err)
	}
	b, err := hex.DecodeString(string(l))
	if err != nil {
		panic(err)
	}
	_, err = hex.NewEncoder(os.Stdout).Write(ethCrypto.Keccak256(b))
	if err != nil {
		panic(err)
	}
}
