#![cfg_attr(target_arch = "wasm32", no_main)]
#![no_std]

use bobcat_sdk::{
    cd::read_words,
    entry::read_args_vec,
    proxy::SEL_MIGRATE,
    storage::{flush_guard, reentrancy_guard_const_keccak},
};

use borsh::de::BorshDeserialize;

#[global_allocator]
#[cfg(target_arch = "wasm32")]
static ALLOC: mini_alloc::MiniAlloc = mini_alloc::MiniAlloc::INIT;

use libaccounts::{entry, entry_migrate::entry_migrate, Args};

#[unsafe(no_mangle)]
pub unsafe extern "C" fn user_entrypoint(len: usize) -> usize {
    flush_guard(|| {
        let args = read_args_vec(len);
        if args[..4] == SEL_MIGRATE {
            // Someone is migrating a client proxy as this contract called itself! We
            // need to call a special function here, and skip the usual entrypoint.
            let (ed_key, eoa_owner, impl_addr) = read_words!(&args[4..], 3);
            return entry_migrate(ed_key, eoa_owner, impl_addr);
        }
        reentrancy_guard_const_keccak(b"superposition.accounts", || {
            entry(Args::deserialize(&mut args.as_slice()).unwrap())
        })
    })
}

#[allow(unused)]
fn main() {}
