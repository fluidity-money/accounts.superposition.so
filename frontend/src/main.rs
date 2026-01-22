#![cfg_attr(not(test), no_main)]

use wasm_bindgen::prelude::*;

extern crate alloc;

use alloc::vec::Vec;

use libaccounts::SolveArgs;

use bobcat_sdk::maths::U;

#[wasm_bindgen]
pub fn add_test(x: U) -> U {
    x + U::ONE
}

#[wasm_bindgen]
pub fn sign_fresh(
    priv_key: U,
    spender_addr: Box<[u8]>,
    solve_args: JsValue,
) -> Result<String, JsValue> {
    let solve_args: Vec<SolveArgs> = serde_wasm_bindgen::from_value(solve_args).unwrap();
    Ok("Hello".to_owned())
}

#[allow(unused)]
fn main() {}
