#[cfg(all(feature = "signing", feature = "proptest"))]
mod test {
    use proptest::prelude::*;

    use superposition_libaccounts::{
        StatementArgs, entry_statement::entry_statement, sign_statement, storage,
    };

    use bobcat_sdk::{entry::contract_address, maths::U};

    use ed25519_dalek::SigningKey;

    proptest! {
        #[test]
        fn test_statements(
            key in any::<[u8; 32]>(),
            msg in proptest::collection::vec(any::<u8>(), 1000),
            ms_ts in any::<[u8; 6]>()
        ) {
            let key = SigningKey::from_bytes(&key);
            storage::ed25519_slot::set(&U::ZERO, &key.verifying_key().to_bytes().into());
            storage::timestamps::set(&ms_ts.into(), &U::ZERO);
            let args = StatementArgs { msg: msg.clone(), ms_ts };
            let sig = sign_statement(key, msg, ms_ts, contract_address());
            assert_eq!(0, entry_statement(args, sig));
        }
    }
}
