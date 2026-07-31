use crate::storage;

use bobcat_sdk::entry::write_result_word;

pub fn entry_authority() -> usize {
    write_result_word(&storage::authority::get());
    0
}
