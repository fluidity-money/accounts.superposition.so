use clap::Parser;

use bobcat_sdk::maths::U;

use ed25519_dalek::{Digest, Sha512, SigningKey};

use libaccounts::{Args, ArgsAddr, FromArgs, Sig, SolveArgs, SolveArgsSigArgs,};

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
    PubKeyForPriv {
        #[arg(value_parser = U::from_str)]
        priv_key: U,
    },
    SignFreshBackwards {
        #[arg(value_parser = U::from_str)]
        priv_key: U,
        eoa_addr: ArgsAddr,
        v: u8,
        r: U,
        s: U,
        #[arg(short)]
        solve_args: Option<Vec<SolveArgs>>,
        authority: Option<ArgsAddr>,
    },
    SignSolve {
        #[arg(value_parser = U::from_str)]
        priv_key: U,
        slot: u32,
        solve_args: Vec<SolveArgs>,
    },
    SignTokenSpend {
        #[arg(value_parser = U::from_str)]
        priv_key: U,
        #[arg(default_value_t = 0)]
        slot: u32,
        from_token: ArgsAddr,
        #[arg(value_parser = U::from_str, default_value_t = U::ZERO)]
        min_spend: U,
        target: ArgsAddr,
        ms_ts: u128,
        cd: ArgsBytes,
    },
    DecodeBorsh,
    LiteArbitraryCd {
        #[arg(value_parser = U::from_str)]
        priv_key: U,
        nonce: u128,
        contract: ArgsAddr,
        target: ArgsAddr,
        cd: ArgsBytes,
    },
}

fn entry(x: CliArgs) {
    match x {
        CliArgs::PubKeyForPriv { priv_key } => {
            let k = SigningKey::from_bytes(&priv_key.0);
            println!("{}", const_hex::encode(k.verifying_key().as_bytes()));
        }
        CliArgs::SignFreshBackwards {
            priv_key,
            eoa_addr,
            v,
            r,
            s,
            solve_args,
            authority,
        } => {
            let k = SigningKey::from_bytes(&priv_key.0);
            let solve_args = solve_args
                .unwrap_or(vec![])
                .into_iter()
                .map(|args| {
                    let mut d = Sha512::new();
                    d.update(&borsh::to_vec(&args).unwrap());
                    SolveArgsSigArgs {
                        sig: Sig(k.sign_prehashed(d, None).unwrap().to_bytes()),
                        args,
                    }
                })
                .collect::<Vec<_>>();
            println!(
                "{}",
                create_blob(
                    &borsh::to_vec(&Args::FreshBackwards {
                        key: U(*k.verifying_key().as_bytes()),
                        eoa_addr,
                        v,
                        r,
                        s,
                        solve_args,
                        authority,
                    })
                    .unwrap()
                )
            );
        }
        CliArgs::SignSolve {
            priv_key,
            slot,
            solve_args,
        } => {
            let k = SigningKey::from_bytes(&priv_key.0);
            let solve_args = solve_args
                .into_iter()
                .map(|args| {
                    let mut d = Sha512::new();
                    d.update(&borsh::to_vec(&args).unwrap());
                    SolveArgsSigArgs {
                        sig: Sig(k.sign_prehashed(d, None).unwrap().to_bytes()),
                        args,
                    }
                })
                .collect::<Vec<_>>();
            println!(
                "0x{}",
                create_blob(
                    &borsh::to_vec(&Args::Solve {
                        slot,
                        args: solve_args
                    })
                    .unwrap()
                )
            );
        }
        CliArgs::SignTokenSpend {
            priv_key,
            slot,
            from_token,
            min_spend,
            target,
            ms_ts,
            cd,
        } => entry(CliArgs::SignSolve {
            priv_key,
            slot,
            solve_args: vec![SolveArgs {
                permit: vec![],
                from: vec![FromArgs {
                    token: from_token,
                    to_take: min_spend,
                    max_unspent: min_spend,
                }],
                target,
                cd: cd.0,
                ms_ts: ms_ts.to_be_bytes(),
            }],
        }),
        CliArgs::DecodeBorsh => {
            let mut buf = Vec::new();
            stdin().read_to_end(&mut buf).unwrap();
            println!(
                "{:?}",
                Args::try_from_slice(&const_hex::decode(&buf).unwrap()).unwrap()
            )
        }
        CliArgs::LiteArbitraryCd {
            priv_key,
            nonce,
            contract,
            target,
            cd,
        } => {
            let k = SigningKey::from_bytes(&priv_key.0);
            let mut x = Sha512::new();
            x.update(&contract.0);
            x.update(&nonce.to_be_bytes());
            x.update(&target.0);
            x.update(&cd.0);
            let sig = k.sign_prehashed(x, None).unwrap().to_bytes();
            println!(
                "{}{}{}{}",
                const_hex::encode(sig),
                const_hex::encode(nonce.to_be_bytes()),
                const_hex::encode(target.0),
                const_hex::encode(cd.clone().0)
            );
            eprintln!(
                "{}{}{}{}",
                const_hex::encode(sig),
                const_hex::encode(nonce.to_be_bytes()),
                const_hex::encode(target.0),
                const_hex::encode(cd.0)
            );
        }
    }
}

fn main() {
    entry(CliArgs::parse())
}

fn create_blob(x: &[u8]) -> String {
    const_hex::encode(x)
}
