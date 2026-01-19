-- migrate:up

CREATE TABLE accounts_executed_transactions_2 (
	id SERIAL PRIMARY KEY,
	created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	eoa_addr ADDRESS NOT NULL,
	transaction_hash HASH NOT NULL,
	gas_limit INTEGER NOT NULL,
	desc_ VARCHAR NOT NULL
);

CREATE INDEX ON accounts_executed_transactions_2 (eoa_addr);
CREATE INDEX ON accounts_executed_transactions_2 (transaction_hash);
CREATE INDEX ON accounts_executed_transactions_2 (desc_);

-- migrate:down
