-- migrate:up

CREATE TABLE accounts_secrets_2 (
	id SERIAL PRIMARY KEY,
	eoa_addr ADDRESS NOT NULL,
	-- This needs to be NULL when we migrate new accounts over. This should be safe
	-- since we can't pass a null address for our check:
	secret BYTES32,
	valid_until TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP + INTERVAL '1 month'
);

CREATE TABLE accounts_secrets_nonces_2 (
	id SERIAL PRIMARY KEY,
	eoa_addr ADDRESS NOT NULL,
	nonce INTEGER NOT NULL
);

CREATE UNIQUE INDEX ON accounts_secrets_nonces_2 (eoa_addr, nonce);

CREATE FUNCTION accounts_insert_nonce_secret_3(
	eoa_addr_ ADDRESS,
	secret_ BYTES32,
	nonce_ INTEGER
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
	INSERT INTO accounts_secrets_nonces_2(eoa_addr, nonce) VALUES (eoa_addr_, nonce_);
	INSERT INTO accounts_secrets_2(eoa_addr, secret)
	VALUES (eoa_addr_, secret_);
END;
$$;

INSERT INTO accounts_secrets_2 (eoa_addr)
SELECT DISTINCT eoa_addr FROM accounts_secrets_1;

-- migrate:down
