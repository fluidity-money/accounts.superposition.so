use bobcat_sdk::{entry::msg_sender, maths::U, storage::storage_store};

use crate::{SLOT_IMPL, storage};

pub fn entry_migrate(ed_key: &U, evm_owner: &U, impl_addr: &U, authority_addr: &U) -> usize {
    // Despite whatever we're doing, we will always change the
    // implementation. So this must be set:
    assert!(impl_addr.is_some());

    let migration_level = storage::version::get();
    let mut is_first_time = false;

    // Duplicate storage writes here aren't a big deal thanks to the Stylus tree:

    /* ~~~~ MIGRATION LEVEL 0: ~~~~
     * 1. Sets up the owner of the contract, including the slots.
     * 2. Migrates to the new storage slot for the implementation.
     */

    if migration_level == U::ZERO {
        assert!(ed_key.is_some());
        assert!(evm_owner.is_some());
        // First time migration: set up the contract state:
        storage::ed25519_slot::set(&U::ZERO, ed_key);
        storage::ed25519_count::set(&U::ONE);
        storage::ethereum_owner::set(evm_owner);
        is_first_time = true;
    }

    /* ~~~~ MIGRATION LEVEL 1: ~~~~
     * 1. Sets up the authority address.
     * 2. Sets up the new implementation address.
     */

    if migration_level <= U::ONE {
        assert!(impl_addr.is_some());
        storage::authority::set(authority_addr);
    }

    // If we've already migrated this contract, then we need to also check
    // the migrator to prevent abuse. This should unwind the tree so it's
    // safe to have here, at the end:
    if !is_first_time {
        assert_eq!(
            storage::ethereum_owner::get(),
            msg_sender().into(),
            "bad migrator"
        );
    }

    // Despite the way this function works as a migration function, we allow
    // users to upgrade themselves to any implementation they want:

    storage_store(&SLOT_IMPL, impl_addr);

    storage::version::set(&U::from(2u32));
    0
}
