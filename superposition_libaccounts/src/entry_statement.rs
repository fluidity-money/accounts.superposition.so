use crate::{Sig, StatementArgs, storage};

use bobcat_sdk::{maths::U, precompiles::superposition::edphverify_pre};

pub fn entry_statement(args: StatementArgs, sig: Sig) -> usize {
    assert!(edphverify_pre(
        &borsh::to_vec(&args).unwrap(),
        storage::ed25519_slot::get(&U::ZERO),
        sig.0
    ));
    let StatementArgs { ms_ts, .. } = args;
    storage::timestamps::exchange(&ms_ts.into());
    0
}
