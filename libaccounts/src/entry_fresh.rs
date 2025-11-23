use alloc::vec::Vec;

use bobcat_sdk::{
    call::{call_unit},
    create::create2_unit,
    entry::{write_result_word, contract_address, msg_sender},
    maths::U,
    proxy::{make_metamorphic_proxy, SEL_MIGRATE},
    storage::transient_store,
};

use crate::{entry_solve, validate_hello_sig, Sig, SolveArgs};

use ed25519_dalek::VerifyingKey;

pub fn entry_fresh(
    pub_key: U,
    sig: Sig,
    solve_args: Vec<(Sig, SolveArgs)>,
) -> usize {
    let pub_key = VerifyingKey::from_bytes(pub_key.as_slice()).unwrap();
    assert!(validate_hello_sig(&pub_key, sig, msg_sender()));
    let proxy = create2_unit(
        &make_metamorphic_proxy(contract_address()),
        U::ZERO,
        msg_sender().into(),
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
