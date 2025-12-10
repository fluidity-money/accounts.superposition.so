package types

import (
	"encoding/hex"

	ethCommon "github.com/ethereum/go-ethereum/common"
	ethCrypto "github.com/ethereum/go-ethereum/crypto"
)

func makeMetamorphicBeaconProxyHash(factory ethCommon.Address) []byte {
	d, _ := hex.DecodeString("60738060093d393df35f3560e01c638fd3ab801461001357610036565b60205f5f5f73")
	d = append(d, factory.Bytes()...)
	d1, _ := hex.DecodeString("5afa5f51610059565b7f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc545b365f5f375f365f5f935af43d5f5f3e3d5f8261007157fd5bf3")
	d = append(d, d1...)
	return ethCrypto.Keccak256(d)
}

func GetClientAddr(factory, eoa ethCommon.Address) ethCommon.Address {
	salt := ethCrypto.Keccak256(eoa.Bytes())
	d := make([]byte, 1+20+32+32)
	d[0] = 0xff
	copy(d[1:21], factory.Bytes())
	copy(d[21:53], salt[:])
	m := makeMetamorphicBeaconProxyHash(factory)
	copy(d[53:85], m[:])
	h := ethCrypto.Keccak256(d)
	return ethCommon.BytesToAddress(h[12:])
}
