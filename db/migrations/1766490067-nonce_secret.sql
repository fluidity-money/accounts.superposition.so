-- migrate:up

CREATE FUNCTION accounts_insert_nonce_secret_1(
	eoa_addr_ ADDRESS,
	priv_key_ BYTES32,
	nonce_ INTEGER,
	salt_ BYTES16
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
	PERFORM accounts_insert_nonce_1(eoa_addr_, nonce_);
	INSERT INTO accounts_secrets_1(eoa_addr, priv_key, salt)
	VALUES (eoa_addr_, priv_key_, salt_);
END;
$$;

-- migrate:down
