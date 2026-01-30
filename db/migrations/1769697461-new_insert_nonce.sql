-- migrate:up

CREATE FUNCTION accounts_insert_nonce_2(
	p_eoa_addr ADDRESS,
	p_consumed_nonce INTEGER
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
	v_secret_id INTEGER;
	v_nonce_id INTEGER;
BEGIN
	SELECT id INTO v_secret_id
	FROM accounts_secrets_1
	WHERE eoa_addr = p_eoa_addr AND valid_until > CURRENT_TIMESTAMP;
	IF v_secret_id IS NULL THEN
		RAISE EXCEPTION 'address not found';
	END IF;
	INSERT INTO accounts_secrets_nonces_1 (secret_id, consumed_nonce)
	VALUES (v_secret_id, p_consumed_nonce)
	RETURNING id INTO v_nonce_id;
	RETURN v_nonce_id;
END;
$$;

CREATE FUNCTION accounts_insert_nonce_secret_2(
	eoa_addr_ ADDRESS,
	priv_key_ BYTES32,
	nonce_ INTEGER,
	salt_ BYTES16
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
	PERFORM accounts_insert_nonce_2(eoa_addr_, nonce_);
	INSERT INTO accounts_secrets_1(eoa_addr, priv_key, salt)
	VALUES (eoa_addr_, priv_key_, salt_);
END;
$$;

-- migrate:down
