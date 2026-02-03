#![cfg_attr(not(feature = "std"), no_std)]

use bobcat_sdk::{maths::U, storage::const_slot_off_curve};

use borsh::{BorshDeserialize, BorshSerialize};

pub mod storage;

pub mod codehashes;
pub mod entry_fresh;
pub mod entry_migrate;
pub mod entry_solve;
pub mod entry_version;
pub mod entry_authority;

pub mod call_authority;

extern crate alloc;

use alloc::vec::Vec;

use core::{
    fmt::{Display, Formatter},
    str::FromStr,
};

use serde::{Deserialize as SerdeDeserialize, Serialize as SerdeSerialize};

#[cfg(feature = "arbitrary")]
use arbitrary::Arbitrary;

use entry_fresh::entry_fresh_backwards;
use entry_solve::entry_solve;
use entry_version::entry_version;
use entry_authority::entry_authority;

type Address = [u8; 20];

pub const SLOT_IMPL: U = const_slot_off_curve(b"eip1967.proxy.implementation");

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
#[cfg_attr(feature = "arbitrary", derive(Arbitrary))]
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
#[cfg_attr(feature = "arbitrary", derive(Arbitrary))]
pub struct Permit {
    pub token: ArgsAddr,
    pub deadline: u64,
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
#[cfg_attr(feature = "arbitrary", derive(Arbitrary))]
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
#[cfg_attr(feature = "arbitrary", derive(Arbitrary))]
pub struct SolveArgs {
    pub permit: Vec<Permit>,
    pub from: Vec<FromArgs>,
    pub target: ArgsAddr,
    pub cd: Vec<u8>,
    pub ms_ts: [u8; 16],
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
#[cfg_attr(feature = "arbitrary", derive(Arbitrary))]
pub struct Sig(#[serde(with = "const_hex")] pub [u8; 64]);

#[derive(
    BorshDeserialize, BorshSerialize, Clone, PartialEq, Debug, SerdeSerialize, SerdeDeserialize,
)]
#[cfg_attr(feature = "arbitrary", derive(Arbitrary))]
pub struct SolveArgsSigArgs {
    pub sig: Sig,
    pub args: SolveArgs,
}

#[derive(
    BorshDeserialize, BorshSerialize, Clone, PartialEq, Debug, SerdeSerialize, SerdeDeserialize,
)]
#[cfg_attr(feature = "arbitrary", derive(Arbitrary))]
pub enum Args {
    /// Take a signature from a EVM EOA user that a ed25519 public key is
    /// authorised to spend on its behalf. Useful in a programmatic setup
    /// context.
    FreshBackwards {
        key: U,
        eoa_addr: ArgsAddr,
        v: u8,
        r: U,
        s: U,
        solve_args: Vec<SolveArgsSigArgs>,
        authority: Option<ArgsAddr>
    },
    /// Execute some calldata.
    Solve {
        slot: u32,
        args: Vec<SolveArgsSigArgs>,
    },
    Version,
    Authority,
}

pub fn entry(x: Args) -> usize {
    match x {
        Args::FreshBackwards {
            key,
            eoa_addr,
            v,
            r,
            s,
            solve_args,
            authority,
        } => entry_fresh_backwards(key, eoa_addr, v, r, s, solve_args, authority),
        Args::Solve { slot, args } => entry_solve(slot, args),
        Args::Version => entry_version(),
        Args::Authority => entry_authority(),
    }
}
