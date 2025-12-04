use alloc::vec::Vec;

use bobcat_sdk::{
    call::call_unit,
    create::create2_pre_unit,
    entry::{contract_address, msg_sender, write_result_word},
    maths::U,
    precompiles::ecrecover,
    proxy::{make_metamorphic_proxy, SEL_MIGRATE},
    storage::transient_store,
};

use crate::{entry_solve, ArgsAddr, SolveArgsSigArgs};

use ed25519_dalek::VerifyingKey;

pub fn entry_fresh(pub_key: U, solve_args: Vec<SolveArgsSigArgs>) -> usize {
    let pub_key = VerifyingKey::from_bytes(pub_key.as_slice()).unwrap();
    let proxy = create2_pre_unit(
        &make_metamorphic_proxy(contract_address()),
        U::ZERO,
        &msg_sender(),
    )
    .unwrap();
    transient_store(&U::ZERO, &pub_key.to_bytes().into());
    assert!(
        call_unit(proxy, &SEL_MIGRATE, &U::ZERO, u64::MAX),
        "bad migration"
    );
    // After we've invoked the function again, we need to send it Solve:
    if entry_solve(0, solve_args) != 0 {
        return 1;
    }
    write_result_word(&proxy.into());
    0
}

pub fn entry_fresh_backwards(
    pub_key: U,
    eoa_addr: ArgsAddr,
    v: u8,
    r: U,
    s: U,
    solve_args: Vec<SolveArgsSigArgs>,
) -> usize {
    assert_eq!(eoa_addr.0, ecrecover(pub_key, v, r, s, u64::MAX).unwrap());
    let pub_key = VerifyingKey::from_bytes(pub_key.as_slice()).unwrap();
    let proxy = create2_pre_unit(
        &make_metamorphic_proxy(contract_address()),
        U::ZERO,
        &msg_sender(),
    )
    .unwrap();
    transient_store(&U::ZERO, &pub_key.to_bytes().into());
    assert!(
        call_unit(proxy, &SEL_MIGRATE, &U::ZERO, u64::MAX),
        "bad migration"
    );
    // After we've invoked the function again, we need to send it Solve:
    if entry_solve(0, solve_args) != 0 {
        return 1;
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
