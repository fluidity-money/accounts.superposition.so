use bobcat_sdk::entry::write_word;

use crate::storage;

pub fn entry_owner() -> usize {
    write_word(&storage::ethereum_owner::get());
    0
}
