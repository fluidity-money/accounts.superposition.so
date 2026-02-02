use bobcat_sdk::{
    entry::msg_sender,
    maths::U,
    storage::{storage_load, storage_store},
};

use crate::{storage, SLOT_IMPL};

pub fn entry_migrate(ed_key: &U, evm_owner: &U, impl_addr: &U, authority_addr: &U) -> usize {
    assert!(ed_key.is_some());
    assert!(evm_owner.is_some());
    let migration_level = storage_load(&SLOT_IMPL);
    if migration_level == U::ZERO {
        // First time migration: set up the contract state:
        storage::ed25519_slot::set(&U::ZERO, ed_key);
        storage::ed25519_count::set(&U::ONE);
        storage::ethereum_owner::set(evm_owner);
        assert!(impl_addr.is_some());
        storage_store(&SLOT_IMPL, impl_addr);
    }
    if migration_level == U::ONE {
        // If we've already migrated this contract, then we need to also check
        // the migrator to prevent abuse:
        if storage::ethereum_owner::get().is_some() {
            assert_eq!(
                storage::ethereum_owner::get(),
                msg_sender().into(),
                "bad migrator"
            );
        }
        // Second time migration: set up the method whitelisting features:
        storage::authority::set(authority_addr);
    }
    storage::version::set(&U::from(2u32));
    0
}
