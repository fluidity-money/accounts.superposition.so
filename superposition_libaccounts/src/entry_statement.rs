use crate::{Sig, StatementArgs, storage};

use bobcat_sdk::{entry::contract_address, maths::U, precompiles::superposition::edphverify_pre};

use array_concat::concat_arrays;

pub fn entry_statement(args: StatementArgs, sig: Sig) -> usize {
    let content = borsh::to_vec(&args).unwrap();
    let mut contract_addr: [u8; 40] = [0u8; 40];
    const_hex::encode_to_slice(contract_address(), &mut contract_addr).unwrap();
    let msg: [u8; 90] = concat_arrays!(*b"Superposition Accounts statement for ", contract_addr);
    let mut msg = msg.to_vec();
    msg.extend(content);
    assert!(edphverify_pre(
        &msg,
        storage::ed25519_slot::get(&U::ZERO),
        sig.0
    ));
    let StatementArgs { ms_ts, .. } = args;
    storage::timestamps::exchange(&ms_ts.into());
    0
}
