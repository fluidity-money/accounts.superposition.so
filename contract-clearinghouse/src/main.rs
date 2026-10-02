#![cfg_attr(target_arch = "wasm32", no_main)]
#![no_std]

use bobcat_sdk::{
    interfaces::uniswap_v4::{
        PoolKey, QuoteExactSingleParams, make_fn_quote_exact_input_zero_hooks,
    },
    prelude::*,
};
use superposition_assets::{Asset, Network};

#[global_allocator]
#[cfg(target_arch = "wasm32")]
static ALLOC: mini_alloc::MiniAlloc = mini_alloc::MiniAlloc::INIT;

#[derive(EvmCdSerialise, EvmCdDeserialise, Debug, Clone)]
#[evm_selector]
enum Entrypoint {
    EstimateEthValueCheckAccountsUniswap {
        asset: u8,
        fee: EvmCdU24,
        tick_spacing: EvmCdI24,
        amt: u128,
    },
    /// CleanHouse figures out how much of the asset given we have using
    /// erc20 balance, then it swaps everything we have to ETH, which it
    /// transfers to the MassSend contract.
    CleanHouse {
        asset: u8,
        fee: EvmCdU24,
        tick_spacing: EvmCdI24,
        min_amt: u128,
    },
}

#[cfg(all(feature = "network-arbitrum", feature = "network-robinhood"))]
compile_error!("too many networks enabled");

#[cfg(not(any(feature = "network-arbitrum", feature = "network-robinhood",)))]
compile_error!("network-arbitrum or network-robinhood must be enabled");

#[cfg(feature = "network-arbitrum")]
const UNISWAP_V4_QUOTER_ARBITRUM: [u8; 20] = address!(b"3972c00f7ed4885e145823eb7c655375d275a1c5");

#[cfg(feature = "network-robinhood")]
const UNISWAP_V4_QUOTER_ROBINHOOD: [u8; 20] = address!(b"8dc178efb8111bb0973dd9d722ebeff267c98f94");

fn make_quote_calldata(
    asset: [u8; 20],
    fee: EvmCdU24,
    tick_spacing: EvmCdI24,
    amt: u128,
) -> [u8; 324] {
    make_fn_quote_exact_input_zero_hooks(QuoteExactSingleParams {
        pool_key: PoolKey {
            currency0: [0; 20],
            currency1: asset,
            fee: fee.into_array(),
            tick_spacing: tick_spacing.into_array(),
            hooks: [0; 20],
        },
        // Native ETH is currency0 and the ERC-20 asset is currency1.
        zero_for_one: false,
        exact_amount: amt,
        hook_data: [],
    })
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn user_entrypoint(len: usize) -> usize {
    #[cfg(feature = "network-arbitrum")]
    let (uniswap_quoter, network) = (UNISWAP_V4_QUOTER_ARBITRUM, Network::Arbitrum);
    #[cfg(feature = "network-robinhood")]
    let (uniswap_quoter, network) = (UNISWAP_V4_QUOTER_ROBINHOOD, Network::Robinhood);

    match read_cd::<Entrypoint>(len) {
        Entrypoint::EstimateEthValueCheckAccountsUniswap {
            asset,
            fee,
            tick_spacing,
            amt,
        } => {
            let asset_addr = Asset::try_from(asset)
                .expect("unknown asset")
                .addr(network)
                .expect("asset is not supported on this network");
            let calldata = make_quote_calldata(asset_addr, fee, tick_spacing, amt);
            let (rc, quote) = call_word(uniswap_quoter, &calldata, &U::ZERO, u64::MAX, 32);
            assert!(rc, "failed to call Uniswap quoter");
            write_word(&quote);
            0
        }
        Entrypoint::CleanHouse {
            asset: _,
            fee: _,
            tick_spacing: _,
            min_amt: _,
        } => 0,
    }
}

#[allow(unused)]
fn main() {}
