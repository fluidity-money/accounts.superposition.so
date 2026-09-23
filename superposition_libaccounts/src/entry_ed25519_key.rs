use bobcat_sdk::{maths::U, entry::write_result_word};

use crate::storage;

pub fn entry_ed25519_key() -> usize {
    write_result_word(&storage::ed25519_slot::get(&U::ZERO));
    0
}
