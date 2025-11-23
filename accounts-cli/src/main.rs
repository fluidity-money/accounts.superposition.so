use clap::Parser;

use bobcat_sdk::maths::U;

use ed25519_dalek::{Signer, SigningKey};

use libaccounts::{Args, ArgsAddr, FromArgs, OurLzss, Sig, SolveArgs, REGISTER_MSG_PREFIX};

use array_concat::concat_arrays;

use core::{
    fmt::{Display, Formatter},
    str::FromStr,
};

use std::time::{SystemTime, UNIX_EPOCH};

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
    SignFresh {
        #[arg(value_parser = U::from_str)]
        priv_key: U,
        spender_addr: ArgsAddr,
        solve_args: Vec<SolveArgs>,
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
        cd: ArgsBytes,
    },
}

fn entry(x: CliArgs) {
    match x {
        CliArgs::SignFresh {
            priv_key,
            spender_addr,
            solve_args,
        } => {
            let k = SigningKey::from_bytes(&priv_key.0);
            let k_pub = k.verifying_key().to_bytes();
            let m: [u8; 37 + 20] = concat_arrays!(*REGISTER_MSG_PREFIX, spender_addr.0);
            let onramping_sig = SigningKey::sign(&k, &m);
            let solve_args = solve_args
                .into_iter()
                .map(|args| {
                    (
                        Sig(SigningKey::sign(&k, &borsh::to_vec(&args).unwrap()).to_bytes()),
                        args,
                    )
                })
                .collect::<Vec<_>>();
            println!(
                "0x{}",
                create_blob(
                    &borsh::to_vec(&Args::Fresh(
                        k_pub.into(),
                        Sig(onramping_sig.into()),
                        solve_args,
                    ))
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
                    (
                        Sig(SigningKey::sign(&k, &borsh::to_vec(&args).unwrap()).to_bytes()),
                        args,
                    )
                })
                .collect::<Vec<_>>();
            println!(
                "0x{}",
                create_blob(&borsh::to_vec(&Args::Solve(slot, solve_args,)).unwrap())
            );
        }
        CliArgs::SignTokenSpend {
            priv_key,
            slot,
            from_token,
            min_spend,
            target,
            cd,
        } => {
            let ms_ts = SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap()
                .as_millis();
            entry(CliArgs::SignSolve {
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
                    ms_ts,
                }],
            })
        }
    }
}

fn main() {
    entry(CliArgs::parse())
}

fn create_blob(x: &[u8]) -> String {
    const_hex::encode(
        &OurLzss::compress_stack(
            lzss::SliceReader::new(x),
            lzss::VecWriter::with_capacity(1024 * 2),
        )
        .unwrap()
        .as_slice(),
    )
}
