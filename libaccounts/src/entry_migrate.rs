
use bobcat_sdk::{maths::U, entry::msg_sender, storage::transient_load};

use crate::storage;

pub fn entry_migrate() -> usize {
    // This function migrates the contract's storage to a v1 form
    // (currently). Aka, it sets a storage field that says this contract can
    // only be used by a pair of addresses.
    assert!(storage::ed25519_slot::get(&U::ZERO).is_zero(), "slot 0 is not empty");
    // In this function, we use transient storage to load the key that's used
    // for the first time and the sender.
    storage::ed25519_slot::set(&U::ZERO, &msg_sender().into());
    storage::ed25519_count::set(&U::ONE);
    let ed25519_key = transient_load(&U::ZERO);
    storage::ethereum_owner::set(&ed25519_key);
    0
}
