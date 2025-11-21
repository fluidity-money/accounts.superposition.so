use alloc::vec::Vec;

use bobcat_sdk::{
    call::{call_unit_err_vec, call_unit},
    create::create2_unit,
    entry::{revert_if_bad_call_unit_vec, contract_address, msg_sender},
    maths::U,
    proxy::{make_metamorphic_proxy, SEL_MIGRATE},
    storage::transient_store,
    interfaces::eip2612::make_fn_permit
};

use array_concat::concat_arrays;

use ed25519_dalek::{Signature, VerifyingKey};

use crate::{entry_solve, Permit, SolveArgs};

fn validate_sig(key: U, sig: [u8; 64], addr: [u8; 20]) -> bool {
    let to_check: [u8; 37 + 20] = concat_arrays!(*b"Creating a Superposition account for ", addr);
    let verify_key = VerifyingKey::from_bytes(key.as_slice()).unwrap();
    let sig = Signature::from_bytes(&sig);
    verify_key.verify_strict(&to_check, &sig).unwrap();
    true
}

pub fn entry_register(
    key: U,
    sig: [u8; 64],
    permit_blobs: Vec<Permit>,
    solve_args: Vec<([u8; 64], SolveArgs)>,
) -> usize {
    // Register validates that the signature given is the user signing the
    // address they provided. Be careful not to have a situation take place
    // where a recursive number of accounts are created.
    assert!(validate_sig(key, sig, msg_sender()));
    let proxy = create2_unit(
        &make_metamorphic_proxy(contract_address()),
        U::ZERO,
        msg_sender().into(),
    )
    .unwrap();
    for Permit {
        token,
        deadline,
        v,
        r,
        s,
    } in permit_blobs
    {
        revert_if_bad_call_unit_vec!(call_unit_err_vec(
            token,
            &make_fn_permit(msg_sender(), proxy, &U::MAX, &deadline, v, &r, &s),
            &U::ZERO,
            u64::MAX
        ));
    }
    transient_store(&U::ZERO, &key);
    assert!(
        call_unit(proxy, &SEL_MIGRATE, &U::ZERO, u64::MAX),
        "bad migration"
    );
    // After we've invoked the function again, we need to send it Solve:
    entry_solve(solve_args)
}
