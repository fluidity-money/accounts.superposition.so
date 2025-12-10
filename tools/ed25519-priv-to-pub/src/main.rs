use ed25519_dalek::SigningKey;

fn main() {
    let k: [u8; 32] = const_hex::decode(std::env::var("SPN_ACCOUNTS_PRIVATE_KEY").unwrap())
        .unwrap()
        .try_into()
        .unwrap();
    println!(
        "{}",
        const_hex::encode(SigningKey::from_bytes(&k).verifying_key().to_bytes())
    )
}
