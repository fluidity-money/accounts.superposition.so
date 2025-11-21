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

use crate::{storage, FromArgs, Permit, SolveArgs};

pub fn entry_solve(args: Vec<([u8; 64], SolveArgs)>) -> usize {
    let owner = storage::ed25519_owner::get();
    for (
        sig,
        SolveArgs {
            permit,
            from,
            target,
            cd,
        },
    ) in args
    {
        for Permit {
            token,
            deadline,
            v,
            r,
            s,
        } in permit
        {
            revert_if_bad_call_unit_vec!(call_unit_err_vec(
                token,
                &make_fn_permit(
                    owner.into(),
                    contract_address(),
                    &U::MAX,
                    &deadline,
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
                *token,
                &make_fn_transfer_from(owner.into(), contract_address(), &to_take),
                &U::ZERO,
                u64::MAX,
            ));
            revert_if_bad_call_unit_vec!(call_unit_err_vec(
                *token,
                &make_fn_approve(target, to_take),
                &U::ZERO,
                u64::MAX
            ));
        }
        revert_if_bad_call_unit_vec!(call_unit_err_vec(target, &cd, &U::ZERO, u64::MAX));
        for FromArgs {
            token, max_unspent, ..
        } in from
        {
            let bal = revert_if_bad_call_slice_vec!(call_word_err_vec(
                token,
                &make_fn_balance_of(contract_address()),
                &U::ZERO,
                u64::MAX,
            ));
            assert!(
                max_unspent > bal,
                "max unspent exceeds: {max_unspent}, {bal}"
            );
        }
    }
    0
}
