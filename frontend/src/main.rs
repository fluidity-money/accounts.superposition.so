#![cfg_attr(not(test), no_main)]

use wasm_bindgen::prelude::*;

extern crate alloc;

use bobcat_sdk::maths::U;

#[wasm_bindgen]
pub fn add_test(x: U) -> U {
    x + U::ONE
}

#[wasm_bindgen]
pub fn sign_fresh(
    _priv_key: U,
    _spender_addr: Box<[u8]>,
    _solve_args: JsValue,
) -> Result<String, JsValue> {
    // let solve_args: Vec<SolveArgs> = serde_wasm_bindgen::from_value(solve_args).unwrap();
    todo!()
}

#[allow(unused)]
fn main() {}
