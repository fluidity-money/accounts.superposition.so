package main

import (
	"crypto/ecdsa"
	"math/big"
	"os"
	"log/slog"
	"encoding/hex"
	"encoding/json"

	ethCommon "github.com/ethereum/go-ethereum/common"
	ethCrypto "github.com/ethereum/go-ethereum/crypto"
)

const (
	// TokenName in use for the canonical USDC on Superposition.
	TokenName = "Bridged USDC (Stargate)"

	// TokenVersion in use for Permit (currently v2 on the deployment).
	TokenVersion = "2"
)

// ChainId of Mainnet Superposition.
var ChainId = new(big.Int).SetInt64(55244)

func main() {
	privKey, err := ethCrypto.HexToECDSA(os.Args[1])
	if err != nil {
		panic(err)
	}
	accountsAddr := ethCommon.HexToAddress(os.Args[2])
	nonce, ok := new(big.Int).SetString(os.Args[3], 10)
	if !ok {
		panic("bad nonce")
	}
	pubKey, _ := privKey.Public().(*ecdsa.PublicKey)
	ownerAddr := ethCrypto.PubkeyToAddress(*pubKey)
	tokenAddr := ethCommon.HexToAddress(os.Args[4])
	deadline, ok := new(big.Int).SetString(os.Args[5], 10)
	if !ok {
		panic("bad deadline")
	}
	domainSep := ethCrypto.Keccak256(
		ethCrypto.Keccak256(
			[]byte("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
		),
		ethCrypto.Keccak256([]byte(TokenName)),
		ethCrypto.Keccak256([]byte(TokenVersion)),
		ethCommon.BigToHash(ChainId).Bytes(),
		ethCommon.LeftPadBytes(tokenAddr.Bytes(), 32),
	)
	permitHash := ethCrypto.Keccak256(
		[]byte("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
	)
	slog.Info("about to do some struct hashing",
		"owner addr", ownerAddr,
		"accounts addr", accountsAddr,
		"max hash", ethCommon.MaxHash,
		"nonce", nonce,
		"deadline", deadline,
	)
	structHash := ethCrypto.Keccak256(
		permitHash,
		ethCommon.LeftPadBytes(ownerAddr.Bytes(), 32),
		ethCommon.LeftPadBytes(accountsAddr.Bytes(), 32),
		ethCommon.MaxHash.Bytes(),
		ethCommon.LeftPadBytes(nonce.Bytes(), 32),
		ethCommon.LeftPadBytes(deadline.Bytes(), 32),
	)
	d := ethCrypto.Keccak256Hash(
		[]byte("\x19\x01"),
		domainSep,
		structHash,
	)
	sig, err := ethCrypto.Sign(d.Bytes(), privKey)
	if err != nil {
		panic(err)
	}
	var (
		r = sig[:32]
		s = sig[32:64]
		v = sig[64]
	)
	if v < 27 {
		v += 27
	}
	err = json.NewEncoder(os.Stdout).Encode(struct {
		V uint8  `json:"v"`
		R string `json:"r"`
		S string `json:"s"`
	}{
		V: v,
		R: hex.EncodeToString(r),
		S: hex.EncodeToString(s),
	})
	if err != nil {
		panic(err)
	}
}
