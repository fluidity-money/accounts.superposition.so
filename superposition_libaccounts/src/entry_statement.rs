use crate::{Sig, StatementArgs, statement_sha512, storage};

use bobcat_sdk::{entry::contract_address, maths::U, precompiles::superposition::edphverify_post};

pub fn entry_statement(StatementArgs { msg, ms_ts }: StatementArgs, sig: Sig) -> usize {
    let hash = statement_sha512(msg, ms_ts, contract_address());
    assert!(edphverify_post(
        hash,
        storage::ed25519_slot::get(&U::ZERO),
        sig.0
    ));
    storage::timestamps::exchange(&ms_ts.into());
    0
}
