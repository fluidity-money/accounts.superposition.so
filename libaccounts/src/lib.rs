#![cfg_attr(not(feature = "std"), no_std)]

use bobcat_sdk::{storage::flush_guard, maths::U};

use borsh::{BorshDeserialize, BorshSerialize};

pub mod storage;

pub mod entry_migrate;
pub mod entry_register;
pub mod entry_solve;

extern crate alloc;

use alloc::vec::Vec;

pub type OurLzss = lzss::Lzss<12, 11, 0, { 1 << 12 }, { 2 << 12 }>;

use entry_register::entry_register;
use entry_solve::entry_solve;

type Address = [u8; 20];

#[derive(BorshDeserialize, BorshSerialize, Clone, PartialEq)]
pub struct Permit {
    pub token: [u8; 20],
    pub deadline: U,
    v: u8,
    r: U,
    s: U,
}

#[derive(BorshDeserialize, BorshSerialize, Clone, PartialEq)]
pub struct FromArgs {
    pub token: Address,
    pub to_take: U,
    pub max_unspent : U,
}

#[derive(BorshDeserialize, BorshSerialize, Clone, PartialEq)]
pub struct SolveArgs {
    pub permit: Vec<Permit>,
    pub from: Vec<FromArgs>,
    pub target: [u8; 20],
    pub cd: Vec<u8>,
    pub ms_ts: u128
}

#[derive(BorshDeserialize, BorshSerialize, Clone, PartialEq)]
pub enum Args {
    Register(U, [u8; 64], Vec<Permit>, Vec<([u8; 64], SolveArgs)>),
    Solve(Vec<([u8; 64], SolveArgs)>),
}

pub fn entry(x: Args) -> usize {
    flush_guard(|| match x {
        Args::Register(key, sig, permit_blobs, solve_args) => {
            entry_register(key, sig, permit_blobs, solve_args)
        }
        Args::Solve(args) => entry_solve(args),
    })
}
