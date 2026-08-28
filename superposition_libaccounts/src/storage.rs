// BUG: uses the wrong operation order for the slot_map function, making
// the storage inequivalent to Solidity.
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
        pub fn exchange($param1: &U) {
            assert!(!storage_exchange(&slot_map(&SLOT, $param1), &U::ZERO, &U::ONE), "exchange failed");
        }
    };
}
storage! {
    // Was this contract created?
    was_created(),
    // The count of the number of ed25519 keys in this contract. Client only.
    ed25519_count(),
    // Slot (u32) => ed25519 public key.
    ed25519_slot(slot),
    // Which Ethereum address owns this contract? Client only.
    ethereum_owner(),
    // Seen timestamps:
    timestamps(ms),
    // The version number of this contract release.
    version(),
    // Authority that should be checked before execution.
    authority()
}
