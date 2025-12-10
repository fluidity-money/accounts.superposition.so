#![cfg_attr(target_arch = "wasm32", no_main)]
#![no_std]

use bobcat_sdk::{
    cd::read_words,
    entry::{read_args_vec, write_result_word},
    proxy::SEL_MIGRATE,
    storage::{flush_guard, reentrancy_guard_const_keccak, storage_load},
};

use borsh::de::BorshDeserialize;

#[global_allocator]
#[cfg(target_arch = "wasm32")]
static ALLOC: mini_alloc::MiniAlloc = mini_alloc::MiniAlloc::INIT;

use libaccounts::{entry, entry_migrate::entry_migrate, Args, SLOT_IMPL};

#[unsafe(no_mangle)]
pub unsafe extern "C" fn user_entrypoint(len: usize) -> usize {
    // If we don't get a message, we dump the location of the implementation.
    // This is due to the recursive metamorphic pattern we use for beacons.
    if len == 0 {
        write_result_word(&storage_load(&SLOT_IMPL));
        return 0;
    }
    flush_guard(|| {
        let args = read_args_vec(len);
        match args[..4].try_into().unwrap() {
            SEL_MIGRATE => {
                // Someone is migrating a client proxy as this contract called itself! We
                // need to call a special function here, and skip the usual entrypoint.
                let (ed_key, eoa_owner, impl_addr) = read_words!(&args[4..], 3);
                entry_migrate(ed_key, eoa_owner, impl_addr);
            }
            _ => reentrancy_guard_const_keccak(b"superposition.accounts", || {
                entry(
                    Args::deserialize(&mut args.as_slice())
                        .map_err(|_| panic!("weird: {}", const_hex::encode(args)))
                        .unwrap(),
                )
            }),
        }
    })
}

#[allow(unused)]
fn main() {}
