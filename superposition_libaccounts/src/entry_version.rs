use crate::storage;

use bobcat_sdk::entry::write_result_word;

pub fn entry_version() -> usize {
    write_result_word(&storage::version::get());
    0
}
