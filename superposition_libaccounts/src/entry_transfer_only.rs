use crate::{Sig, Transfer, TransferOnlyArgs, TransferPermit, U, storage};

use bobcat_sdk::{
    call::{call_unit_err_vec, safe_call_bool_err_vec},
    entry::{contract_address, revert_if_bad_call_unit_vec},
    interfaces::{eip20::make_fn_transfer_from, eip2612::make_fn_permit},
    precompiles::superposition::edphverify_pre,
};

pub fn entry_transfer_only(slot: u32, args: TransferOnlyArgs, sig: Sig) -> usize {
    let ed_owner = storage::ed25519_slot::get(&slot.into());
    assert!(edphverify_pre(
        &borsh::to_vec(&args).unwrap(),
        ed_owner,
        sig.0
    ));
    let TransferOnlyArgs { args, ms_ts } = args;
    if args.is_empty() {
        panic!("no arguments")
    }
    storage::timestamps::exchange(&ms_ts.into());
    for Transfer {
        from,
        asset,
        recipient,
        permit,
        amt,
    } in args
    {
        let token: [u8; 20] = asset.into();
        if let Some(TransferPermit { deadline, v, r, s }) = permit {
            revert_if_bad_call_unit_vec!(call_unit_err_vec(
                token,
                &make_fn_permit(
                    from.0,
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
        };
        revert_if_bad_call_unit_vec!(safe_call_bool_err_vec(
            token,
            &make_fn_transfer_from(from.0, recipient.0, &amt),
            &U::ZERO,
            u64::MAX,
        ));
    }
    0
}
