use alloc::vec::Vec;

use bobcat_sdk::{
    call::{call_unit_err_vec, call_word_err_vec, safe_call_bool_err_vec},
    entry::{contract_address, revert_if_bad_call_slice_vec, revert_if_bad_call_unit_vec},
    interfaces::{
        eip20::{make_fn_approve, make_fn_balance_of, make_fn_transfer_from},
        eip2612::make_fn_permit,
    },
    maths::U,
};

use crate::{storage, FromArgs, Permit, SolveArgs, SolveArgsSigArgs};

use ed25519_dalek::{Signature, VerifyingKey};

pub fn entry_solve(owner: u32, args: Vec<SolveArgsSigArgs>) -> usize {
    let eth_owner = storage::ethereum_owner::get();
    let ed_owner =
        VerifyingKey::from_bytes(storage::ed25519_slot::get(&owner.into()).as_slice()).unwrap();
    for SolveArgsSigArgs { sig, args } in args {
        let sig = Signature::from_bytes(&sig.0);
        ed_owner
            .verify_strict(&borsh::to_vec(&args).unwrap(), &sig)
            .unwrap();
        let SolveArgs {
            permit,
            from,
            target,
            cd,
            ms_ts,
        } = args;
        storage::timestamps::exchange(&ms_ts.into());
        for Permit {
            token,
            deadline,
            v,
            r,
            s,
        } in permit
        {
            revert_if_bad_call_unit_vec!(call_unit_err_vec(
                token.0,
                &make_fn_permit(
                    eth_owner.into(),
                    contract_address(),
                    &U::MAX,
                    &deadline.into(),
                    v,
                    &r,
                    &s
                ),
                &U::ZERO,
                u64::MAX
            ));
        }
        for FromArgs { token, to_take, .. } in &from {
            revert_if_bad_call_unit_vec!(safe_call_bool_err_vec(
                token.0,
                &make_fn_transfer_from(eth_owner.into(), contract_address(), &to_take),
                &U::ZERO,
                u64::MAX,
            ));
            revert_if_bad_call_unit_vec!(call_unit_err_vec(
                token.0,
                &make_fn_approve(target.0, to_take),
                &U::ZERO,
                u64::MAX
            ));
        }
        revert_if_bad_call_unit_vec!(safe_call_bool_err_vec(target.0, &cd, &U::ZERO, u64::MAX));
        for FromArgs {
            token, max_unspent, ..
        } in from
        {
            let bal = revert_if_bad_call_slice_vec!(call_word_err_vec(
                token.0,
                &make_fn_balance_of(contract_address()),
                &U::ZERO,
                u64::MAX,
            ));
            assert!(
                max_unspent >= bal,
                "max unspent exceeds: {max_unspent}, {bal}"
            );
        }
    }
    0
}
