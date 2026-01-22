use bobcat_sdk::{
    maths::U,
    storage::{storage_load, storage_store},
};

use crate::{SLOT_IMPL, storage};

pub fn entry_migrate(ed_key: &U, evm_owner: &U, impl_addr: &U) -> usize {
    assert!(ed_key.is_some());
    assert!(evm_owner.is_some());
    if storage_load(&SLOT_IMPL).is_zero() {
        storage::ed25519_slot::set(&U::ZERO, ed_key);
        storage::ed25519_count::set(&U::ONE);
        storage::ethereum_owner::set(evm_owner);
        assert!(impl_addr.is_some());
        storage_store(&SLOT_IMPL, impl_addr);
        storage::version::set(&U::ONE);
    }
    0
}
