use alloc::vec::Vec;

use bobcat_sdk::{
    call::call_unit,
    create::create2_pre_unit,
    entry::{contract_address, write_result_word},
    maths::U,
    precompiles::ethereum::ecrecover,
    proxy::{make_metamorphic_proxy, SEL_MIGRATE},
    storage::{const_slot_off_curve, storage_load},
};

use crate::{Args, ArgsAddr, SolveArgsSigArgs};

use array_concat::concat_arrays;

const SLOT_IMPL: U = const_slot_off_curve(b"eip1967.proxy.implementation");

pub fn entry_fresh_backwards(
    pub_key: U,
    eoa_addr: ArgsAddr,
    v: u8,
    r: U,
    s: U,
    solve_args: Vec<SolveArgsSigArgs>,
) -> usize {
    assert_eq!(eoa_addr.0, ecrecover(pub_key, v, r, s, u64::MAX).unwrap());
    let proxy = create2_pre_unit(
        &make_metamorphic_proxy(contract_address()),
        U::ZERO,
        &eoa_addr.0,
    )
    .unwrap();
    let impl_addr = storage_load(&SLOT_IMPL);
    let migrate_cd: [u8; 4 + 32 * 3] =
        concat_arrays!(SEL_MIGRATE, pub_key.0, U::from(eoa_addr.0).0, impl_addr.0);
    assert!(
        call_unit(proxy, &migrate_cd, &U::ZERO, u64::MAX),
        "bad migration"
    );
    if !solve_args.is_empty() {
        assert!(call_unit(
            proxy,
            &borsh::to_vec(&Args::Solve {
                slot: 0,
                args: solve_args
            })
            .unwrap(),
            &U::ZERO,
            u64::MAX
        ));
    }
    write_result_word(&proxy.into());
    0
}

#[cfg(all(test, feature = "std"))]
mod test {
    use super::*;

    use bobcat_sdk::prelude::{address, const_estimate_addr_pre};

    #[test]
    #[ignore]
    fn test_print_derived_address() {
        println!(
            "{}",
            const_hex::encode(const_estimate_addr_pre(
                address!(b"0000000000000000000000000000000000000000"),
                &make_metamorphic_proxy(address!(b"0000000000000000000000000000000000000000")),
                &address!(b"feb6034fc7df27df18a3a6bad5fb94c0d3dcb6d5"),
            ))
        );
    }
}
