#![cfg_attr(target_arch = "wasm32", no_main)]
#![no_std]

use bobcat_sdk::{
    cd::read_words,
    entry::{read_args_vec, write_result_word},
    proxy::SEL_MIGRATE,
    storage::{flush_guard, storage_load},
};

use borsh::de::BorshDeserialize;

#[global_allocator]
#[cfg(target_arch = "wasm32")]
static ALLOC: mini_alloc::MiniAlloc = mini_alloc::MiniAlloc::INIT;

use superposition_libaccounts::{Args, SLOT_IMPL, entry, entry_migrate::entry_migrate};

use superposition_assets::Network;

#[cfg(all(feature = "network-arbitrum", feature = "network-robinhood"))]
compile_error!("network-arbitrum and network-robinhood can't be both enabled");

#[cfg(not(any(feature = "network-arbitrum", feature = "network-robinhood")))]
compile_error!("network-arbitrum or network-robinhood must be enabled");

#[unsafe(no_mangle)]
pub unsafe extern "C" fn user_entrypoint(len: usize) -> usize {
    // If we don't get amessage, we dump the location of the implementation.
    // This is due to the recursive metamorphic pattern we use for beacons.
    if len == 0 {
        write_result_word(&storage_load(&SLOT_IMPL));
        return 0;
    }
    #[cfg(feature = "network-arbitrum")]
    let network = Network::Arbitrum;
    #[cfg(feature = "network-robinhood")]
    let network = Network::Robinhood;
    flush_guard(|| {
        let args = read_args_vec(len);
        if args.len() > 4 && args[..4] == SEL_MIGRATE {
            // Someone is migrating a client proxy as this contract called itself! We
            // need to call a special function here, and skip the usual entrypoint.
            let (ed_key, eoa_owner, impl_addr, authority_addr) = read_words!(&args[4..], 4);
            entry_migrate(ed_key, eoa_owner, impl_addr, authority_addr)
        } else {
            entry(
                network,
                Args::deserialize(&mut args.as_slice())
                    .map_err(|err| panic!("weird: {}: err: {err}", const_hex::encode(args)))
                    .unwrap(),
            )
        }
    })
}

#[allow(unused)]
fn main() {}
