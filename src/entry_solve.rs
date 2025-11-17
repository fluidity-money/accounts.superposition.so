use alloc::vec::Vec;

use bobcat_sdk::maths::U;

use crate::{Permit, SolveArgs};

pub fn entry_solve(args: Vec<([u8; 64], SolveArgs)>) -> usize {
    let owner = storage::ed25519_owner::get();
    for (
        sig,
        SolveArgs {
            permit,
            from,
            target,
            cd,
            goal,
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
            revert_if_bad_call_unit_vec!(call_err_vec(
                token,
                make_fn_permit(owner, contract_address(), &U::MAX, v, r, s),
                u64::MAX,
                &U::ZERO
            ));
        }
        for FromArgs { token, to_take, .. } in from {
            revert_if_bad_call_unit_vec!(call_err_vec(
                erc20_addr,
                make_fn_transfer_from(owner, contract_address(), amt),
                u64::MAX,
                &U::ZERO
            ));
        }
        revert_if_bad_call_unit_vec!(call_err_vec(
            target,
            &cd,
            u64::MAX,
            &U::ZERO
        ));
        for FromArgs { token, max_unspent, .. } in from {
            let bal = revert_if_bad_call_word_err_vec(token, make_fn_balance_of(contract_address());
            assert!(max_unspent > bal, "max unspent exceeds: {max_unspent}, {bal}");
        }
        for
    }
    0
}
