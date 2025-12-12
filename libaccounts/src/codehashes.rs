use const_hex::const_decode_to_array;

#[macro_export]
macro_rules! hash {
    ($a:expr) => {{
        match const_decode_to_array::<32>($a) {
            Ok(v) => v,
            Err(_) => panic!("bad hash"),
        }
    }};
}

pub const TEST_TARGET: [u8; 32] =
    hash!(b"f1551e4ce13adaacbf51b67ee3e5afd2d09b07a6c51bd9e51082fe4442da1a93");

pub const NINELIVES_AMM: [u8; 32] =
    hash!(b"79b617bf8b0a9467570172a9320058be29e22e847e56ac01933f44c7cc1cf7df");
pub const NINELIVES_DPPM: [u8; 32] =
    hash!(b"ab1ebbe8f681a54f59253762126d70550b0a2d3d4868789269e26641aa1d2b02");
pub const NINELIVES_DPM: [u8; 32] =
    hash!(b"af5c76470b21d952e940ad65d566b43133214bfda5cd859a7ab799e5cfd55ea0");
