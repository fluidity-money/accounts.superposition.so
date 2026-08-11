package main

import (
	"fmt"
	"math/big"
	"os"
)

func main() {
	v, ok := new(big.Int).SetString(os.Args[1], 10)
	if !ok {
		panic("bad arg")
	}
	b := v.Bytes()
	c := make([]byte, 32-len(b))
	fmt.Printf("%x\n", append(c, b...))
}
