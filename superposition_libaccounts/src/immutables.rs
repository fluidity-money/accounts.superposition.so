use superposition_assets::Network;

#[derive(Clone, Debug, PartialEq)]
pub struct Imm {
    pub network: Network,
    pub clearinghouse: [u8; 20],
}
