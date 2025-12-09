#![no_main]

use libfuzzer_sys::fuzz_target;

fuzz_target!(|a: libaccounts::Args| {
    assert_eq!(a, borsh::de::from_slice(&borsh::to_vec(&a).unwrap()).unwrap());
});
