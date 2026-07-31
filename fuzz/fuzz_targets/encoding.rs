#![no_main]

use libfuzzer_sys::fuzz_target;

fuzz_target!(|a: superposition_libaccounts::Args| {
    assert_eq!(a, borsh::de::from_slice(&borsh::to_vec(&a).unwrap()).unwrap());
});
