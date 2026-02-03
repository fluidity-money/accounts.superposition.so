use bobcat_sdk::{
    entry::msg_sender,
    maths::U,
    storage::{storage_load, storage_store},
};

use crate::{storage, SLOT_IMPL};

pub fn entry_migrate(ed_key: &U, evm_owner: &U, impl_addr: &U, authority_addr: &U) -> usize {
    let migration_level = storage_load(&SLOT_IMPL);
    let mut is_first_time = false;

    // Duplicate storage writes here aren't a big deal thanks to the Stylus trie:

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
        assert!(impl_addr.is_some());
        storage_store(&SLOT_IMPL, impl_addr);
        is_first_time = true;
    }

    /* ~~~~ MIGRATION LEVEL 1: ~~~~
     * 1. Sets up the authority address.
     * 2. Sets up the new implementation address.
     */

    if migration_level <= U::ONE {
        // If we've already migrated this contract, then we need to also check
        // the migrator to prevent abuse:
        if storage::ethereum_owner::get().is_some() && !is_first_time {
            assert_eq!(
                storage::ethereum_owner::get(),
                msg_sender().into(),
                "bad migrator"
            );
        }
        assert!(impl_addr.is_some());
        storage_store(&SLOT_IMPL, impl_addr);
        storage::authority::set(authority_addr);
    }
    storage::version::set(&U::from(2u32));
    0
}
