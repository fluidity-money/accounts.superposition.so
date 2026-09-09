use clap::Parser;

use bobcat_sdk::maths::U;

use ed25519_dalek::{Digest, Sha512, SigningKey};

use superposition_libaccounts::{Args, ArgsAddr, FromArgs, Sig, SolveArgs, SolveArgsSigArgs};

use superposition_assets::Asset;

use core::{
    fmt::{Display, Formatter},
    str::FromStr,
};

use borsh::BorshDeserialize;

use std::io::{Read, stdin};

#[derive(Debug, Clone, PartialEq, Default)]
pub struct ArgsBytes(Vec<u8>);

#[derive(Debug, Clone, PartialEq, Copy)]
pub struct ErrArgsBytes;

impl Display for ErrArgsBytes {
    fn fmt(&self, f: &mut Formatter<'_>) -> core::fmt::Result {
        write!(f, "args from str err")
    }
}

impl FromStr for ArgsBytes {
    type Err = ErrArgsBytes;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        const_hex::decode(s.trim_start_matches("0x"))
            .map_err(|_| ErrArgsBytes)
            .map(ArgsBytes)
    }
}

impl core::error::Error for ErrArgsBytes {}

#[derive(Parser, Debug, Clone, PartialEq)]
#[command(version, about)]
enum CliArgs {
    DecodeBorsh,
}

fn entry(x: CliArgs) {
    match x {
        CliArgs::DecodeBorsh => {
            let mut buf = Vec::new();
            stdin().read_to_end(&mut buf).unwrap();
            println!(
                "{:?}",
                Args::try_from_slice(&const_hex::decode(&buf).unwrap()).unwrap()
            )
        }
    }
}

fn main() {
    entry(CliArgs::parse())
}

fn create_blob(x: &[u8]) -> String {
    const_hex::encode(x)
}
