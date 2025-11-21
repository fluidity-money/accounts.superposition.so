
macro_rules! storage {
    ($($name:ident($($param:ident),*)),* $(,)?) => {
        storage! {
            @internal
            counter: 0,
            items: [$($name($($param),*)),*]
        }
    };
    (@internal
        counter: $counter:expr,
        items: []
    ) => {};
    (@internal
        counter: $counter:expr,
        items: [$name:ident($($param:ident),*) $(, $($rest:tt)*)?]
    ) => {
        pub mod $name {
            pub(crate) use bobcat_sdk::storage::*;
            use bobcat_sdk::maths::{u, U};
            const SLOT: U = u!($counter);
            storage!(@impl [$($param),*]);
        }
        $(
            storage! {
                @internal
                counter: $counter + 1,
                items: [$($rest)*]
            }
        )?
    };
    (@impl []) => {
        pub fn get() -> U {
            storage_load(&SLOT)
        }
        pub fn set(x: &U) {
            storage_store(&SLOT, x)
        }
    };
    (@impl [$param1:ident]) => {
        pub fn get($param1: &U) -> U {
            storage_load(&slot_map(&SLOT, $param1))
        }
        pub fn set($param1: &U, x: &U) {
            storage_store(&slot_map(&SLOT, $param1), x)
        }
        pub fn add($param1: &U, x: &U) -> Option<()> {
            storage_checked_add(&slot_map(&SLOT, $param1), x)
        }
        pub fn sub($param1: &U, x: &U) -> Option<()> {
            storage_checked_sub(&slot_map(&SLOT, $param1), x)
        }
        pub fn get_hash($param1: &[u8; 64]) -> U {
            let x: [u8; 32] = $param1[..32].try_into().unwrap();
            get(&U(x))
        }
    };
}
storage! {
    // Was this contract created?
    was_created(),
    // Which ed25519 address owns this contract? Client only.
    ed25519_owner(),
    // Which Ethereum address owns this contract? Client only.
    ethereum_owner(),
}
