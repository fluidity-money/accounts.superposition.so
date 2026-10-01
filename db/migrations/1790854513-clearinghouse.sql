-- migrate:up

DO $$
BEGIN
	IF NOT EXISTS (
		SELECT 1 FROM pg_type WHERE typname = 'network'
	) THEN
		CREATE TYPE NETWORK AS ENUM (
			'Arbitrum',
			'Robinhood'
		);
	END IF;
END $$;

CREATE TABLE accounts_clearinghouse_assets_uniswap_v4_1 (
	id SERIAL PRIMARY KEY,
	created_by TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	asset ADDRESS NOT NULL,
	fee INTEGER NOT NULL,
	network NETWORK NOT NULL,
	tick_spacing INTEGER NOT NULL,
	UNIQUE (network, asset)
);

INSERT INTO accounts_clearinghouse_assets_uniswap_v4_1 (
	asset,
	fee,
	network,
	tick_spacing
) VALUES
	-- Arbitrum One PoolManager, native ETH/USDC, pool
	-- 0x864abca0a6202dba5b8868772308da953ff125b0f95015adbf89aaf579e903a8.
	('0xaf88d065e77c8cc2239327c5edb3a432268e5831', 500, 'Arbitrum', 10),

	-- Arbitrum One PoolManager, native ETH/ARB, pool
	-- 0x973b2ab0a5108ead5eb3c6feeffc5c2b9c3c4004be8376d51f6f3241c41aca6e.
	('0x912ce59144191c1204e64559fe8253a0e49e6548', 3000, 'Arbitrum', 60),

	-- Robinhood Chain PoolManager, native ETH/WETH, pool
	-- 0x207783b44fcb4359b281e8040bf476b69cfebf1c93021a11923277ced238d1bc.
	('0x0bd7d308f8e1639fab988df18a8011f41eacad73', 500, 'Robinhood', 1),

	-- Robinhood Chain PoolManager, native ETH/USDG, highest-liquidity
	-- hookless pool: 0x54f7883914619af9105355bf83ed678bcf9f63560218ac61c9963b9503d0ba32.
	('0x5fc5360d0400a0fd4f2af552add042d716f1d168', 460, 'Robinhood', 9)
);

-- Arbitrum USDG is not seeded: its only native ETH pool uses hooks and currently
-- has no active liquidity, while this table describes hookless pools.

-- migrate:down
