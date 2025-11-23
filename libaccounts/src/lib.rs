#![cfg_attr(not(feature = "std"), no_std)]

use bobcat_sdk::{maths::U, storage::flush_guard};

use borsh::{BorshDeserialize, BorshSerialize};

pub mod storage;

pub mod entry_fresh;
pub mod entry_migrate;
pub mod entry_solve;

extern crate alloc;

use alloc::vec::Vec;

use array_concat::concat_arrays;

use ed25519_dalek::{Signature, Signer, SigningKey, VerifyingKey};

use core::{
    fmt::{Display, Formatter},
    str::FromStr,
};

use serde::{Deserialize as SerdeDeserialize, Serialize as SerdeSerialize};

pub type OurLzss = lzss::Lzss<12, 11, 0, { 1 << 12 }, { 2 << 12 }>;

use entry_fresh::entry_fresh;
use entry_solve::entry_solve;

type Address = [u8; 20];

pub const REGISTER_MSG_PREFIX: &'static [u8; 37] = b"Creating a Superposition account for ";

#[derive(
    Debug,
    BorshDeserialize,
    BorshSerialize,
    Clone,
    PartialEq,
    Default,
    SerdeSerialize,
    SerdeDeserialize,
)]
pub struct ArgsAddr(pub Address);

#[derive(Debug, Clone, PartialEq, Copy)]
pub struct ErrArgsAddr;

impl Display for ErrArgsAddr {
    fn fmt(&self, f: &mut Formatter<'_>) -> core::fmt::Result {
        write!(f, "args from str err")
    }
}

impl core::error::Error for ErrArgsAddr {}

impl FromStr for ArgsAddr {
    type Err = ErrArgsAddr;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let mut b = ArgsAddr::default();
        const_hex::decode_to_slice(s.trim_start_matches("0x"), &mut b.0)
            .map_err(|_| ErrArgsAddr)?;
        Ok(b)
    }
}

#[derive(
    BorshDeserialize, BorshSerialize, Clone, PartialEq, Debug, SerdeSerialize, SerdeDeserialize,
)]
pub struct Permit {
    pub token: ArgsAddr,
    pub deadline: U,
    v: u8,
    r: U,
    s: U,
}

#[derive(Debug, Clone, PartialEq, Copy)]
pub struct ErrPermitFromStr;

impl Display for ErrPermitFromStr {
    fn fmt(&self, f: &mut Formatter<'_>) -> core::fmt::Result {
        write!(f, "args from permit err")
    }
}

impl core::error::Error for ErrPermitFromStr {}

impl FromStr for Permit {
    type Err = ErrPermitFromStr;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        serde_json::from_str(s).map_err(|_| ErrPermitFromStr)
    }
}

#[derive(
    BorshDeserialize, BorshSerialize, Clone, PartialEq, Debug, SerdeSerialize, SerdeDeserialize,
)]
pub struct FromArgs {
    pub token: ArgsAddr,
    pub to_take: U,
    pub max_unspent: U,
}

#[derive(Debug, Clone, PartialEq, Copy)]
pub struct ErrFromArgs;

impl Display for ErrFromArgs {
    fn fmt(&self, f: &mut Formatter<'_>) -> core::fmt::Result {
        write!(f, "args from permit err")
    }
}

impl core::error::Error for ErrFromArgs {}

impl FromStr for FromArgs {
    type Err = ErrFromArgs;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        serde_json::from_str(s).map_err(|_| ErrFromArgs)
    }
}

#[derive(
    BorshDeserialize, BorshSerialize, Clone, PartialEq, Debug, SerdeSerialize, SerdeDeserialize,
)]
pub struct SolveArgs {
    pub permit: Vec<Permit>,
    pub from: Vec<FromArgs>,
    pub target: ArgsAddr,
    pub cd: Vec<u8>,
    pub ms_ts: u128,
}

#[derive(Debug, Clone, PartialEq, Copy)]
pub struct ErrSolveArgs;

impl Display for ErrSolveArgs {
    fn fmt(&self, f: &mut Formatter<'_>) -> core::fmt::Result {
        write!(f, "solve args err")
    }
}

impl core::error::Error for ErrSolveArgs {}

impl FromStr for SolveArgs {
    type Err = ErrSolveArgs;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        serde_json::from_str(s).map_err(|_| ErrSolveArgs)
    }
}

#[derive(
    BorshDeserialize, BorshSerialize, Clone, PartialEq, Debug, SerdeSerialize, SerdeDeserialize,
)]
pub struct Sig(#[serde(with = "const_hex")] pub [u8; 64]);

#[derive(
    BorshDeserialize, BorshSerialize, Clone, PartialEq, Debug, SerdeSerialize, SerdeDeserialize,
)]
pub enum Args {
    /// Create a new account and execute some calldata given.
    Fresh(U, Sig, Vec<(Sig, SolveArgs)>),
    /// Take a signature from a EVM EOA user that a ed25519 public key is
    /// authorised to spend on its behalf. Useful in a programmatic setup
    /// context.
    FreshBackwards(U, ArgsAddr, u8, U, U),
    /// Execute some calldata.
    Solve(u32, Vec<(Sig, SolveArgs)>),
}

pub fn entry(x: Args) -> usize {
    flush_guard(|| match x {
        Args::Fresh(key, sig, solve_args) => entry_fresh(key, sig, solve_args),
        Args::FreshBackwards(key, sig) => entry_fresh_backwards(key, sig),
        Args::Solve(slot, args) => entry_solve(slot, args),
    })
}

pub fn sign_hello(k: SigningKey, addr: [u8; 20]) -> Sig {
    let m: [u8; 37 + 20] = concat_arrays!(*REGISTER_MSG_PREFIX, addr);
    Sig(SigningKey::sign(&k, &m).to_bytes())
}

fn validate_hello_sig(pub_key: &VerifyingKey, sig: Sig, addr: [u8; 20]) -> bool {
    let to_check: [u8; 37 + 20] = concat_arrays!(*REGISTER_MSG_PREFIX, addr);
    let sig = Signature::from_bytes(&sig.0);
    if let Err(_) = pub_key.verify_strict(&to_check, &sig) {
        return false;
    }
    true
}

#[cfg(all(test, feature = "std"))]
mod test {
    use super::*;

    use proptest::prelude::*;

    proptest! {
        #[test]
        fn test_sign_validate(addr in any::<[u8; 20]>(), k in any::<[u8; 32]>()) {
            let k = SigningKey::from_bytes(&k);
            let pub_key = k.verifying_key();
            let sig = sign_hello(k, addr);
            assert!(validate_hello_sig(&pub_key, sig, addr));
        }
    }
}
