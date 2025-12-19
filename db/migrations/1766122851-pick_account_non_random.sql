-- migrate:up

CREATE FUNCTION accounts_get_private_key_2()
RETURNS BYTES32
LANGUAGE plpgsql
AS $$
DECLARE
	selected_key BYTES32;
BEGIN
	UPDATE accounts_sender_keys_1
	SET last_accessed = NOW()
	WHERE id = (
		SELECT id
		FROM accounts_sender_keys_1
		ORDER BY last_accessed ASC NULLS FIRST
		LIMIT 1
	)
	RETURNING private_key INTO selected_key;
	RETURN selected_key;
END;
$$;

-- migrate:down
