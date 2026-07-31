
use crate::{storage, Sig, StatementArgs};

use bobcat_sdk::precompiles::superposition::edphverify_pre;

pub fn entry_statement(slot: u32, args: StatementArgs, sig: Sig) -> usize {
    assert!(edphverify_pre(
        &borsh::to_vec(&args).unwrap(),
        storage::ed25519_slot::get(&slot.into()),
        sig.0
    ));
    let StatementArgs { ms_ts, .. } = args;
    storage::timestamps::exchange(&ms_ts.into());
    0
}
