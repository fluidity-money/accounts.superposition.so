-- migrate:up

CREATE TABLE accounts_sender_keys_1 (
	id SERIAL PRIMARY KEY NOT NULL,
	private_key BYTES32 NOT NULL UNIQUE,
	last_accessed TIMESTAMP
);

CREATE FUNCTION accounts_get_private_key_1()
RETURNS BYTES32
LANGUAGE plpgsql
AS $$
DECLARE
	selected_key BYTES64;
	random_offset INT;
	total_rows INT;
BEGIN
	SELECT COUNT(*) INTO total_rows FROM accounts_sender_keys_1;
	IF total_rows > 0 THEN
		random_offset := floor(random() * LEAST(5, total_rows))::INT;
		UPDATE accounts_sender_keys_1
		SET last_accessed = NOW()
		WHERE id = (
			SELECT id
			FROM accounts_sender_keys_1
			ORDER BY last_accessed ASC
			LIMIT 1
			OFFSET random_offset
		)
		RETURNING private_key INTO selected_key;
	END IF;
	RETURN selected_key;
END;
$$;

-- migrate:down
