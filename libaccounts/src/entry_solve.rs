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
    precompiles::superposition::edverify,
};

use sha2::{Digest, Sha512};

use crate::{codehashes, storage, FromArgs, Permit, SolveArgs, SolveArgsSigArgs};

pub fn entry_solve(owner: u32, args: Vec<SolveArgsSigArgs>) -> usize {
    let eth_owner = storage::ethereum_owner::get();
    let ed_owner = storage::ed25519_slot::get(&owner.into());
    for SolveArgsSigArgs { sig, args } in args {
        let mut d = Sha512::new();
        d.update(borsh::to_vec(&args).unwrap());
        assert!(edverify(d.finalize().into(), ed_owner, sig.0),);
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
                &make_fn_transfer_from(eth_owner.into(), contract_address(), to_take),
                &U::ZERO,
                u64::MAX,
            ));
            revert_if_bad_call_unit_vec!(call_unit_err_vec(
                token.0,
                &make_fn_approve(target.clone().0, to_take),
                &U::ZERO,
                u64::MAX
            ));
        }
        match code_hash(target.0) {
            codehashes::NINELIVES_AMM | codehashes::NINELIVES_DPPM | codehashes::NINELIVES_DPM => {}
            hash => panic!("target not whitelisted: {}", const_hex::encode(hash)),
        };
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
                bal >= max_unspent,
                "max unspent exceeds: {max_unspent}, {bal}"
            );
        }
    }
    0
}
