package ninelives

import (
	"bytes"
	_ "embed"
	"fmt"
	"math/big"

	ethAbi "github.com/ethereum/go-ethereum/accounts/abi"
	ethCommon "github.com/ethereum/go-ethereum/common"
)

//go:embed abi.json
var abiB []byte

var abi, _ = ethAbi.JSON(bytes.NewReader(abiB))

// NewMint by creating the calldata that would be generated for this invocation.
func NewMint(outcome [8]byte, value [32]byte, referrer, recipient [20]byte) []byte {
	a, err := abi.Pack(
		"mint8A059B6E",
		outcome,
		new(big.Int).SetBytes(value[:]),
		ethCommon.Address(referrer),
		ethCommon.Address(recipient),
	)
	if err != nil {
		panic(err)
	}
	return a
}

// UnpackMint calldata for testing and reproduction purposes.
func UnpackMint(cd []byte) (outcome [8]byte, value [32]byte, referrer, recipient [20]byte, err error) {
	if l := len(cd); l != 4 + 32 * 4 {
		err = fmt.Errorf("bad mint cd: %v", l)
		return
	}
	copy(outcome[:], cd[4:4+32][:32-8])
	copy(value[:], cd[4+32:4+32*2])
	copy(referrer[:], cd[4+32*2:4+32*3][:32-20])
	copy(referrer[:], cd[4+32*3:4+32*4][:32-20])
	return
}

func NewClaimForOther(addresses []ethCommon.Address, eoa ethCommon.Address) []byte {
	a, err := abi.Pack("claimForOther",addresses, eoa,)
	if err != nil {
		panic(err)
	}
	return a
}
