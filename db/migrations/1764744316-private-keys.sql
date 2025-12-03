-- migrate:up

DO $$
BEGIN
	IF NOT EXISTS (
		SELECT 1 FROM pg_type WHERE typname = 'bytes64'
	) THEN
		CREATE DOMAIN BYTES64 AS CHAR(128);
	END IF;
END $$;

CREATE TABLE accounts_sender_keys_1 (
	id SERIAL PRIMARY KEY NOT NULL,
	private_key BYTES64 NOT NULL UNIQUE,
	last_accessed TIMESTAMP NOT NULL
);

CREATE OR REPLACE FUNCTION accounts_get_private_key_1()
RETURNS BYTES64
LANGUAGE plpgsql
AS $$
DECLARE
	selected_key BYTES64;
	random_offset INT;
BEGIN
	random_offset := floor(random() * 5)::INT;
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
	RETURN selected_key;
END;
$$;

-- migrate:down
