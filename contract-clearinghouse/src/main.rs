use bobcat_sdk::prelude::*;

use superposition_assets::{Asset, Network};

#[derive(EvmCdSerialise, EvmCdDeserialise, Debug, Clone)]
#[evm_selector]
enum Entrypoint {
    EstimateEthValueCheckAccountsUniswap {
        asset: Asset,
        fee: EvmCdU24,
        tick_spacing: EvmCdI24,
        amt: u128,
    },
    /// CleanHouse figures out how much of the asset given we have using
    /// erc20 balance, then it swaps everything we have to ETH, which it
    /// transfers to the MassSend contract.
    CleanHouse {
        asset: Asset,
        fee: EvmCdU24,
        tick_spacing: EvmCdI24,
        min_amt: u128,
    },
}

#[cfg(not(any(
    feature = "network-arbitrum",
    feature = "network-robinhood",
)))]
compile_error!(
    "network-arbitrum or network-robinhood-testnet is needed to be enabled"
);

const UNISWAP_V4_QUOTER_ARBITRUM: [u8; 20] = address!("3972c00f7ed4885e145823eb7c655375d275a1c5");

const UNISWAP_V4_QUOTER_ROBINHOOD: [u8; 20] = address("8dc178efb8111bb0973dd9d722ebeff267c98f94");

#[unsafe(no_mangle)]
fn user_entrypoint(len: usize) -> usize {
    #[cfg(feature = "network-arbitrum")]
    let (uniswap_quoter, network) = (UNISWAP_V4_QUOTER_ARBITRUM, Network::Arbitrum);
    #[cfg(feature = "network-robinhood")]
    let (uniswap_quoter, network) = (UNISWAP_V4_QUOTER_ROBINHOOD, Network::Robinhood);
    match read_cd::<_>(len) {
        Entrypoint::EstimateEthValueCheckAccountsUniswap {
            asset,
            fee,
            tick_spacing,
            amt,
        } => {
            let (rc, rd) = call_word(
                UNISWAP_QUOTER,
                &make_fn_quote_exact_input_zero_hooks(QuoteExactSingleParams {
                    pool_key: PoolKey {
                        currency0: [0u8; 20],
                        currency1: asset,
                        fee: EvmCdU24(fee),
                        tick_spacing: EvmCdI24(tick_spacing),
                        hooks: [0u8; 20],
                    },
                    zero_for_one: true,
                    exact_amount: amt,
                    hook_data: [0u8; 0],
                }),
                &U::ZERO,
                u64::MAX,
                32,
            );
            assert!(rc, "failed to call uniswap quoter");
            write_word(rd);
            0
        }
        Entrypoint::CleanHouse {
            asset,
            fee,
            tick_spacing,
            min_amt,
        } => 0,
    }
}
