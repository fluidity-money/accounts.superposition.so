use bobcat_sdk::maths::U;

use crate::storage;

pub fn entry_migrate(ed_key: &U, evm_owner: &U) -> usize {
    // This function migrates the contract's storage to a v1 form
    // (currently). Aka, it sets a storage field that says this contract can
    // only be used by a pair of addresses.
    assert!(
        storage::ed25519_slot::get(&U::ZERO).is_zero(),
        "slot 0 is not empty"
    );
    // In this function, we use transient storage to load the key that's used
    // for the first time and the sender.
    storage::ed25519_slot::set(&U::ZERO, &ed_key);
    storage::ed25519_count::set(&U::ONE);
    storage::ethereum_owner::set(&evm_owner);
    0
}
