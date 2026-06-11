use crate::{storage, Permit, Sig, TransferArgs, U};

use sha2::{Digest, Sha512};

use bobcat_sdk::{
    call::{call_unit_err_vec, safe_call_bool_err_vec},
    entry::{contract_address, revert_if_bad_call_unit_vec},
    interfaces::{eip20::make_fn_transfer_from, eip2612::make_fn_permit},
    precompiles::superposition::edphverify,
};

use alloc::vec::Vec;

pub fn entry_transfer(slot: u32, args: Vec<TransferArgs>, ms_ts: [u8; 16], sig: Sig) -> usize {
    let ed_owner = storage::ed25519_slot::get(&slot.into());
    if args.is_empty() {
        panic!("no arguments")
    }
    let mut d = Sha512::new();
    d.update(borsh::to_vec(&args).unwrap());
    assert!(edphverify(d.finalize().into(), ed_owner, sig.0));
    storage::timestamps::exchange(&ms_ts.into());
    for TransferArgs {
        from,
        token,
        recipient,
        permit,
        amt,
    } in args
    {
        if let Some(Permit {
            token,
            deadline,
            v,
            r,
            s,
        }) = permit
        {
            revert_if_bad_call_unit_vec!(call_unit_err_vec(
                token.0,
                &make_fn_permit(
                    from,
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
            &make_fn_transfer_from(from, recipient, &amt),
            &U::ZERO,
            u64::MAX,
        ));
    }
    0
}
