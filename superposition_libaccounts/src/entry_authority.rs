use crate::storage;

use bobcat_sdk::entry::write_word;

pub fn entry_authority() -> usize {
    write_word(&storage::authority::get());
    0
}
