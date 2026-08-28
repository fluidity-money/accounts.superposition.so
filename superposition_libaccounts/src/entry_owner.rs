use bobcat_sdk::entry::write_result_word;

use crate::storage;

pub fn entry_owner() -> usize {
    write_result_word(&storage::ethereum_owner::get());
    0
}
