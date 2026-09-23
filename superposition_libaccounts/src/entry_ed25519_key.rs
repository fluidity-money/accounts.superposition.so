use bobcat_sdk::{entry::write_result_word, maths::U};

use crate::storage;

pub fn entry_ed25519_key() -> usize {
    write_result_word(&storage::ed25519_slot::get(&U::ZERO));
    0
}
