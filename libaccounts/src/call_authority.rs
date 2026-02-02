use bobcat_sdk::{call::static_call_bool, cd::const_keccak_sel, maths::U};

use array_concat::concat_arrays;

const SEL_ALLOWED: [u8; 4] = const_keccak_sel(b"allowed(bytes32)");

pub fn is_allowed(auth: [u8; 20], hash: U) -> bool {
    let cd: [u8; 4 + 32] = concat_arrays!(SEL_ALLOWED, hash.0);
    static_call_bool(auth, &cd, u64::MAX)
}
