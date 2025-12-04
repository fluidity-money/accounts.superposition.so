package types

import (
	"testing"

	ethCommon "github.com/ethereum/go-ethereum/common"

	"github.com/stretchr/testify/assert"
)

func TestGetClientAddr(t *testing.T) {
	assert.Equal(t,
		ethCommon.HexToAddress("0x0977b7ed94dd96f1adc28225ac4eb11f363d5eb7"),
		GetClientAddr(
			ethCommon.HexToAddress("0x0000000000000000000000000000000000000000"),
			ethCommon.HexToAddress("0xfeb6034fc7df27df18a3a6bad5fb94c0d3dcb6d5"),
		),
	)
}
