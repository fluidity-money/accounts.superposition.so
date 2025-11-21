#![no_main]
#![no_std]

use bobcat_sdk::{
    entry::{read_args_vec},
    proxy::SEL_MIGRATE,
    storage::reentrancy_guard_const_keccak,
};

use borsh::de::BorshDeserialize;

#[global_allocator]
#[cfg(target_arch = "wasm32")]
static ALLOC: mini_alloc::MiniAlloc = mini_alloc::MiniAlloc::INIT;

use libaccounts::{entry_migrate::entry_migrate, entry, Args};

pub type OurLzss = lzss::Lzss<12, 11, 0, { 1 << 12 }, { 2 << 12 }>;

#[unsafe(no_mangle)]
pub unsafe extern "C" fn user_entrypoint(len: usize) -> usize {
    let args = read_args_vec(len);
    if args[..4] == SEL_MIGRATE {
    // Someone is migrating a client proxy! We need to call a special
    // function here, and skip the usual entrypoint.
        return entry_migrate();
    }
    reentrancy_guard_const_keccak(b"superposition.accounts", || {
        entry(
            Args::deserialize(
                &mut OurLzss::decompress_stack(
                    lzss::SliceReader::new(&args[1..]),
                    lzss::VecWriter::with_capacity(1024 * 10),
                )
                .unwrap()
                .as_slice(),
            )
            .unwrap(),
        )
    })
}
