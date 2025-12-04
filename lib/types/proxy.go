package types

import (
	"encoding/hex"

	ethCommon "github.com/ethereum/go-ethereum/common"
	ethCrypto "github.com/ethereum/go-ethereum/crypto"
)

func makeMetamorphicProxyHash(factory ethCommon.Address) []byte {
	d, _ := hex.DecodeString("606a8060093d393df3365f5f375f3560e01c638fd3ab801461001757610031565b73")
	d = append(d, factory.Bytes()...)
	d1, _ := hex.DecodeString("610054565b7f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc545b5f365f5f935af43d5f5f3e3d5f8261006857fd5bf3")
	d = append(d, d1...)
	return ethCrypto.Keccak256(d)
}

func GetClientAddr(factory, eoa ethCommon.Address) ethCommon.Address {
	salt := ethCrypto.Keccak256(eoa.Bytes())
	d := make([]byte, 1+20+32+32)
	d[0] = 0xff
	copy(d[1:21], factory.Bytes())
	copy(d[21:53], salt[:])
	m := makeMetamorphicProxyHash(factory)
	copy(d[53:85], m[:])
	h := ethCrypto.Keccak256(d)
	return ethCommon.BytesToAddress(h[12:])
}
