use bobcat_sdk::entry::write_result_word;

pub fn entry_assets_version() -> usize {
    write_result_word(&superposition_assets::VERSION_CURRENT.into());
    0
}
