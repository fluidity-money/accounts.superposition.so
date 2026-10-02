use crate::storage;

use bobcat_sdk::entry::write_word;

pub fn entry_version() -> usize {
    write_word(&storage::version::get());
    0
}
