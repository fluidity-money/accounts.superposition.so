package db

import (
	"crypto/ecdsa"
	"database/sql"
	"fmt"

	ethCommon "github.com/ethereum/go-ethereum/common"
	ethCrypto "github.com/ethereum/go-ethereum/crypto"
)

// PickPrivateKey using a backoff system of picking the lowest ranked
// address at a given time. Then derive the public key here.
func PickPrivateKey(db *sql.DB) (*ecdsa.PrivateKey, *ethCommon.Address, error) {
	r := db.QueryRow("SELECT accounts_get_private_key_1()")
	var s string
	switch err := r.Scan(&s); err {
	case sql.ErrNoRows:
		return nil, nil, fmt.Errorf("no rows")
	case nil:
	default:
		return nil, nil, fmt.Errorf("calling function: %v", err)
	}
	key, err := ethCrypto.HexToECDSA(s)
	if err != nil {
		return nil, nil, fmt.Errorf("hex to ecdsa: %v", err)
	}
	p, _ := key.Public().(*ecdsa.PublicKey)
	pub := ethCrypto.PubkeyToAddress(*p)
	return key, &pub, nil
}