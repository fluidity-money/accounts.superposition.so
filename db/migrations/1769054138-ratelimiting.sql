-- migrate:up

-- The bloom filter is regularly updated by a separate CDC service. It's kept updated to
-- prevent abuse. It's tough to actually prevent abuse, so this exists more as a checkpoint
-- to encourage adoption of the RPC service, which will have a free tier. Some actions,
-- like account creation, would better be serviced with a captcha.

CREATE TABLE ninelives_ratelimit_bloom_1 (
	id SERIAL PRIMARY KEY,
	created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	bloom VARCHAR NOT NULL,
	bucket VARCHAR NOT NULL DEFAULT 'accounts'
);

CREATE FUNCTION ninelives_ratelimit_timeslice_1()
RETURNS TIMESTAMP AS $$
    SELECT to_timestamp(FLOOR(EXTRACT(EPOCH FROM NOW()) / 300) * 300)::timestamp;
$$ LANGUAGE SQL STABLE;

-- Based on updates to the hook table that's added to to mutations:

CREATE TABLE ninelives_ratelimit_hook_1 (
	id SERIAL PRIMARY KEY,
	created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	timeslice TIMESTAMP NOT NULL DEFAULT ninelives_ratelimit_timeslice_1(),
	id ADDRESS NOT NULL,
	count INTEGER NOT NULL DEFAULT 0
);

CREATE FUNCTION ninelives_bump_ratelimit_1(p_user_id VARCHAR)
RETURNS INTEGER AS $$
	INSERT INTO ninelives_ratelimit_hook_1 (id, timeslice, count)
	VALUES (p_user_id, ninelives_ratelimit_timeslice_1(), 1)
	ON CONFLICT (timeslice, id) DO UPDATE
		SET count = ninelives_ratelimit_hook_1.count + 1
	RETURNING count;
$$ LANGUAGE SQL;

CREATE UNIQUE INDEX ON ninelives_ratelimit_hook_1 (timeslice, id);

-- Which in turn has specifics of how many requests a user has made in a bucket, returning
-- nothing if the time slice isn't current anymore.

CREATE FUNCTION ninelives_get_ratelimit_1(p_user_id VARCHAR)
RETURNS INTEGER AS $$
	SELECT COALESCE(
		(SELECT count FROM ninelives_ratelimit_hook_1
		 WHERE timeslice = ninelives_ratelimit_timeslice_1() AND user_id = p_user_id),
		1
	);
$$ LANGUAGE SQL STABLE;

CREATE FUNCTION ninelives_ratelimit_trigger_fn_1()
RETURNS TRIGGER AS $$
BEGIN
	PERFORM ninelives_bump_ratelimit_1(NEW.eoa_addr::VARCHAR);
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ninelives_ratelimit_trigger_1
	AFTER INSERT ON accounts_executed_transactions_1
	FOR EACH ROW
	EXECUTE FUNCTION ninelives_ratelimit_trigger_fn_1();

-- migrate:down
