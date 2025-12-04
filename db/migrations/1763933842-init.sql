-- migrate:up

DO $$
BEGIN
	IF NOT EXISTS (
		SELECT 1 FROM pg_type WHERE typname = 'hugeint'
	) THEN
		CREATE DOMAIN HUGEINT AS NUMERIC(78, 0);
	END IF;

	IF NOT EXISTS (
		SELECT 1 FROM pg_type WHERE typname = 'address'
	) THEN
		CREATE DOMAIN ADDRESS AS CHAR(42);
	END IF;

	IF NOT EXISTS (
		SELECT 1 FROM pg_type WHERE typname = 'hash'
	) THEN
		CREATE DOMAIN HASH AS CHAR(66);
	END IF;

	IF NOT EXISTS (
		SELECT 1 FROM pg_type WHERE typname = 'bytes32'
	) THEN
		CREATE DOMAIN BYTES32 AS CHAR(64);
	END IF;
END $$;

-- Secrets needed for the worker to execute a transaction.
CREATE TABLE accounts_secrets_1 (
	id SERIAL PRIMARY KEY,
	eoa_addr ADDRESS NOT NULL,
	-- The secret that's needed to spend for a user to send instructions to this
	-- account. This is the digest of the Argon2id hashing we do.
	priv_key VARCHAR NOT NULL,
	-- Salt for this address.
	salt VARCHAR(16) NOT NULL
);

-- Unsent transcations that need executing. The timestamp is provided by the end user and ensured
-- to be larger than the maximum for the sender here.
CREATE TABLE accounts_executed_transactions_1 (
	id SERIAL PRIMARY KEY,
	eoa_addr ADDRESS NOT NULL,
	transaction_hash HASH NOT NULL UNIQUE
);

-- migrate:down
