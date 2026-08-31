use alloc::vec::Vec;

use bobcat_sdk::{
    call::{call_unit_err_vec, call_word_err_vec, safe_call_bool_err_vec, safe_call_unit_err_vec},
    entry::{
        code_hash, contract_address, revert_if_bad_call_slice_vec, revert_if_bad_call_unit_vec,
    },
    interfaces::{
        eip20::{make_fn_approve, make_fn_balance_of, make_fn_transfer_from},
        eip2612::make_fn_permit,
    },
    maths::U,
    precompiles::superposition::edphverify_pre,
};

use crate::{
    FromArgs, Permit, Sig, SolveArgs, SolveArgsSigArgs, SolveV2Args, call_authority, storage,
};

pub fn entry_solve(
    args: Vec<SolveArgs>,
    permit_owner: [u8; 20],
    transfer_owner: [u8; 20],
) -> usize {
    for args in args {
        let SolveArgs {
            permit,
            from,
            target,
            cd,
            ms_ts,
            ..
        } = args;
        storage::timestamps::exchange(&ms_ts.into());
        for Permit {
            asset,
            deadline,
            v,
            r,
            s,
        } in permit
        {
            let token: [u8; 20] = asset.addr();
            revert_if_bad_call_unit_vec!(call_unit_err_vec(
                token,
                &make_fn_permit(
                    permit_owner,
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
        for FromArgs { asset, to_take, .. } in &from {
            let token: [u8; 20] = asset.addr();
            revert_if_bad_call_unit_vec!(safe_call_bool_err_vec(
                token,
                &make_fn_transfer_from(transfer_owner, contract_address(), to_take),
                &U::ZERO,
                u64::MAX,
            ));
            revert_if_bad_call_unit_vec!(call_unit_err_vec(
                token,
                &make_fn_approve(target.clone().0, to_take),
                &U::ZERO,
                u64::MAX
            ));
        }
        let authority_addr = storage::authority::get();
        if authority_addr.is_some() {
            let c = code_hash(target.0);
            if !call_authority::is_allowed(authority_addr.into(), c) {
                // Branching to avoid possibly always making this string:
                panic!("not allowed: {}", const_hex::encode(c.0));
            }
        }
        match safe_call_unit_err_vec(target.0, &cd, &U::ZERO, u64::MAX) {
            (false, Some(v)) => {
                panic!(
                    "error calling: {}, cd: {}, res: {}",
                    const_hex::encode(target.0),
                    const_hex::encode(cd),
                    const_hex::encode(v)
                )
            }
            (false, None) => panic!(
                "error calling: {}, cd: {}, no res",
                const_hex::encode(target.0),
                const_hex::encode(cd)
            ),
            _ => (),
        };
        for FromArgs {
            asset, max_unspent, ..
        } in from
        {
            let bal = revert_if_bad_call_slice_vec!(call_word_err_vec(
                asset.into(),
                &make_fn_balance_of(contract_address()),
                &U::ZERO,
                u64::MAX,
            ));
            assert!(
                bal >= max_unspent,
                "max unspent exceeds: {max_unspent}, {bal}"
            );
        }
    }
    0
}

pub fn entry_solve_v1(args: Vec<SolveArgsSigArgs>) -> usize {
    let ed_owner = storage::ed25519_slot::get(&U::ZERO);
    let args = args
        .into_iter()
        .map(|SolveArgsSigArgs { sig, args }| {
            assert!(edphverify_pre(
                &borsh::to_vec(&args).unwrap(),
                ed_owner,
                sig.0
            ));
            args
        })
        .collect();
    let eth_owner: [u8; 20] = storage::ethereum_owner::get().into();
    entry_solve(args, eth_owner, eth_owner)
}

pub fn entry_solve_v2(args: SolveV2Args, sig: Sig) -> usize {
    let ed_owner = storage::ed25519_slot::get(&U::ZERO);
    assert!(edphverify_pre(
        &borsh::to_vec(&args).unwrap(),
        ed_owner,
        sig.0
    ));
    let SolveV2Args {
        args,
        permit_owner,
        transfer_owner,
    } = args;
    entry_solve(args, permit_owner, transfer_owner)
}
