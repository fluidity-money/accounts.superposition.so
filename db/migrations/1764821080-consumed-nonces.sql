-- migrate:up

-- Nonces that were consumed in the process of reusing a secret key that was created in the
-- past.

CREATE TABLE accounts_secrets_nonces_1 (
	id SERIAL PRIMARY KEY,
	secret_id INTEGER NOT NULL,
	consumed_nonce INTEGER NOT NULL,
	FOREIGN KEY (secret_id) REFERENCES accounts_secrets_1(id)
);

CREATE UNIQUE INDEX ON accounts_secrets_nonces_1 (secret_id, consumed_nonce);

CREATE FUNCTION accounts_insert_nonce_1(
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
	WHERE eoa_addr = p_eoa_addr;
	IF v_secret_id IS NULL THEN
		RAISE EXCEPTION 'address not found';
	END IF;
	INSERT INTO accounts_secrets_nonces_1 (secret_id, consumed_nonce)
	VALUES (v_secret_id, p_consumed_nonce)
	RETURNING id INTO v_nonce_id;
	RETURN v_nonce_id;
END;
$$;

-- migrate:down
