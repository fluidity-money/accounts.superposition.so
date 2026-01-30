\restrict jaz2xk4yuhd95iVMg1oW0SXCwYUP38f3cFt9aKsSrEeoL6m7GqVQ05S3wrFurTg

-- Dumped from database version 16.11
-- Dumped by pg_dump version 17.7 (Debian 17.7-0+deb13u1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: timescaledb; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS timescaledb WITH SCHEMA public;


--
-- Name: EXTENSION timescaledb; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION timescaledb IS 'Enables scalable inserts and complex queries for time-series data (Community Edition)';


--
-- Name: aiven_extras; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA aiven_extras;


--
-- Name: pg_cron; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION pg_cron; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_cron IS 'Job scheduler for PostgreSQL';


--
-- Name: aiven_extras; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS aiven_extras WITH SCHEMA aiven_extras;


--
-- Name: EXTENSION aiven_extras; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION aiven_extras IS 'aiven_extras';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: address; Type: DOMAIN; Schema: public; Owner: -
--

CREATE DOMAIN public.address AS character(42);


--
-- Name: bytes; Type: DOMAIN; Schema: public; Owner: -
--

CREATE DOMAIN public.bytes AS character varying;


--
-- Name: bytes16; Type: DOMAIN; Schema: public; Owner: -
--

CREATE DOMAIN public.bytes16 AS character(32);


--
-- Name: bytes32; Type: DOMAIN; Schema: public; Owner: -
--

CREATE DOMAIN public.bytes32 AS character(64);


--
-- Name: bytes64; Type: DOMAIN; Schema: public; Owner: -
--

CREATE DOMAIN public.bytes64 AS character(128);


--
-- Name: bytes8; Type: DOMAIN; Schema: public; Owner: -
--

CREATE DOMAIN public.bytes8 AS character(16);


--
-- Name: bytes8_0x; Type: DOMAIN; Schema: public; Owner: -
--

CREATE DOMAIN public.bytes8_0x AS character(18);


--
-- Name: hash; Type: DOMAIN; Schema: public; Owner: -
--

CREATE DOMAIN public.hash AS character(66);


--
-- Name: hugeint; Type: DOMAIN; Schema: public; Owner: -
--

CREATE DOMAIN public.hugeint AS numeric(78,0);


--
-- Name: sarp_outcome; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.sarp_outcome AS ENUM (
    'abandoned',
    'completed'
);


--
-- Name: accounts_get_private_key_1(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.accounts_get_private_key_1() RETURNS public.bytes32
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


--
-- Name: accounts_get_private_key_2(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.accounts_get_private_key_2() RETURNS public.bytes32
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


--
-- Name: accounts_insert_nonce_1(public.address, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.accounts_insert_nonce_1(p_eoa_addr public.address, p_consumed_nonce integer) RETURNS integer
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


--
-- Name: accounts_insert_nonce_2(public.address, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.accounts_insert_nonce_2(p_eoa_addr public.address, p_consumed_nonce integer) RETURNS integer
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


--
-- Name: accounts_insert_nonce_secret_1(public.address, public.bytes32, integer, public.bytes16); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.accounts_insert_nonce_secret_1(eoa_addr_ public.address, priv_key_ public.bytes32, nonce_ integer, salt_ public.bytes16) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	PERFORM accounts_insert_nonce_1(eoa_addr_, nonce_);
	INSERT INTO accounts_secrets_1(eoa_addr, priv_key, salt)
	VALUES (eoa_addr_, priv_key_, salt_);
END;
$$;


--
-- Name: accounts_insert_nonce_secret_2(public.address, public.bytes32, integer, public.bytes16); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.accounts_insert_nonce_secret_2(eoa_addr_ public.address, priv_key_ public.bytes32, nonce_ integer, salt_ public.bytes16) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	PERFORM accounts_insert_nonce_2(eoa_addr_, nonce_);
	INSERT INTO accounts_secrets_1(eoa_addr, priv_key, salt)
	VALUES (eoa_addr_, priv_key_, salt_);
END;
$$;


--
-- Name: bozo_insert_comment_1(integer, character varying, public.hash); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.bozo_insert_comment_1(p_epoch integer, p_content character varying, p_transaction_hash public.hash) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
	v_epoch_seq INTEGER;
BEGIN
	SELECT COALESCE(MAX(epoch_seq), 0) + 1
	INTO v_epoch_seq
	FROM bozo_comments_1
	WHERE epoch = p_epoch;

	INSERT INTO bozo_comments_1 (epoch, epoch_seq, content, transaction_hash)
	VALUES (p_epoch, v_epoch_seq, p_content, p_transaction_hash);
END;
$$;


--
-- Name: discord_associate_username_1(character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.discord_associate_username_1(secretkey character varying, address_ character varying, discord_snowflake_ character varying, discord_username_ character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO discord_usernames_2 (
		discord_snowflake,
		discord_username,
		address,
		association_giver
	)
	VALUES (
		discord_snowflake_,
		discord_username_,
		address_,
		(SELECT id FROM points_auth_secret_keys_1 WHERE key = secretkey)
	);
END $$;


--
-- Name: erc20_insert_1(public.address, character varying, character varying, public.hugeint, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.erc20_insert_1(a public.address, n character varying, s character varying, t public.hugeint, d integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO erc20_cache_1 (address, name, symbol, total_supply, decimals)
	VALUES (a, n, s, t, d)
	ON CONFLICT (address) DO NOTHING;
END $$;


--
-- Name: ninelives_create_snapshot_from_summary_1(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ninelives_create_snapshot_from_summary_1() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO ninelives_market_odds_snapshot_1 (pool_address, odds)
	VALUES (NEW.pool_address, NEW.odds);
	RETURN NEW;
END;
$$;


--
-- Name: ninelives_emergency_wipe_1(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ninelives_emergency_wipe_1() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	DELETE FROM ninelives_paymaster_poll_1
	WHERE id NOT IN (
		SELECT poll_id FROM ninelives_paymaster_attempts_2
	);
END;
$$;


--
-- Name: ninelives_fun_ninelives_events_shares_burned_to_ninelives_buys_(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ninelives_fun_ninelives_events_shares_burned_to_ninelives_buys_() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	campaign_id TEXT;
	campaign_content JSONB;
	total_volume HUGEINT;
BEGIN
 	SELECT id, content
	INTO campaign_id, campaign_content
	FROM ninelives_campaigns_1
	WHERE content->>'poolAddress' = NEW.emitter_addr;

	SELECT SUM(total) as total_vol
    INTO total_volume
    FROM (
      SELECT COALESCE(SUM(fusdc_spent), 0) AS total
      FROM ninelives_events_shares_minted
      WHERE emitter_addr = NEW.emitter_addr
      UNION ALL
      SELECT COALESCE(SUM(fusdc_returned), 0) AS total
      FROM ninelives_events_shares_burned
      WHERE emitter_addr = NEW.emitter_addr
      union all
      SELECT COALESCE(SUM(fusdc_amt), 0) AS total
      FROM ninelives_events_liquidity_added
      WHERE emitter_addr = NEW.emitter_addr
    ) AS combined_totals;

	INSERT INTO ninelives_buys_and_sells_1 (
		transaction_hash,
		created_by,
		block_hash,
		block_number,
		emitter_addr,
		from_amount,
		from_symbol,
		to_amount,
		to_symbol,
		type,
		spender,
		recipient,
		total_volume,
		outcome_id,
		campaign_id,
		campaign_content
	)
	VALUES (
		NEW.transaction_hash,
		NEW.created_by,
		NEW.block_hash,
		NEW.block_number,
		NEW.emitter_addr,
        NEW.share_amount,
		'9#Share',
		NEW.fusdc_returned,
		'fUSDC',
		'sell',
		NEW.spender,
		NEW.recipient,
		total_volume,
		NEW.identifier,
		campaign_id,
		campaign_content
	);
	RETURN NEW;
END $$;


--
-- Name: ninelives_fun_ninelives_events_shares_minted_to_ninelives_buys_(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ninelives_fun_ninelives_events_shares_minted_to_ninelives_buys_() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	campaign_id TEXT;
	campaign_content JSONB;
	total_volume HUGEINT;
BEGIN
 	SELECT id, content
	INTO campaign_id, campaign_content
	FROM ninelives_campaigns_1
	WHERE content->>'poolAddress' = NEW.emitter_addr;

	SELECT SUM(total) as total_vol
    INTO total_volume
    FROM (
      SELECT COALESCE(SUM(fusdc_spent), 0) AS total
      FROM ninelives_events_shares_minted
      WHERE emitter_addr = NEW.emitter_addr
      UNION ALL
      SELECT COALESCE(SUM(fusdc_returned), 0) AS total
      FROM ninelives_events_shares_burned
      WHERE emitter_addr = NEW.emitter_addr
      union all
      SELECT COALESCE(SUM(fusdc_amt), 0) AS total
      FROM ninelives_events_liquidity_added
      WHERE emitter_addr = NEW.emitter_addr
    ) AS combined_totals;

	INSERT INTO ninelives_buys_and_sells_1 (
		transaction_hash,
		created_by,
		block_hash,
		block_number,
		emitter_addr,
		from_amount,
		from_symbol,
		to_amount,
		to_symbol,
		type,
		spender,
		recipient,
		total_volume,
		outcome_id,
		campaign_id,
		campaign_content
	)
	VALUES (
		NEW.transaction_hash,
		NEW.created_by,
		NEW.block_hash,
		NEW.block_number,
		NEW.emitter_addr,
		NEW.fusdc_spent,
		'fUSDC',
		NEW.share_amount,
		'9#Share',
		'buy',
		NEW.spender,
		NEW.recipient,
		total_volume,
		NEW.identifier,
		campaign_id,
		campaign_content
	);
	RETURN NEW;
END $$;


--
-- Name: ninelives_get_featured_campaigns_1(interval, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ninelives_get_featured_campaigns_1(interval_value interval, limit_count integer) RETURNS TABLE(id text, created_at timestamp without time zone, updated_at timestamp without time zone, content jsonb, name_to_search text, shown boolean, total_volume public.hugeint, total_liquidity public.hugeint, liquidity_last_hour public.hugeint)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    WITH liquidity_changes AS (
        SELECT emitter_addr AS pool, created_by, fusdc_amt AS delta_liquidity
        FROM ninelives_events_liquidity_added
        UNION ALL
        SELECT emitter_addr AS pool, created_by, -fusdc_amt AS delta_liquidity
        FROM ninelives_events_liquidity_removed
        UNION ALL
        SELECT emitter_addr AS pool, created_by, -fusdc_amt AS delta_liquidity
        FROM ninelives_events_liquidity_claimed
    ),
    hourly_change AS (
        SELECT
            pool,
            SUM(ABS(delta_liquidity)) AS liquidity_last_hour
        FROM liquidity_changes
        WHERE created_by >= NOW() - interval_value
        GROUP BY pool
    ),
    current_liquidity AS (
        SELECT
            pool,
            SUM(delta_liquidity) AS total_liquidity
        FROM liquidity_changes
        GROUP BY pool
    ),
    campaigns_with_liquidity AS (
        SELECT
            c.*,
            COALESCE(cl.total_liquidity, 0)::HUGEINT AS total_liquidity,
            COALESCE(hc.liquidity_last_hour, 0)::HUGEINT AS liquidity_last_hour
        FROM ninelives_campaigns_1 c
        LEFT JOIN current_liquidity cl ON c.content->>'poolAddress' = cl.pool
        LEFT JOIN hourly_change hc ON c.content->>'poolAddress' = hc.pool
    )
    SELECT *
    FROM campaigns_with_liquidity
    ORDER BY liquidity_last_hour DESC, total_liquidity DESC, total_volume DESC
    LIMIT limit_count;
END;
$$;


--
-- Name: ninelives_insert_unused_payoff_1(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ninelives_insert_unused_payoff_1() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO ninelives_payoff_unused_1 (pool_address, spender)
	VALUES (NEW.emitter_addr, NEW.recipient)
	ON CONFLICT (pool_address, spender) DO NOTHING;
	RETURN NEW;
END;
$$;


--
-- Name: ninelives_mark_payoff_spent_1(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ninelives_mark_payoff_spent_1() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	UPDATE ninelives_payoff_unused_1
	SET was_spent = TRUE
	WHERE pool_address = NEW.emitter_addr
	AND spender = NEW.spender;
	RETURN NEW;
END;
$$;


--
-- Name: ninelives_market_odds_summaries_1(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ninelives_market_odds_summaries_1() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	current_total NUMERIC;
	updated_odds JSONB;
BEGIN
	SELECT COALESCE((odds->>NEW.identifier::text)::NUMERIC, 0)
	INTO current_total
	FROM ninelives_market_summaries_1
	WHERE pool_address = NEW.emitter_addr;
	current_total := current_total + NEW.fusdc_spent;
	SELECT COALESCE(odds, '{}'::JSONB) || jsonb_build_object(NEW.identifier::text, current_total::text)
	INTO updated_odds
	FROM ninelives_market_summaries_1
	WHERE pool_address = NEW.emitter_addr;
	IF updated_odds IS NULL THEN
		updated_odds := jsonb_build_object(NEW.identifier::text, NEW.fusdc_spent::text);
	END IF;
	INSERT INTO ninelives_market_summaries_1 (pool_address, odds)
	VALUES (NEW.emitter_addr, updated_odds)
	ON CONFLICT (pool_address) DO UPDATE
	SET odds = EXCLUDED.odds,
		created_by = CURRENT_TIMESTAMP;

	RETURN NEW;
END;
$$;


--
-- Name: ninelives_not_claimed_payoffs_1(public.address); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ninelives_not_claimed_payoffs_1(target_address public.address) RETURNS TABLE(emitter_addr public.address)
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN QUERY
	SELECT DISTINCT sm.emitter_addr
	FROM ninelives_events_shares_minted sm
	WHERE sm.recipient = target_address
	AND EXISTS (
		SELECT 1
		FROM ninelives_events_payoff_activated pa
		WHERE pa.emitter_addr = sm.emitter_addr
		AND pa.identifier = sm.identifier
	)
	AND NOT EXISTS (
		SELECT 1
		FROM ninelives_events_payoff_activated pa
		WHERE pa.emitter_addr = sm.emitter_addr
		AND pa.identifier = sm.identifier
		AND pa.spender = target_address
	)
	AND NOT EXISTS (
		SELECT 1
		FROM ninelives_events_ninetails_loser_payoff nlp
		WHERE nlp.emitter_addr = sm.emitter_addr
		AND nlp.outcome = sm.identifier
		AND nlp.spender = target_address
	);
END;
$$;


--
-- Name: ninelives_paymaster_fail_poll_1(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ninelives_paymaster_fail_poll_1() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	DELETE FROM ninelives_paymaster_poll_1
	WHERE id NOT IN (
		SELECT poll_id FROM ninelives_paymaster_attempts_2
	);
END;
$$;


--
-- Name: ninelives_paymaster_track_result_1(integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ninelives_paymaster_track_result_1(p_poll_id integer, p_success boolean) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO ninelives_paymaster_attempts_1 (poll_id, success)
	VALUES (p_poll_id, p_success);
END;
$$;


--
-- Name: ninelives_paymaster_track_result_2(integer, boolean, public.hash); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ninelives_paymaster_track_result_2(p_poll_id integer, p_success boolean, hash public.hash) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO ninelives_paymaster_attempts_2 (poll_id, success, transaction_hash)
	VALUES (p_poll_id, p_success, hash);
END;
$$;


--
-- Name: ninelives_time_extension_1(public.bytes8, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ninelives_time_extension_1(cid public.bytes8, new_ts integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	UPDATE ninelives_buys_and_sells_1
	SET campaign_content = jsonb_set(campaign_content, '{ending}', to_jsonb(new_ts))
	WHERE campaign_id = cid;
	UPDATE ninelives_campaigns_1
	SET content = jsonb_set(content, '{ending}', to_jsonb(new_ts))
	WHERE id = '0x' || cid;
END $$;


--
-- Name: ninelives_update_all_earned_1(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ninelives_update_all_earned_1() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO ninelives_all_earned_1 (emitter_addr, recipient, fusdc_received)
	VALUES (NEW.emitter_addr, NEW.recipient, NEW.fusdc_received)
	ON CONFLICT ON CONSTRAINT ninelives_all_earned_1_emitter_recipient_unique
	DO UPDATE SET
		fusdc_received = ninelives_all_earned_1.fusdc_received + EXCLUDED.fusdc_received,
		updated_by = CURRENT_TIMESTAMP;
	RETURN NEW;
END;
$$;


--
-- Name: ninelives_update_buys_and_sells_for_winner(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ninelives_update_buys_and_sells_for_winner() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	UPDATE ninelives_buys_and_sells_1
	SET campaign_content = jsonb_set(campaign_content, '{winner}', ('"' || '0x' || NEW.identifier || '"')::jsonb)
	WHERE campaign_content->>'poolAddress' = NEW.emitter_addr;

	RETURN NEW;
END $$;


--
-- Name: ninelives_update_buys_sells_on_create(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ninelives_update_buys_sells_on_create() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	UPDATE ninelives_buys_and_sells_1
	SET campaign_content = NEW.content
	WHERE emitter_addr = NEW.content->>'poolAddress';

	RETURN NEW;
END $$;


--
-- Name: ninelives_update_campaign_for_winner(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ninelives_update_campaign_for_winner() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	UPDATE ninelives_campaigns_1
	SET content = jsonb_set(content, '{winner}', ('"' || '0x' || NEW.identifier || '"')::jsonb)
	WHERE content->>'poolAddress' = NEW.emitter_addr;

	RETURN NEW;
END $$;


--
-- Name: ninelives_update_liquidity_on_campaign_creation_1(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ninelives_update_liquidity_on_campaign_creation_1() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	UPDATE ninelives_campaigns_1
	SET total_volume =
		COALESCE(
			(
				SELECT sum(fusdc_amt) FROM ninelives_events_liquidity_added
				WHERE emitter_addr = NEW.content->>'poolAddress'
			),
			0
		)
		- COALESCE(
			(
				SELECT sum(fusdc_amt) FROM ninelives_events_liquidity_removed
				WHERE emitter_addr = NEW.content->>'poolAddress'
			),
			0
		)
       WHERE content->>'poolAddress' = NEW.content->>'poolAddress';

	RETURN NEW;
END;
$$;


--
-- Name: ninelives_update_market_odds_snapshot_1(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ninelives_update_market_odds_snapshot_1() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
INSERT INTO ninelives_market_odds_snapshot_1 (pool_address, odds)
SELECT
NEW.emitter_addr,
jsonb_object_agg(
identifier::text,
total_spent
) AS odds
FROM (
SELECT
identifier,
SUM(fusdc_spent) AS total_spent
FROM ninelives_events_shares_minted
WHERE emitter_addr = NEW.emitter_addr
GROUP BY identifier
) AS aggregated_data;
RETURN NEW;
END;
$$;


--
-- Name: ninelives_update_total_volume_after_burn(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ninelives_update_total_volume_after_burn() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	UPDATE ninelives_campaigns_1 AS nc
	SET total_volume = nc.total_volume + NEW.fusdc_returned
	WHERE NEW.emitter_addr = nc.content->>'poolAddress';

	RETURN NEW;
END $$;


--
-- Name: ninelives_update_total_volume_after_mint(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ninelives_update_total_volume_after_mint() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	UPDATE ninelives_campaigns_1 AS nc
	SET total_volume = nc.total_volume + NEW.fusdc_spent
	WHERE NEW.emitter_addr = nc.content->>'poolAddress';

	RETURN NEW;
END $$;


--
-- Name: ninelives_update_total_volume_after_stake(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ninelives_update_total_volume_after_stake() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	UPDATE ninelives_campaigns_1 AS nc
	SET total_volume = nc.total_volume + NEW.fusdc_amt
	WHERE NEW.emitter_addr = nc.content->>'poolAddress';

	RETURN NEW;
END $$;


--
-- Name: oracles_ninelives_copy_prices_1_to_2_1(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.oracles_ninelives_copy_prices_1_to_2_1() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO oracles_ninelives_prices_2 (created_by, base, quote, amount, source)
	VALUES (NEW.created_by, NEW.base, NEW.quote, NEW.amount::numeric, NEW.source);
	RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: points_achievements_leaderboard_1_return; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.points_achievements_leaderboard_1_return (
    address character varying NOT NULL,
    scoring integer NOT NULL
);


--
-- Name: points_achievements_leaderboard_1(character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.points_achievements_leaderboard_1(product_ character varying, season_ integer) RETURNS SETOF public.points_achievements_leaderboard_1_return
    LANGUAGE sql STABLE
    AS $$
	SELECT
		address,
		SUM(scoring * achievement_count) AS scoring
	FROM points_achievements_received_2
	WHERE product= product_ AND season = season_
	GROUP BY address, product, season;
$$;


--
-- Name: points_auth_bearer_tokens_create_1(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.points_auth_bearer_tokens_create_1(secretkey character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE new_key VARCHAR;
BEGIN
	INSERT INTO points_auth_bearer_tokens_1 (secretkey)
		SELECT key AS secretkey FROM points_auth_secret_keys_1 WHERE key = secretkey
	RETURNING authkey INTO new_key;
	RETURN new_key;
END $$;


--
-- Name: points_auth_secret_keys_create_1(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.points_auth_secret_keys_create_1(email character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE new_key VARCHAR;
BEGIN
	INSERT INTO points_auth_secret_keys_1 (email) VALUES (email)
	RETURNING key INTO new_key;
	RETURN new_key;
END $$;


--
-- Name: points_displayed_via_endpoint_2(character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.points_displayed_via_endpoint_2(user_address character varying, from_rank integer) RETURNS TABLE(id integer, address character varying, points bigint, rank_position bigint, is_user_row boolean)
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN QUERY
	WITH ranked_points AS (
		SELECT
			p.id,
			p.address,
			p.points,
			ROW_NUMBER() OVER (ORDER BY p.points DESC) as rank_position
		FROM points_displayed_via_endpoint_1 p
	),
	page_results AS (
		SELECT
			rp.id,
			rp.address,
			rp.points,
			rp.rank_position,
			FALSE as is_user_row
		FROM ranked_points rp
		WHERE rp.rank_position >= from_rank
		AND rp.rank_position < from_rank + 50
	),
	user_row AS (
		SELECT
			rp.id,
			rp.address,
			rp.points,
			rp.rank_position,
			TRUE as is_user_row
		FROM ranked_points rp
		WHERE rp.address = user_address
		AND (rp.rank_position < from_rank OR rp.rank_position >= from_rank + 50)
	)
	SELECT * FROM page_results
	UNION ALL
	SELECT * FROM user_row
	ORDER BY rank_position;
END;
$$;


--
-- Name: points_displayed_via_endpoint_3(character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.points_displayed_via_endpoint_3(user_address character varying, from_rank integer) RETURNS TABLE(id integer, address character varying, points bigint, rank_position bigint, is_user_row boolean, default_domain character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN QUERY
	WITH ranked_points AS (
		SELECT
			p.id,
			p.address,
			p.points,
			ROW_NUMBER() OVER (ORDER BY p.points DESC) as rank_position
		FROM points_displayed_via_endpoint_1 p
	),
	ranked_points_with_domains AS (
		SELECT
			rp.id,
			rp.address,
			rp.points,
			rp.rank_position,
			pd.default_domain
		FROM ranked_points rp
		LEFT JOIN punk_domains_current_domains_1 pd ON rp.address = pd.address
	),
	page_results AS (
		SELECT
			rpd.id,
			rpd.address,
			rpd.points,
			rpd.rank_position,
			FALSE as is_user_row,
			rpd.default_domain
		FROM ranked_points_with_domains rpd
		WHERE rpd.rank_position >= from_rank
		AND rpd.rank_position < from_rank + 50
	),
	user_row AS (
		SELECT
			rpd.id,
			rpd.address,
			rpd.points,
			rpd.rank_position,
			TRUE as is_user_row,
			rpd.default_domain
		FROM ranked_points_with_domains rpd
		WHERE rpd.address = user_address
		AND (rpd.rank_position < from_rank OR rpd.rank_position >= from_rank + 50)
	)
	SELECT * FROM page_results
	UNION ALL
	SELECT * FROM user_row
	ORDER BY rank_position;
END;
$$;


--
-- Name: points_galaxe_has_bought_meow_domain_1(public.address); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.points_galaxe_has_bought_meow_domain_1(address public.address) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE result BOOLEAN;
BEGIN
	SELECT TRUE INTO result
	FROM nfts_user_owned_1
	WHERE user_address = address AND token_address = '0x4087fb91a1fbdef05761c02714335d232a2bf3a1';
	RETURN result;
END $$;


--
-- Name: points_galaxe_has_bought_ninelives_position_1(public.address); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.points_galaxe_has_bought_ninelives_position_1(address public.address) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE result BOOLEAN;
BEGIN
	SELECT TRUE INTO result
	FROM ninelives_buys_and_sells_1
	WHERE recipient = address;
	RETURN result;
END $$;


--
-- Name: points_galaxe_has_bridged_more_than_10_usd_6(public.address); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.points_galaxe_has_bridged_more_than_10_usd_6(address public.address) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    result BOOLEAN;
BEGIN
	SELECT EXISTS (
		SELECT 1
		FROM points_galxe_confirmed_bridge_to_spn_1
		WHERE owner = address
		AND is_swap = false
	) OR EXISTS (
		SELECT 1
		FROM stargate_events_stargate_oft_received
		WHERE to_address = address
		AND amount_received_ld > 10000000
		AND emitter_addr = '0x8ee21165ecb7562ba716c9549c1de751282b9b33'
	) INTO result;

	RETURN result;
END;
$$;


--
-- Name: points_galaxe_has_ninelives_created_market_1(public.address); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.points_galaxe_has_ninelives_created_market_1(address public.address) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE result BOOLEAN;
BEGIN
	SELECT TRUE INTO result
	FROM ninelives_campaigns_1
	WHERE content->'creator'->>'address' = address;
	RETURN result;
END $$;


--
-- Name: points_galaxe_has_ninelives_lpd_market_1(public.address); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.points_galaxe_has_ninelives_lpd_market_1(address public.address) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE result BOOLEAN;
BEGIN
	SELECT TRUE INTO result
	FROM ninelives_events_liquidity_added
	WHERE recipient = address;
	RETURN result;
END $$;


--
-- Name: points_galaxe_has_provided_liquidity_to_camelot_1(public.address); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.points_galaxe_has_provided_liquidity_to_camelot_1(address public.address) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE result BOOLEAN;
BEGIN
	SELECT TRUE INTO result
	FROM points_camelot_lp_positions_cleaned_1
	WHERE owner = address;
	RETURN result;
END $$;


--
-- Name: points_galaxe_has_user_bridged_more_than_10_usd_1(public.address); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.points_galaxe_has_user_bridged_more_than_10_usd_1(address public.address) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE result BOOLEAN;
BEGIN
	SELECT TRUE INTO result
	FROM lifi_events_generic_swap_completed
	WHERE receiver = address
	AND created_by < CURRENT_DATE + INTERVAL '1 day'
	AND (
		(to_asset_id = '0x6c030c5cc283f791b26816f325b9c632d964f8a1' AND to_amount > 1e6) OR
		(to_asset_id = '0x0000000000000000000000000000000000000000' AND to_amount > 3800000000000000)
	);
	RETURN result;
END $$;


--
-- Name: points_galaxe_has_user_bridged_more_than_10_usd_2(public.address); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.points_galaxe_has_user_bridged_more_than_10_usd_2(address public.address) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE result BOOLEAN;
BEGIN
	SELECT TRUE INTO result
	FROM points_galxe_confirmed_bridge_to_spn_1
	WHERE owner = address
	AND created_at < CURRENT_DATE + INTERVAL '1 day';
	RETURN result;
END $$;


--
-- Name: points_galaxe_has_user_bridged_more_than_10_usd_3(public.address, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.points_galaxe_has_user_bridged_more_than_10_usd_3(address public.address, was_swap boolean) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE result BOOLEAN;
BEGIN
	SELECT TRUE INTO result
	FROM points_galxe_confirmed_bridge_to_spn_1
	WHERE owner = address
	AND created_at < CURRENT_DATE + INTERVAL '1 day'
	AND is_swap = was_swap;
	RETURN result;
END $$;


--
-- Name: points_galaxe_has_user_bridged_more_than_10_usd_4(public.address, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.points_galaxe_has_user_bridged_more_than_10_usd_4(address public.address, was_swap boolean) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    result BOOLEAN;
BEGIN
	SELECT EXISTS (
		SELECT 1
		FROM points_galxe_confirmed_bridge_to_spn_1
		WHERE owner = address
		AND created_at < CURRENT_DATE + INTERVAL '1 day'
		AND is_swap = was_swap
	) OR EXISTS (
		SELECT 1
		FROM stargate_events_stargate_oft_received
		WHERE to_address = address
		AND amount_received_ld > 10000000
		AND emitter_addr = '0x8ee21165ecb7562ba716c9549c1de751282b9b33'
		AND created_by < CURRENT_DATE + INTERVAL '1 day'
	) INTO result;

	RETURN result;
END;
$$;


--
-- Name: points_galaxe_has_user_bridged_more_than_10_usd_5(public.address); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.points_galaxe_has_user_bridged_more_than_10_usd_5(address public.address) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    result BOOLEAN;
BEGIN
	SELECT EXISTS (
		SELECT 1
		FROM points_galxe_confirmed_bridge_to_spn_1
		WHERE owner = address
		AND created_at < CURRENT_DATE + INTERVAL '1 day'
	) OR EXISTS (
		SELECT 1
		FROM stargate_events_stargate_oft_received
		WHERE to_address = address
		AND amount_received_ld > 10000000
		AND created_at < CURRENT_DATE + INTERVAL '1 day'
		AND emitter_addr = '0x8ee21165ecb7562ba716c9549c1de751282b9b33'
	) INTO result;

	RETURN result;
END;
$$;


--
-- Name: points_galxe_confirm_bridge_to_spn(public.bytes32); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.points_galxe_confirm_bridge_to_spn(transaction_id public.bytes32) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO points_galxe_confirmed_bridge_to_spn_1 (owner)
	SELECT owner FROM points_galxe_pending_1
	WHERE points_galxe_pending_1.transaction_id = points_galxe_confirm_bridge_to_spn.transaction_id;

	UPDATE points_galxe_pending_1
	SET was_found = TRUE
	WHERE points_galxe_pending_1.transaction_id = points_galxe_confirm_bridge_to_spn.transaction_id;
END;
$$;


--
-- Name: points_galxe_confirm_bridge_to_spn_2(public.bytes32, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.points_galxe_confirm_bridge_to_spn_2(transaction_id public.bytes32, is_swap boolean) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO points_galxe_confirmed_bridge_to_spn_1 (owner, is_swap)
	SELECT owner, is_swap FROM points_galxe_pending_1
	WHERE points_galxe_pending_1.transaction_id = points_galxe_confirm_bridge_to_spn_2.transaction_id;

	UPDATE points_galxe_pending_1
	SET was_found = TRUE
	WHERE points_galxe_pending_1.transaction_id = points_galxe_confirm_bridge_to_spn_2.transaction_id;
END;
$$;


--
-- Name: points_galxe_confirm_bridge_to_spn_3(public.bytes32, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.points_galxe_confirm_bridge_to_spn_3(id_ public.bytes32, is_swap boolean) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO points_galxe_confirmed_bridge_to_spn_1 (created_at, owner, is_swap)
	SELECT created_at, owner, is_swap FROM points_galxe_pending_1
	WHERE points_galxe_pending_1.transaction_id = id_;
	UPDATE points_galxe_pending_1
	SET was_found = TRUE
	WHERE points_galxe_pending_1.transaction_id = id_;
END;
$$;


--
-- Name: points_galxe_gm_done_1(public.address); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.points_galxe_gm_done_1(a public.address) RETURNS boolean
    LANGUAGE plpgsql
    AS $$ BEGIN
	RETURN EXISTS (
		SELECT 1 FROM onchaingm_events_onchaingmevent
		WHERE sender = a AND created_by > DATE('2025-06-18 19:09:57.072554+00')
	);
END $$;


--
-- Name: points_galxe_has_lifi_swapped_1(public.address); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.points_galxe_has_lifi_swapped_1(address public.address) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    result BOOLEAN;
BEGIN
	SELECT EXISTS (
		SELECT 1
		FROM points_galxe_confirmed_bridge_to_spn_1
		WHERE owner = address
		AND is_swap
		AND created_at > CURRENT_DATE - INTERVAL '1 day'
	) INTO result;
	RETURN result;
END;
$$;


--
-- Name: points_galxe_has_swapped_camelot_24h_1(public.address); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.points_galxe_has_swapped_camelot_24h_1(address public.address) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    result BOOLEAN;
BEGIN
	SELECT EXISTS (
		SELECT 1
		FROM points_galxe_camelot_24h_swap_1
		WHERE transaction_sender = address
	)  INTO result;
	RETURN result;
END;
$$;


--
-- Name: points_galxe_track_incoming_lifi_1(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.points_galxe_track_incoming_lifi_1() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (
        (NEW.to_asset_id = '0x6c030c5cc283f791b26816f325b9c632d964f8a1' AND NEW.to_amount > 1e6) OR
        (NEW.to_asset_id = '0x0000000000000000000000000000000000000000' AND NEW.to_amount > 3500000000000000)
    ) THEN
        INSERT INTO points_galxe_pending_1 (owner, transaction_id)
        VALUES (NEW.receiver, NEW.transaction_id)
        ON CONFLICT (transaction_id) DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: points_give_achievement_discord_2(character varying, character varying, character varying, character varying, integer, public.hugeint, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.points_give_achievement_discord_2(secretkey character varying, discord_snowflake_ character varying, name_ character varying, product_ character varying, season_ integer, count public.hugeint, should_count_matter boolean) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF NOT EXISTS
		(
			SELECT 1
			FROM discord_usernames_2
			WHERE discord_snowflake = discord_snowflake_
		)
	THEN RAISE EXCEPTION 'discord not found';
		END IF;
	PERFORM points_give_achievement_wallet_2(
		secretkey,
		(
			SELECT address
			FROM discord_usernames_2
			WHERE discord_snowflake = discord_snowflake_
		),
		name_,
		product_,
		season_,
		count,
		should_count_matter
	);
END $$;


--
-- Name: points_give_achievement_wallet_1(character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.points_give_achievement_wallet_1(secretkey character varying, address_ character varying, name character varying, count integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO points_achievements_received_1 (
		address,
		achievement_giver,
		achievement_name,
		achievement_count
	)
	VALUES (
		address_,
		(SELECT id FROM points_auth_secret_keys_1 WHERE key = secretkey),
		name,
		count
	);
END $$;


--
-- Name: points_give_achievement_wallet_2(character varying, character varying, character varying, character varying, integer, public.hugeint, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.points_give_achievement_wallet_2(secretkey character varying, address_ character varying, name_ character varying, product_ character varying, season_ integer, count public.hugeint, should_count_matter boolean) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF NOT should_count_matter THEN
		IF EXISTS (
			SELECT 1
			FROM points_achievements_received_2
			WHERE
				address = address_
				AND achievement_name = name_
				AND season = season_
		) THEN
			RETURN;
		END IF;
	END IF;
	INSERT INTO points_achievements_received_2 (
		address,
		achievement_giver,
		achievement_name,
		product,
		season,
		achievement_count,
		scoring
	)
	VALUES (
		address_,
		(SELECT id FROM points_auth_secret_keys_1 WHERE key = secretkey),
		name_,
		product_,
		season_,
		count,
		(SELECT scoring FROM points_achievement_leaderboard_value_1 WHERE name = name_)
	);
END $$;


--
-- Name: points_has_bought_non_dpm_shares_1(public.address); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.points_has_bought_non_dpm_shares_1(user_address public.address) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
	RETURN EXISTS (
		SELECT 1
		FROM ninelives_events_shares_minted esm
		INNER JOIN ninelives_campaigns_1 c
			ON (c.content->>'poolAddress') = esm.emitter_addr::text
		WHERE esm.recipient = user_address
			AND esm.created_by > '2025-11-10 14:33:01.107069+00'::timestamp
			AND (c.content->>'isDppm')::boolean = false
	);
END;
$$;


--
-- Name: points_ninelives_delete_campaign_erik_superadmin_1(public.bytes8); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.points_ninelives_delete_campaign_erik_superadmin_1(id_ public.bytes8) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	DELETE FROM ninelives_buys_and_sells_1 WHERE campaign_id = '0x' || id_;
	DELETE FROM ninelives_campaigns_1 WHERE id = '0x' || id_;
END $$;


--
-- Name: points_snapshot_points_2(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.points_snapshot_points_2() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	DELETE FROM points_displayed_via_endpoint_1;
	INSERT INTO points_displayed_via_endpoint_1 (address, points)
	SELECT LOWER(address), SUM(total_points)::bigint
	FROM points_everything_2
	GROUP BY LOWER(address)
	ON CONFLICT (address)
	DO UPDATE SET points = EXCLUDED.points, updated_by = CURRENT_TIMESTAMP;
END $$;


--
-- Name: points_snapshot_points_3(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.points_snapshot_points_3() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	DELETE FROM points_displayed_via_endpoint_1;
	INSERT INTO points_displayed_via_endpoint_1 (address, points)
	SELECT LOWER(address), SUM(total_points)::bigint
	FROM points_everything_2_1
	GROUP BY LOWER(address)
	ON CONFLICT (address)
	DO UPDATE SET points = EXCLUDED.points, updated_by = CURRENT_TIMESTAMP;
END $$;


--
-- Name: points_system_secretkey(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.points_system_secretkey() RETURNS character varying
    LANGUAGE sql STABLE
    AS $$
	SELECT key FROM points_auth_secret_keys_1 where email = 'points@superposition';
$$;


--
-- Name: points_trigger_fun_9_lives_1(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.points_trigger_fun_9_lives_1() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF (SELECT COUNT(DISTINCT identifier) AS count FROM ninelives_events_shares_minted WHERE count) > 8 THEN
		PERFORM points_give_achievement_wallet_2(
			(SELECT points_system_secretkey()),
			NEW.recipient,
			'9 Lives',
			'9lives',
			1,
			9 * NEW.fusdc_spent,
			FALSE
		);
	END IF;
	RETURN NEW;
END $$;


--
-- Name: points_trigger_fun_dont_stop_believing_1(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.points_trigger_fun_dont_stop_believing_1() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	PERFORM points_give_achievement_wallet_2(
		(SELECT points_system_secretkey()),
		NEW.recipient,
		'Don''t stop believing',
		'9lives',
		1,
		0.00001 * NEW.fusdc_received,
		TRUE
	);
	RETURN NEW;
END $$;


--
-- Name: points_trigger_fun_liquidity_purrvider_1(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.points_trigger_fun_liquidity_purrvider_1() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	PERFORM points_give_achievement_wallet_2(
		(SELECT points_system_secretkey()),
		NEW.recipient,
		'Liquidity Purrvider',
		'9lives',
		1,
		1 * NEW.fusdc_spent,
		TRUE
	);
	RETURN NEW;
END $$;


--
-- Name: points_trigger_fun_predict_the_presidential_election_1(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.points_trigger_fun_predict_the_presidential_election_1() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF NEW.emitter_addr = '0xc0393bb76c72378eb59ae5690c71efb62a420921' THEN
		PERFORM points_give_achievement_wallet_2(
			(SELECT points_system_secretkey()),
			NEW.recipient,
			'Predict the presidential election',
			'9lives',
			1,
			1,
			FALSE
		);
	END IF;
	RETURN NEW;
END $$;


--
-- Name: refresh_swap_price_volume_views(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.refresh_swap_price_volume_views() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	REFRESH MATERIALIZED VIEW seawater_pool_swap2_price_hourly_1;
	REFRESH MATERIALIZED VIEW seawater_swaps_average_price_hourly_1;
	REFRESH MATERIALIZED VIEW seawater_pool_swap_volume_hourly_1;
	REFRESH MATERIALIZED VIEW seawater_pool_swap_volume_daily_1;
	REFRESH MATERIALIZED VIEW seawater_pool_swap_volume_monthly_1;
END $$;


--
-- Name: refresh_swap_price_volume_views_2(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.refresh_swap_price_volume_views_2() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	REFRESH MATERIALIZED VIEW seawater_pool_swap2_price_hourly_2;
	REFRESH MATERIALIZED VIEW seawater_swaps_average_price_hourly_2;
	REFRESH MATERIALIZED VIEW seawater_pool_swap_volume_hourly_2;
	REFRESH MATERIALIZED VIEW seawater_pool_swap_volume_daily_2;
	REFRESH MATERIALIZED VIEW seawater_pool_swap_volume_monthly_2;
END $$;


--
-- Name: sarp_track_requests(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sarp_track_requests() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO sarp_tracked_requests (
		created_by,
		block_hash,
		transaction_hash,
		block_number,
		emitter_addr,
		ticket_no,
		trading
	) VALUES (
		NEW.created_by,
		NEW.block_hash,
		NEW.transaction_hash,
		NEW.block_number,
		NEW.emitter_addr,
		NEW.ticket,
		NEW.trading
	);
	RETURN NEW;
END $$;


--
-- Name: seawater_swaps_1_return; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.seawater_swaps_1_return (
    id integer NOT NULL,
    "timestamp" public.hugeint NOT NULL,
    sender character varying NOT NULL,
    token_in character varying NOT NULL,
    token_out character varying NOT NULL,
    amount_in public.hugeint NOT NULL,
    amount_out public.hugeint NOT NULL,
    token_out_decimals public.hugeint NOT NULL,
    token_in_decimals public.hugeint NOT NULL
);


--
-- Name: seawater_swaps_1(public.address, public.hugeint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.seawater_swaps_1(fusdcaddress public.address, fusdcdecimals public.hugeint) RETURNS SETOF public.seawater_swaps_1_return
    LANGUAGE sql STABLE
    AS $$
SELECT
		swaps.id,
		swaps.timestamp,
		swaps.sender,
		swaps.token_in,
		swaps.token_out,
		swaps.amount_in,
		swaps.amount_out,
	COALESCE(toPool.decimals, fusdcDecimals) AS token_out_decimals,
	COALESCE(fromPool.decimals, fusdcDecimals) AS token_in_decimals
FROM (
	SELECT
		id,
		FLOOR(EXTRACT(EPOCH FROM created_by)) AS timestamp,
		user_ AS sender,
		from_ AS token_in,
		to_ AS token_out,
		amount_in,
		amount_out
	FROM
		events_seawater_swap2
	UNION ALL
	SELECT
		id,
		FLOOR(EXTRACT(EPOCH FROM created_by)) AS timestamp,
		user_,
		CASE
			WHEN zero_for_one THEN pool
			ELSE fusdcAddress
		END AS from,
		CASE
			WHEN zero_for_one THEN fusdcAddress
			ELSE pool
		END AS to,
		CASE
			WHEN zero_for_one THEN amount0
			ELSE amount1
		END AS amount_in,
		CASE
			WHEN zero_for_one THEN amount1
			ELSE amount0
		END AS amount_out
	FROM
		events_seawater_swap1
) swaps
LEFT JOIN events_seawater_newpool fromPool
	ON swaps.token_in = fromPool.token
LEFT JOIN events_seawater_newpool toPool
	ON swaps.token_out = toPool.token;
$$;


--
-- Name: seawater_swaps_2_return; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.seawater_swaps_2_return (
    created_by timestamp without time zone NOT NULL,
    sender public.address NOT NULL,
    token_in public.address NOT NULL,
    token_out public.address NOT NULL,
    amount_in public.hugeint NOT NULL,
    amount_out public.hugeint NOT NULL,
    token_out_decimals public.hugeint NOT NULL,
    token_in_decimals public.hugeint NOT NULL
);


--
-- Name: seawater_swaps_pool_1(public.address, public.hugeint, public.address, timestamp without time zone, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.seawater_swaps_pool_1(fusdcaddress public.address, fusdcdecimals public.hugeint, filter public.address, after timestamp without time zone, limit_ integer) RETURNS SETOF public.seawater_swaps_2_return
    LANGUAGE sql STABLE
    AS $$
SELECT
	swaps.created_by,
	swaps.sender,
	swaps.token_in,
	swaps.token_out,
	swaps.amount_in,
	swaps.amount_out,
	COALESCE(toPool.decimals, fusdcDecimals) AS token_out_decimals,
	COALESCE(fromPool.decimals, fusdcDecimals) AS token_in_decimals
FROM (
	(
		SELECT
			created_by,
			user_ AS sender,
			from_ AS token_in,
			to_ AS token_out,
			amount_in,
			amount_out
		FROM
			events_seawater_swap2
		WHERE created_by > after AND (from_ = filter OR to_ = filter)
		ORDER BY created_by DESC
		LIMIT limit_
	)
	UNION ALL
	(
		SELECT
			created_by,
			user_ AS sender,
			CASE
				WHEN zero_for_one THEN pool
				ELSE fusdcAddress
			END AS from,
			CASE
				WHEN zero_for_one THEN fusdcAddress
				ELSE pool
			END AS to,
			CASE
				WHEN zero_for_one THEN amount0
				ELSE amount1
			END AS amount_in,
			CASE
				WHEN zero_for_one THEN amount1
				ELSE amount0
			END AS amount_out
		FROM
			events_seawater_swap1
		WHERE created_by > after AND pool = filter
		ORDER BY created_by DESC
		LIMIT limit_
	)
) swaps
LEFT JOIN events_seawater_newpool fromPool
	ON swaps.token_in = fromPool.token
LEFT JOIN events_seawater_newpool toPool
	ON swaps.token_out = toPool.token;
$$;


--
-- Name: seawater_swaps_3_return; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.seawater_swaps_3_return (
    created_by timestamp without time zone NOT NULL,
    sender public.address NOT NULL,
    token_in public.address NOT NULL,
    token_out public.address NOT NULL,
    amount_in public.hugeint NOT NULL,
    amount_out public.hugeint NOT NULL,
    transaction_hash public.hash NOT NULL,
    token_out_decimals public.hugeint NOT NULL,
    token_in_decimals public.hugeint NOT NULL
);


--
-- Name: seawater_swaps_pool_2(public.address, public.hugeint, public.address, timestamp without time zone, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.seawater_swaps_pool_2(fusdcaddress public.address, fusdcdecimals public.hugeint, filter public.address, after timestamp without time zone, limit_ integer) RETURNS SETOF public.seawater_swaps_3_return
    LANGUAGE sql STABLE
    AS $$
SELECT
	swaps.created_by,
	swaps.sender,
	swaps.token_in,
	swaps.token_out,
	swaps.amount_in,
	swaps.amount_out,
	swaps.transaction_hash,
	COALESCE(toPool.decimals, fusdcDecimals) AS token_out_decimals,
	COALESCE(fromPool.decimals, fusdcDecimals) AS token_in_decimals
FROM (
	(
		SELECT
			created_by,
			user_ AS sender,
			from_ AS token_in,
			to_ AS token_out,
			amount_in,
			amount_out,
			transaction_hash
		FROM
			events_seawater_swap2
		WHERE created_by > after AND (from_ = filter OR to_ = filter)
		ORDER BY created_by DESC
		LIMIT limit_
	)
	UNION ALL
	(
		SELECT
			created_by,
			user_ AS sender,
			CASE
				WHEN zero_for_one THEN pool
				ELSE fusdcAddress
			END AS from,
			CASE
				WHEN zero_for_one THEN fusdcAddress
				ELSE pool
			END AS to,
			CASE
				WHEN zero_for_one THEN amount0
				ELSE amount1
			END AS amount_in,
			CASE
				WHEN zero_for_one THEN amount1
				ELSE amount0
			END AS amount_out,
			transaction_hash
		FROM
			events_seawater_swap1
		WHERE created_by > after AND pool = filter
		ORDER BY created_by DESC
		LIMIT limit_
	)
) swaps
LEFT JOIN events_seawater_newpool fromPool
	ON swaps.token_in = fromPool.token
LEFT JOIN events_seawater_newpool toPool
	ON swaps.token_out = toPool.token;
$$;


--
-- Name: seawater_swaps_pool_3(public.address, public.hugeint, public.address, timestamp without time zone, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.seawater_swaps_pool_3(fusdcaddress public.address, fusdcdecimals public.hugeint, filter public.address, after timestamp without time zone, limit_ integer) RETURNS SETOF public.seawater_swaps_3_return
    LANGUAGE sql STABLE
    AS $$
SELECT
	swaps.created_by,
	swaps.sender,
	swaps.token_in,
	swaps.token_out,
	swaps.amount_in,
	swaps.amount_out,
	swaps.transaction_hash,
	COALESCE(toPool.decimals, fusdcDecimals) AS token_out_decimals,
	COALESCE(fromPool.decimals, fusdcDecimals) AS token_in_decimals
FROM (
	(
		SELECT
			created_by,
			user_ AS sender,
			from_ AS token_in,
			to_ AS token_out,
			amount_in,
			amount_out,
			transaction_hash
		FROM
			events_seawater_swap2
		WHERE created_by > after AND (from_ = filter OR to_ = filter) AND (from_ = fusdcAddress OR to_ = fusdcAddress)
		ORDER BY created_by DESC
		LIMIT limit_
	)
	UNION ALL
	(
		SELECT
			created_by,
			user_ AS sender,
			CASE
				WHEN zero_for_one THEN pool
				ELSE fusdcAddress
			END AS from,
			CASE
				WHEN zero_for_one THEN fusdcAddress
				ELSE pool
			END AS to,
			CASE
				WHEN zero_for_one THEN amount0
				ELSE amount1
			END AS amount_in,
			CASE
				WHEN zero_for_one THEN amount1
				ELSE amount0
			END AS amount_out,
			transaction_hash
		FROM
			events_seawater_swap1
		WHERE created_by > after AND pool = filter
		ORDER BY created_by DESC
		LIMIT limit_
	)
) swaps
LEFT JOIN events_seawater_newpool fromPool
	ON swaps.token_in = fromPool.token
LEFT JOIN events_seawater_newpool toPool
	ON swaps.token_out = toPool.token;
$$;


--
-- Name: seawater_swaps_pool_4(public.address, public.hugeint, public.address, timestamp without time zone, integer, public.address); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.seawater_swaps_pool_4(fusdcaddress public.address, fusdcdecimals public.hugeint, pool_ public.address, after timestamp without time zone, limit_ integer, filter public.address DEFAULT NULL::bpchar) RETURNS SETOF public.seawater_swaps_3_return
    LANGUAGE sql STABLE
    AS $$
WITH all_swaps AS (
    -- swap1
    SELECT
        created_by,
        user_ AS sender,
        CASE
            WHEN zero_for_one THEN pool_
            ELSE fusdcAddress
        END AS token_in,
        CASE
            WHEN zero_for_one THEN fusdcAddress
            ELSE pool_
        END AS token_out,
        CASE
            WHEN zero_for_one THEN amount0
            ELSE amount1
        END AS amount_in,
        CASE
            WHEN zero_for_one THEN amount1
            ELSE amount0
        END AS amount_out,
        transaction_hash
    FROM events_seawater_swap1
    WHERE created_by > after AND pool_ = pool_
    UNION ALL
    -- swap2
    SELECT
        created_by,
        user_ AS sender,
        from_ AS token_in,
        to_ AS token_out,
        amount_in,
        amount_out,
        transaction_hash
    FROM events_seawater_swap2
    WHERE created_by > after AND (from_ = pool_ OR to_ = pool_)
),
filtered_swaps AS (
    SELECT *
    FROM all_swaps
    WHERE
        -- all swaps
        filter IS NULL OR
        -- fUSDC->pool_ OR pool->fUSDC
        (
            filter = fusdcAddress
            AND (token_in = fusdcAddress AND token_out = pool_) OR
            (token_in = pool_ AND token_out = fusdcAddress)
        )
        -- filter->pool_ OR pool_->filter
        OR
        (
            filter <> fusdcAddress
            AND (token_in = filter AND token_out = pool_) OR
            (token_in = pool_ AND token_out = filter)
        )
)
SELECT
    swaps.created_by,
    swaps.sender,
    swaps.token_in,
    swaps.token_out,
    swaps.amount_in,
    swaps.amount_out,
    swaps.transaction_hash,
    COALESCE(toPool.decimals, fusdcDecimals) AS token_out_decimals,
    COALESCE(fromPool.decimals, fusdcDecimals) AS token_in_decimals
FROM filtered_swaps swaps
LEFT JOIN events_seawater_newpool fromPool
    ON swaps.token_in = fromPool.token
LEFT JOIN events_seawater_newpool toPool
    ON swaps.token_out = toPool.token
ORDER BY swaps.created_by DESC
LIMIT limit_;
$$;


--
-- Name: seawater_swaps_pool_5(public.address, public.hugeint, public.address, timestamp without time zone, integer, public.address); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.seawater_swaps_pool_5(fusdcaddress public.address, fusdcdecimals public.hugeint, pool_ public.address, after timestamp without time zone, limit_ integer, filter public.address DEFAULT NULL::bpchar) RETURNS SETOF public.seawater_swaps_3_return
    LANGUAGE sql STABLE
    AS $$
WITH all_swaps AS (
    -- swap1
    SELECT
        created_by,
        user_ AS sender,
        CASE
            WHEN zero_for_one THEN pool
            ELSE fusdcAddress
        END AS token_in,
        CASE
            WHEN zero_for_one THEN fusdcAddress
            ELSE pool
        END AS token_out,
        CASE
            WHEN zero_for_one THEN amount0
            ELSE amount1
        END AS amount_in,
        CASE
            WHEN zero_for_one THEN amount1
            ELSE amount0
        END AS amount_out,
        transaction_hash
    FROM events_seawater_swap1
    WHERE created_by > after AND pool = pool_
    UNION ALL
    -- swap2
    SELECT
        created_by,
        user_ AS sender,
        from_ AS token_in,
        to_ AS token_out,
        amount_in,
        amount_out,
        transaction_hash
    FROM events_seawater_swap2
    WHERE created_by > after AND (from_ = pool_ OR to_ = pool_)
),
filtered_swaps AS (
    SELECT *
    FROM all_swaps
    WHERE
        -- all swaps
        filter IS NULL OR
        -- fUSDC->pool_ OR pool->fUSDC
        (
            filter = fusdcAddress
            AND (token_in = fusdcAddress AND token_out = pool_) OR
            (token_in = pool_ AND token_out = fusdcAddress)
        )
        -- filter->pool_ OR pool_->filter
        OR
        (
            filter <> fusdcAddress
            AND (token_in = filter AND token_out = pool_) OR
            (token_in = pool_ AND token_out = filter)
        )
)
SELECT
    swaps.created_by,
    swaps.sender,
    swaps.token_in,
    swaps.token_out,
    swaps.amount_in,
    swaps.amount_out,
    swaps.transaction_hash,
    COALESCE(toPool.decimals, fusdcDecimals) AS token_out_decimals,
    COALESCE(fromPool.decimals, fusdcDecimals) AS token_in_decimals
FROM filtered_swaps swaps
LEFT JOIN events_seawater_newpool fromPool
    ON swaps.token_in = fromPool.token
LEFT JOIN events_seawater_newpool toPool
    ON swaps.token_out = toPool.token
ORDER BY swaps.created_by DESC
LIMIT limit_;
$$;


--
-- Name: seawater_swaps_pool_6(public.address, public.hugeint, public.address, timestamp without time zone, integer, public.address); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.seawater_swaps_pool_6(fusdcaddress public.address, fusdcdecimals public.hugeint, pool_ public.address, after timestamp without time zone, limit_ integer, filter public.address DEFAULT NULL::bpchar) RETURNS SETOF public.seawater_swaps_3_return
    LANGUAGE sql STABLE
    AS $$
WITH all_swaps AS (
    -- swap1
    SELECT
        created_by,
        user_ AS sender,
        CASE
            WHEN zero_for_one THEN pool
            ELSE fusdcAddress
        END AS token_in,
        CASE
            WHEN zero_for_one THEN fusdcAddress
            ELSE pool
        END AS token_out,
        CASE
            WHEN zero_for_one THEN amount0
            ELSE amount1
        END AS amount_in,
        CASE
            WHEN zero_for_one THEN amount1
            ELSE amount0
        END AS amount_out,
        transaction_hash
    FROM events_seawater_swap1
    WHERE created_by > after AND pool = pool_
    UNION ALL
    -- swap2
    SELECT
        created_by,
        user_ AS sender,
        from_ AS token_in,
        to_ AS token_out,
        amount_in,
        amount_out,
        transaction_hash
    FROM events_seawater_swap2
    WHERE created_by > after AND (from_ = pool_ OR to_ = pool_)
),
filtered_swaps AS (
    SELECT *
    FROM all_swaps
    WHERE
        -- all swaps
        filter IS NULL OR
        -- fUSDC->pool_ OR pool->fUSDC
        (
            filter = fusdcAddress
            AND (
                (token_in = fusdcAddress AND token_out = pool_) OR
                (token_in = pool_ AND token_out = fusdcAddress)
            )
        )
        -- filter->pool_ OR pool_->filter
        OR
        (
            filter <> fusdcAddress
            AND (
                (token_in = filter AND token_out = pool_) OR
                (token_in = pool_ AND token_out = filter)
            )
        )
)
SELECT
    swaps.created_by,
    swaps.sender,
    swaps.token_in,
    swaps.token_out,
    swaps.amount_in,
    swaps.amount_out,
    swaps.transaction_hash,
    COALESCE(toPool.decimals, fusdcDecimals) AS token_out_decimals,
    COALESCE(fromPool.decimals, fusdcDecimals) AS token_in_decimals
FROM filtered_swaps swaps
LEFT JOIN events_seawater_newpool fromPool
    ON swaps.token_in = fromPool.token
LEFT JOIN events_seawater_newpool toPool
    ON swaps.token_out = toPool.token
ORDER BY swaps.created_by DESC
LIMIT limit_;
$$;


--
-- Name: seawater_swaps_user_1(public.address, public.hugeint, public.address, timestamp without time zone, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.seawater_swaps_user_1(fusdcaddress public.address, fusdcdecimals public.hugeint, owner public.address, after timestamp without time zone, limit_ integer) RETURNS SETOF public.seawater_swaps_2_return
    LANGUAGE sql STABLE
    AS $$
SELECT
	swaps.created_by,
	swaps.sender,
	swaps.token_in,
	swaps.token_out,
	swaps.amount_in,
	swaps.amount_out,
	COALESCE(toPool.decimals, fusdcDecimals) AS token_out_decimals,
	COALESCE(fromPool.decimals, fusdcDecimals) AS token_in_decimals
FROM (
	(
		SELECT
			created_by,
			user_ AS sender,
			from_ AS token_in,
			to_ AS token_out,
			amount_in,
			amount_out
		FROM
			events_seawater_swap2
		WHERE created_by > after AND user_ = owner
		ORDER BY created_by DESC
		LIMIT limit_
	)
	UNION ALL
	(
		SELECT
			created_by,
			user_ AS sender,
			CASE
				WHEN zero_for_one THEN pool
				ELSE fusdcAddress
			END AS from,
			CASE
				WHEN zero_for_one THEN fusdcAddress
				ELSE pool
			END AS to,
			CASE
				WHEN zero_for_one THEN amount0
				ELSE amount1
			END AS amount_in,
			CASE
				WHEN zero_for_one THEN amount1
				ELSE amount0
			END AS amount_out
		FROM
			events_seawater_swap1
		WHERE created_by > after AND user_ = owner
		ORDER BY created_by DESC
		LIMIT limit_
	)
) swaps
LEFT JOIN events_seawater_newpool fromPool
	ON swaps.token_in = fromPool.token
LEFT JOIN events_seawater_newpool toPool
	ON swaps.token_out = toPool.token;
$$;


--
-- Name: seawater_swaps_user_2(public.address, public.hugeint, public.address, timestamp without time zone, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.seawater_swaps_user_2(fusdcaddress public.address, fusdcdecimals public.hugeint, owner public.address, after timestamp without time zone, limit_ integer) RETURNS SETOF public.seawater_swaps_3_return
    LANGUAGE sql STABLE
    AS $$
SELECT
	swaps.created_by,
	swaps.sender,
	swaps.token_in,
	swaps.token_out,
	swaps.amount_in,
	swaps.amount_out,
	swaps.transaction_hash,
	COALESCE(toPool.decimals, fusdcDecimals) AS token_out_decimals,
	COALESCE(fromPool.decimals, fusdcDecimals) AS token_in_decimals
FROM (
	(
		SELECT
			created_by,
			user_ AS sender,
			from_ AS token_in,
			to_ AS token_out,
			amount_in,
			amount_out,
			transaction_hash
		FROM
			events_seawater_swap2
		WHERE created_by > after AND user_ = owner
		ORDER BY created_by DESC
		LIMIT limit_
	)
	UNION ALL
	(
		SELECT
			created_by,
			user_ AS sender,
			CASE
				WHEN zero_for_one THEN pool
				ELSE fusdcAddress
			END AS from,
			CASE
				WHEN zero_for_one THEN fusdcAddress
				ELSE pool
			END AS to,
			CASE
				WHEN zero_for_one THEN amount0
				ELSE amount1
			END AS amount_in,
			CASE
				WHEN zero_for_one THEN amount1
				ELSE amount0
			END AS amount_out,
			transaction_hash
		FROM
			events_seawater_swap1
		WHERE created_by > after AND user_ = owner
		ORDER BY created_by DESC
		LIMIT limit_
	)
) swaps
LEFT JOIN events_seawater_newpool fromPool
	ON swaps.token_in = fromPool.token
LEFT JOIN events_seawater_newpool toPool
	ON swaps.token_out = toPool.token;
$$;


--
-- Name: seawater_swaps_user_3(public.address, public.hugeint, public.address, timestamp without time zone, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.seawater_swaps_user_3(fusdcaddress public.address, fusdcdecimals public.hugeint, owner public.address, after timestamp without time zone, limit_ integer) RETURNS SETOF public.seawater_swaps_3_return
    LANGUAGE sql STABLE
    AS $$
SELECT
	swaps.created_by,
	swaps.sender,
	swaps.token_in,
	swaps.token_out,
	swaps.amount_in,
	swaps.amount_out,
	swaps.transaction_hash,
	COALESCE(toPool.decimals, fusdcDecimals) AS token_out_decimals,
	COALESCE(fromPool.decimals, fusdcDecimals) AS token_in_decimals
FROM (
	(
		SELECT
			created_by,
			user_ AS sender,
			from_ AS token_in,
			to_ AS token_out,
			amount_in,
			amount_out,
			transaction_hash
		FROM
			events_seawater_swap2
		WHERE created_by > after AND user_ = owner
		ORDER BY created_by DESC
		LIMIT limit_
	)
	UNION ALL
	(
		SELECT
			created_by,
			user_ AS sender,
			CASE
				WHEN zero_for_one THEN pool
				ELSE fusdcAddress
			END AS from,
			CASE
				WHEN zero_for_one THEN fusdcAddress
				ELSE pool
			END AS to,
			CASE
				WHEN zero_for_one THEN amount0
				ELSE amount1
			END AS amount_in,
			CASE
				WHEN zero_for_one THEN amount1
				ELSE amount0
			END AS amount_out,
			transaction_hash
		FROM
			events_seawater_swap1
		WHERE created_by > after AND user_ = owner
		ORDER BY created_by DESC
		LIMIT limit_
	)
) swaps
LEFT JOIN events_seawater_newpool fromPool
	ON swaps.token_in = fromPool.token
LEFT JOIN events_seawater_newpool toPool
	ON swaps.token_out = toPool.token;
$$;


--
-- Name: snapshot_create_positions_1(character varying[], public.hugeint[], public.hugeint[], public.hugeint[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.snapshot_create_positions_1(pools character varying[], ids public.hugeint[], amount0s public.hugeint[], amount1s public.hugeint[]) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE affected_rows INT;
BEGIN
	DELETE FROM snapshot_positions_latest_1;
	FOR i IN 1..array_length(ids, 1) LOOP
		INSERT INTO snapshot_positions_latest_1 (
			updated_by,
			pos_id,
			owner,
			pool,
			lower,
			upper,
			amount0,
			amount1
		)
		SELECT
			CURRENT_TIMESTAMP,
			sw.pos_id,
			sw.owner,
			pool,
			sw.lower,
			sw.upper,
			amount0s[i],
			amount1s[i]
		FROM
			events_seawater_mintPosition sw
		WHERE
			sw.pos_id = ids[i] AND
			sw.pool = pools[i];

		INSERT INTO snapshot_positions_log_1 (
			created_by,
			pos_id,
			owner,
			pool,
			lower,
			upper,
			amount0,
			amount1
		)
		SELECT
			CURRENT_TIMESTAMP,
			sw.pos_id,
			sw.owner,
			pool,
			sw.lower,
			sw.upper,
			amount0s[i],
			amount1s[i]
		FROM
			events_seawater_mintPosition sw
		WHERE
			sw.pos_id = ids[i] AND
			sw.pool = pools[i];
	END LOOP;
END $$;


--
-- Name: snapshot_final_ticks_daily_1(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.snapshot_final_ticks_daily_1() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	DELETE FROM seawater_final_ticks_daily_2;
	INSERT INTO seawater_final_ticks_daily_2 SELECT * FROM seawater_final_ticks_daily_1;
END $$;


--
-- Name: snapshot_final_ticks_daily_3(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.snapshot_final_ticks_daily_3() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	DELETE FROM seawater_final_ticks_daily_3;
	INSERT INTO seawater_final_ticks_daily_3 SELECT * FROM seawater_final_ticks_daily_1;
END $$;


--
-- Name: snapshot_final_ticks_monthly_2(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.snapshot_final_ticks_monthly_2() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	DELETE FROM seawater_final_ticks_monthly_2;
	INSERT INTO seawater_final_ticks_daily_2 SELECT * FROM seawater_final_ticks_monthly_1;
END $$;


--
-- Name: snapshot_final_ticks_monthly_3(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.snapshot_final_ticks_monthly_3() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	DELETE FROM seawater_final_ticks_monthly_3;
	INSERT INTO seawater_final_ticks_monthly_3 SELECT * FROM seawater_final_ticks_monthly_1;
END $$;


--
-- Name: snapshot_latest_ticks_1(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.snapshot_latest_ticks_1() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	DELETE FROM seawater_latest_ticks_2;
	INSERT INTO seawater_latest_ticks_2 SELECT * FROM seawater_latest_ticks_1;
END $$;


--
-- Name: snapshot_liquidity_groups_1(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.snapshot_liquidity_groups_1() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	DELETE FROM seawater_liquidity_groups_2;
	INSERT INTO seawater_liquidity_groups_2 SELECT * FROM seawater_liquidity_groups_1;
END $$;


--
-- Name: snapshot_positions_latest_decimals_grouped_user_1_return; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.snapshot_positions_latest_decimals_grouped_user_1_return (
    pool public.address NOT NULL,
    decimals public.hugeint NOT NULL,
    cumulative_amount0 public.hugeint NOT NULL,
    cumulative_amount1 public.hugeint NOT NULL
);


--
-- Name: snapshot_positions_latest_decimals_grouped_user_1(public.address); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.snapshot_positions_latest_decimals_grouped_user_1(wallet public.address) RETURNS SETOF public.snapshot_positions_latest_decimals_grouped_user_1_return
    LANGUAGE sql STABLE
    AS $$
SELECT
	pool,
	decimals,
	SUM(amount0) AS cumulative_amount0,
	SUM(amount1) AS cumulative_amount1
FROM
	snapshot_positions_latest_decimals_1
WHERE owner = wallet
GROUP BY
	pool,
	decimals;
$$;


--
-- Name: snapshot_seawater_active_positions(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.snapshot_seawater_active_positions() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	DELETE FROM seawater_active_positions_2;
	INSERT INTO seawater_active_positions_2 SELECT * FROM seawater_active_positions_1;
END $$;


--
-- Name: snapshot_seawater_active_positions_2(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.snapshot_seawater_active_positions_2() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	DELETE FROM seawater_active_positions_6;
	INSERT INTO seawater_active_positions_6
	SELECT *
	FROM seawater_positions_5
	WHERE pos_id NOT IN (
		SELECT pos_id FROM events_seawater_burnPosition
	);
END $$;


--
-- Name: snitch_insert_fact_1(uuid, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.snitch_insert_fact_1(tag_ uuid, key_ character varying, value_ character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO snitch_facts_1(tag, key, value)
	VALUES (tag_, key_, value_)
	ON CONFLICT DO NOTHING;
END;
$$;


--
-- Name: snitch_report_tag_3(character varying, public.address, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.snitch_report_tag_3(prop character varying, addr public.address, tag_uuid uuid) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
DECLARE
	resulting_tag UUID;
    resulting_addr ADDRESS;
BEGIN
	SELECT tag, address INTO resulting_tag, resulting_addr FROM snitch_tags_1 WHERE property = prop AND tag = tag_uuid LIMIT  1;
	IF resulting_tag IS NULL THEN
		INSERT INTO snitch_tags_1(property, address, tag)
		VALUES (
			prop,
			addr,
			COALESCE(tag_uuid, uuid_generate_v4())
		)
		RETURNING tag INTO resulting_tag;
        ELSIF resulting_tag IS NOT NULL AND resulting_addr IS NULL AND addr IS NOT NULL THEN
		UPDATE snitch_tags_1
		SET address = addr
		WHERE property = prop AND tag = tag_uuid;
	END IF;

	RETURN resulting_tag;
END;
$$;


--
-- Name: snitch_report_tag_4(character varying, public.address, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.snitch_report_tag_4(prop character varying, addr public.address, tag_uuid uuid) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
DECLARE
	resulting_tag UUID;
BEGIN
	SELECT tag INTO resulting_tag FROM snitch_tags_1 WHERE address = addr LIMIT 1;
	IF resulting_tag IS NULL THEN
		INSERT INTO snitch_tags_1(property, address, tag)
		VALUES (
			prop,
			addr,
			COALESCE(tag_uuid, uuid_generate_v4())
		)
		RETURNING tag INTO resulting_tag;
	END IF;

	RETURN resulting_tag;
END;
$$;


--
-- Name: stylus_insert_contract_1(text, text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.stylus_insert_contract_1(chain_id_ text, block_number_ text, block_hash_ text, transaction_hash_ text, contract_address_ text, code_hash_ text, module_hash_ text, data_fee_ text, version_ text) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO stylus_contracts_deployed_1(
		chain_id,
		block_number,
		block_hash,
		transaction_hash,
		contract_address,
		code_hash,
		module_hash,
		data_fee,
		version
	)
	VALUES (
		chain_id_::INTEGER,
		block_number_::HUGEINT,
		block_hash_::HASH,
		transaction_hash_::HASH,
		contract_address_::ADDRESS,
		code_hash_::BYTES32,
		module_hash_::BYTES32,
		data_fee_::HUGEINT,
		version_::INTEGER
	) ON CONFLICT (transaction_hash) DO NOTHING;
END;
$$;


--
-- Name: stylus_update_ingestor_checkpoint_1(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.stylus_update_ingestor_checkpoint_1(chain_id_ text, block_number_ text) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO stylus_ingestor_checkpointing_1(chain_id, block_number)
	VALUES (chain_id_::HUGEINT, block_number_::HUGEINT)
	ON CONFLICT (chain_id) DO UPDATE
	SET block_number = EXCLUDED.block_number,
	last_updated = CURRENT_TIMESTAMP;
END;
$$;


--
-- Name: swaps_decimals_group_1_return; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.swaps_decimals_group_1_return (
    pool public.address NOT NULL,
    decimals public.hugeint NOT NULL,
    cumulative_amount0 public.hugeint NOT NULL,
    cumulative_amount1 public.hugeint NOT NULL
);


--
-- Name: swaps_decimals_pool_group_1(public.address, public.hugeint, public.address); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.swaps_decimals_pool_group_1(fusdcaddress public.address, fusdcdecimals public.hugeint, pooladdress public.address) RETURNS SETOF public.swaps_decimals_group_1_return
    LANGUAGE sql STABLE
    AS $$
WITH swap_data AS (
	SELECT *
	FROM seawater_swaps_1(fusdcAddress, fusdcDecimals)
	WHERE
		token_in = poolAddress
		OR token_out = poolAddress
		OR token_in = fusdcAddress
		OR token_out = fusdcAddress
)
SELECT
	CASE
		WHEN token_in != fusdcAddress THEN token_in
		ELSE token_out
	END AS pool,
	CASE
		WHEN token_in != fusdcAddress THEN token_in_decimals
		ELSE token_out_decimals
	END AS decimals,
	SUM(CASE
		WHEN token_in = fusdcAddress THEN amount_in
		ELSE amount_out
	END) AS cumulative_amount0,
	SUM(CASE
		WHEN token_in != fusdcAddress THEN amount_in
		ELSE amount_out
	END) AS cumulative_amount1
FROM swap_data
GROUP BY
	CASE
		WHEN token_in != fusdcAddress THEN token_in
		ELSE token_out
	END,
	CASE
		WHEN token_in != fusdcAddress THEN token_in_decimals
		ELSE token_out_decimals
	END;
$$;


--
-- Name: swaps_decimals_user_group_1(public.address, public.hugeint, public.address); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.swaps_decimals_user_group_1(fusdcaddress public.address, fusdcdecimals public.hugeint, walletaddress public.address) RETURNS SETOF public.swaps_decimals_group_1_return
    LANGUAGE sql STABLE
    AS $$
WITH swap_data AS (
	SELECT *
	FROM seawater_swaps_1(fusdcAddress, fusdcDecimals)
	WHERE sender = walletAddress
)
SELECT
	CASE
		WHEN token_in != fusdcAddress THEN token_in
		ELSE token_out
	END AS pool,
	CASE
		WHEN token_in != fusdcAddress THEN token_in_decimals
		ELSE token_out_decimals
	END AS decimals,
	SUM(CASE
		WHEN token_in = fusdcAddress THEN amount_in
		ELSE amount_out
	END) AS cumulative_amount0,
	SUM(CASE
		WHEN token_in != fusdcAddress THEN amount_in
		ELSE amount_out
	END) AS cumulative_amount1
FROM swap_data
GROUP BY
	CASE
		WHEN token_in != fusdcAddress THEN token_in
		ELSE token_out
	END,
	CASE
		WHEN token_in != fusdcAddress THEN token_in_decimals
		ELSE token_out_decimals
	END;
$$;


--
-- Name: events_seawater_newpool; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events_seawater_newpool (
    id integer NOT NULL,
    created_by timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    token public.address NOT NULL,
    fee integer NOT NULL,
    decimals public.hugeint NOT NULL,
    tick_spacing integer NOT NULL
);


--
-- Name: events_seawater_swap1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events_seawater_swap1 (
    id integer NOT NULL,
    created_by timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    user_ public.address NOT NULL,
    pool public.address NOT NULL,
    zero_for_one boolean NOT NULL,
    amount0 public.hugeint NOT NULL,
    amount1 public.hugeint NOT NULL,
    final_tick bigint NOT NULL
);


--
-- Name: _direct_view_3; Type: VIEW; Schema: _timescaledb_internal; Owner: -
--

CREATE VIEW _timescaledb_internal._direct_view_3 AS
 SELECT public.time_bucket('01:00:00'::interval, events_seawater_swap1.created_by) AS hourly_interval,
    events_seawater_swap1.pool,
    (((1.0001 ^ avg(events_seawater_swap1.final_tick)) * (1000000)::numeric) / ((10)::numeric ^ (events_seawater_newpool.decimals)::numeric)) AS price,
    events_seawater_newpool.decimals
   FROM (public.events_seawater_swap1
     JOIN public.events_seawater_newpool ON (((events_seawater_newpool.token)::bpchar = (events_seawater_swap1.pool)::bpchar)))
  GROUP BY events_seawater_swap1.pool, (public.time_bucket('01:00:00'::interval, events_seawater_swap1.created_by)), events_seawater_newpool.decimals;


--
-- Name: _direct_view_4; Type: VIEW; Schema: _timescaledb_internal; Owner: -
--

CREATE VIEW _timescaledb_internal._direct_view_4 AS
 SELECT public.time_bucket('01:00:00'::interval, events_seawater_swap1.created_by) AS hourly_interval,
    events_seawater_swap1.pool,
    (((1.0001 ^ avg(events_seawater_swap1.final_tick)) / (1000000)::numeric) * ((10)::numeric ^ (events_seawater_newpool.decimals)::numeric)) AS price,
    events_seawater_newpool.decimals
   FROM (public.events_seawater_swap1
     JOIN public.events_seawater_newpool ON (((events_seawater_newpool.token)::bpchar = (events_seawater_swap1.pool)::bpchar)))
  GROUP BY events_seawater_swap1.pool, (public.time_bucket('01:00:00'::interval, events_seawater_swap1.created_by)), events_seawater_newpool.decimals;


--
-- Name: events_seawater_swap2; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events_seawater_swap2 (
    id integer NOT NULL,
    created_by timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    user_ public.address NOT NULL,
    from_ public.address NOT NULL,
    to_ public.address NOT NULL,
    amount_in public.hugeint NOT NULL,
    amount_out public.hugeint NOT NULL,
    fluid_volume public.hugeint NOT NULL,
    final_tick0 bigint NOT NULL,
    final_tick1 bigint NOT NULL
);


--
-- Name: _hyper_1_10_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_10_chunk (
    CONSTRAINT constraint_10 CHECK (((created_by >= '2025-01-16 00:00:00+00'::timestamp with time zone) AND (created_by < '2025-01-23 00:00:00+00'::timestamp with time zone)))
)
INHERITS (public.events_seawater_swap2);


--
-- Name: _hyper_1_12_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_12_chunk (
    CONSTRAINT constraint_12 CHECK (((created_by >= '2025-01-23 00:00:00+00'::timestamp with time zone) AND (created_by < '2025-01-30 00:00:00+00'::timestamp with time zone)))
)
INHERITS (public.events_seawater_swap2);


--
-- Name: _hyper_1_14_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_14_chunk (
    CONSTRAINT constraint_14 CHECK (((created_by >= '2025-01-30 00:00:00+00'::timestamp with time zone) AND (created_by < '2025-02-06 00:00:00+00'::timestamp with time zone)))
)
INHERITS (public.events_seawater_swap2);


--
-- Name: _hyper_1_8_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_1_8_chunk (
    CONSTRAINT constraint_8 CHECK (((created_by >= '2025-01-09 00:00:00+00'::timestamp with time zone) AND (created_by < '2025-01-16 00:00:00+00'::timestamp with time zone)))
)
INHERITS (public.events_seawater_swap2);


--
-- Name: _hyper_2_11_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_2_11_chunk (
    CONSTRAINT constraint_11 CHECK (((created_by >= '2025-01-23 00:00:00+00'::timestamp with time zone) AND (created_by < '2025-01-30 00:00:00+00'::timestamp with time zone)))
)
INHERITS (public.events_seawater_swap1);


--
-- Name: _hyper_2_13_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_2_13_chunk (
    CONSTRAINT constraint_13 CHECK (((created_by >= '2025-01-30 00:00:00+00'::timestamp with time zone) AND (created_by < '2025-02-06 00:00:00+00'::timestamp with time zone)))
)
INHERITS (public.events_seawater_swap1);


--
-- Name: _hyper_2_1_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_2_1_chunk (
    CONSTRAINT constraint_1 CHECK (((created_by >= '2024-12-12 00:00:00+00'::timestamp with time zone) AND (created_by < '2024-12-19 00:00:00+00'::timestamp with time zone)))
)
INHERITS (public.events_seawater_swap1);


--
-- Name: _hyper_2_4_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_2_4_chunk (
    CONSTRAINT constraint_4 CHECK (((created_by >= '2024-12-19 00:00:00+00'::timestamp with time zone) AND (created_by < '2024-12-26 00:00:00+00'::timestamp with time zone)))
)
INHERITS (public.events_seawater_swap1);


--
-- Name: _hyper_2_5_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_2_5_chunk (
    CONSTRAINT constraint_5 CHECK (((created_by >= '2025-01-09 00:00:00+00'::timestamp with time zone) AND (created_by < '2025-01-16 00:00:00+00'::timestamp with time zone)))
)
INHERITS (public.events_seawater_swap1);


--
-- Name: _hyper_2_9_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_2_9_chunk (
    CONSTRAINT constraint_9 CHECK (((created_by >= '2025-01-16 00:00:00+00'::timestamp with time zone) AND (created_by < '2025-01-23 00:00:00+00'::timestamp with time zone)))
)
INHERITS (public.events_seawater_swap1);


--
-- Name: _materialized_hypertable_3; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._materialized_hypertable_3 (
    hourly_interval timestamp with time zone NOT NULL,
    pool public.address,
    price numeric,
    decimals public.hugeint
);


--
-- Name: _hyper_3_3_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_3_3_chunk (
    CONSTRAINT constraint_3 CHECK (((hourly_interval >= '2024-10-24 00:00:00+00'::timestamp with time zone) AND (hourly_interval < '2025-01-02 00:00:00+00'::timestamp with time zone)))
)
INHERITS (_timescaledb_internal._materialized_hypertable_3);


--
-- Name: _hyper_3_7_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_3_7_chunk (
    CONSTRAINT constraint_7 CHECK (((hourly_interval >= '2025-01-02 00:00:00+00'::timestamp with time zone) AND (hourly_interval < '2025-03-13 00:00:00+00'::timestamp with time zone)))
)
INHERITS (_timescaledb_internal._materialized_hypertable_3);


--
-- Name: _materialized_hypertable_4; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._materialized_hypertable_4 (
    hourly_interval timestamp with time zone NOT NULL,
    pool public.address,
    price numeric,
    decimals public.hugeint
);


--
-- Name: _hyper_4_2_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_4_2_chunk (
    CONSTRAINT constraint_2 CHECK (((hourly_interval >= '2024-10-24 00:00:00+00'::timestamp with time zone) AND (hourly_interval < '2025-01-02 00:00:00+00'::timestamp with time zone)))
)
INHERITS (_timescaledb_internal._materialized_hypertable_4);


--
-- Name: _hyper_4_6_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: -
--

CREATE TABLE _timescaledb_internal._hyper_4_6_chunk (
    CONSTRAINT constraint_6 CHECK (((hourly_interval >= '2025-01-02 00:00:00+00'::timestamp with time zone) AND (hourly_interval < '2025-03-13 00:00:00+00'::timestamp with time zone)))
)
INHERITS (_timescaledb_internal._materialized_hypertable_4);


--
-- Name: _partial_view_3; Type: VIEW; Schema: _timescaledb_internal; Owner: -
--

CREATE VIEW _timescaledb_internal._partial_view_3 AS
 SELECT public.time_bucket('01:00:00'::interval, events_seawater_swap1.created_by) AS hourly_interval,
    events_seawater_swap1.pool,
    (((1.0001 ^ avg(events_seawater_swap1.final_tick)) * (1000000)::numeric) / ((10)::numeric ^ (events_seawater_newpool.decimals)::numeric)) AS price,
    events_seawater_newpool.decimals
   FROM (public.events_seawater_swap1
     JOIN public.events_seawater_newpool ON (((events_seawater_newpool.token)::bpchar = (events_seawater_swap1.pool)::bpchar)))
  GROUP BY events_seawater_swap1.pool, (public.time_bucket('01:00:00'::interval, events_seawater_swap1.created_by)), events_seawater_newpool.decimals;


--
-- Name: _partial_view_4; Type: VIEW; Schema: _timescaledb_internal; Owner: -
--

CREATE VIEW _timescaledb_internal._partial_view_4 AS
 SELECT public.time_bucket('01:00:00'::interval, events_seawater_swap1.created_by) AS hourly_interval,
    events_seawater_swap1.pool,
    (((1.0001 ^ avg(events_seawater_swap1.final_tick)) / (1000000)::numeric) * ((10)::numeric ^ (events_seawater_newpool.decimals)::numeric)) AS price,
    events_seawater_newpool.decimals
   FROM (public.events_seawater_swap1
     JOIN public.events_seawater_newpool ON (((events_seawater_newpool.token)::bpchar = (events_seawater_swap1.pool)::bpchar)))
  GROUP BY events_seawater_swap1.pool, (public.time_bucket('01:00:00'::interval, events_seawater_swap1.created_by)), events_seawater_newpool.decimals;


--
-- Name: accounts_does_exist_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts_does_exist_1 (
    id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    eoa_addr public.address NOT NULL
);


--
-- Name: accounts_does_exist_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounts_does_exist_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts_does_exist_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounts_does_exist_1_id_seq OWNED BY public.accounts_does_exist_1.id;


--
-- Name: accounts_executed_transactions_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts_executed_transactions_1 (
    id integer NOT NULL,
    eoa_addr public.address NOT NULL,
    transaction_hash public.hash NOT NULL
);


--
-- Name: accounts_executed_transactions_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounts_executed_transactions_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts_executed_transactions_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounts_executed_transactions_1_id_seq OWNED BY public.accounts_executed_transactions_1.id;


--
-- Name: accounts_executed_transactions_2; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts_executed_transactions_2 (
    id integer NOT NULL,
    eoa_addr public.address NOT NULL,
    transaction_hash public.hash NOT NULL,
    gas_limit integer NOT NULL,
    desc_ character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: accounts_executed_transactions_2_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounts_executed_transactions_2_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts_executed_transactions_2_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounts_executed_transactions_2_id_seq OWNED BY public.accounts_executed_transactions_2.id;


--
-- Name: accounts_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: accounts_secrets_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts_secrets_1 (
    id integer NOT NULL,
    eoa_addr public.address NOT NULL,
    priv_key public.bytes32 NOT NULL,
    salt public.bytes16 NOT NULL,
    valid_until timestamp without time zone DEFAULT (CURRENT_TIMESTAMP + '1 mon'::interval) NOT NULL
);


--
-- Name: accounts_secrets_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounts_secrets_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts_secrets_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounts_secrets_1_id_seq OWNED BY public.accounts_secrets_1.id;


--
-- Name: accounts_secrets_nonces_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts_secrets_nonces_1 (
    id integer NOT NULL,
    secret_id integer NOT NULL,
    consumed_nonce integer NOT NULL
);


--
-- Name: accounts_secrets_nonces_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounts_secrets_nonces_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts_secrets_nonces_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounts_secrets_nonces_1_id_seq OWNED BY public.accounts_secrets_nonces_1.id;


--
-- Name: accounts_secrets_nonces_old_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts_secrets_nonces_old_1 (
    id integer NOT NULL,
    secret_id integer NOT NULL,
    consumed_nonce integer NOT NULL
);


--
-- Name: accounts_secrets_nonces_old_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounts_secrets_nonces_old_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts_secrets_nonces_old_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounts_secrets_nonces_old_1_id_seq OWNED BY public.accounts_secrets_nonces_old_1.id;


--
-- Name: accounts_sender_keys_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts_sender_keys_1 (
    id integer NOT NULL,
    private_key public.bytes32 NOT NULL,
    last_accessed timestamp without time zone
);


--
-- Name: accounts_sender_keys_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounts_sender_keys_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts_sender_keys_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounts_sender_keys_1_id_seq OWNED BY public.accounts_sender_keys_1.id;


--
-- Name: accounts_transaction_statistics_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.accounts_transaction_statistics_1 AS
 SELECT desc_ AS action,
    avg(
        CASE
            WHEN (created_at >= (now() - '24:00:00'::interval)) THEN gas_limit
            ELSE NULL::integer
        END) AS avg_gas_limit_24_hours,
    avg(
        CASE
            WHEN (created_at >= (now() - '7 days'::interval)) THEN gas_limit
            ELSE NULL::integer
        END) AS avg_gas_limit_week,
    avg(gas_limit) AS avg_gas_limit_all_time,
    (count(
        CASE
            WHEN (created_at >= (now() - '24:00:00'::interval)) THEN 1
            ELSE NULL::integer
        END))::integer AS tx_24_hours,
    (count(
        CASE
            WHEN (created_at >= (now() - '7 days'::interval)) THEN 1
            ELSE NULL::integer
        END))::integer AS tx_week,
    (count(*))::integer AS tx_all_time
   FROM public.accounts_executed_transactions_2
  GROUP BY desc_;


--
-- Name: bozo_comments_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bozo_comments_1 (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    epoch integer NOT NULL,
    epoch_seq integer NOT NULL,
    content character varying NOT NULL,
    transaction_hash public.hash NOT NULL
);


--
-- Name: bozo_comments_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bozo_comments_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bozo_comments_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bozo_comments_1_id_seq OWNED BY public.bozo_comments_1.id;


--
-- Name: bozo_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bozo_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: camelot_events_algebra_swap; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.camelot_events_algebra_swap (
    id integer NOT NULL,
    created_by timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    sender public.address NOT NULL,
    recipient public.address NOT NULL,
    amount0 public.hugeint NOT NULL,
    amount1 public.hugeint NOT NULL,
    price public.hugeint NOT NULL,
    liquidity public.hugeint NOT NULL,
    tick public.hugeint NOT NULL,
    transaction_sender public.address
);


--
-- Name: camelot_events_algebra_swap_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.camelot_events_algebra_swap_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: camelot_events_algebra_swap_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.camelot_events_algebra_swap_id_seq OWNED BY public.camelot_events_algebra_swap.id;


--
-- Name: camelot_events_camelot_decreaseliquidity; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.camelot_events_camelot_decreaseliquidity (
    id integer NOT NULL,
    created_by timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    liquidity public.hugeint NOT NULL,
    amount0 public.hugeint NOT NULL,
    amount1 public.hugeint NOT NULL,
    pos_id public.hugeint NOT NULL
);


--
-- Name: camelot_events_camelot_decreaseliquidity_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.camelot_events_camelot_decreaseliquidity_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: camelot_events_camelot_decreaseliquidity_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.camelot_events_camelot_decreaseliquidity_id_seq OWNED BY public.camelot_events_camelot_decreaseliquidity.id;


--
-- Name: camelot_events_camelot_increaseliquidity; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.camelot_events_camelot_increaseliquidity (
    id integer NOT NULL,
    created_by timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    pool public.address NOT NULL,
    liquidity public.hugeint NOT NULL,
    actual_liquidity public.hugeint NOT NULL,
    amount0 public.hugeint NOT NULL,
    amount1 public.hugeint NOT NULL,
    pos_id public.hugeint NOT NULL
);


--
-- Name: camelot_events_camelot_increaseliquidity_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.camelot_events_camelot_increaseliquidity_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: camelot_events_camelot_increaseliquidity_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.camelot_events_camelot_increaseliquidity_id_seq OWNED BY public.camelot_events_camelot_increaseliquidity.id;


--
-- Name: camelot_events_camelot_swap; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.camelot_events_camelot_swap (
    id integer NOT NULL,
    created_by timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    sender public.address NOT NULL,
    amount0_in public.hugeint NOT NULL,
    amount1_in public.hugeint NOT NULL,
    amount0_out public.hugeint NOT NULL,
    amount1_out public.hugeint NOT NULL,
    to_ public.address NOT NULL
);


--
-- Name: camelot_events_camelot_swap_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.camelot_events_camelot_swap_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: camelot_events_camelot_swap_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.camelot_events_camelot_swap_id_seq OWNED BY public.camelot_events_camelot_swap.id;


--
-- Name: camelot_events_camelot_transferposition; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.camelot_events_camelot_transferposition (
    id integer NOT NULL,
    created_by timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    from_ public.address NOT NULL,
    to_ public.address NOT NULL,
    pos_id public.hugeint NOT NULL
);


--
-- Name: camelot_events_camelot_transferposition_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.camelot_events_camelot_transferposition_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: camelot_events_camelot_transferposition_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.camelot_events_camelot_transferposition_id_seq OWNED BY public.camelot_events_camelot_transferposition.id;


--
-- Name: camelot_ingestor_checkpointing_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.camelot_ingestor_checkpointing_1 (
    id integer NOT NULL,
    last_updated timestamp without time zone NOT NULL,
    block_number integer NOT NULL
);


--
-- Name: camelot_ingestor_checkpointing_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.camelot_ingestor_checkpointing_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: camelot_ingestor_checkpointing_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.camelot_ingestor_checkpointing_1_id_seq OWNED BY public.camelot_ingestor_checkpointing_1.id;


--
-- Name: camelot_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.camelot_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: cuntfuck_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cuntfuck_1 (
    id integer NOT NULL,
    last_updated timestamp without time zone NOT NULL,
    block_number integer NOT NULL
);


--
-- Name: cuntfuck_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cuntfuck_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cuntfuck_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cuntfuck_1_id_seq OWNED BY public.cuntfuck_1.id;


--
-- Name: dinero_events_ownership_transferred; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dinero_events_ownership_transferred (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    previous_owner public.address NOT NULL,
    new_owner public.address NOT NULL
);


--
-- Name: dinero_events_ownership_transferred_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dinero_events_ownership_transferred_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dinero_events_ownership_transferred_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dinero_events_ownership_transferred_id_seq OWNED BY public.dinero_events_ownership_transferred.id;


--
-- Name: discord_usernames_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.discord_usernames_1 (
    id integer NOT NULL,
    updated_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    discord character varying,
    address character varying NOT NULL,
    ip_address character varying NOT NULL
);


--
-- Name: discord_usernames_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.discord_usernames_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: discord_usernames_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.discord_usernames_1_id_seq OWNED BY public.discord_usernames_1.id;


--
-- Name: discord_usernames_2; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.discord_usernames_2 (
    id integer NOT NULL,
    updated_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    discord_snowflake character varying,
    discord_username character varying,
    address character varying NOT NULL,
    association_giver integer NOT NULL
);


--
-- Name: discord_usernames_2_association_giver_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.discord_usernames_2_association_giver_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: discord_usernames_2_association_giver_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.discord_usernames_2_association_giver_seq OWNED BY public.discord_usernames_2.association_giver;


--
-- Name: discord_usernames_2_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.discord_usernames_2_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: discord_usernames_2_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.discord_usernames_2_id_seq OWNED BY public.discord_usernames_2.id;


--
-- Name: emergency_current_reserves; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.emergency_current_reserves (
    pool public.address,
    value public.hugeint,
    decimals integer
);


--
-- Name: emergency_token_prices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.emergency_token_prices (
    pool public.address NOT NULL,
    value numeric NOT NULL
);


--
-- Name: erc20_cache_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.erc20_cache_1 (
    id integer NOT NULL,
    address public.address NOT NULL,
    name character varying NOT NULL,
    symbol character varying NOT NULL,
    total_supply public.hugeint NOT NULL,
    decimals integer NOT NULL
);


--
-- Name: erc20_cache_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.erc20_cache_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erc20_cache_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.erc20_cache_1_id_seq OWNED BY public.erc20_cache_1.id;


--
-- Name: events_erc20_transfer; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events_erc20_transfer (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    sender public.address NOT NULL,
    recipient public.address NOT NULL,
    value public.hugeint NOT NULL
);


--
-- Name: events_erc20_transfer_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.events_erc20_transfer_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_erc20_transfer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.events_erc20_transfer_id_seq OWNED BY public.events_erc20_transfer.id;


--
-- Name: events_leo_campaignbalanceupdated; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events_leo_campaignbalanceupdated (
    id integer NOT NULL,
    created_by timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    identifier character varying NOT NULL,
    new_maximum public.hugeint NOT NULL
);


--
-- Name: events_leo_campaignbalanceupdated_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.events_leo_campaignbalanceupdated_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_leo_campaignbalanceupdated_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.events_leo_campaignbalanceupdated_id_seq OWNED BY public.events_leo_campaignbalanceupdated.id;


--
-- Name: events_leo_campaigncreated; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events_leo_campaigncreated (
    id integer NOT NULL,
    created_by timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    identifier character varying NOT NULL,
    pool public.address NOT NULL,
    token public.address NOT NULL,
    tick_lower integer NOT NULL,
    tick_upper integer NOT NULL,
    owner public.address NOT NULL,
    starting timestamp without time zone,
    ending timestamp without time zone,
    per_second bigint NOT NULL
);


--
-- Name: events_leo_campaigncreated_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.events_leo_campaigncreated_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_leo_campaigncreated_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.events_leo_campaigncreated_id_seq OWNED BY public.events_leo_campaigncreated.id;


--
-- Name: events_leo_campaignupdated; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events_leo_campaignupdated (
    id integer NOT NULL,
    created_by timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    identifier character varying NOT NULL,
    pool public.address NOT NULL,
    per_second public.hugeint NOT NULL,
    tick_lower integer NOT NULL,
    tick_upper integer NOT NULL,
    starting timestamp without time zone,
    ending timestamp without time zone
);


--
-- Name: events_leo_campaignupdated_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.events_leo_campaignupdated_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_leo_campaignupdated_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.events_leo_campaignupdated_id_seq OWNED BY public.events_leo_campaignupdated.id;


--
-- Name: events_leo_positiondivested; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events_leo_positiondivested (
    id integer NOT NULL,
    created_by timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    position_id public.hugeint NOT NULL
);


--
-- Name: events_leo_positiondivested2; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events_leo_positiondivested2 (
    id integer NOT NULL,
    created_by timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    position_id public.hugeint NOT NULL,
    recipient public.address NOT NULL
);


--
-- Name: events_leo_positiondivested2_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.events_leo_positiondivested2_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_leo_positiondivested2_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.events_leo_positiondivested2_id_seq OWNED BY public.events_leo_positiondivested2.id;


--
-- Name: events_leo_positiondivested_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.events_leo_positiondivested_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_leo_positiondivested_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.events_leo_positiondivested_id_seq OWNED BY public.events_leo_positiondivested.id;


--
-- Name: events_leo_positionvested; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events_leo_positionvested (
    id integer NOT NULL,
    created_by timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    position_id public.hugeint NOT NULL
);


--
-- Name: events_leo_positionvested2; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events_leo_positionvested2 (
    id integer NOT NULL,
    created_by timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    position_id public.hugeint NOT NULL,
    owner public.address NOT NULL
);


--
-- Name: events_leo_positionvested2_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.events_leo_positionvested2_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_leo_positionvested2_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.events_leo_positionvested2_id_seq OWNED BY public.events_leo_positionvested2.id;


--
-- Name: events_leo_positionvested_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.events_leo_positionvested_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_leo_positionvested_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.events_leo_positionvested_id_seq OWNED BY public.events_leo_positionvested.id;


--
-- Name: events_ninelives_stargate_bridged; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events_ninelives_stargate_bridged (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    guid public.bytes32 NOT NULL,
    spender public.address NOT NULL,
    amount_received public.hugeint NOT NULL,
    amount_fee public.hugeint NOT NULL,
    destination_eid integer NOT NULL
);


--
-- Name: events_ninelives_stargate_bridged_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.events_ninelives_stargate_bridged_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_ninelives_stargate_bridged_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.events_ninelives_stargate_bridged_id_seq OWNED BY public.events_ninelives_stargate_bridged.id;


--
-- Name: events_purrstream_donated; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events_purrstream_donated (
    id integer NOT NULL,
    created_by timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    cat public.bytes8_0x NOT NULL,
    address public.address NOT NULL,
    amount public.hugeint NOT NULL
);


--
-- Name: events_purrstream_donated_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.events_purrstream_donated_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_purrstream_donated_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.events_purrstream_donated_id_seq OWNED BY public.events_purrstream_donated.id;


--
-- Name: events_seawater_burnposition; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events_seawater_burnposition (
    id integer NOT NULL,
    created_by timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    pos_id public.hugeint NOT NULL,
    owner public.address NOT NULL
);


--
-- Name: events_seawater_burnposition_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.events_seawater_burnposition_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_seawater_burnposition_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.events_seawater_burnposition_id_seq OWNED BY public.events_seawater_burnposition.id;


--
-- Name: events_seawater_collectfees; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events_seawater_collectfees (
    id integer NOT NULL,
    created_by timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    pos_id public.hugeint NOT NULL,
    pool public.address NOT NULL,
    to_ public.address NOT NULL,
    amount0 public.hugeint NOT NULL,
    amount1 public.hugeint NOT NULL
);


--
-- Name: events_seawater_collectfees_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.events_seawater_collectfees_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_seawater_collectfees_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.events_seawater_collectfees_id_seq OWNED BY public.events_seawater_collectfees.id;


--
-- Name: events_seawater_collectprotocolfees; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events_seawater_collectprotocolfees (
    id integer NOT NULL,
    created_by timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    pool public.address NOT NULL,
    to_ public.address NOT NULL,
    amount0 public.hugeint NOT NULL,
    amount1 public.hugeint NOT NULL
);


--
-- Name: events_seawater_collectprotocolfees_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.events_seawater_collectprotocolfees_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_seawater_collectprotocolfees_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.events_seawater_collectprotocolfees_id_seq OWNED BY public.events_seawater_collectprotocolfees.id;


--
-- Name: events_seawater_mintposition; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events_seawater_mintposition (
    id integer NOT NULL,
    created_by timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    pos_id public.hugeint NOT NULL,
    owner public.address NOT NULL,
    pool public.address NOT NULL,
    lower bigint NOT NULL,
    upper bigint NOT NULL
);


--
-- Name: events_seawater_mintposition_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.events_seawater_mintposition_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_seawater_mintposition_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.events_seawater_mintposition_id_seq OWNED BY public.events_seawater_mintposition.id;


--
-- Name: events_seawater_newpool_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.events_seawater_newpool_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_seawater_newpool_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.events_seawater_newpool_id_seq OWNED BY public.events_seawater_newpool.id;


--
-- Name: events_seawater_swap1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.events_seawater_swap1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_seawater_swap1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.events_seawater_swap1_id_seq OWNED BY public.events_seawater_swap1.id;


--
-- Name: events_seawater_swap2_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.events_seawater_swap2_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_seawater_swap2_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.events_seawater_swap2_id_seq OWNED BY public.events_seawater_swap2.id;


--
-- Name: events_seawater_transferposition; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events_seawater_transferposition (
    id integer NOT NULL,
    created_by timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    from_ public.address NOT NULL,
    to_ public.address NOT NULL,
    pos_id public.hugeint NOT NULL
);


--
-- Name: events_seawater_transferposition_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.events_seawater_transferposition_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_seawater_transferposition_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.events_seawater_transferposition_id_seq OWNED BY public.events_seawater_transferposition.id;


--
-- Name: events_seawater_updatepositionliquidity; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events_seawater_updatepositionliquidity (
    id integer NOT NULL,
    created_by timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    pos_id public.hugeint NOT NULL,
    token0 public.hugeint NOT NULL,
    token1 public.hugeint NOT NULL
);


--
-- Name: events_seawater_updatepositionliquidity_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.events_seawater_updatepositionliquidity_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_seawater_updatepositionliquidity_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.events_seawater_updatepositionliquidity_id_seq OWNED BY public.events_seawater_updatepositionliquidity.id;


--
-- Name: events_thirdweb_accountcreated; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events_thirdweb_accountcreated (
    id integer NOT NULL,
    created_by timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    account public.address NOT NULL,
    account_admin public.address NOT NULL
);


--
-- Name: events_thirdweb_accountcreated_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.events_thirdweb_accountcreated_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_thirdweb_accountcreated_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.events_thirdweb_accountcreated_id_seq OWNED BY public.events_thirdweb_accountcreated.id;


--
-- Name: faucet_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.faucet_requests (
    id integer NOT NULL,
    addr public.address NOT NULL,
    ip_addr character varying NOT NULL,
    created_by timestamp without time zone NOT NULL,
    updated_by timestamp without time zone NOT NULL,
    was_sent boolean DEFAULT false NOT NULL,
    is_fly_staker boolean DEFAULT false NOT NULL
);


--
-- Name: faucet_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.faucet_requests_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: faucet_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.faucet_requests_id_seq OWNED BY public.faucet_requests.id;


--
-- Name: fly_stakers_fly_staked_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fly_stakers_fly_staked_1 (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    spender public.address NOT NULL,
    amount public.hugeint NOT NULL,
    position_made timestamp without time zone NOT NULL
);


--
-- Name: fly_stakers_fly_staked_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fly_stakers_fly_staked_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fly_stakers_fly_staked_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.fly_stakers_fly_staked_1_id_seq OWNED BY public.fly_stakers_fly_staked_1.id;


--
-- Name: fly_stakers_fly_unstaked_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fly_stakers_fly_unstaked_1 (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    spender public.address NOT NULL,
    amount public.hugeint NOT NULL,
    position_closed timestamp without time zone NOT NULL
);


--
-- Name: fly_stakers_fly_unstaked_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fly_stakers_fly_unstaked_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fly_stakers_fly_unstaked_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.fly_stakers_fly_unstaked_1_id_seq OWNED BY public.fly_stakers_fly_unstaked_1.id;


--
-- Name: fly_stakers_ingestor_checkpointing_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fly_stakers_ingestor_checkpointing_1 (
    id integer NOT NULL,
    last_updated timestamp without time zone NOT NULL,
    block_number integer NOT NULL
);


--
-- Name: fly_stakers_ingestor_checkpointing_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fly_stakers_ingestor_checkpointing_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fly_stakers_ingestor_checkpointing_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.fly_stakers_ingestor_checkpointing_1_id_seq OWNED BY public.fly_stakers_ingestor_checkpointing_1.id;


--
-- Name: fly_stakers_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fly_stakers_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: ingestor_checkpointing_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ingestor_checkpointing_1 (
    id integer NOT NULL,
    last_updated timestamp without time zone NOT NULL,
    block_number integer NOT NULL
);


--
-- Name: ingestor_checkpointing_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ingestor_checkpointing_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ingestor_checkpointing_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ingestor_checkpointing_1_id_seq OWNED BY public.ingestor_checkpointing_1.id;


--
-- Name: layerzero_events_packet_burnt; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.layerzero_events_packet_burnt (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    src_eid integer NOT NULL,
    sender public.address NOT NULL,
    receiver public.address NOT NULL,
    nonce bigint NOT NULL,
    payload_hash public.bytes32 NOT NULL
);


--
-- Name: layerzero_events_packet_burnt_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.layerzero_events_packet_burnt_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: layerzero_events_packet_burnt_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.layerzero_events_packet_burnt_id_seq OWNED BY public.layerzero_events_packet_burnt.id;


--
-- Name: layerzero_events_packet_delivered; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.layerzero_events_packet_delivered (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    origin_src_eid integer NOT NULL,
    origin_sender public.bytes32 NOT NULL,
    origin_nonce bigint NOT NULL,
    receiver public.address NOT NULL
);


--
-- Name: layerzero_events_packet_delivered_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.layerzero_events_packet_delivered_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: layerzero_events_packet_delivered_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.layerzero_events_packet_delivered_id_seq OWNED BY public.layerzero_events_packet_delivered.id;


--
-- Name: layerzero_events_packet_nilified; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.layerzero_events_packet_nilified (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    src_eid integer NOT NULL,
    sender public.bytes32 NOT NULL,
    receiver public.address NOT NULL,
    nonce bigint NOT NULL,
    payload_hash public.bytes32 NOT NULL
);


--
-- Name: layerzero_events_packet_nilified_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.layerzero_events_packet_nilified_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: layerzero_events_packet_nilified_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.layerzero_events_packet_nilified_id_seq OWNED BY public.layerzero_events_packet_nilified.id;


--
-- Name: layerzero_events_packet_sent; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.layerzero_events_packet_sent (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    encoded_payload public.bytes NOT NULL,
    options public.bytes NOT NULL,
    send_library public.address NOT NULL
);


--
-- Name: layerzero_events_packet_sent_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.layerzero_events_packet_sent_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: layerzero_events_packet_sent_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.layerzero_events_packet_sent_id_seq OWNED BY public.layerzero_events_packet_sent.id;


--
-- Name: layerzero_events_packet_verified; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.layerzero_events_packet_verified (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    origin_src_eid integer NOT NULL,
    origin_sender public.bytes32 NOT NULL,
    origin_nonce bigint NOT NULL,
    receiver public.address NOT NULL,
    payload_hash public.bytes32 NOT NULL
);


--
-- Name: layerzero_events_packet_verified_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.layerzero_events_packet_verified_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: layerzero_events_packet_verified_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.layerzero_events_packet_verified_id_seq OWNED BY public.layerzero_events_packet_verified.id;


--
-- Name: leo_campaigns_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.leo_campaigns_1 AS
 SELECT events_leo_campaigncreated.pool,
    events_leo_campaigncreated.token,
    COALESCE(updated.tick_lower, events_leo_campaigncreated.tick_lower) AS tick_lower,
    COALESCE(updated.tick_upper, events_leo_campaigncreated.tick_upper) AS tick_upper,
    events_leo_campaigncreated.owner,
    COALESCE(updated.starting, events_leo_campaigncreated.starting) AS starting,
    COALESCE(updated.ending, events_leo_campaigncreated.ending) AS ending,
    events_leo_campaigncreated.identifier,
    COALESCE((balanceupdated.new_maximum)::numeric, (0)::numeric) AS maximum_amount,
    COALESCE((updated.per_second)::numeric, (events_leo_campaigncreated.per_second)::numeric) AS per_second
   FROM ((public.events_leo_campaigncreated
     LEFT JOIN ( SELECT DISTINCT ON (events_leo_campaignbalanceupdated.identifier) events_leo_campaignbalanceupdated.identifier,
            events_leo_campaignbalanceupdated.new_maximum
           FROM public.events_leo_campaignbalanceupdated
          ORDER BY events_leo_campaignbalanceupdated.identifier, events_leo_campaignbalanceupdated.created_by DESC) balanceupdated ON (((events_leo_campaigncreated.identifier)::text = (balanceupdated.identifier)::text)))
     LEFT JOIN ( SELECT DISTINCT ON (events_leo_campaignupdated.identifier) events_leo_campaignupdated.identifier,
            events_leo_campaignupdated.tick_lower,
            events_leo_campaignupdated.tick_upper,
            events_leo_campaignupdated.starting,
            events_leo_campaignupdated.ending,
            events_leo_campaignupdated.per_second
           FROM public.events_leo_campaignupdated
          ORDER BY events_leo_campaignupdated.identifier, events_leo_campaignupdated.created_by DESC) updated ON (((events_leo_campaigncreated.identifier)::text = (updated.identifier)::text)));


--
-- Name: leo_active_campaigns_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.leo_active_campaigns_1 AS
 SELECT pool,
    token,
    tick_lower,
    tick_upper,
    owner,
    starting,
    ending,
    identifier,
    maximum_amount,
    per_second
   FROM public.leo_campaigns_1
  WHERE ((starting <= now()) AND (ending >= now()));


--
-- Name: leo_upcoming_campaigns_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.leo_upcoming_campaigns_1 AS
 SELECT pool,
    token,
    tick_lower,
    tick_upper,
    owner,
    starting,
    ending,
    identifier,
    maximum_amount,
    per_second
   FROM public.leo_campaigns_1
  WHERE (starting > now());


--
-- Name: lifi_events_generic_swap_completed; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lifi_events_generic_swap_completed (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    transaction_id public.bytes32 NOT NULL,
    integrator character varying(100) NOT NULL,
    referrer character varying(100) NOT NULL,
    receiver public.address NOT NULL,
    from_asset_id public.address NOT NULL,
    to_asset_id public.address NOT NULL,
    from_amount public.hugeint NOT NULL,
    to_amount public.hugeint NOT NULL
);


--
-- Name: lifi_events_generic_swap_completed_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lifi_events_generic_swap_completed_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lifi_events_generic_swap_completed_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lifi_events_generic_swap_completed_id_seq OWNED BY public.lifi_events_generic_swap_completed.id;


--
-- Name: points_swaps_consolidated_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_swaps_consolidated_1 AS
 SELECT s.id,
    s.created_by,
    s.block_hash,
    s.transaction_hash,
    s.block_number,
    s.emitter_addr,
    s.user_,
    s.from_,
    s.to_,
    s.amount_in,
    s.amount_out,
    s.fluid_volume,
    s.final_tick0,
    s.final_tick1,
    f.decimals AS from_decimals,
    t.decimals AS to_decimals
   FROM ((( SELECT events_seawater_swap1.id,
            events_seawater_swap1.created_by,
            events_seawater_swap1.block_hash,
            events_seawater_swap1.transaction_hash,
            events_seawater_swap1.block_number,
            events_seawater_swap1.emitter_addr,
            events_seawater_swap1.user_,
                CASE
                    WHEN (NOT events_seawater_swap1.zero_for_one) THEN '0xa8ea92c819463efbeddfb670fefc881a480f0115'::bpchar
                    ELSE (events_seawater_swap1.pool)::bpchar
                END AS from_,
                CASE
                    WHEN (NOT events_seawater_swap1.zero_for_one) THEN (events_seawater_swap1.pool)::bpchar
                    ELSE '0xa8ea92c819463efbeddfb670fefc881a480f0115'::bpchar
                END AS to_,
            events_seawater_swap1.amount0 AS amount_in,
            events_seawater_swap1.amount1 AS amount_out,
            (NULL::numeric)::public.hugeint AS fluid_volume,
            events_seawater_swap1.final_tick AS final_tick0,
            NULL::bigint AS final_tick1
           FROM public.events_seawater_swap1
        UNION ALL
         SELECT events_seawater_swap2.id,
            events_seawater_swap2.created_by,
            events_seawater_swap2.block_hash,
            events_seawater_swap2.transaction_hash,
            events_seawater_swap2.block_number,
            events_seawater_swap2.emitter_addr,
            events_seawater_swap2.user_,
            events_seawater_swap2.from_,
            events_seawater_swap2.to_,
            events_seawater_swap2.amount_in,
            events_seawater_swap2.amount_out,
            events_seawater_swap2.fluid_volume,
            events_seawater_swap2.final_tick0,
            events_seawater_swap2.final_tick1
           FROM public.events_seawater_swap2) s
     LEFT JOIN public.erc20_cache_1 f ON ((s.from_ = (f.address)::bpchar)))
     LEFT JOIN public.erc20_cache_1 t ON ((s.to_ = (t.address)::bpchar)));


--
-- Name: longtail_swaps_user_totals_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.longtail_swaps_user_totals_1 AS
 WITH user_totals AS (
         SELECT points_swaps_consolidated_1.user_,
            (sum((points_swaps_consolidated_1.amount_out)::numeric) / (1000000)::numeric) AS total_amount_out
           FROM public.points_swaps_consolidated_1
          WHERE ((points_swaps_consolidated_1.from_ = '0x3f1Eae7D46d88F08fc2F8ed27FCb2AB183EB2d0E'::bpchar) OR (points_swaps_consolidated_1.to_ = '0x3f1Eae7D46d88F08fc2F8ed27FCb2AB183EB2d0E'::bpchar))
          GROUP BY points_swaps_consolidated_1.user_
        ), total_sum AS (
         SELECT sum(user_totals_1.total_amount_out) AS grand_total
           FROM user_totals user_totals_1
        )
 SELECT user_totals.user_,
    user_totals.total_amount_out,
    round(((user_totals.total_amount_out / total_sum.grand_total) * (5800000)::numeric), 2) AS points_earned
   FROM (user_totals
     CROSS JOIN total_sum)
  ORDER BY (round(((user_totals.total_amount_out / total_sum.grand_total) * (5800000)::numeric), 2)) DESC;


--
-- Name: nfts_cached_not_nft_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nfts_cached_not_nft_1 (
    id integer NOT NULL,
    contract public.address NOT NULL,
    was_nft boolean NOT NULL
);


--
-- Name: nfts_cache_not_tracked_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.nfts_cache_not_tracked_1 AS
 SELECT et.emitter_addr AS pool_address,
    max((et.value)::numeric) AS id
   FROM (public.events_erc20_transfer et
     LEFT JOIN public.nfts_cached_not_nft_1 ncn ON (((et.emitter_addr)::bpchar = (ncn.contract)::bpchar)))
  WHERE (ncn.contract IS NULL)
  GROUP BY et.emitter_addr;


--
-- Name: nfts_cached_lookup_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nfts_cached_lookup_1 (
    id integer NOT NULL,
    created_by timestamp without time zone NOT NULL,
    contract public.address NOT NULL,
    erc20_name character varying NOT NULL,
    erc20_decimals integer NOT NULL,
    erc20_symbol character varying NOT NULL
);


--
-- Name: nfts_cached_lookup_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.nfts_cached_lookup_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nfts_cached_lookup_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.nfts_cached_lookup_1_id_seq OWNED BY public.nfts_cached_lookup_1.id;


--
-- Name: nfts_cached_not_nft_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.nfts_cached_not_nft_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nfts_cached_not_nft_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.nfts_cached_not_nft_1_id_seq OWNED BY public.nfts_cached_not_nft_1.id;


--
-- Name: nfts_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nfts_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: nfts_user_owned_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.nfts_user_owned_1 AS
 SELECT received.recipient AS user_address,
    received.value AS token_amount,
    received.emitter_addr AS token_address,
    nc.erc20_name AS token_name,
    nc.erc20_symbol AS token_symbol,
    nc.erc20_decimals AS decimals
   FROM (((public.events_erc20_transfer received
     LEFT JOIN public.events_erc20_transfer sent ON ((((received.recipient)::bpchar = (sent.sender)::bpchar) AND ((received.value)::numeric = (sent.value)::numeric) AND ((received.emitter_addr)::bpchar = (sent.emitter_addr)::bpchar))))
     LEFT JOIN public.nfts_cached_lookup_1 nc ON (((nc.contract)::bpchar = (received.emitter_addr)::bpchar)))
     LEFT JOIN public.nfts_cached_not_nft_1 nn ON ((((nn.contract)::bpchar = (received.emitter_addr)::bpchar) AND (nn.was_nft = true))))
  WHERE ((sent.id IS NULL) AND (nn.contract IS NOT NULL));


--
-- Name: nfts_user_owned_2; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.nfts_user_owned_2 AS
 SELECT received.recipient AS user_address,
    received.value AS token_amount,
    received.emitter_addr AS token_address,
    nc.erc20_name AS token_name,
    nc.erc20_symbol AS token_symbol,
    nc.erc20_decimals AS decimals
   FROM (((public.events_erc20_transfer received
     LEFT JOIN public.events_erc20_transfer sent ON ((((received.recipient)::bpchar = (sent.sender)::bpchar) AND ((received.emitter_addr)::bpchar = (sent.emitter_addr)::bpchar) AND ((received.value)::numeric = (sent.value)::numeric) AND (sent.created_by > received.created_by))))
     LEFT JOIN public.nfts_cached_lookup_1 nc ON (((nc.contract)::bpchar = (received.emitter_addr)::bpchar)))
     LEFT JOIN public.nfts_cached_not_nft_1 nn ON ((((nn.contract)::bpchar = (received.emitter_addr)::bpchar) AND (nn.was_nft = true))))
  WHERE ((sent.id IS NULL) AND (nn.contract IS NULL) AND (nc.contract IS NOT NULL));


--
-- Name: nfts_user_owned_3; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.nfts_user_owned_3 AS
 SELECT received.recipient AS user_address,
    received.value AS token_amount,
    received.emitter_addr AS token_address,
    nc.erc20_name AS token_name,
    nc.erc20_symbol AS token_symbol,
    nc.erc20_decimals AS decimals
   FROM (public.events_erc20_transfer received
     LEFT JOIN public.nfts_cached_lookup_1 nc ON (((nc.contract)::bpchar = (received.emitter_addr)::bpchar)))
  WHERE ((nc.erc20_decimals = 0) AND (nc.contract IS NOT NULL) AND (NOT (EXISTS ( SELECT 1
           FROM public.events_erc20_transfer sent
          WHERE (((sent.sender)::bpchar = (received.recipient)::bpchar) AND ((sent.emitter_addr)::bpchar = (received.emitter_addr)::bpchar) AND ((sent.value)::numeric = (received.value)::numeric) AND (sent.created_by > received.created_by))))));


--
-- Name: ninelives_all_earned_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_all_earned_1 (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    emitter_addr public.address NOT NULL,
    recipient public.address NOT NULL,
    fusdc_received public.hugeint
);


--
-- Name: ninelives_all_earned_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_all_earned_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_all_earned_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_all_earned_1_id_seq OWNED BY public.ninelives_all_earned_1.id;


--
-- Name: ninelives_banners_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_banners_1 (
    id integer NOT NULL,
    pool public.address NOT NULL,
    message text NOT NULL
);


--
-- Name: ninelives_banners_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_banners_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_banners_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_banners_1_id_seq OWNED BY public.ninelives_banners_1.id;


--
-- Name: ninelives_buys_and_sells_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_buys_and_sells_1 (
    transaction_hash public.hash NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    from_amount public.hugeint NOT NULL,
    from_symbol character varying(30) NOT NULL,
    to_amount public.hugeint NOT NULL,
    to_symbol character varying(30) NOT NULL,
    type character varying(4) NOT NULL,
    spender public.address NOT NULL,
    recipient public.address NOT NULL,
    total_volume public.hugeint DEFAULT 0 NOT NULL,
    outcome_id public.bytes8 NOT NULL,
    campaign_id text,
    campaign_content jsonb,
    shown boolean DEFAULT true,
    id integer NOT NULL,
    CONSTRAINT ninelives_buys_and_sells_1_type_check CHECK (((type)::text = ANY ((ARRAY['buy'::character varying, 'sell'::character varying])::text[])))
);

ALTER TABLE ONLY public.ninelives_buys_and_sells_1 REPLICA IDENTITY FULL;


--
-- Name: ninelives_buys_and_sells_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_buys_and_sells_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_buys_and_sells_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_buys_and_sells_1_id_seq OWNED BY public.ninelives_buys_and_sells_1.id;


--
-- Name: ninelives_campaigns_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_campaigns_1 (
    id text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    content jsonb NOT NULL,
    name_to_search text GENERATED ALWAYS AS ((content ->> 'name'::text)) STORED,
    shown boolean DEFAULT true,
    total_volume public.hugeint DEFAULT 0 NOT NULL
);

ALTER TABLE ONLY public.ninelives_campaigns_1 REPLICA IDENTITY FULL;


--
-- Name: ninelives_campaigns_categories_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_campaigns_categories_1 (
    campaign_id text NOT NULL,
    category_id integer NOT NULL
);


--
-- Name: ninelives_categories_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_categories_1 (
    id integer NOT NULL,
    name text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ninelives_categories_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_categories_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_categories_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_categories_1_id_seq OWNED BY public.ninelives_categories_1.id;


--
-- Name: ninelives_comments_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_comments_1 (
    id integer NOT NULL,
    campaign_id text NOT NULL,
    wallet_address public.address NOT NULL,
    content text NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT ninelives_comments_1_content_check CHECK ((char_length(content) <= 2000))
);

ALTER TABLE ONLY public.ninelives_comments_1 REPLICA IDENTITY FULL;


--
-- Name: ninelives_comments_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_comments_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_comments_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_comments_1_id_seq OWNED BY public.ninelives_comments_1.id;


--
-- Name: ninelives_events_address_fees_claimed; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_events_address_fees_claimed (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    recipient public.address NOT NULL,
    amount public.hugeint NOT NULL
);


--
-- Name: ninelives_events_address_fees_claimed_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_events_address_fees_claimed_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_events_address_fees_claimed_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_events_address_fees_claimed_id_seq OWNED BY public.ninelives_events_address_fees_claimed.id;


--
-- Name: ninelives_events_amm_details; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_events_amm_details (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    product public.hugeint NOT NULL,
    shares jsonb NOT NULL
);


--
-- Name: ninelives_events_amm_details_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_events_amm_details_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_events_amm_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_events_amm_details_id_seq OWNED BY public.ninelives_events_amm_details.id;


--
-- Name: ninelives_events_call_made; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_events_call_made (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    trading_addr public.address NOT NULL,
    winner public.bytes8 NOT NULL,
    incentive_recipient public.address NOT NULL
);


--
-- Name: ninelives_events_call_made_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_events_call_made_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_events_call_made_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_events_call_made_id_seq OWNED BY public.ninelives_events_call_made.id;


--
-- Name: ninelives_events_campaign_escaped; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_events_campaign_escaped (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    trading_addr public.address NOT NULL
);


--
-- Name: ninelives_events_campaign_escaped_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_events_campaign_escaped_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_events_campaign_escaped_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_events_campaign_escaped_id_seq OWNED BY public.ninelives_events_campaign_escaped.id;


--
-- Name: ninelives_events_commitment_revealed; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_events_commitment_revealed (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    trading public.address NOT NULL,
    revealer public.address NOT NULL,
    outcome public.bytes32 NOT NULL,
    caller public.address NOT NULL,
    bal public.hugeint NOT NULL
);


--
-- Name: ninelives_events_commitment_revealed_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_events_commitment_revealed_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_events_commitment_revealed_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_events_commitment_revealed_id_seq OWNED BY public.ninelives_events_commitment_revealed.id;


--
-- Name: ninelives_events_committed; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_events_committed (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    trading public.address NOT NULL,
    predictor public.address NOT NULL,
    commitment public.bytes32 NOT NULL
);


--
-- Name: ninelives_events_committed_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_events_committed_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_events_committed_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_events_committed_id_seq OWNED BY public.ninelives_events_committed.id;


--
-- Name: ninelives_events_concluded; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_events_concluded (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    ticket public.hugeint NOT NULL,
    justification public.bytes32 NOT NULL
);


--
-- Name: ninelives_events_concluded_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_events_concluded_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_events_concluded_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_events_concluded_id_seq OWNED BY public.ninelives_events_concluded.id;


--
-- Name: ninelives_events_dao_money_distributed; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_events_dao_money_distributed (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    amount public.hugeint NOT NULL,
    recipient public.address NOT NULL
);


--
-- Name: ninelives_events_dao_money_distributed_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_events_dao_money_distributed_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_events_dao_money_distributed_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_events_dao_money_distributed_id_seq OWNED BY public.ninelives_events_dao_money_distributed.id;


--
-- Name: ninelives_events_deadline_extension; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_events_deadline_extension (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    time_before timestamp without time zone NOT NULL,
    time_after timestamp without time zone NOT NULL
);


--
-- Name: ninelives_events_deadline_extension_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_events_deadline_extension_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_events_deadline_extension_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_events_deadline_extension_id_seq OWNED BY public.ninelives_events_deadline_extension.id;


--
-- Name: ninelives_events_declared; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_events_declared (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    trading_addr public.address NOT NULL,
    winning_outcome public.bytes8 NOT NULL,
    fee_recipient public.address NOT NULL
);


--
-- Name: ninelives_events_declared_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_events_declared_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_events_declared_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_events_declared_id_seq OWNED BY public.ninelives_events_declared.id;


--
-- Name: ninelives_events_dppm_clawback; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_events_dppm_clawback (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    recipient public.address NOT NULL,
    fusdc_clawback public.hugeint NOT NULL
);


--
-- Name: ninelives_events_dppm_clawback_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_events_dppm_clawback_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_events_dppm_clawback_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_events_dppm_clawback_id_seq OWNED BY public.ninelives_events_dppm_clawback.id;


--
-- Name: ninelives_events_frozen; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_events_frozen (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    victim public.address NOT NULL,
    until timestamp without time zone NOT NULL
);


--
-- Name: ninelives_events_frozen_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_events_frozen_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_events_frozen_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_events_frozen_id_seq OWNED BY public.ninelives_events_frozen.id;


--
-- Name: ninelives_events_infra_market_closed; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_events_infra_market_closed (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    incentive_recipient public.address NOT NULL,
    trading_addr public.address NOT NULL,
    winner public.bytes32 NOT NULL
);


--
-- Name: ninelives_events_infra_market_closed_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_events_infra_market_closed_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_events_infra_market_closed_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_events_infra_market_closed_id_seq OWNED BY public.ninelives_events_infra_market_closed.id;


--
-- Name: ninelives_events_liquidity_added; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_events_liquidity_added (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    sender public.address NOT NULL,
    fusdc_amt public.hugeint NOT NULL,
    recipient public.address NOT NULL,
    liquidity_shares public.hugeint NOT NULL
);


--
-- Name: ninelives_events_liquidity_added_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_events_liquidity_added_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_events_liquidity_added_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_events_liquidity_added_id_seq OWNED BY public.ninelives_events_liquidity_added.id;


--
-- Name: ninelives_events_liquidity_added_shares_sent; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_events_liquidity_added_shares_sent (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    outcome public.bytes8 NOT NULL,
    liquidity_shares public.hugeint NOT NULL,
    recipient public.address NOT NULL
);


--
-- Name: ninelives_events_liquidity_added_shares_sent_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_events_liquidity_added_shares_sent_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_events_liquidity_added_shares_sent_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_events_liquidity_added_shares_sent_id_seq OWNED BY public.ninelives_events_liquidity_added_shares_sent.id;


--
-- Name: ninelives_events_liquidity_claimed; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_events_liquidity_claimed (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    recipient public.address NOT NULL,
    fusdc_amt public.hugeint NOT NULL
);


--
-- Name: ninelives_events_liquidity_claimed_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_events_liquidity_claimed_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_events_liquidity_claimed_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_events_liquidity_claimed_id_seq OWNED BY public.ninelives_events_liquidity_claimed.id;


--
-- Name: ninelives_events_liquidity_removed; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_events_liquidity_removed (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    fusdc_amt public.hugeint NOT NULL,
    recipient public.address NOT NULL,
    liquidity_amt public.hugeint NOT NULL
);


--
-- Name: ninelives_events_liquidity_removed_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_events_liquidity_removed_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_events_liquidity_removed_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_events_liquidity_removed_id_seq OWNED BY public.ninelives_events_liquidity_removed.id;


--
-- Name: ninelives_events_liquidity_removed_shares_sent; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_events_liquidity_removed_shares_sent (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    outcome public.bytes8 NOT NULL,
    recipient public.address NOT NULL,
    amount public.hugeint NOT NULL
);


--
-- Name: ninelives_events_liquidity_removed_shares_sent_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_events_liquidity_removed_shares_sent_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_events_liquidity_removed_shares_sent_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_events_liquidity_removed_shares_sent_id_seq OWNED BY public.ninelives_events_liquidity_removed_shares_sent.id;


--
-- Name: ninelives_events_locked_up; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_events_locked_up (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    amount public.hugeint NOT NULL,
    recipient public.address NOT NULL
);


--
-- Name: ninelives_events_locked_up_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_events_locked_up_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_events_locked_up_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_events_locked_up_id_seq OWNED BY public.ninelives_events_locked_up.id;


--
-- Name: ninelives_events_lp_fees_claimed; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_events_lp_fees_claimed (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    sender public.address NOT NULL,
    recipient public.address NOT NULL,
    fees_earned public.hugeint NOT NULL,
    sender_liquidity_shares public.hugeint NOT NULL
);


--
-- Name: ninelives_events_lp_fees_claimed_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_events_lp_fees_claimed_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_events_lp_fees_claimed_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_events_lp_fees_claimed_id_seq OWNED BY public.ninelives_events_lp_fees_claimed.id;


--
-- Name: ninelives_events_market_created2; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_events_market_created2 (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    incentive_sender text NOT NULL,
    trading_addr text NOT NULL,
    desc_ public.bytes32 NOT NULL,
    launch_ts timestamp without time zone NOT NULL,
    call_deadline bigint NOT NULL
);


--
-- Name: ninelives_events_market_created2_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_events_market_created2_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_events_market_created2_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_events_market_created2_id_seq OWNED BY public.ninelives_events_market_created2.id;


--
-- Name: ninelives_events_new_trading; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_events_new_trading (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    identifier public.bytes32 NOT NULL,
    address public.address NOT NULL,
    oracle public.address NOT NULL
);


--
-- Name: ninelives_events_new_trading2; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_events_new_trading2 (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    identifier public.bytes32 NOT NULL,
    address public.address NOT NULL,
    oracle public.address NOT NULL,
    backend integer NOT NULL
);


--
-- Name: ninelives_events_new_trading2_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_events_new_trading2_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_events_new_trading2_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_events_new_trading2_id_seq OWNED BY public.ninelives_events_new_trading2.id;


--
-- Name: ninelives_events_new_trading_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_events_new_trading_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_events_new_trading_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_events_new_trading_id_seq OWNED BY public.ninelives_events_new_trading.id;


--
-- Name: ninelives_events_ninetails_boosted_shares_received; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_events_ninetails_boosted_shares_received (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    spender public.address NOT NULL,
    recipient public.address NOT NULL,
    amount_received public.hugeint NOT NULL,
    outcome public.bytes8 NOT NULL
);


--
-- Name: ninelives_events_ninetails_boosted_shares_received_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_events_ninetails_boosted_shares_received_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_events_ninetails_boosted_shares_received_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_events_ninetails_boosted_shares_received_id_seq OWNED BY public.ninelives_events_ninetails_boosted_shares_received.id;


--
-- Name: ninelives_events_ninetails_cumulative_winner_payoff; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_events_ninetails_cumulative_winner_payoff (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    spender public.address NOT NULL,
    recipient public.address NOT NULL,
    shares_spent public.hugeint NOT NULL,
    fusdc_received public.hugeint NOT NULL,
    outcome public.bytes8 NOT NULL
);


--
-- Name: ninelives_events_ninetails_cumulative_winner_payoff_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_events_ninetails_cumulative_winner_payoff_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_events_ninetails_cumulative_winner_payoff_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_events_ninetails_cumulative_winner_payoff_id_seq OWNED BY public.ninelives_events_ninetails_cumulative_winner_payoff.id;


--
-- Name: ninelives_events_ninetails_loser_payoff; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_events_ninetails_loser_payoff (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    spender public.address NOT NULL,
    recipient public.address NOT NULL,
    shares_spent public.hugeint NOT NULL,
    fusdc_received public.hugeint NOT NULL,
    outcome public.bytes8 NOT NULL
);


--
-- Name: ninelives_events_ninetails_loser_payoff_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_events_ninetails_loser_payoff_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_events_ninetails_loser_payoff_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_events_ninetails_loser_payoff_id_seq OWNED BY public.ninelives_events_ninetails_loser_payoff.id;


--
-- Name: ninelives_events_outcome_created; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_events_outcome_created (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    trading_identifier public.bytes8 NOT NULL,
    erc20_identifier public.bytes32 NOT NULL,
    erc20_addr public.bytes32 NOT NULL
);


--
-- Name: ninelives_events_outcome_created_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_events_outcome_created_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_events_outcome_created_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_events_outcome_created_id_seq OWNED BY public.ninelives_events_outcome_created.id;


--
-- Name: ninelives_events_outcome_decided; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_events_outcome_decided (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    identifier public.bytes8 NOT NULL,
    oracle public.address NOT NULL
);

ALTER TABLE ONLY public.ninelives_events_outcome_decided REPLICA IDENTITY FULL;


--
-- Name: ninelives_events_outcome_decided_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_events_outcome_decided_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_events_outcome_decided_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_events_outcome_decided_id_seq OWNED BY public.ninelives_events_outcome_decided.id;


--
-- Name: ninelives_events_paymaster_paid_for; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_events_paymaster_paid_for (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    owner public.address NOT NULL,
    maximum_fee public.hugeint NOT NULL,
    amount_to_spend public.hugeint NOT NULL,
    fee_taken public.hugeint NOT NULL,
    referrer public.address NOT NULL,
    outcome public.bytes8 NOT NULL
);


--
-- Name: ninelives_events_paymaster_paid_for_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_events_paymaster_paid_for_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_events_paymaster_paid_for_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_events_paymaster_paid_for_id_seq OWNED BY public.ninelives_events_paymaster_paid_for.id;


--
-- Name: ninelives_events_payoff_activated; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_events_payoff_activated (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    identifier public.bytes8 NOT NULL,
    shares_spent public.hugeint NOT NULL,
    spender public.address NOT NULL,
    recipient public.address NOT NULL,
    fusdc_received public.hugeint NOT NULL
);


--
-- Name: ninelives_events_payoff_activated_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_events_payoff_activated_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_events_payoff_activated_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_events_payoff_activated_id_seq OWNED BY public.ninelives_events_payoff_activated.id;


--
-- Name: ninelives_events_referrer_earned_fees; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_events_referrer_earned_fees (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    recipient public.address NOT NULL,
    fees public.hugeint NOT NULL,
    volume public.hugeint DEFAULT 0 NOT NULL
);


--
-- Name: ninelives_events_requested; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_events_requested (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    trading public.address NOT NULL,
    ticket public.hugeint NOT NULL
);


--
-- Name: ninelives_events_requested_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_events_requested_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_events_requested_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_events_requested_id_seq OWNED BY public.ninelives_events_requested.id;


--
-- Name: ninelives_events_shares_burned; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_events_shares_burned (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    identifier public.bytes8 NOT NULL,
    share_amount public.hugeint NOT NULL,
    spender public.address NOT NULL,
    recipient public.address NOT NULL,
    fusdc_returned public.hugeint NOT NULL
);


--
-- Name: ninelives_events_shares_burned_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_events_shares_burned_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_events_shares_burned_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_events_shares_burned_id_seq OWNED BY public.ninelives_events_shares_burned.id;


--
-- Name: ninelives_events_shares_minted; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_events_shares_minted (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    identifier public.bytes8 NOT NULL,
    share_amount public.hugeint NOT NULL,
    spender public.address NOT NULL,
    recipient public.address NOT NULL,
    fusdc_spent public.hugeint NOT NULL
);


--
-- Name: ninelives_events_shares_minted_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_events_shares_minted_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_events_shares_minted_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_events_shares_minted_id_seq OWNED BY public.ninelives_events_shares_minted.id;


--
-- Name: ninelives_events_slashed; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_events_slashed (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    victim public.address NOT NULL,
    recipient public.address NOT NULL,
    slashed_amount public.hugeint NOT NULL
);


--
-- Name: ninelives_events_slashed_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_events_slashed_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_events_slashed_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_events_slashed_id_seq OWNED BY public.ninelives_events_slashed.id;


--
-- Name: ninelives_events_whinged; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_events_whinged (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    trading_addr public.address NOT NULL,
    preferred_outcome public.bytes32 NOT NULL,
    whinger public.address NOT NULL
);


--
-- Name: ninelives_events_whinged_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_events_whinged_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_events_whinged_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_events_whinged_id_seq OWNED BY public.ninelives_events_whinged.id;


--
-- Name: ninelives_events_withdrew; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_events_withdrew (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    amount public.hugeint NOT NULL,
    recipient public.address NOT NULL
);


--
-- Name: ninelives_events_withdrew_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_events_withdrew_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_events_withdrew_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_events_withdrew_id_seq OWNED BY public.ninelives_events_withdrew.id;


--
-- Name: ninelives_frontpage_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_frontpage_1 (
    id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    "from" timestamp without time zone NOT NULL,
    until timestamp without time zone NOT NULL,
    campaign_id text NOT NULL
);


--
-- Name: ninelives_frontpage_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_frontpage_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_frontpage_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_frontpage_1_id_seq OWNED BY public.ninelives_frontpage_1.id;


--
-- Name: ninelives_frontpage_liquidity_opportunities_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.ninelives_frontpage_liquidity_opportunities_1 AS
 WITH liquidity_changes AS (
         SELECT camelot_events_camelot_increaseliquidity.pool,
            camelot_events_camelot_increaseliquidity.created_by,
            camelot_events_camelot_increaseliquidity.liquidity AS delta_liquidity
           FROM public.camelot_events_camelot_increaseliquidity
        UNION ALL
         SELECT camelot_events_camelot_decreaseliquidity.emitter_addr AS pool,
            camelot_events_camelot_decreaseliquidity.created_by,
            (- (camelot_events_camelot_decreaseliquidity.liquidity)::numeric) AS delta_liquidity
           FROM public.camelot_events_camelot_decreaseliquidity
        ), hourly_volume AS (
         SELECT liquidity_changes.pool,
            sum(abs(liquidity_changes.delta_liquidity)) AS volume_last_hour
           FROM liquidity_changes
          WHERE (liquidity_changes.created_by >= (now() - '01:00:00'::interval))
          GROUP BY liquidity_changes.pool
        ), current_liquidity AS (
         SELECT liquidity_changes.pool,
            sum(liquidity_changes.delta_liquidity) AS total_liquidity
           FROM liquidity_changes
          GROUP BY liquidity_changes.pool
        ), buys_sells_volume AS (
         SELECT ninelives_buys_and_sells_1.outcome_id AS pool,
            sum((ninelives_buys_and_sells_1.from_amount)::numeric) AS buys_sells_volume
           FROM public.ninelives_buys_and_sells_1
          WHERE (ninelives_buys_and_sells_1.shown = true)
          GROUP BY ninelives_buys_and_sells_1.outcome_id
        ), combined_pools AS (
         SELECT DISTINCT all_pools.pool
           FROM ( SELECT current_liquidity.pool
                   FROM current_liquidity
                UNION
                 SELECT buys_sells_volume.pool
                   FROM buys_sells_volume) all_pools
        ), ranked_pools AS (
         SELECT cp.pool,
            COALESCE(hv.volume_last_hour, (0)::numeric) AS volume_last_hour,
            COALESCE(cl.total_liquidity, (0)::numeric) AS total_liquidity,
            COALESCE(bsv.buys_sells_volume, (0)::numeric) AS buys_sells_volume
           FROM (((combined_pools cp
             LEFT JOIN hourly_volume hv ON ((cp.pool = (hv.pool)::bpchar)))
             LEFT JOIN current_liquidity cl ON ((cp.pool = (cl.pool)::bpchar)))
             LEFT JOIN buys_sells_volume bsv ON ((cp.pool = (bsv.pool)::bpchar)))
        ), final_selection AS (
         SELECT bs.transaction_hash,
            bs.created_by,
            bs.block_hash,
            bs.block_number,
            bs.emitter_addr,
            bs.from_amount,
            bs.from_symbol,
            bs.to_amount,
            bs.to_symbol,
            bs.type,
            bs.spender,
            bs.recipient,
            bs.total_volume,
            bs.outcome_id,
            bs.campaign_id,
            bs.campaign_content,
            bs.shown,
            bs.id,
            rp.volume_last_hour,
            rp.total_liquidity,
            rp.buys_sells_volume
           FROM (public.ninelives_buys_and_sells_1 bs
             JOIN ranked_pools rp ON (((bs.outcome_id)::bpchar = rp.pool)))
          WHERE (bs.shown = true)
        )
 SELECT transaction_hash,
    created_by,
    block_hash,
    block_number,
    emitter_addr,
    from_amount,
    from_symbol,
    to_amount,
    to_symbol,
    type,
    spender,
    recipient,
    total_volume,
    outcome_id,
    campaign_id,
    campaign_content,
    shown,
    id,
    volume_last_hour,
    total_liquidity,
    buys_sells_volume
   FROM final_selection
  ORDER BY volume_last_hour DESC, total_liquidity, buys_sells_volume DESC;


--
-- Name: ninelives_ingestor_checkpointing_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_ingestor_checkpointing_1 (
    id integer NOT NULL,
    last_updated timestamp without time zone NOT NULL,
    block_number integer NOT NULL
);


--
-- Name: ninelives_ingestor_checkpointing_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_ingestor_checkpointing_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_ingestor_checkpointing_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_ingestor_checkpointing_1_id_seq OWNED BY public.ninelives_ingestor_checkpointing_1.id;


--
-- Name: ninelives_market_odds_snapshot_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_market_odds_snapshot_1 (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    pool_address public.address NOT NULL,
    odds jsonb NOT NULL
);

ALTER TABLE ONLY public.ninelives_market_odds_snapshot_1 REPLICA IDENTITY FULL;


--
-- Name: ninelives_market_odds_snapshot_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_market_odds_snapshot_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_market_odds_snapshot_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_market_odds_snapshot_1_id_seq OWNED BY public.ninelives_market_odds_snapshot_1.id;


--
-- Name: ninelives_market_summaries_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_market_summaries_1 (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    pool_address public.address NOT NULL,
    odds jsonb NOT NULL
);


--
-- Name: ninelives_market_summaries_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_market_summaries_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_market_summaries_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_market_summaries_1_id_seq OWNED BY public.ninelives_market_summaries_1.id;


--
-- Name: ninelives_markets_enabled_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_markets_enabled_1 (
    id integer NOT NULL,
    base character varying NOT NULL,
    quote character varying NOT NULL,
    enabled boolean DEFAULT true NOT NULL
);


--
-- Name: ninelives_markets_enabled_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_markets_enabled_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_markets_enabled_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_markets_enabled_1_id_seq OWNED BY public.ninelives_markets_enabled_1.id;


--
-- Name: ninelives_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: ninelives_newsfeed_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_newsfeed_1 (
    id integer NOT NULL,
    headline character varying NOT NULL,
    date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: ninelives_newsfeed_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_newsfeed_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_newsfeed_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_newsfeed_1_id_seq OWNED BY public.ninelives_newsfeed_1.id;


--
-- Name: ninelives_newsfeed_for_today_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.ninelives_newsfeed_for_today_1 AS
 SELECT DISTINCT headline
   FROM public.ninelives_newsfeed_1
  WHERE (date(date) = CURRENT_DATE);


--
-- Name: ninelives_oracle_metadata_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_oracle_metadata_1 (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    campaign_id public.bytes8 NOT NULL,
    price_sym character varying,
    price_source character varying,
    should_be_invoked_at timestamp without time zone NOT NULL,
    was_invoked boolean DEFAULT false NOT NULL
);


--
-- Name: ninelives_oracle_metadata_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_oracle_metadata_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_oracle_metadata_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_oracle_metadata_1_id_seq OWNED BY public.ninelives_oracle_metadata_1.id;


--
-- Name: oracles_ninelives_prices_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oracles_ninelives_prices_1 (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    base character varying NOT NULL,
    quote character varying NOT NULL,
    amount integer NOT NULL,
    source character varying NOT NULL
);


--
-- Name: ninelives_oracles_unresolved_dppm_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.ninelives_oracles_unresolved_dppm_1 AS
 SELECT c.id,
    (c.content ->> 'poolAddress'::text) AS pool_address,
    (((c.content -> 'outcomes'::text) -> 0) ->> 'identifier'::text) AS outcome_id_low,
    (((c.content -> 'outcomes'::text) -> 1) ->> 'identifier'::text) AS outcome_id_high,
    ((p.amount)::bigint > (((c.content -> 'priceMetadata'::text) ->> 'priceTargetForUp'::text))::bigint) AS is_over_price
   FROM ((public.ninelives_campaigns_1 c
     LEFT JOIN public.ninelives_events_outcome_decided ed ON (((c.content ->> 'poolAddress'::text) = (ed.emitter_addr)::text)))
     LEFT JOIN LATERAL ( SELECT oracles_ninelives_prices_1.amount,
            oracles_ninelives_prices_1.created_by
           FROM public.oracles_ninelives_prices_1
          WHERE (((oracles_ninelives_prices_1.base)::text = ((c.content -> 'priceMetadata'::text) ->> 'baseAsset'::text)) AND ((oracles_ninelives_prices_1.quote)::text = ((c.content -> 'priceMetadata'::text) ->> 'quoteAsset'::text)) AND (oracles_ninelives_prices_1.created_by < to_timestamp((((c.content ->> 'ending'::text))::bigint)::double precision)))
          ORDER BY oracles_ninelives_prices_1.created_by DESC
         LIMIT 1) p ON (true))
  WHERE (((c.content ->> 'isDppm'::text) = 'true'::text) AND (CURRENT_TIMESTAMP > to_timestamp((((c.content ->> 'ending'::text))::bigint)::double precision)) AND (ed.id IS NULL))
  ORDER BY c.id;


--
-- Name: oracles_ninelives_prices_2; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oracles_ninelives_prices_2 (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    base character varying NOT NULL,
    quote character varying NOT NULL,
    amount numeric NOT NULL,
    source character varying NOT NULL
);

ALTER TABLE ONLY public.oracles_ninelives_prices_2 REPLICA IDENTITY FULL;


--
-- Name: ninelives_oracles_unresolved_dppm_2; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.ninelives_oracles_unresolved_dppm_2 AS
 SELECT c.id,
    (c.content ->> 'poolAddress'::text) AS pool_address,
    (((c.content -> 'outcomes'::text) -> 0) ->> 'identifier'::text) AS outcome_id_low,
    (((c.content -> 'outcomes'::text) -> 1) ->> 'identifier'::text) AS outcome_id_high,
    (((p.amount)::bigint)::numeric > (((c.content -> 'priceMetadata'::text) ->> 'priceTargetForUp'::text))::numeric) AS is_over_price
   FROM ((public.ninelives_campaigns_1 c
     LEFT JOIN public.ninelives_events_outcome_decided ed ON (((c.content ->> 'poolAddress'::text) = (ed.emitter_addr)::text)))
     LEFT JOIN LATERAL ( SELECT oracles_ninelives_prices_2.amount,
            oracles_ninelives_prices_2.created_by
           FROM public.oracles_ninelives_prices_2
          WHERE (((oracles_ninelives_prices_2.base)::text = ((c.content -> 'priceMetadata'::text) ->> 'baseAsset'::text)) AND ((oracles_ninelives_prices_2.quote)::text = ((c.content -> 'priceMetadata'::text) ->> 'quoteAsset'::text)) AND (oracles_ninelives_prices_2.created_by < to_timestamp((((c.content ->> 'ending'::text))::bigint)::double precision)))
          ORDER BY oracles_ninelives_prices_2.created_by DESC
         LIMIT 1) p ON (true))
  WHERE (((c.content ->> 'isDppm'::text) = 'true'::text) AND (CURRENT_TIMESTAMP > to_timestamp((((c.content ->> 'ending'::text))::bigint)::double precision)) AND (ed.id IS NULL))
  ORDER BY c.id;


--
-- Name: ninelives_oracles_unresolved_dppm_3; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.ninelives_oracles_unresolved_dppm_3 AS
 SELECT c.id,
    (c.content ->> 'poolAddress'::text) AS pool_address,
    (((c.content -> 'outcomes'::text) -> 0) ->> 'identifier'::text) AS outcome_id_low,
    (((c.content -> 'outcomes'::text) -> 1) ->> 'identifier'::text) AS outcome_id_high,
    (p.amount > (((c.content -> 'priceMetadata'::text) ->> 'priceTargetForUp'::text))::numeric) AS is_over_price
   FROM ((public.ninelives_campaigns_1 c
     LEFT JOIN public.ninelives_events_outcome_decided ed ON (((c.content ->> 'poolAddress'::text) = (ed.emitter_addr)::text)))
     LEFT JOIN LATERAL ( SELECT oracles_ninelives_prices_2.amount,
            oracles_ninelives_prices_2.created_by
           FROM public.oracles_ninelives_prices_2
          WHERE (((oracles_ninelives_prices_2.base)::text = ((c.content -> 'priceMetadata'::text) ->> 'baseAsset'::text)) AND ((oracles_ninelives_prices_2.quote)::text = ((c.content -> 'priceMetadata'::text) ->> 'quoteAsset'::text)) AND (oracles_ninelives_prices_2.created_by < to_timestamp((((c.content ->> 'ending'::text))::integer)::double precision)))
          ORDER BY oracles_ninelives_prices_2.created_by DESC
         LIMIT 1) p ON (true))
  WHERE (((c.content ->> 'isDppm'::text) = 'true'::text) AND (CURRENT_TIMESTAMP > to_timestamp((((c.content ->> 'ending'::text))::integer)::double precision)) AND (ed.id IS NULL))
  ORDER BY c.id;


--
-- Name: ninelives_paymaster_attempts_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_paymaster_attempts_1 (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    poll_id integer NOT NULL,
    success boolean DEFAULT false NOT NULL
);


--
-- Name: ninelives_paymaster_attempts_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_paymaster_attempts_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_paymaster_attempts_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_paymaster_attempts_1_id_seq OWNED BY public.ninelives_paymaster_attempts_1.id;


--
-- Name: ninelives_paymaster_attempts_2; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_paymaster_attempts_2 (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    poll_id integer NOT NULL,
    success boolean DEFAULT false NOT NULL,
    transaction_hash public.hash
);


--
-- Name: ninelives_paymaster_attempts_2_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_paymaster_attempts_2_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_paymaster_attempts_2_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_paymaster_attempts_2_id_seq OWNED BY public.ninelives_paymaster_attempts_2.id;


--
-- Name: ninelives_paymaster_poll_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_paymaster_poll_1 (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    owner public.address NOT NULL,
    deadline integer NOT NULL,
    typ integer NOT NULL,
    permit_amount public.hugeint,
    permit_r public.bytes32,
    permit_s public.bytes32,
    permit_v integer,
    market public.address NOT NULL,
    maximum_fee public.hugeint NOT NULL,
    amount_to_spend public.hugeint NOT NULL,
    minimum_back public.hugeint,
    r public.bytes32 NOT NULL,
    s public.bytes32 NOT NULL,
    v integer NOT NULL,
    referrer public.address,
    outcome public.bytes8,
    originating_chain_id public.hugeint NOT NULL,
    nonce public.hugeint NOT NULL,
    outgoing_chain_eid integer NOT NULL
);


--
-- Name: ninelives_paymaster_poll_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_paymaster_poll_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_paymaster_poll_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_paymaster_poll_1_id_seq OWNED BY public.ninelives_paymaster_poll_1.id;


--
-- Name: ninelives_paymaster_poll_outstanding_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.ninelives_paymaster_poll_outstanding_1 AS
 SELECT p.id,
    p.created_by,
    p.owner,
    p.deadline,
    p.typ,
    p.permit_amount,
    p.permit_r,
    p.permit_s,
    p.permit_v,
    p.market,
    p.maximum_fee,
    p.amount_to_spend,
    p.minimum_back,
    p.r,
    p.s,
    p.v,
    p.referrer,
    p.outcome,
    p.originating_chain_id,
    p.nonce
   FROM (public.ninelives_paymaster_poll_1 p
     LEFT JOIN ( SELECT ninelives_paymaster_attempts_1.poll_id,
            count(*) AS tries,
            bool_or(ninelives_paymaster_attempts_1.success) AS any_success
           FROM public.ninelives_paymaster_attempts_1
          GROUP BY ninelives_paymaster_attempts_1.poll_id) a ON ((a.poll_id = p.id)))
  WHERE ((COALESCE(a.tries, (0)::bigint) < 5) AND (NOT COALESCE(a.any_success, false)));


--
-- Name: ninelives_paymaster_poll_outstanding_2; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.ninelives_paymaster_poll_outstanding_2 AS
 SELECT p.id,
    p.created_by,
    p.owner,
    p.deadline,
    p.typ,
    p.permit_amount,
    p.permit_r,
    p.permit_s,
    p.permit_v,
    p.market,
    p.maximum_fee,
    p.amount_to_spend,
    p.minimum_back,
    p.r,
    p.s,
    p.v,
    p.referrer,
    p.outcome,
    p.originating_chain_id,
    p.nonce,
    p.outgoing_chain_eid
   FROM (public.ninelives_paymaster_poll_1 p
     LEFT JOIN ( SELECT ninelives_paymaster_attempts_2.poll_id,
            count(*) AS tries,
            bool_or(ninelives_paymaster_attempts_2.success) AS any_success
           FROM public.ninelives_paymaster_attempts_2
          GROUP BY ninelives_paymaster_attempts_2.poll_id) a ON ((a.poll_id = p.id)))
  WHERE ((COALESCE(a.tries, (0)::bigint) < 5) AND (NOT COALESCE(a.any_success, false)));


--
-- Name: ninelives_payoff_unused_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_payoff_unused_1 (
    id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    pool_address public.address NOT NULL,
    spender public.address NOT NULL,
    was_spent boolean DEFAULT false NOT NULL
);

ALTER TABLE ONLY public.ninelives_payoff_unused_1 REPLICA IDENTITY FULL;


--
-- Name: ninelives_payoff_unused_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_payoff_unused_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_payoff_unused_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_payoff_unused_1_id_seq OWNED BY public.ninelives_payoff_unused_1.id;


--
-- Name: ninelives_referrer_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_referrer_1 (
    id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    creator_ip character varying NOT NULL,
    owner public.address NOT NULL,
    code character varying(50) NOT NULL
);


--
-- Name: ninelives_referrer_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_referrer_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_referrer_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_referrer_1_id_seq OWNED BY public.ninelives_referrer_1.id;


--
-- Name: ninelives_referrer_earned_fees_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_referrer_earned_fees_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_referrer_earned_fees_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_referrer_earned_fees_id_seq OWNED BY public.ninelives_events_referrer_earned_fees.id;


--
-- Name: ninelives_revealed_commitments_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_revealed_commitments_1 (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    trading_addr public.address NOT NULL,
    sender public.address NOT NULL,
    seed public.hugeint NOT NULL,
    preferred_outcome public.bytes8 NOT NULL
);


--
-- Name: ninelives_revealed_commitments_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_revealed_commitments_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_revealed_commitments_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_revealed_commitments_1_id_seq OWNED BY public.ninelives_revealed_commitments_1.id;


--
-- Name: ninelives_tracked_trading_contracts_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_tracked_trading_contracts_1 (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    trading_addr public.address NOT NULL
);


--
-- Name: ninelives_tracked_trading_contracts_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ninelives_tracked_trading_contracts_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ninelives_tracked_trading_contracts_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ninelives_tracked_trading_contracts_1_id_seq OWNED BY public.ninelives_tracked_trading_contracts_1.id;


--
-- Name: ninelives_users_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ninelives_users_1 (
    wallet_address public.address NOT NULL,
    email character varying(320) NOT NULL,
    settings jsonb
);


--
-- Name: ninelives_view_all_earned_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.ninelives_view_all_earned_1 AS
 SELECT recipient,
    emitter_addr,
    sum((fusdc_received)::numeric) AS fusdc_received
   FROM ( SELECT ninelives_events_ninetails_loser_payoff.recipient,
            ninelives_events_ninetails_loser_payoff.emitter_addr,
            ninelives_events_ninetails_loser_payoff.fusdc_received
           FROM public.ninelives_events_ninetails_loser_payoff
        UNION ALL
         SELECT ninelives_events_ninetails_cumulative_winner_payoff.recipient,
            ninelives_events_ninetails_cumulative_winner_payoff.emitter_addr,
            ninelives_events_ninetails_cumulative_winner_payoff.fusdc_received
           FROM public.ninelives_events_ninetails_cumulative_winner_payoff
        UNION ALL
         SELECT ninelives_events_payoff_activated.recipient,
            ninelives_events_payoff_activated.emitter_addr,
            ninelives_events_payoff_activated.fusdc_received
           FROM public.ninelives_events_payoff_activated) combined_payoffs
  GROUP BY recipient, emitter_addr
  ORDER BY recipient, (sum((fusdc_received)::numeric)) DESC;


--
-- Name: notes_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notes_1 (
    id integer NOT NULL,
    created_by timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    content character varying NOT NULL,
    placement character varying NOT NULL,
    from_ timestamp without time zone NOT NULL,
    to_ timestamp without time zone NOT NULL,
    target public.address
);


--
-- Name: notes_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notes_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notes_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notes_1_id_seq OWNED BY public.notes_1.id;


--
-- Name: notes_current_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.notes_current_1 AS
 SELECT id,
    created_by,
    content,
    placement,
    from_,
    to_,
    target
   FROM public.notes_1
  WHERE ((from_ < CURRENT_TIMESTAMP) AND (to_ > CURRENT_TIMESTAMP));


--
-- Name: onchaingm_events_onchaingmevent; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.onchaingm_events_onchaingmevent (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    sender public.address NOT NULL,
    referrer public.address NOT NULL
);


--
-- Name: onchaingm_events_onchaingmevent_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.onchaingm_events_onchaingmevent_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: onchaingm_events_onchaingmevent_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.onchaingm_events_onchaingmevent_id_seq OWNED BY public.onchaingm_events_onchaingmevent.id;


--
-- Name: oracle_ninelives_decisions_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oracle_ninelives_decisions_1 (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    pool_address public.address NOT NULL,
    outcome public.bytes16 NOT NULL
);


--
-- Name: oracle_ninelives_decisions_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oracle_ninelives_decisions_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oracle_ninelives_decisions_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oracle_ninelives_decisions_1_id_seq OWNED BY public.oracle_ninelives_decisions_1.id;


--
-- Name: oracle_ninelives_starting_liq_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oracle_ninelives_starting_liq_1 (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    base character varying NOT NULL,
    quote character varying NOT NULL,
    amount integer NOT NULL
);


--
-- Name: oracle_ninelives_starting_liq_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oracle_ninelives_starting_liq_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oracle_ninelives_starting_liq_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oracle_ninelives_starting_liq_1_id_seq OWNED BY public.oracle_ninelives_starting_liq_1.id;


--
-- Name: oracles_ninelives_clawbackable_campaigns_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.oracles_ninelives_clawbackable_campaigns_1 AS
 SELECT c.id,
    (c.content ->> 'poolAddress'::text) AS pool_address
   FROM (public.ninelives_campaigns_1 c
     LEFT JOIN public.ninelives_events_dppm_clawback dc ON (((c.content ->> 'poolAddress'::text) = (dc.emitter_addr)::text)))
  WHERE (((c.content ->> 'isDppm'::text) = 'true'::text) AND (CURRENT_TIMESTAMP > to_timestamp((((c.content ->> 'ending'::text))::bigint)::double precision)) AND (NOT (EXISTS ( SELECT 1
           FROM public.ninelives_events_shares_minted nbsr
          WHERE ((nbsr.emitter_addr)::text = (c.content ->> 'poolAddress'::text))))) AND (dc.id IS NULL))
  ORDER BY c.id;


--
-- Name: oracles_ninelives_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oracles_ninelives_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: oracles_ninelives_prices_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oracles_ninelives_prices_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oracles_ninelives_prices_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oracles_ninelives_prices_1_id_seq OWNED BY public.oracles_ninelives_prices_1.id;


--
-- Name: oracles_ninelives_prices_2_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oracles_ninelives_prices_2_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oracles_ninelives_prices_2_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oracles_ninelives_prices_2_id_seq OWNED BY public.oracles_ninelives_prices_2.id;


--
-- Name: points_9lives_points_15mins; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_9lives_points_15mins AS
 WITH filtered_transactions AS (
         SELECT ninelives_buys_and_sells_1.transaction_hash,
            ninelives_buys_and_sells_1.recipient,
            ninelives_buys_and_sells_1.from_amount,
            ninelives_buys_and_sells_1.created_by,
            ninelives_buys_and_sells_1.campaign_content
           FROM public.ninelives_buys_and_sells_1
          WHERE (((ninelives_buys_and_sells_1.campaign_content ->> 'isDppm'::text) = 'true'::text) AND ((ninelives_buys_and_sells_1.campaign_content -> 'categories'::text) @> '"15mins"'::jsonb))
        ), unique_transactions AS (
         SELECT DISTINCT filtered_transactions.transaction_hash,
            filtered_transactions.recipient,
            filtered_transactions.from_amount,
            filtered_transactions.created_by,
            filtered_transactions.campaign_content
           FROM filtered_transactions
        ), time_decay AS (
         SELECT unique_transactions.transaction_hash,
            unique_transactions.recipient,
            ((unique_transactions.from_amount)::numeric / (1000000)::numeric) AS volume,
            unique_transactions.created_by,
            date_trunc('15 minutes'::text, unique_transactions.created_by) AS period_start,
            (date_trunc('15 minutes'::text, unique_transactions.created_by) + '00:15:00'::interval) AS period_end,
            ((EXTRACT(epoch FROM (unique_transactions.created_by - date_trunc('15 minutes'::text, unique_transactions.created_by))))::double precision / (900.0)::double precision) AS position_in_period,
            GREATEST(((2.0)::double precision - (((EXTRACT(epoch FROM (unique_transactions.created_by - date_trunc('15 minutes'::text, unique_transactions.created_by))))::double precision / (900.0)::double precision) * (1.9)::double precision)), (0.1)::double precision) AS decay_multiplier
           FROM unique_transactions
        )
 SELECT recipient,
    sum(volume) AS volume,
    sum(((volume)::double precision * decay_multiplier)) AS points
   FROM time_decay
  GROUP BY recipient
  ORDER BY (sum(((volume)::double precision * decay_multiplier))) DESC;


--
-- Name: points_9lives_points_15mins_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_9lives_points_15mins_1 AS
 WITH filtered_transactions AS (
         SELECT ninelives_buys_and_sells_1.transaction_hash,
            ninelives_buys_and_sells_1.recipient,
            ninelives_buys_and_sells_1.from_amount,
            ninelives_buys_and_sells_1.created_by,
            ninelives_buys_and_sells_1.campaign_content
           FROM public.ninelives_buys_and_sells_1
          WHERE (((ninelives_buys_and_sells_1.campaign_content ->> 'isDppm'::text) = 'true'::text) AND ((ninelives_buys_and_sells_1.campaign_content -> 'categories'::text) @> '"15mins"'::jsonb))
        ), unique_transactions AS (
         SELECT DISTINCT filtered_transactions.transaction_hash,
            filtered_transactions.recipient,
            filtered_transactions.from_amount,
            filtered_transactions.created_by,
            filtered_transactions.campaign_content
           FROM filtered_transactions
        ), time_decay AS (
         SELECT unique_transactions.transaction_hash,
            unique_transactions.recipient,
            ((unique_transactions.from_amount)::numeric / (1000000)::numeric) AS volume,
            unique_transactions.created_by,
            (date_trunc('hour'::text, unique_transactions.created_by) + ((((floor((EXTRACT(minute FROM unique_transactions.created_by) / (15)::numeric)))::integer * 15) || ' minutes'::text))::interval) AS period_start,
            ((EXTRACT(epoch FROM (unique_transactions.created_by - (date_trunc('hour'::text, unique_transactions.created_by) + ((((floor((EXTRACT(minute FROM unique_transactions.created_by) / (15)::numeric)))::integer * 15) || ' minutes'::text))::interval))))::double precision / (900.0)::double precision) AS position_in_period,
            GREATEST(((2.0)::double precision - (((EXTRACT(epoch FROM (unique_transactions.created_by - (date_trunc('hour'::text, unique_transactions.created_by) + ((((floor((EXTRACT(minute FROM unique_transactions.created_by) / (15)::numeric)))::integer * 15) || ' minutes'::text))::interval))))::double precision / (900.0)::double precision) * (1.9)::double precision)), (0.1)::double precision) AS decay_multiplier
           FROM unique_transactions
        )
 SELECT recipient,
    sum(volume) AS volume,
    sum(((volume)::double precision * decay_multiplier)) AS points
   FROM time_decay
  GROUP BY recipient
  ORDER BY (sum(((volume)::double precision * decay_multiplier))) DESC;


--
-- Name: points_9lives_points_5mins_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_9lives_points_5mins_1 AS
 WITH filtered_transactions AS (
         SELECT ninelives_buys_and_sells_1.transaction_hash,
            ninelives_buys_and_sells_1.recipient,
            ninelives_buys_and_sells_1.from_amount,
            ninelives_buys_and_sells_1.created_by,
            ninelives_buys_and_sells_1.campaign_content
           FROM public.ninelives_buys_and_sells_1
          WHERE (((ninelives_buys_and_sells_1.campaign_content ->> 'isDppm'::text) = 'true'::text) AND ((ninelives_buys_and_sells_1.campaign_content -> 'categories'::text) @> '"5mins"'::jsonb))
        ), unique_transactions AS (
         SELECT DISTINCT filtered_transactions.transaction_hash,
            filtered_transactions.recipient,
            filtered_transactions.from_amount,
            filtered_transactions.created_by,
            filtered_transactions.campaign_content
           FROM filtered_transactions
        ), time_decay AS (
         SELECT unique_transactions.transaction_hash,
            unique_transactions.recipient,
            ((unique_transactions.from_amount)::numeric / (1000000)::numeric) AS volume,
            unique_transactions.created_by,
            (date_trunc('hour'::text, unique_transactions.created_by) + ((((floor((EXTRACT(minute FROM unique_transactions.created_by) / (5)::numeric)))::integer * 5) || ' minutes'::text))::interval) AS period_start,
            ((EXTRACT(epoch FROM (unique_transactions.created_by - (date_trunc('hour'::text, unique_transactions.created_by) + ((((floor((EXTRACT(minute FROM unique_transactions.created_by) / (5)::numeric)))::integer * 5) || ' minutes'::text))::interval))))::double precision / (300.0)::double precision) AS position_in_period,
            GREATEST(((2.0)::double precision - (((EXTRACT(epoch FROM (unique_transactions.created_by - (date_trunc('hour'::text, unique_transactions.created_by) + ((((floor((EXTRACT(minute FROM unique_transactions.created_by) / (5)::numeric)))::integer * 5) || ' minutes'::text))::interval))))::double precision / (300.0)::double precision) * (1.9)::double precision)), (0.1)::double precision) AS decay_multiplier
           FROM unique_transactions
        )
 SELECT recipient,
    sum(volume) AS volume,
    sum(((volume)::double precision * decay_multiplier)) AS points
   FROM time_decay
  GROUP BY recipient
  ORDER BY (sum(((volume)::double precision * decay_multiplier))) DESC;


--
-- Name: points_9lives_points_buys_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_9lives_points_buys_1 AS
 SELECT recipient,
    (sum((from_amount)::numeric) / (1000000)::numeric) AS volume,
    ((sum((from_amount)::numeric) / (1000000)::numeric) * (1)::numeric) AS points
   FROM ( SELECT DISTINCT ninelives_buys_and_sells_1.transaction_hash,
            ninelives_buys_and_sells_1.recipient,
            ninelives_buys_and_sells_1.from_amount
           FROM public.ninelives_buys_and_sells_1) unique_transactions
  GROUP BY recipient
  ORDER BY (sum((from_amount)::numeric) / (1000000)::numeric) DESC;


--
-- Name: points_9lives_points_buys_2; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_9lives_points_buys_2 AS
 SELECT recipient,
    (sum((from_amount)::numeric) / (1000000)::numeric) AS volume,
    ((sum((from_amount)::numeric) / (1000000)::numeric) * (1)::numeric) AS points
   FROM ( SELECT DISTINCT ninelives_buys_and_sells_1.transaction_hash,
            ninelives_buys_and_sells_1.recipient,
            ninelives_buys_and_sells_1.from_amount,
            ninelives_buys_and_sells_1.campaign_content
           FROM public.ninelives_buys_and_sells_1
          WHERE ((ninelives_buys_and_sells_1.campaign_content ->> 'isDppm'::text) = 'false'::text)) unique_transactions
  GROUP BY recipient
  ORDER BY (sum((from_amount)::numeric) / (1000000)::numeric) DESC;


--
-- Name: points_9lives_points_buys_3; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_9lives_points_buys_3 AS
 SELECT recipient,
    (sum((from_amount)::numeric) / (1000000)::numeric) AS volume,
    ((sum((from_amount)::numeric) / (1000000)::numeric) * (1)::numeric) AS points
   FROM ( SELECT DISTINCT ninelives_buys_and_sells_1.transaction_hash,
            ninelives_buys_and_sells_1.recipient,
            ninelives_buys_and_sells_1.from_amount,
            ninelives_buys_and_sells_1.campaign_content
           FROM public.ninelives_buys_and_sells_1
          WHERE (((ninelives_buys_and_sells_1.campaign_content ->> 'isDppm'::text) = 'false'::text) OR ((ninelives_buys_and_sells_1.campaign_content -> 'isDppm'::text) IS NULL))) unique_transactions
  GROUP BY recipient
  ORDER BY (sum((from_amount)::numeric) / (1000000)::numeric) DESC;


--
-- Name: points_9lives_points_creators_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_9lives_points_creators_1 AS
 SELECT ((content -> 'creator'::text) ->> 'address'::text) AS creator_address,
    count(DISTINCT id) AS campaign_count,
    (count(DISTINCT id) * 2) AS points
   FROM public.ninelives_campaigns_1
  GROUP BY ((content -> 'creator'::text) ->> 'address'::text)
  ORDER BY (count(DISTINCT id)) DESC;


--
-- Name: points_9lives_points_daily_btc; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_9lives_points_daily_btc AS
 WITH filtered_transactions AS (
         SELECT ninelives_buys_and_sells_1.transaction_hash,
            ninelives_buys_and_sells_1.recipient,
            ninelives_buys_and_sells_1.from_amount,
            ninelives_buys_and_sells_1.created_by,
            ninelives_buys_and_sells_1.campaign_content
           FROM public.ninelives_buys_and_sells_1
          WHERE (((ninelives_buys_and_sells_1.campaign_content ->> 'isDppm'::text) = 'true'::text) AND ((ninelives_buys_and_sells_1.campaign_content -> 'categories'::text) @> '"Daily"'::jsonb) AND (((ninelives_buys_and_sells_1.campaign_content -> 'priceMetadata'::text) ->> 'baseAsset'::text) = 'BTC'::text))
        ), unique_transactions AS (
         SELECT DISTINCT filtered_transactions.transaction_hash,
            filtered_transactions.recipient,
            filtered_transactions.from_amount,
            filtered_transactions.created_by,
            filtered_transactions.campaign_content
           FROM filtered_transactions
        ), time_decay AS (
         SELECT unique_transactions.transaction_hash,
            unique_transactions.recipient,
            ((unique_transactions.from_amount)::numeric / (1000000)::numeric) AS volume,
            unique_transactions.created_by,
                CASE
                    WHEN (EXTRACT(hour FROM unique_transactions.created_by) < (9)::numeric) THEN (date_trunc('day'::text, unique_transactions.created_by) - '15:00:00'::interval)
                    ELSE (date_trunc('day'::text, unique_transactions.created_by) + '09:00:00'::interval)
                END AS day_start,
            ((EXTRACT(epoch FROM (unique_transactions.created_by -
                CASE
                    WHEN (EXTRACT(hour FROM unique_transactions.created_by) < (9)::numeric) THEN (date_trunc('day'::text, unique_transactions.created_by) - '15:00:00'::interval)
                    ELSE (date_trunc('day'::text, unique_transactions.created_by) + '09:00:00'::interval)
                END)))::double precision / (86400.0)::double precision) AS position_in_day,
            GREATEST(((4.0)::double precision - (((EXTRACT(epoch FROM (unique_transactions.created_by -
                CASE
                    WHEN (EXTRACT(hour FROM unique_transactions.created_by) < (9)::numeric) THEN (date_trunc('day'::text, unique_transactions.created_by) - '15:00:00'::interval)
                    ELSE (date_trunc('day'::text, unique_transactions.created_by) + '09:00:00'::interval)
                END)))::double precision / (86400.0)::double precision) * (3.9)::double precision)), (0.1)::double precision) AS decay_multiplier
           FROM unique_transactions
        )
 SELECT recipient,
    sum(volume) AS volume,
    sum(((volume)::double precision * decay_multiplier)) AS points
   FROM time_decay
  GROUP BY recipient
  ORDER BY (sum(((volume)::double precision * decay_multiplier))) DESC;


--
-- Name: points_9lives_points_daily_qqq; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_9lives_points_daily_qqq AS
 WITH filtered_transactions AS (
         SELECT ninelives_buys_and_sells_1.transaction_hash,
            ninelives_buys_and_sells_1.recipient,
            ninelives_buys_and_sells_1.from_amount,
            ninelives_buys_and_sells_1.created_by,
            ninelives_buys_and_sells_1.campaign_content
           FROM public.ninelives_buys_and_sells_1
          WHERE (((ninelives_buys_and_sells_1.campaign_content ->> 'isDppm'::text) = 'true'::text) AND ((ninelives_buys_and_sells_1.campaign_content -> 'categories'::text) @> '"Daily"'::jsonb) AND (((ninelives_buys_and_sells_1.campaign_content -> 'priceMetadata'::text) ->> 'baseAsset'::text) = 'QQQ'::text))
        ), unique_transactions AS (
         SELECT DISTINCT filtered_transactions.transaction_hash,
            filtered_transactions.recipient,
            filtered_transactions.from_amount,
            filtered_transactions.created_by,
            filtered_transactions.campaign_content
           FROM filtered_transactions
        ), time_decay AS (
         SELECT unique_transactions.transaction_hash,
            unique_transactions.recipient,
            ((unique_transactions.from_amount)::numeric / (1000000)::numeric) AS volume,
            unique_transactions.created_by,
                CASE
                    WHEN (EXTRACT(hour FROM unique_transactions.created_by) < (14)::numeric) THEN (date_trunc('day'::text, unique_transactions.created_by) - '10:00:00'::interval)
                    ELSE (date_trunc('day'::text, unique_transactions.created_by) + '14:00:00'::interval)
                END AS day_start,
            ((EXTRACT(epoch FROM (unique_transactions.created_by -
                CASE
                    WHEN (EXTRACT(hour FROM unique_transactions.created_by) < (14)::numeric) THEN (date_trunc('day'::text, unique_transactions.created_by) - '10:00:00'::interval)
                    ELSE (date_trunc('day'::text, unique_transactions.created_by) + '14:00:00'::interval)
                END)))::double precision / (86400.0)::double precision) AS position_in_day,
            GREATEST(((4.0)::double precision - (((EXTRACT(epoch FROM (unique_transactions.created_by -
                CASE
                    WHEN (EXTRACT(hour FROM unique_transactions.created_by) < (14)::numeric) THEN (date_trunc('day'::text, unique_transactions.created_by) - '10:00:00'::interval)
                    ELSE (date_trunc('day'::text, unique_transactions.created_by) + '14:00:00'::interval)
                END)))::double precision / (86400.0)::double precision) * (3.9)::double precision)), (0.1)::double precision) AS decay_multiplier
           FROM unique_transactions
        )
 SELECT recipient,
    sum(volume) AS volume,
    sum(((volume)::double precision * decay_multiplier)) AS points
   FROM time_decay
  GROUP BY recipient
  ORDER BY (sum(((volume)::double precision * decay_multiplier))) DESC;


--
-- Name: points_9lives_points_hourly; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_9lives_points_hourly AS
 WITH filtered_transactions AS (
         SELECT ninelives_buys_and_sells_1.transaction_hash,
            ninelives_buys_and_sells_1.recipient,
            ninelives_buys_and_sells_1.from_amount,
            ninelives_buys_and_sells_1.created_by,
            ninelives_buys_and_sells_1.campaign_content
           FROM public.ninelives_buys_and_sells_1
          WHERE (((ninelives_buys_and_sells_1.campaign_content ->> 'isDppm'::text) = 'true'::text) AND ((ninelives_buys_and_sells_1.campaign_content -> 'categories'::text) @> '"Hourly"'::jsonb))
        ), unique_transactions AS (
         SELECT DISTINCT filtered_transactions.transaction_hash,
            filtered_transactions.recipient,
            filtered_transactions.from_amount,
            filtered_transactions.created_by,
            filtered_transactions.campaign_content
           FROM filtered_transactions
        ), time_decay AS (
         SELECT unique_transactions.transaction_hash,
            unique_transactions.recipient,
            ((unique_transactions.from_amount)::numeric / (1000000)::numeric) AS volume,
            unique_transactions.created_by,
            date_trunc('hour'::text, unique_transactions.created_by) AS hour_start,
            (date_trunc('hour'::text, unique_transactions.created_by) + '01:00:00'::interval) AS hour_end,
            ((EXTRACT(epoch FROM (unique_transactions.created_by - date_trunc('hour'::text, unique_transactions.created_by))))::double precision / (3600.0)::double precision) AS position_in_hour,
            GREATEST(((2.0)::double precision - (((EXTRACT(epoch FROM (unique_transactions.created_by - date_trunc('hour'::text, unique_transactions.created_by))))::double precision / (3600.0)::double precision) * (1.9)::double precision)), (0.1)::double precision) AS decay_multiplier
           FROM unique_transactions
        )
 SELECT recipient,
    sum(volume) AS volume,
    sum(((volume)::double precision * decay_multiplier)) AS points
   FROM time_decay
  GROUP BY recipient
  ORDER BY (sum(((volume)::double precision * decay_multiplier))) DESC;


--
-- Name: points_9lives_points_lps_3; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_9lives_points_lps_3 AS
 WITH all_events AS (
         SELECT ninelives_events_liquidity_added.recipient,
            ninelives_events_liquidity_added.emitter_addr,
            ninelives_events_liquidity_added.created_by AS event_timestamp,
            ninelives_events_liquidity_added.liquidity_shares AS amount,
            'add'::text AS event_type
           FROM public.ninelives_events_liquidity_added
        UNION ALL
         SELECT ninelives_events_liquidity_removed.recipient,
            ninelives_events_liquidity_removed.emitter_addr,
            ninelives_events_liquidity_removed.created_by AS event_timestamp,
            (- (ninelives_events_liquidity_removed.fusdc_amt)::numeric) AS amount,
            'remove'::text AS event_type
           FROM public.ninelives_events_liquidity_removed
        ), ordered_events AS (
         SELECT all_events.recipient,
            all_events.emitter_addr,
            all_events.event_timestamp,
            all_events.event_type,
            all_events.amount,
            row_number() OVER (PARTITION BY all_events.recipient, all_events.emitter_addr ORDER BY all_events.event_timestamp) AS event_num,
            sum(all_events.amount) OVER (PARTITION BY all_events.recipient, all_events.emitter_addr ORDER BY all_events.event_timestamp) AS running_liquidity_balance
           FROM all_events
        ), events_with_next_timestamp AS (
         SELECT ordered_events.recipient,
            ordered_events.emitter_addr,
            ordered_events.event_timestamp,
            ordered_events.event_type,
            ordered_events.amount,
            ordered_events.event_num,
            ordered_events.running_liquidity_balance,
            lag(ordered_events.running_liquidity_balance, 1, (0)::numeric) OVER (PARTITION BY ordered_events.recipient, ordered_events.emitter_addr ORDER BY ordered_events.event_timestamp) AS liquidity_before_event,
            lead((ordered_events.event_timestamp)::timestamp with time zone, 1, now()) OVER (PARTITION BY ordered_events.recipient, ordered_events.emitter_addr ORDER BY ordered_events.event_timestamp) AS next_event_timestamp
           FROM ordered_events
        ), events_with_points AS (
         SELECT events_with_next_timestamp.recipient,
            events_with_next_timestamp.emitter_addr,
            events_with_next_timestamp.event_timestamp,
            events_with_next_timestamp.event_type,
            events_with_next_timestamp.amount,
            events_with_next_timestamp.event_num,
            events_with_next_timestamp.liquidity_before_event,
            events_with_next_timestamp.running_liquidity_balance,
            events_with_next_timestamp.next_event_timestamp,
            EXTRACT(epoch FROM (events_with_next_timestamp.next_event_timestamp - (events_with_next_timestamp.event_timestamp)::timestamp with time zone)) AS seconds_held,
            round(((events_with_next_timestamp.running_liquidity_balance / '1000000'::numeric) * EXTRACT(epoch FROM (events_with_next_timestamp.next_event_timestamp - (events_with_next_timestamp.event_timestamp)::timestamp with time zone))), 6) AS points_earned
           FROM events_with_next_timestamp
        ), position_points AS (
         SELECT events_with_points.recipient,
            events_with_points.emitter_addr,
            sum(events_with_points.points_earned) AS total_points,
            count(*) AS num_events
           FROM events_with_points
          GROUP BY events_with_points.recipient, events_with_points.emitter_addr
        )
 SELECT recipient,
    floor((sum(total_points) / (1500000)::numeric)) AS total_points_per_address,
    count(*) AS num_pools,
    sum(num_events) AS total_events
   FROM position_points
  GROUP BY recipient
  ORDER BY (floor((sum(total_points) / (1500000)::numeric))) DESC;


--
-- Name: points_9lives_points_everything_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_9lives_points_everything_1 AS
 SELECT COALESCE((a.recipient)::bpchar, (b.creator_address)::bpchar, (c.recipient)::bpchar, (d.recipient)::bpchar, (e.recipient)::bpchar, (f.recipient)::bpchar, (g.recipient)::bpchar, (h.recipient)::bpchar) AS address,
    ((((((((COALESCE(a.points, (0)::numeric) + (COALESCE(b.points, (0)::bigint))::numeric) + COALESCE(c.total_points_per_address, (0)::numeric)))::double precision + COALESCE(d.points, (0)::double precision)) + COALESCE(e.points, (0)::double precision)) + COALESCE(f.points, (0)::double precision)) + COALESCE(g.points, (0)::double precision)) + COALESCE(h.points, (0)::double precision)) AS total_points
   FROM (((((((public.points_9lives_points_buys_3 a
     FULL JOIN public.points_9lives_points_creators_1 b ON (((a.recipient)::text = b.creator_address)))
     FULL JOIN public.points_9lives_points_lps_3 c ON ((COALESCE((a.recipient)::bpchar, (b.creator_address)::bpchar) = (c.recipient)::bpchar)))
     FULL JOIN public.points_9lives_points_hourly d ON ((COALESCE((a.recipient)::bpchar, (b.creator_address)::bpchar, (c.recipient)::bpchar) = (d.recipient)::bpchar)))
     FULL JOIN public.points_9lives_points_daily_btc e ON ((COALESCE((a.recipient)::bpchar, (b.creator_address)::bpchar, (c.recipient)::bpchar, (d.recipient)::bpchar) = (e.recipient)::bpchar)))
     FULL JOIN public.points_9lives_points_daily_qqq f ON ((COALESCE((a.recipient)::bpchar, (b.creator_address)::bpchar, (c.recipient)::bpchar, (d.recipient)::bpchar, (e.recipient)::bpchar) = (f.recipient)::bpchar)))
     FULL JOIN public.points_9lives_points_15mins_1 g ON ((COALESCE((a.recipient)::bpchar, (b.creator_address)::bpchar, (c.recipient)::bpchar, (d.recipient)::bpchar, (e.recipient)::bpchar, (f.recipient)::bpchar) = (g.recipient)::bpchar)))
     FULL JOIN public.points_9lives_points_5mins_1 h ON ((COALESCE((a.recipient)::bpchar, (b.creator_address)::bpchar, (c.recipient)::bpchar, (d.recipient)::bpchar, (e.recipient)::bpchar, (f.recipient)::bpchar, (g.recipient)::bpchar) = (h.recipient)::bpchar)))
  ORDER BY ((((((((COALESCE(a.points, (0)::numeric) + (COALESCE(b.points, (0)::bigint))::numeric) + COALESCE(c.total_points_per_address, (0)::numeric)))::double precision + COALESCE(d.points, (0)::double precision)) + COALESCE(e.points, (0)::double precision)) + COALESCE(f.points, (0)::double precision)) + COALESCE(g.points, (0)::double precision)) + COALESCE(h.points, (0)::double precision)) DESC;


--
-- Name: points_9lives_points_lps_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_9lives_points_lps_1 AS
 WITH all_events AS (
         SELECT ninelives_events_liquidity_added.recipient,
            ninelives_events_liquidity_added.emitter_addr,
            ninelives_events_liquidity_added.block_number,
            ninelives_events_liquidity_added.liquidity_shares AS amount,
            'add'::text AS event_type
           FROM public.ninelives_events_liquidity_added
        UNION ALL
         SELECT ninelives_events_liquidity_removed.recipient,
            ninelives_events_liquidity_removed.emitter_addr,
            ninelives_events_liquidity_removed.block_number,
            (- (ninelives_events_liquidity_removed.fusdc_amt)::numeric) AS amount,
            'remove'::text AS event_type
           FROM public.ninelives_events_liquidity_removed
        ), ordered_events AS (
         SELECT all_events.recipient,
            all_events.emitter_addr,
            all_events.block_number,
            all_events.event_type,
            all_events.amount,
            row_number() OVER (PARTITION BY all_events.recipient, all_events.emitter_addr ORDER BY all_events.block_number) AS event_num,
            sum(all_events.amount) OVER (PARTITION BY all_events.recipient, all_events.emitter_addr ORDER BY all_events.block_number) AS running_liquidity_balance
           FROM all_events
        ), events_with_next_block AS (
         SELECT ordered_events.recipient,
            ordered_events.emitter_addr,
            ordered_events.block_number,
            ordered_events.event_type,
            ordered_events.amount,
            ordered_events.event_num,
            ordered_events.running_liquidity_balance,
            lag(ordered_events.running_liquidity_balance, 1, (0)::numeric) OVER (PARTITION BY ordered_events.recipient, ordered_events.emitter_addr ORDER BY ordered_events.block_number) AS liquidity_before_event,
            lead(ordered_events.block_number, 1, 2371683) OVER (PARTITION BY ordered_events.recipient, ordered_events.emitter_addr ORDER BY ordered_events.block_number) AS next_block_number
           FROM ordered_events
        ), events_with_points AS (
         SELECT events_with_next_block.recipient,
            events_with_next_block.emitter_addr,
            events_with_next_block.block_number,
            events_with_next_block.event_type,
            events_with_next_block.amount,
            events_with_next_block.event_num,
            events_with_next_block.liquidity_before_event,
            events_with_next_block.running_liquidity_balance,
            events_with_next_block.next_block_number,
            (events_with_next_block.next_block_number - events_with_next_block.block_number) AS blocks_held,
            round(((events_with_next_block.running_liquidity_balance / '1000000'::numeric) * ((events_with_next_block.next_block_number - events_with_next_block.block_number))::numeric), 6) AS points_earned
           FROM events_with_next_block
        ), position_points AS (
         SELECT events_with_points.recipient,
            events_with_points.emitter_addr,
            sum(events_with_points.points_earned) AS total_points,
            count(*) AS num_events
           FROM events_with_points
          GROUP BY events_with_points.recipient, events_with_points.emitter_addr
        )
 SELECT recipient,
    sum(total_points) AS total_points_per_address,
    count(*) AS num_pools,
    sum(num_events) AS total_events
   FROM position_points
  GROUP BY recipient
  ORDER BY (sum(total_points)) DESC;


--
-- Name: points_9lives_points_lps_2; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_9lives_points_lps_2 AS
 WITH all_events AS (
         SELECT ninelives_events_liquidity_added.recipient,
            ninelives_events_liquidity_added.emitter_addr,
            ninelives_events_liquidity_added.block_number,
            ninelives_events_liquidity_added.liquidity_shares AS amount,
            'add'::text AS event_type
           FROM public.ninelives_events_liquidity_added
        UNION ALL
         SELECT ninelives_events_liquidity_removed.recipient,
            ninelives_events_liquidity_removed.emitter_addr,
            ninelives_events_liquidity_removed.block_number,
            (- (ninelives_events_liquidity_removed.fusdc_amt)::numeric) AS amount,
            'remove'::text AS event_type
           FROM public.ninelives_events_liquidity_removed
        ), ordered_events AS (
         SELECT all_events.recipient,
            all_events.emitter_addr,
            all_events.block_number,
            all_events.event_type,
            all_events.amount,
            row_number() OVER (PARTITION BY all_events.recipient, all_events.emitter_addr ORDER BY all_events.block_number) AS event_num,
            sum(all_events.amount) OVER (PARTITION BY all_events.recipient, all_events.emitter_addr ORDER BY all_events.block_number) AS running_liquidity_balance
           FROM all_events
        ), events_with_next_block AS (
         SELECT ordered_events.recipient,
            ordered_events.emitter_addr,
            ordered_events.block_number,
            ordered_events.event_type,
            ordered_events.amount,
            ordered_events.event_num,
            ordered_events.running_liquidity_balance,
            lag(ordered_events.running_liquidity_balance, 1, (0)::numeric) OVER (PARTITION BY ordered_events.recipient, ordered_events.emitter_addr ORDER BY ordered_events.block_number) AS liquidity_before_event,
            lead(ordered_events.block_number, 1, 2378034) OVER (PARTITION BY ordered_events.recipient, ordered_events.emitter_addr ORDER BY ordered_events.block_number) AS next_block_number
           FROM ordered_events
        ), events_with_points AS (
         SELECT events_with_next_block.recipient,
            events_with_next_block.emitter_addr,
            events_with_next_block.block_number,
            events_with_next_block.event_type,
            events_with_next_block.amount,
            events_with_next_block.event_num,
            events_with_next_block.liquidity_before_event,
            events_with_next_block.running_liquidity_balance,
            events_with_next_block.next_block_number,
            (events_with_next_block.next_block_number - events_with_next_block.block_number) AS blocks_held,
            round(((events_with_next_block.running_liquidity_balance / '1000000'::numeric) * ((events_with_next_block.next_block_number - events_with_next_block.block_number))::numeric), 6) AS points_earned
           FROM events_with_next_block
        ), position_points AS (
         SELECT events_with_points.recipient,
            events_with_points.emitter_addr,
            sum(events_with_points.points_earned) AS total_points,
            count(*) AS num_events
           FROM events_with_points
          GROUP BY events_with_points.recipient, events_with_points.emitter_addr
        )
 SELECT recipient,
    floor((sum(total_points) / (50000)::numeric)) AS total_points_per_address,
    count(*) AS num_pools,
    sum(num_events) AS total_events
   FROM position_points
  GROUP BY recipient
  ORDER BY (floor((sum(total_points) / (50000)::numeric))) DESC;


--
-- Name: points_achievement_leaderboard_value_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.points_achievement_leaderboard_value_1 (
    id integer NOT NULL,
    updated_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    product character varying NOT NULL,
    season integer NOT NULL,
    name character varying NOT NULL,
    scoring double precision NOT NULL
);


--
-- Name: points_achievement_leaderboard_value_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.points_achievement_leaderboard_value_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: points_achievement_leaderboard_value_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.points_achievement_leaderboard_value_1_id_seq OWNED BY public.points_achievement_leaderboard_value_1.id;


--
-- Name: points_achievements_received_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.points_achievements_received_1 (
    id integer NOT NULL,
    updated_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    address character varying NOT NULL,
    achievement_name character varying NOT NULL,
    achievement_count integer NOT NULL,
    achievement_giver integer NOT NULL
);


--
-- Name: points_achievements_grouped_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_achievements_grouped_1 AS
 SELECT address,
    achievement_name,
    sum(achievement_count) AS achievement_count
   FROM public.points_achievements_received_1
  GROUP BY address, achievement_name;


--
-- Name: points_achievements_received_2; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.points_achievements_received_2 (
    id integer NOT NULL,
    updated_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    address character varying NOT NULL,
    achievement_name character varying NOT NULL,
    achievement_count public.hugeint NOT NULL,
    product character varying NOT NULL,
    season integer NOT NULL,
    achievement_giver integer NOT NULL,
    scoring double precision NOT NULL
);


--
-- Name: points_achievements_grouped_all_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_achievements_grouped_all_1 AS
 SELECT achievement_name AS name,
    sum((achievement_count)::numeric) AS count,
    scoring,
    product,
    season
   FROM public.points_achievements_received_2
  GROUP BY achievement_name, product, scoring, season;


--
-- Name: points_achievements_grouped_user_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_achievements_grouped_user_1 AS
 SELECT address,
    achievement_name AS name,
    sum((achievement_count)::numeric) AS count,
    scoring,
    product,
    season
   FROM public.points_achievements_received_2
  GROUP BY address, achievement_name, scoring, product, season;


--
-- Name: points_achievements_leaderboard_return_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.points_achievements_leaderboard_return_1 (
    address character varying NOT NULL,
    scoring integer NOT NULL
);


--
-- Name: points_achievements_received_1_achievement_giver_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.points_achievements_received_1_achievement_giver_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: points_achievements_received_1_achievement_giver_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.points_achievements_received_1_achievement_giver_seq OWNED BY public.points_achievements_received_1.achievement_giver;


--
-- Name: points_achievements_received_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.points_achievements_received_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: points_achievements_received_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.points_achievements_received_1_id_seq OWNED BY public.points_achievements_received_1.id;


--
-- Name: points_achievements_received_2_achievement_giver_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.points_achievements_received_2_achievement_giver_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: points_achievements_received_2_achievement_giver_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.points_achievements_received_2_achievement_giver_seq OWNED BY public.points_achievements_received_2.achievement_giver;


--
-- Name: points_achievements_received_2_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.points_achievements_received_2_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: points_achievements_received_2_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.points_achievements_received_2_id_seq OWNED BY public.points_achievements_received_2.id;


--
-- Name: points_testnet_addresses_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.points_testnet_addresses_1 (
    id integer NOT NULL,
    updated_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    address character varying NOT NULL
);


--
-- Name: points_all_addresses_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_all_addresses_1 AS
 SELECT DISTINCT address
   FROM ( SELECT points_testnet_addresses_1.address
           FROM public.points_testnet_addresses_1
        UNION
         SELECT events_leo_campaigncreated.owner AS address
           FROM public.events_leo_campaigncreated
        UNION
         SELECT events_seawater_mintposition.owner AS address
           FROM public.events_seawater_mintposition
        UNION
         SELECT events_seawater_swap2.user_ AS address
           FROM public.events_seawater_swap2
        UNION
         SELECT events_seawater_swap1.user_ AS address
           FROM public.events_seawater_swap1
        UNION
         SELECT events_erc20_transfer.sender AS address
           FROM public.events_erc20_transfer
        UNION
         SELECT events_erc20_transfer.recipient AS address
           FROM public.events_erc20_transfer) rows;


--
-- Name: points_camelot_pool_pair_cache_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.points_camelot_pool_pair_cache_1 (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    pool public.address NOT NULL,
    token0 public.address NOT NULL,
    token1 public.address NOT NULL
);


--
-- Name: points_camelot_positions_over_time_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_camelot_positions_over_time_1 AS
 WITH liquidity_events AS (
         SELECT il.transaction_hash,
            il.block_number,
            il.pool,
            il.pos_id,
            il.emitter_addr AS owner,
            il.amount0,
            il.amount1,
            ec0.decimals AS decimals0,
            ec1.decimals AS decimals1,
            il.created_by AS start_time,
            NULL::timestamp without time zone AS end_time
           FROM (((public.camelot_events_camelot_increaseliquidity il
             JOIN public.points_camelot_pool_pair_cache_1 pc ON (((il.pool)::bpchar = (pc.pool)::bpchar)))
             JOIN public.erc20_cache_1 ec0 ON (((pc.token0)::bpchar = (ec0.address)::bpchar)))
             JOIN public.erc20_cache_1 ec1 ON (((pc.token1)::bpchar = (ec1.address)::bpchar)))
        UNION ALL
         SELECT dl.transaction_hash,
            dl.block_number,
            il.pool,
            dl.pos_id,
            dl.emitter_addr AS owner,
            (- (dl.amount0)::numeric) AS amount0,
            (- (dl.amount1)::numeric) AS amount1,
            ec0.decimals AS decimals0,
            ec1.decimals AS decimals1,
            NULL::timestamp without time zone AS start_time,
            dl.created_by AS end_time
           FROM ((((public.camelot_events_camelot_decreaseliquidity dl
             LEFT JOIN public.camelot_events_camelot_increaseliquidity il ON (((dl.pos_id)::numeric = (il.pos_id)::numeric)))
             LEFT JOIN public.points_camelot_pool_pair_cache_1 pc ON (((il.pool)::bpchar = (pc.pool)::bpchar)))
             LEFT JOIN public.erc20_cache_1 ec0 ON (((pc.token0)::bpchar = (ec0.address)::bpchar)))
             LEFT JOIN public.erc20_cache_1 ec1 ON (((pc.token1)::bpchar = (ec1.address)::bpchar)))
        UNION ALL
         SELECT tp.transaction_hash,
            tp.block_number,
            il.pool,
            tp.pos_id,
            tp.to_ AS owner,
            0 AS amount0,
            0 AS amount1,
            NULL::integer AS decimals0,
            NULL::integer AS decimals1,
            tp.created_by AS start_time,
            NULL::timestamp without time zone AS end_time
           FROM (public.camelot_events_camelot_transferposition tp
             LEFT JOIN public.camelot_events_camelot_increaseliquidity il ON (((tp.pos_id)::numeric = (il.pos_id)::numeric)))
        )
 SELECT transaction_hash,
    block_number,
    pool,
    pos_id,
    owner,
    ((amount0)::double precision / power((10)::double precision, (COALESCE(decimals0, 18))::double precision)) AS normalised_amount0,
    ((amount1)::double precision / power((10)::double precision, (COALESCE(decimals1, 18))::double precision)) AS normalised_amount1,
    start_time,
    COALESCE(end_time, now()) AS end_time,
    EXTRACT(epoch FROM (COALESCE(end_time, now()) - start_time)) AS duration_seconds
   FROM liquidity_events le;


--
-- Name: points_camelot_lp_positions_cleaned_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_camelot_lp_positions_cleaned_1 AS
 WITH all_pos_ids AS (
         SELECT DISTINCT points_camelot_positions_over_time_1.pos_id
           FROM public.points_camelot_positions_over_time_1
          WHERE ((points_camelot_positions_over_time_1.normalised_amount0 <> (0)::double precision) OR (points_camelot_positions_over_time_1.normalised_amount1 <> (0)::double precision))
        ), closing_transactions AS (
         SELECT DISTINCT points_camelot_positions_over_time_1.transaction_hash,
            points_camelot_positions_over_time_1.pos_id
           FROM public.points_camelot_positions_over_time_1
          WHERE ((points_camelot_positions_over_time_1.owner)::bpchar = '0x0000000000000000000000000000000000000000'::bpchar)
        ), position_owners AS (
         SELECT points_camelot_positions_over_time_1.pos_id,
            max(
                CASE
                    WHEN ((points_camelot_positions_over_time_1.owner)::bpchar <> ALL (ARRAY['0x36049d5b4aaef6c39cd4a5bd1a2e1224f07621a2'::bpchar, '0x0000000000000000000000000000000000000000'::bpchar])) THEN (points_camelot_positions_over_time_1.owner)::bpchar
                    ELSE NULL::bpchar
                END) AS real_owner
           FROM public.points_camelot_positions_over_time_1
          GROUP BY points_camelot_positions_over_time_1.pos_id
        ), deduplicated_actions AS (
         SELECT DISTINCT ON (p.pos_id, p.transaction_hash, (abs(p.normalised_amount0)), (abs(p.normalised_amount1))) p.transaction_hash,
            p.block_number,
            p.pool,
            p.pos_id,
            COALESCE(po.real_owner, (p.owner)::bpchar) AS owner,
            p.normalised_amount0,
            p.normalised_amount1,
            p.start_time,
            p.end_time,
                CASE
                    WHEN ((p.normalised_amount0 < (0)::double precision) OR (p.normalised_amount1 < (0)::double precision)) THEN 'REMOVE'::text
                    ELSE 'ADD'::text
                END AS action_type,
            (EXISTS ( SELECT 1
                   FROM closing_transactions ct
                  WHERE (((ct.transaction_hash)::bpchar = (p.transaction_hash)::bpchar) AND ((ct.pos_id)::numeric = (p.pos_id)::numeric)))) AS is_position_closed
           FROM (public.points_camelot_positions_over_time_1 p
             LEFT JOIN position_owners po ON (((p.pos_id)::numeric = (po.pos_id)::numeric)))
          WHERE (((p.pos_id)::numeric IN ( SELECT all_pos_ids.pos_id
                   FROM all_pos_ids)) AND ((p.normalised_amount0 <> (0)::double precision) OR (p.normalised_amount1 <> (0)::double precision)))
          ORDER BY p.pos_id, p.transaction_hash, (abs(p.normalised_amount0)), (abs(p.normalised_amount1)), p.block_number
        ), position_history AS (
         SELECT deduplicated_actions.transaction_hash,
            deduplicated_actions.block_number,
            deduplicated_actions.pool,
            deduplicated_actions.pos_id,
            deduplicated_actions.owner,
            deduplicated_actions.normalised_amount0,
            deduplicated_actions.normalised_amount1,
            deduplicated_actions.start_time,
            deduplicated_actions.end_time,
            deduplicated_actions.action_type,
            deduplicated_actions.is_position_closed,
            lead(deduplicated_actions.start_time) OVER (PARTITION BY deduplicated_actions.pos_id ORDER BY deduplicated_actions.block_number) AS next_start_time,
            lead(deduplicated_actions.action_type) OVER (PARTITION BY deduplicated_actions.pos_id ORDER BY deduplicated_actions.block_number) AS next_action_type,
            lead(deduplicated_actions.end_time) OVER (PARTITION BY deduplicated_actions.pos_id ORDER BY deduplicated_actions.block_number) AS next_end_time
           FROM deduplicated_actions
        )
 SELECT transaction_hash,
    block_number,
    pool,
    pos_id,
    owner,
    normalised_amount0,
    normalised_amount1,
    start_time,
    end_time,
    action_type,
    is_position_closed,
        CASE
            WHEN ((action_type = 'ADD'::text) AND (next_action_type = 'ADD'::text)) THEN EXTRACT(epoch FROM (next_start_time - start_time))
            WHEN ((action_type = 'ADD'::text) AND (next_action_type = 'REMOVE'::text)) THEN EXTRACT(epoch FROM (next_end_time - start_time))
            WHEN ((action_type = 'ADD'::text) AND (next_action_type IS NULL)) THEN EXTRACT(epoch FROM (CURRENT_TIMESTAMP - start_time))
            WHEN (action_type = 'REMOVE'::text) THEN EXTRACT(epoch FROM (end_time - start_time))
            ELSE NULL::numeric
        END AS duration_seconds
   FROM position_history
  ORDER BY pos_id, block_number;


--
-- Name: points_camelot_lp_points_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_camelot_lp_points_1 AS
 WITH position_events AS (
         SELECT points_camelot_lp_positions_cleaned_1.transaction_hash,
            points_camelot_lp_positions_cleaned_1.block_number,
            points_camelot_lp_positions_cleaned_1.pool,
            points_camelot_lp_positions_cleaned_1.pos_id,
            points_camelot_lp_positions_cleaned_1.owner,
            points_camelot_lp_positions_cleaned_1.normalised_amount0,
            points_camelot_lp_positions_cleaned_1.normalised_amount1,
            points_camelot_lp_positions_cleaned_1.start_time,
            points_camelot_lp_positions_cleaned_1.end_time,
            points_camelot_lp_positions_cleaned_1.action_type,
            points_camelot_lp_positions_cleaned_1.is_position_closed,
            points_camelot_lp_positions_cleaned_1.duration_seconds,
            lead(points_camelot_lp_positions_cleaned_1.action_type) OVER (PARTITION BY points_camelot_lp_positions_cleaned_1.pos_id ORDER BY points_camelot_lp_positions_cleaned_1.block_number, points_camelot_lp_positions_cleaned_1.transaction_hash) AS next_action_type,
            lead(points_camelot_lp_positions_cleaned_1.start_time) OVER (PARTITION BY points_camelot_lp_positions_cleaned_1.pos_id ORDER BY points_camelot_lp_positions_cleaned_1.block_number, points_camelot_lp_positions_cleaned_1.transaction_hash) AS next_start_time,
            lead(points_camelot_lp_positions_cleaned_1.end_time) OVER (PARTITION BY points_camelot_lp_positions_cleaned_1.pos_id ORDER BY points_camelot_lp_positions_cleaned_1.block_number, points_camelot_lp_positions_cleaned_1.transaction_hash) AS next_end_time,
                CASE
                    WHEN ((points_camelot_lp_positions_cleaned_1.pool)::bpchar = '0x7fc956a5c0aef46aa25b8911f4cb4619cbb7d90f'::bpchar) THEN points_camelot_lp_positions_cleaned_1.normalised_amount1
                    WHEN ((points_camelot_lp_positions_cleaned_1.pool)::bpchar = '0xf401f9e336cd4fb11f33f4afa81c7a40cfabf26e'::bpchar) THEN points_camelot_lp_positions_cleaned_1.normalised_amount0
                    WHEN ((points_camelot_lp_positions_cleaned_1.pool)::bpchar = '0x2b4ea69870659de72e8fd6de086ad958a712349e'::bpchar) THEN points_camelot_lp_positions_cleaned_1.normalised_amount0
                    ELSE (0)::double precision
                END AS relevant_amount
           FROM public.points_camelot_lp_positions_cleaned_1
          WHERE ((points_camelot_lp_positions_cleaned_1.pool)::bpchar = ANY (ARRAY['0x7fc956a5c0aef46aa25b8911f4cb4619cbb7d90f'::bpchar, '0xf401f9e336cd4fb11f33f4afa81c7a40cfabf26e'::bpchar, '0x2b4ea69870659de72e8fd6de086ad958a712349e'::bpchar]))
        ), position_state AS (
         SELECT position_events.transaction_hash,
            position_events.block_number,
            position_events.pool,
            position_events.pos_id,
            position_events.owner,
            position_events.normalised_amount0,
            position_events.normalised_amount1,
            position_events.start_time,
            position_events.end_time,
            position_events.action_type,
            position_events.is_position_closed,
            position_events.duration_seconds,
            position_events.next_action_type,
            position_events.next_start_time,
            position_events.next_end_time,
            position_events.relevant_amount,
            sum(position_events.relevant_amount) OVER (PARTITION BY position_events.pos_id ORDER BY position_events.block_number, position_events.transaction_hash ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_state,
                CASE
                    WHEN ((position_events.relevant_amount < (0)::double precision) AND (position_events.is_position_closed = false)) THEN
                    CASE
                        WHEN (position_events.next_action_type = 'REMOVE'::text) THEN EXTRACT(epoch FROM (position_events.next_end_time - position_events.end_time))
                        WHEN (position_events.next_action_type = 'ADD'::text) THEN EXTRACT(epoch FROM (position_events.next_start_time - position_events.end_time))
                        ELSE NULL::numeric
                    END
                    ELSE position_events.duration_seconds
                END AS calculated_duration
           FROM position_events
        ), position_points AS (
         SELECT position_state.transaction_hash,
            position_state.block_number,
            position_state.pool,
            position_state.pos_id,
            position_state.owner,
            position_state.normalised_amount0,
            position_state.normalised_amount1,
            position_state.start_time,
            position_state.end_time,
            position_state.action_type,
            position_state.is_position_closed,
            position_state.duration_seconds,
            position_state.next_action_type,
            position_state.next_start_time,
            position_state.next_end_time,
            position_state.relevant_amount,
            position_state.running_state,
            position_state.calculated_duration,
                CASE
                    WHEN (((position_state.action_type = 'REMOVE'::text) AND (position_state.is_position_closed = true)) OR (position_state.calculated_duration IS NULL)) THEN (0)::double precision
                    ELSE ((position_state.running_state * (position_state.calculated_duration)::double precision) * (0.00001)::double precision)
                END AS points
           FROM position_state
        )
 SELECT owner,
    sum(points) AS points_t
   FROM position_points
  GROUP BY owner
  ORDER BY (sum(points)) DESC;


--
-- Name: points_camelot_swap_points_2; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_camelot_swap_points_2 AS
 WITH amounts AS (
         SELECT camelot_events_algebra_swap.transaction_sender,
            sum(
                CASE
                    WHEN (lower((camelot_events_algebra_swap.emitter_addr)::text) = '0x59aa3937cd09c11258e44720ce56093b5fe37939'::text) THEN ((abs((camelot_events_algebra_swap.amount0)::numeric) * (2)::numeric) / (1000000)::numeric)
                    WHEN (lower((camelot_events_algebra_swap.emitter_addr)::text) = '0x7fc956a5c0aef46aa25b8911f4cb4619cbb7d90f'::text) THEN ((abs((camelot_events_algebra_swap.amount1)::numeric) * (2)::numeric) / (1000000)::numeric)
                    WHEN (lower((camelot_events_algebra_swap.emitter_addr)::text) = '0xf401f9e336cd4fb11f33f4afa81c7a40cfabf26e'::text) THEN ((abs((camelot_events_algebra_swap.amount0)::numeric) * (2)::numeric) / (1000000)::numeric)
                    WHEN (lower((camelot_events_algebra_swap.emitter_addr)::text) = '0x2b4ea69870659de72e8fd6de086ad958a712349e'::text) THEN ((abs((camelot_events_algebra_swap.amount0)::numeric) * (2)::numeric) / (1000000)::numeric)
                    ELSE (0)::numeric
                END) AS total_amount
           FROM public.camelot_events_algebra_swap
          WHERE ((camelot_events_algebra_swap.transaction_sender IS NOT NULL) AND ((camelot_events_algebra_swap.transaction_sender)::bpchar <> ''::bpchar) AND (camelot_events_algebra_swap.block_number < 891306))
          GROUP BY camelot_events_algebra_swap.transaction_sender
        ), total AS (
         SELECT sum(amounts.total_amount) AS grand_total
           FROM amounts
        )
 SELECT a.transaction_sender,
    a.total_amount,
    round(((a.total_amount / t.grand_total) * (10000000)::numeric)) AS points
   FROM (amounts a
     CROSS JOIN total t)
  ORDER BY (round(((a.total_amount / t.grand_total) * (10000000)::numeric))) DESC;


--
-- Name: points_camelot_swap_points_3; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_camelot_swap_points_3 AS
 WITH amounts AS (
         SELECT camelot_events_algebra_swap.transaction_sender,
            sum(
                CASE
                    WHEN (lower((camelot_events_algebra_swap.emitter_addr)::text) = '0x59aa3937cd09c11258e44720ce56093b5fe37939'::text) THEN ((abs((camelot_events_algebra_swap.amount0)::numeric) * (2)::numeric) / (1000000)::numeric)
                    WHEN (lower((camelot_events_algebra_swap.emitter_addr)::text) = '0x7fc956a5c0aef46aa25b8911f4cb4619cbb7d90f'::text) THEN ((abs((camelot_events_algebra_swap.amount1)::numeric) * (2)::numeric) / (1000000)::numeric)
                    WHEN (lower((camelot_events_algebra_swap.emitter_addr)::text) = '0xf401f9e336cd4fb11f33f4afa81c7a40cfabf26e'::text) THEN ((abs((camelot_events_algebra_swap.amount0)::numeric) * (2)::numeric) / (1000000)::numeric)
                    WHEN (lower((camelot_events_algebra_swap.emitter_addr)::text) = '0x2b4ea69870659de72e8fd6de086ad958a712349e'::text) THEN ((abs((camelot_events_algebra_swap.amount0)::numeric) * (2)::numeric) / (1000000)::numeric)
                    ELSE (0)::numeric
                END) AS total_amount
           FROM public.camelot_events_algebra_swap
          WHERE ((camelot_events_algebra_swap.transaction_sender IS NOT NULL) AND ((camelot_events_algebra_swap.transaction_sender)::bpchar <> ''::bpchar) AND (camelot_events_algebra_swap.block_number > 891306) AND (camelot_events_algebra_swap.block_number < 1090849))
          GROUP BY camelot_events_algebra_swap.transaction_sender
        ), total AS (
         SELECT sum(amounts.total_amount) AS grand_total
           FROM amounts
        )
 SELECT a.transaction_sender,
    a.total_amount,
    round(((a.total_amount / t.grand_total) * (8000000)::numeric)) AS points
   FROM (amounts a
     CROSS JOIN total t)
  ORDER BY (round(((a.total_amount / t.grand_total) * (8000000)::numeric))) DESC;


--
-- Name: points_camelot_swap_points_4; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_camelot_swap_points_4 AS
 WITH amounts AS (
         SELECT camelot_events_algebra_swap.transaction_sender,
            sum(
                CASE
                    WHEN (lower((camelot_events_algebra_swap.emitter_addr)::text) = '0x59aa3937cd09c11258e44720ce56093b5fe37939'::text) THEN ((abs((camelot_events_algebra_swap.amount0)::numeric) * (2)::numeric) / (1000000)::numeric)
                    WHEN (lower((camelot_events_algebra_swap.emitter_addr)::text) = '0x7fc956a5c0aef46aa25b8911f4cb4619cbb7d90f'::text) THEN ((abs((camelot_events_algebra_swap.amount1)::numeric) * (2)::numeric) / (1000000)::numeric)
                    WHEN (lower((camelot_events_algebra_swap.emitter_addr)::text) = '0xf401f9e336cd4fb11f33f4afa81c7a40cfabf26e'::text) THEN ((abs((camelot_events_algebra_swap.amount0)::numeric) * (2)::numeric) / (1000000)::numeric)
                    WHEN (lower((camelot_events_algebra_swap.emitter_addr)::text) = '0x2b4ea69870659de72e8fd6de086ad958a712349e'::text) THEN ((abs((camelot_events_algebra_swap.amount0)::numeric) * (2)::numeric) / (1000000)::numeric)
                    ELSE (0)::numeric
                END) AS total_amount
           FROM public.camelot_events_algebra_swap
          WHERE ((camelot_events_algebra_swap.transaction_sender IS NOT NULL) AND ((camelot_events_algebra_swap.transaction_sender)::bpchar <> ''::bpchar) AND (camelot_events_algebra_swap.block_number > 1090849) AND (camelot_events_algebra_swap.block_number < 1231907))
          GROUP BY camelot_events_algebra_swap.transaction_sender
        ), total AS (
         SELECT sum(amounts.total_amount) AS grand_total
           FROM amounts
        )
 SELECT a.transaction_sender,
    a.total_amount,
    round(((a.total_amount / t.grand_total) * (8000000)::numeric)) AS points
   FROM (amounts a
     CROSS JOIN total t)
  ORDER BY (round(((a.total_amount / t.grand_total) * (8000000)::numeric))) DESC;


--
-- Name: points_camelot_swap_points_5; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_camelot_swap_points_5 AS
 WITH amounts AS (
         SELECT camelot_events_algebra_swap.transaction_sender,
            sum(
                CASE
                    WHEN (lower((camelot_events_algebra_swap.emitter_addr)::text) = '0x59aa3937cd09c11258e44720ce56093b5fe37939'::text) THEN ((abs((camelot_events_algebra_swap.amount0)::numeric) * (2)::numeric) / (1000000)::numeric)
                    WHEN (lower((camelot_events_algebra_swap.emitter_addr)::text) = '0x7fc956a5c0aef46aa25b8911f4cb4619cbb7d90f'::text) THEN ((abs((camelot_events_algebra_swap.amount1)::numeric) * (2)::numeric) / (1000000)::numeric)
                    WHEN (lower((camelot_events_algebra_swap.emitter_addr)::text) = '0xf401f9e336cd4fb11f33f4afa81c7a40cfabf26e'::text) THEN ((abs((camelot_events_algebra_swap.amount0)::numeric) * (2)::numeric) / (1000000)::numeric)
                    WHEN (lower((camelot_events_algebra_swap.emitter_addr)::text) = '0x2b4ea69870659de72e8fd6de086ad958a712349e'::text) THEN ((abs((camelot_events_algebra_swap.amount0)::numeric) * (2)::numeric) / (1000000)::numeric)
                    ELSE (0)::numeric
                END) AS total_amount
           FROM public.camelot_events_algebra_swap
          WHERE ((camelot_events_algebra_swap.transaction_sender IS NOT NULL) AND ((camelot_events_algebra_swap.transaction_sender)::bpchar <> ''::bpchar) AND (camelot_events_algebra_swap.block_number > 1231907) AND (camelot_events_algebra_swap.block_number < 1336999))
          GROUP BY camelot_events_algebra_swap.transaction_sender
        ), total AS (
         SELECT sum(amounts.total_amount) AS grand_total
           FROM amounts
        )
 SELECT a.transaction_sender,
    a.total_amount,
    round(((a.total_amount / t.grand_total) * (10000000)::numeric)) AS points
   FROM (amounts a
     CROSS JOIN total t)
  ORDER BY (round(((a.total_amount / t.grand_total) * (10000000)::numeric))) DESC;


--
-- Name: points_camelot_swap_points_6; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_camelot_swap_points_6 AS
 WITH amounts AS (
         SELECT camelot_events_algebra_swap.transaction_sender,
            sum(
                CASE
                    WHEN (lower((camelot_events_algebra_swap.emitter_addr)::text) = '0x59aa3937cd09c11258e44720ce56093b5fe37939'::text) THEN ((abs((camelot_events_algebra_swap.amount0)::numeric) * (2)::numeric) / (1000000)::numeric)
                    WHEN (lower((camelot_events_algebra_swap.emitter_addr)::text) = '0x7fc956a5c0aef46aa25b8911f4cb4619cbb7d90f'::text) THEN ((abs((camelot_events_algebra_swap.amount1)::numeric) * (2)::numeric) / (1000000)::numeric)
                    WHEN (lower((camelot_events_algebra_swap.emitter_addr)::text) = '0xf401f9e336cd4fb11f33f4afa81c7a40cfabf26e'::text) THEN ((abs((camelot_events_algebra_swap.amount0)::numeric) * (2)::numeric) / (1000000)::numeric)
                    WHEN (lower((camelot_events_algebra_swap.emitter_addr)::text) = '0x2b4ea69870659de72e8fd6de086ad958a712349e'::text) THEN ((abs((camelot_events_algebra_swap.amount0)::numeric) * (2)::numeric) / (1000000)::numeric)
                    ELSE (0)::numeric
                END) AS total_amount
           FROM public.camelot_events_algebra_swap
          WHERE ((camelot_events_algebra_swap.transaction_sender IS NOT NULL) AND ((camelot_events_algebra_swap.transaction_sender)::bpchar <> ''::bpchar) AND (camelot_events_algebra_swap.block_number > 1336999) AND (camelot_events_algebra_swap.block_number < 1424523))
          GROUP BY camelot_events_algebra_swap.transaction_sender
        ), total AS (
         SELECT sum(amounts.total_amount) AS grand_total
           FROM amounts
        )
 SELECT a.transaction_sender,
    a.total_amount,
    round(((a.total_amount / t.grand_total) * (10000000)::numeric)) AS points
   FROM (amounts a
     CROSS JOIN total t)
  ORDER BY (round(((a.total_amount / t.grand_total) * (10000000)::numeric))) DESC;


--
-- Name: points_camelot_swap_points_7; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_camelot_swap_points_7 AS
 WITH amounts AS (
         SELECT camelot_events_algebra_swap.transaction_sender,
            sum(
                CASE
                    WHEN (lower((camelot_events_algebra_swap.emitter_addr)::text) = '0x59aa3937cd09c11258e44720ce56093b5fe37939'::text) THEN ((abs((camelot_events_algebra_swap.amount0)::numeric) * (2)::numeric) / (1000000)::numeric)
                    WHEN (lower((camelot_events_algebra_swap.emitter_addr)::text) = '0x7fc956a5c0aef46aa25b8911f4cb4619cbb7d90f'::text) THEN ((abs((camelot_events_algebra_swap.amount1)::numeric) * (2)::numeric) / (1000000)::numeric)
                    WHEN (lower((camelot_events_algebra_swap.emitter_addr)::text) = '0xf401f9e336cd4fb11f33f4afa81c7a40cfabf26e'::text) THEN ((abs((camelot_events_algebra_swap.amount0)::numeric) * (2)::numeric) / (1000000)::numeric)
                    WHEN (lower((camelot_events_algebra_swap.emitter_addr)::text) = '0x2b4ea69870659de72e8fd6de086ad958a712349e'::text) THEN ((abs((camelot_events_algebra_swap.amount0)::numeric) * (2)::numeric) / (1000000)::numeric)
                    ELSE (0)::numeric
                END) AS total_amount
           FROM public.camelot_events_algebra_swap
          WHERE ((camelot_events_algebra_swap.transaction_sender IS NOT NULL) AND ((camelot_events_algebra_swap.transaction_sender)::bpchar <> ''::bpchar) AND (camelot_events_algebra_swap.block_number > 1424523))
          GROUP BY camelot_events_algebra_swap.transaction_sender
        )
 SELECT transaction_sender,
    total_amount,
    round((total_amount * (50)::numeric)) AS points
   FROM amounts
  ORDER BY (round((total_amount * (50)::numeric))) DESC;


--
-- Name: points_discovered_debank_balances_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.points_discovered_debank_balances_1 (
    id integer NOT NULL,
    updated_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    address character varying NOT NULL,
    network character varying NOT NULL,
    asset_name character varying NOT NULL,
    asset_usd_value double precision NOT NULL,
    debt_usd_value double precision NOT NULL
);


--
-- Name: points_discovered_debank_nobal_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.points_discovered_debank_nobal_1 (
    id integer NOT NULL,
    updated_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    address character varying NOT NULL
);


--
-- Name: points_displayed_via_endpoint_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.points_displayed_via_endpoint_1 (
    id integer NOT NULL,
    updated_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    address character varying NOT NULL,
    points bigint NOT NULL
);


--
-- Name: points_fly_staked_snapshot_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.points_fly_staked_snapshot_1 (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    address public.address NOT NULL,
    points public.hugeint NOT NULL
);


--
-- Name: points_fly_staked_points_aggregated_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_fly_staked_points_aggregated_1 AS
 SELECT DISTINCT ON (address) address,
    points
   FROM public.points_fly_staked_snapshot_1
  ORDER BY address, created_by DESC;


--
-- Name: points_staked_to_spn_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.points_staked_to_spn_1 (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    address public.address NOT NULL,
    fly_converted integer NOT NULL,
    start_date timestamp without time zone NOT NULL
);


--
-- Name: points_fly_staking_to_points_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_fly_staking_to_points_1 AS
 SELECT address,
    fly_converted,
    start_date,
    (((fly_converted)::numeric * 0.000003) * EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (start_date)::timestamp with time zone))) AS points
   FROM public.points_staked_to_spn_1;


--
-- Name: points_layer3_cube_points_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_layer3_cube_points_1 AS
 SELECT user_address,
    count(*) AS amount,
    (count(*) * 1500) AS points
   FROM public.nfts_user_owned_1
  WHERE ((token_address)::text = lower('0x1195Cf65f83B3A5768F3C496D3A05AD6412c64B7'::text))
  GROUP BY user_address
  ORDER BY (count(*)) DESC;


--
-- Name: points_longtail_lp_time_since_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_longtail_lp_time_since_1 AS
 WITH position_events AS (
         SELECT events_seawater_updatepositionliquidity.pos_id,
            events_seawater_updatepositionliquidity.created_by AS event_time,
            events_seawater_updatepositionliquidity.token1 AS amount1,
            lead(events_seawater_updatepositionliquidity.created_by) OVER (PARTITION BY events_seawater_updatepositionliquidity.pos_id ORDER BY events_seawater_updatepositionliquidity.created_by) AS next_event_time
           FROM public.events_seawater_updatepositionliquidity
        )
 SELECT pos_id,
    event_time AS start_time,
    COALESCE(next_event_time, now()) AS end_time,
    amount1,
    (EXTRACT(epoch FROM COALESCE(next_event_time, now())) - EXTRACT(epoch FROM event_time)) AS active_seconds
   FROM position_events pe;


--
-- Name: points_longtail_lp_pos_ids_points_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_longtail_lp_pos_ids_points_1 AS
 WITH running_state AS (
         SELECT points_longtail_lp_time_since_1.pos_id,
            points_longtail_lp_time_since_1.start_time,
            points_longtail_lp_time_since_1.end_time,
            points_longtail_lp_time_since_1.amount1,
            points_longtail_lp_time_since_1.active_seconds,
            sum((points_longtail_lp_time_since_1.amount1)::numeric) OVER (PARTITION BY points_longtail_lp_time_since_1.pos_id ORDER BY points_longtail_lp_time_since_1.start_time ROWS UNBOUNDED PRECEDING) AS current_amount1_state
           FROM public.points_longtail_lp_time_since_1
        )
 SELECT pos_id,
    sum(
        CASE
            WHEN (current_amount1_state > (0)::numeric) THEN (((current_amount1_state * active_seconds) * 0.000001) * 0.00002)
            ELSE (0)::numeric
        END) AS points
   FROM running_state
  GROUP BY pos_id
  ORDER BY pos_id;


--
-- Name: points_longtail_lp_pos_ids_owner_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_longtail_lp_pos_ids_owner_1 AS
 SELECT t.to_ AS owner,
    sum(p.points) AS sum
   FROM (public.points_longtail_lp_pos_ids_points_1 p
     LEFT JOIN public.events_seawater_transferposition t ON (((t.pos_id)::numeric = (p.pos_id)::numeric)))
  GROUP BY t.to_;


--
-- Name: points_longtail_swap_points_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_longtail_swap_points_1 AS
 WITH user_totals AS (
         SELECT points_swaps_consolidated_1.user_,
            (sum((points_swaps_consolidated_1.amount_out)::numeric) / (1000000)::numeric) AS total_amount_out
           FROM public.points_swaps_consolidated_1
          WHERE ((points_swaps_consolidated_1.from_ = '0xa8ea92c819463efbeddfb670fefc881a480f0115'::bpchar) OR (points_swaps_consolidated_1.to_ = '0xa8ea92c819463efbeddfb670fefc881a480f0115'::bpchar))
          GROUP BY points_swaps_consolidated_1.user_
        ), total_sum AS (
         SELECT sum(user_totals_1.total_amount_out) AS grand_total
           FROM user_totals user_totals_1
        )
 SELECT user_totals.user_,
    user_totals.total_amount_out,
    round(((user_totals.total_amount_out / total_sum.grand_total) * (5800000)::numeric), 2) AS points_earned
   FROM (user_totals
     CROSS JOIN total_sum)
  ORDER BY (round(((user_totals.total_amount_out / total_sum.grand_total) * (5800000)::numeric), 2)) DESC;


--
-- Name: points_ninelives_buys_points_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_ninelives_buys_points_1 AS
 SELECT recipient,
    (sum((from_amount)::numeric) / (1000000)::numeric) AS volume,
    ((sum((from_amount)::numeric) / (1000000)::numeric) * (10)::numeric) AS points
   FROM ( SELECT DISTINCT ninelives_buys_and_sells_1.transaction_hash,
            ninelives_buys_and_sells_1.recipient,
            ninelives_buys_and_sells_1.from_amount
           FROM public.ninelives_buys_and_sells_1) unique_transactions
  GROUP BY recipient
  ORDER BY (sum((from_amount)::numeric) / (1000000)::numeric) DESC;


--
-- Name: points_ninelives_creator_points_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_ninelives_creator_points_1 AS
 SELECT ((content -> 'creator'::text) ->> 'address'::text) AS creator_address,
    count(DISTINCT id) AS campaign_count,
    (count(DISTINCT id) * 1000) AS points
   FROM public.ninelives_campaigns_1
  GROUP BY ((content -> 'creator'::text) ->> 'address'::text)
  ORDER BY (count(DISTINCT id)) DESC;


--
-- Name: points_purrstream_donation_points_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_purrstream_donation_points_1 AS
 SELECT address,
    count(DISTINCT transaction_hash) AS unique_donation_count,
    (count(DISTINCT transaction_hash) * 10) AS points
   FROM public.events_purrstream_donated
  GROUP BY address
  ORDER BY (count(DISTINCT transaction_hash) * 10) DESC;


--
-- Name: points_everything_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_everything_1 AS
 SELECT COALESCE((a.address)::bpchar, (b.owner)::bpchar, (c.user_)::bpchar, (d.transaction_sender)::bpchar, (e.transaction_sender)::bpchar, (f.address)::bpchar, (g.transaction_sender)::bpchar, (h.user_address)::bpchar, (i.transaction_sender)::bpchar, (j.transaction_sender)::bpchar, k.owner, (l.recipient)::bpchar, (m.creator_address)::bpchar, (n.address)::bpchar, (o.transaction_sender)::bpchar) AS address,
    (((((((((((((((COALESCE((a.points)::numeric, (0)::numeric) + COALESCE(b.sum, (0)::numeric)) + COALESCE(c.points_earned, (0)::numeric)) + COALESCE(d.points, (0)::numeric)) + COALESCE(e.points, (0)::numeric)) + COALESCE(f.points, (0)::numeric)) + COALESCE(g.points, (0)::numeric)) + (COALESCE(h.points, (0)::bigint))::numeric) + COALESCE(i.points, (0)::numeric)) + COALESCE(j.points, (0)::numeric)))::double precision + COALESCE(k.points_t, (0)::double precision)) + (COALESCE(l.points, (0)::numeric))::double precision) + (COALESCE(m.points, (0)::bigint))::double precision) + (COALESCE(n.points, (0)::bigint))::double precision) + (COALESCE(o.points, (0)::numeric))::double precision) AS total_points
   FROM ((((((((((((((public.points_fly_staked_points_aggregated_1 a
     FULL JOIN public.points_longtail_lp_pos_ids_owner_1 b ON (((a.address)::bpchar = (b.owner)::bpchar)))
     FULL JOIN public.points_longtail_swap_points_1 c ON (((COALESCE(a.address, b.owner))::bpchar = (c.user_)::bpchar)))
     FULL JOIN public.points_camelot_swap_points_2 d ON (((COALESCE(a.address, b.owner, c.user_))::bpchar = (d.transaction_sender)::bpchar)))
     FULL JOIN public.points_camelot_swap_points_3 e ON (((COALESCE(a.address, b.owner, c.user_, d.transaction_sender))::bpchar = (e.transaction_sender)::bpchar)))
     FULL JOIN public.points_fly_staking_to_points_1 f ON (((COALESCE(a.address, b.owner, c.user_, d.transaction_sender, e.transaction_sender))::bpchar = (f.address)::bpchar)))
     FULL JOIN public.points_camelot_swap_points_4 g ON (((COALESCE(a.address, b.owner, c.user_, d.transaction_sender, e.transaction_sender, f.address))::bpchar = (g.transaction_sender)::bpchar)))
     FULL JOIN public.points_layer3_cube_points_1 h ON (((COALESCE(a.address, b.owner, c.user_, d.transaction_sender, e.transaction_sender, f.address, g.transaction_sender))::bpchar = (h.user_address)::bpchar)))
     FULL JOIN public.points_camelot_swap_points_5 i ON (((COALESCE(a.address, b.owner, c.user_, d.transaction_sender, e.transaction_sender, f.address, g.transaction_sender, h.user_address))::bpchar = (i.transaction_sender)::bpchar)))
     FULL JOIN public.points_camelot_swap_points_6 j ON (((COALESCE(a.address, b.owner, c.user_, d.transaction_sender, e.transaction_sender, f.address, g.transaction_sender, h.user_address, i.transaction_sender))::bpchar = (j.transaction_sender)::bpchar)))
     FULL JOIN public.points_camelot_lp_points_1 k ON (((COALESCE(a.address, b.owner, c.user_, d.transaction_sender, e.transaction_sender, f.address, g.transaction_sender, h.user_address, i.transaction_sender, j.transaction_sender))::bpchar = k.owner)))
     FULL JOIN public.points_ninelives_buys_points_1 l ON ((COALESCE((a.address)::bpchar, (b.owner)::bpchar, (c.user_)::bpchar, (d.transaction_sender)::bpchar, (e.transaction_sender)::bpchar, (f.address)::bpchar, (g.transaction_sender)::bpchar, (h.user_address)::bpchar, (i.transaction_sender)::bpchar, (j.transaction_sender)::bpchar, k.owner) = (l.recipient)::bpchar)))
     FULL JOIN public.points_ninelives_creator_points_1 m ON (((COALESCE((a.address)::bpchar, (b.owner)::bpchar, (c.user_)::bpchar, (d.transaction_sender)::bpchar, (e.transaction_sender)::bpchar, (f.address)::bpchar, (g.transaction_sender)::bpchar, (h.user_address)::bpchar, (i.transaction_sender)::bpchar, (j.transaction_sender)::bpchar, k.owner, (l.recipient)::bpchar))::text = m.creator_address)))
     FULL JOIN public.points_purrstream_donation_points_1 n ON ((COALESCE((a.address)::bpchar, (b.owner)::bpchar, (c.user_)::bpchar, (d.transaction_sender)::bpchar, (e.transaction_sender)::bpchar, (f.address)::bpchar, (g.transaction_sender)::bpchar, (h.user_address)::bpchar, (i.transaction_sender)::bpchar, (j.transaction_sender)::bpchar, k.owner, (l.recipient)::bpchar, (m.creator_address)::bpchar) = (n.address)::bpchar)))
     FULL JOIN public.points_camelot_swap_points_7 o ON ((COALESCE((a.address)::bpchar, (b.owner)::bpchar, (c.user_)::bpchar, (d.transaction_sender)::bpchar, (e.transaction_sender)::bpchar, (f.address)::bpchar, (g.transaction_sender)::bpchar, (h.user_address)::bpchar, (i.transaction_sender)::bpchar, (j.transaction_sender)::bpchar, k.owner, (l.recipient)::bpchar, (m.creator_address)::bpchar, (n.address)::bpchar) = (o.transaction_sender)::bpchar)))
  ORDER BY (((((((((((((((COALESCE((a.points)::numeric, (0)::numeric) + COALESCE(b.sum, (0)::numeric)) + COALESCE(c.points_earned, (0)::numeric)) + COALESCE(d.points, (0)::numeric)) + COALESCE(e.points, (0)::numeric)) + COALESCE(f.points, (0)::numeric)) + COALESCE(g.points, (0)::numeric)) + (COALESCE(h.points, (0)::bigint))::numeric) + COALESCE(i.points, (0)::numeric)) + COALESCE(j.points, (0)::numeric)))::double precision + COALESCE(k.points_t, (0)::double precision)) + (COALESCE(l.points, (0)::numeric))::double precision) + (COALESCE(m.points, (0)::bigint))::double precision) + (COALESCE(n.points, (0)::bigint))::double precision) + (COALESCE(o.points, (0)::numeric))::double precision) DESC;


--
-- Name: points_undiscovered_debank_addresses_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_undiscovered_debank_addresses_1 AS
 SELECT a.address
   FROM ((public.points_all_addresses_1 a
     LEFT JOIN public.points_discovered_debank_balances_1 d ON (((d.address)::text = (a.address)::text)))
     LEFT JOIN public.points_discovered_debank_nobal_1 n ON (((n.address)::text = (a.address)::text)))
  WHERE ((d.address IS NULL) AND (n.address IS NULL));


--
-- Name: points_all_addresses_2; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_all_addresses_2 AS
 SELECT DISTINCT address
   FROM ( SELECT discord_usernames_1.address
           FROM public.discord_usernames_1
        UNION
         SELECT discord_usernames_2.address
           FROM public.discord_usernames_2
        UNION
         SELECT erc20_cache_1.address
           FROM public.erc20_cache_1
        UNION
         SELECT events_purrstream_donated.address
           FROM public.events_purrstream_donated
        UNION
         SELECT nfts_cache_not_tracked_1.pool_address
           FROM public.nfts_cache_not_tracked_1
          WHERE (nfts_cache_not_tracked_1.pool_address IS NOT NULL)
        UNION
         SELECT nfts_user_owned_1.user_address
           FROM public.nfts_user_owned_1
          WHERE (nfts_user_owned_1.user_address IS NOT NULL)
        UNION
         SELECT nfts_user_owned_1.token_address
           FROM public.nfts_user_owned_1
          WHERE (nfts_user_owned_1.token_address IS NOT NULL)
        UNION
         SELECT ninelives_events_address_fees_claimed.recipient
           FROM public.ninelives_events_address_fees_claimed
        UNION
         SELECT ninelives_events_address_fees_claimed.emitter_addr
           FROM public.ninelives_events_address_fees_claimed
        UNION
         SELECT ninelives_events_new_trading.address
           FROM public.ninelives_events_new_trading
        UNION
         SELECT ninelives_events_new_trading2.address
           FROM public.ninelives_events_new_trading2
        UNION
         SELECT ninelives_users_1.wallet_address
           FROM public.ninelives_users_1
        UNION
         SELECT points_achievements_grouped_1.address
           FROM public.points_achievements_grouped_1
          WHERE (points_achievements_grouped_1.address IS NOT NULL)
        UNION
         SELECT points_achievements_grouped_user_1.address
           FROM public.points_achievements_grouped_user_1
          WHERE (points_achievements_grouped_user_1.address IS NOT NULL)
        UNION
         SELECT points_achievements_leaderboard_1_return.address
           FROM public.points_achievements_leaderboard_1_return
        UNION
         SELECT points_achievements_leaderboard_return_1.address
           FROM public.points_achievements_leaderboard_return_1
        UNION
         SELECT points_achievements_received_1.address
           FROM public.points_achievements_received_1
        UNION
         SELECT points_achievements_received_2.address
           FROM public.points_achievements_received_2
        UNION
         SELECT points_all_addresses_1.address
           FROM public.points_all_addresses_1
          WHERE (points_all_addresses_1.address IS NOT NULL)
        UNION
         SELECT points_discovered_debank_balances_1.address
           FROM public.points_discovered_debank_balances_1
        UNION
         SELECT points_discovered_debank_nobal_1.address
           FROM public.points_discovered_debank_nobal_1
        UNION
         SELECT points_displayed_via_endpoint_1.address
           FROM public.points_displayed_via_endpoint_1
        UNION
         SELECT points_everything_1.address
           FROM public.points_everything_1
          WHERE (points_everything_1.address IS NOT NULL)
        UNION
         SELECT points_fly_staked_points_aggregated_1.address
           FROM public.points_fly_staked_points_aggregated_1
          WHERE (points_fly_staked_points_aggregated_1.address IS NOT NULL)
        UNION
         SELECT points_fly_staked_snapshot_1.address
           FROM public.points_fly_staked_snapshot_1
        UNION
         SELECT points_fly_staking_to_points_1.address
           FROM public.points_fly_staking_to_points_1
          WHERE (points_fly_staking_to_points_1.address IS NOT NULL)
        UNION
         SELECT points_layer3_cube_points_1.user_address
           FROM public.points_layer3_cube_points_1
          WHERE (points_layer3_cube_points_1.user_address IS NOT NULL)
        UNION
         SELECT points_ninelives_creator_points_1.creator_address
           FROM public.points_ninelives_creator_points_1
          WHERE (points_ninelives_creator_points_1.creator_address IS NOT NULL)
        UNION
         SELECT points_purrstream_donation_points_1.address
           FROM public.points_purrstream_donation_points_1
          WHERE (points_purrstream_donation_points_1.address IS NOT NULL)
        UNION
         SELECT points_staked_to_spn_1.address
           FROM public.points_staked_to_spn_1
        UNION
         SELECT points_testnet_addresses_1.address
           FROM public.points_testnet_addresses_1
        UNION
         SELECT points_undiscovered_debank_addresses_1.address
           FROM public.points_undiscovered_debank_addresses_1
          WHERE (points_undiscovered_debank_addresses_1.address IS NOT NULL)) rows;


--
-- Name: points_auth_bearer_tokens_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.points_auth_bearer_tokens_1 (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    expires_at timestamp without time zone DEFAULT (CURRENT_TIMESTAMP + '7 days'::interval) NOT NULL,
    authkey character varying DEFAULT md5((random())::text) NOT NULL,
    secretkey character varying NOT NULL
);


--
-- Name: points_auth_bearer_tokens_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.points_auth_bearer_tokens_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: points_auth_bearer_tokens_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.points_auth_bearer_tokens_1_id_seq OWNED BY public.points_auth_bearer_tokens_1.id;


--
-- Name: points_auth_powers_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.points_auth_powers_1 (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    secretkey character varying NOT NULL,
    role character varying NOT NULL
);


--
-- Name: points_auth_powers_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.points_auth_powers_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: points_auth_powers_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.points_auth_powers_1_id_seq OWNED BY public.points_auth_powers_1.id;


--
-- Name: points_auth_secret_keys_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.points_auth_secret_keys_1 (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    key character varying DEFAULT md5((random())::text) NOT NULL,
    email character varying NOT NULL
);


--
-- Name: points_auth_secret_keys_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.points_auth_secret_keys_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: points_auth_secret_keys_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.points_auth_secret_keys_1_id_seq OWNED BY public.points_auth_secret_keys_1.id;


--
-- Name: points_camelot_lp_points_2; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.points_camelot_lp_points_2 (
    id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    owner public.address NOT NULL,
    points_t double precision NOT NULL
);


--
-- Name: points_camelot_lp_points_2_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.points_camelot_lp_points_2_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: points_camelot_lp_points_2_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.points_camelot_lp_points_2_id_seq OWNED BY public.points_camelot_lp_points_2.id;


--
-- Name: points_camelot_lp_points_3; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_camelot_lp_points_3 AS
 WITH position_events AS (
         SELECT points_camelot_lp_positions_cleaned_1.transaction_hash,
            points_camelot_lp_positions_cleaned_1.block_number,
            points_camelot_lp_positions_cleaned_1.pool,
            points_camelot_lp_positions_cleaned_1.pos_id,
            points_camelot_lp_positions_cleaned_1.owner,
            points_camelot_lp_positions_cleaned_1.normalised_amount0,
            points_camelot_lp_positions_cleaned_1.normalised_amount1,
            points_camelot_lp_positions_cleaned_1.start_time,
            points_camelot_lp_positions_cleaned_1.end_time,
            points_camelot_lp_positions_cleaned_1.action_type,
            points_camelot_lp_positions_cleaned_1.is_position_closed,
            points_camelot_lp_positions_cleaned_1.duration_seconds,
            lead(points_camelot_lp_positions_cleaned_1.action_type) OVER (PARTITION BY points_camelot_lp_positions_cleaned_1.pos_id ORDER BY points_camelot_lp_positions_cleaned_1.block_number, points_camelot_lp_positions_cleaned_1.transaction_hash) AS next_action_type,
            lead(points_camelot_lp_positions_cleaned_1.start_time) OVER (PARTITION BY points_camelot_lp_positions_cleaned_1.pos_id ORDER BY points_camelot_lp_positions_cleaned_1.block_number, points_camelot_lp_positions_cleaned_1.transaction_hash) AS next_start_time,
            lead(points_camelot_lp_positions_cleaned_1.end_time) OVER (PARTITION BY points_camelot_lp_positions_cleaned_1.pos_id ORDER BY points_camelot_lp_positions_cleaned_1.block_number, points_camelot_lp_positions_cleaned_1.transaction_hash) AS next_end_time,
                CASE
                    WHEN ((points_camelot_lp_positions_cleaned_1.pool)::bpchar = '0x7fc956a5c0aef46aa25b8911f4cb4619cbb7d90f'::bpchar) THEN points_camelot_lp_positions_cleaned_1.normalised_amount1
                    WHEN ((points_camelot_lp_positions_cleaned_1.pool)::bpchar = '0xf401f9e336cd4fb11f33f4afa81c7a40cfabf26e'::bpchar) THEN points_camelot_lp_positions_cleaned_1.normalised_amount0
                    WHEN ((points_camelot_lp_positions_cleaned_1.pool)::bpchar = '0x2b4ea69870659de72e8fd6de086ad958a712349e'::bpchar) THEN points_camelot_lp_positions_cleaned_1.normalised_amount0
                    ELSE (0)::double precision
                END AS relevant_amount
           FROM public.points_camelot_lp_positions_cleaned_1
          WHERE ((points_camelot_lp_positions_cleaned_1.pool)::bpchar = ANY (ARRAY['0x7fc956a5c0aef46aa25b8911f4cb4619cbb7d90f'::bpchar, '0xf401f9e336cd4fb11f33f4afa81c7a40cfabf26e'::bpchar, '0x2b4ea69870659de72e8fd6de086ad958a712349e'::bpchar]))
        ), position_state AS (
         SELECT position_events.transaction_hash,
            position_events.block_number,
            position_events.pool,
            position_events.pos_id,
            position_events.owner,
            position_events.normalised_amount0,
            position_events.normalised_amount1,
            position_events.start_time,
            position_events.end_time,
            position_events.action_type,
            position_events.is_position_closed,
            position_events.duration_seconds,
            position_events.next_action_type,
            position_events.next_start_time,
            position_events.next_end_time,
            position_events.relevant_amount,
            sum(position_events.relevant_amount) OVER (PARTITION BY position_events.pos_id ORDER BY position_events.block_number, position_events.transaction_hash ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_state,
                CASE
                    WHEN ((position_events.relevant_amount < (0)::double precision) AND (position_events.is_position_closed = false)) THEN
                    CASE
                        WHEN (position_events.next_action_type = 'REMOVE'::text) THEN EXTRACT(epoch FROM (position_events.next_end_time - position_events.end_time))
                        WHEN (position_events.next_action_type = 'ADD'::text) THEN EXTRACT(epoch FROM (position_events.next_start_time - position_events.end_time))
                        ELSE NULL::numeric
                    END
                    ELSE position_events.duration_seconds
                END AS calculated_duration
           FROM position_events
        ), position_points AS (
         SELECT position_state.transaction_hash,
            position_state.block_number,
            position_state.pool,
            position_state.pos_id,
            position_state.owner,
            position_state.normalised_amount0,
            position_state.normalised_amount1,
            position_state.start_time,
            position_state.end_time,
            position_state.action_type,
            position_state.is_position_closed,
            position_state.duration_seconds,
            position_state.next_action_type,
            position_state.next_start_time,
            position_state.next_end_time,
            position_state.relevant_amount,
            position_state.running_state,
            position_state.calculated_duration,
                CASE
                    WHEN ((position_state.running_state <= (0)::double precision) OR (position_state.calculated_duration IS NULL)) THEN (0)::double precision
                    ELSE ((position_state.running_state * (position_state.calculated_duration)::double precision) * (0.00001)::double precision)
                END AS points
           FROM position_state
        )
 SELECT owner,
    sum(points) AS points_t
   FROM position_points
  GROUP BY owner
  ORDER BY (sum(points)) DESC;


--
-- Name: points_camelot_lp_points_diff; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_camelot_lp_points_diff AS
 SELECT COALESCE(t1.owner, (t2.owner)::bpchar) AS owner,
        CASE
            WHEN (t2.owner IS NULL) THEN t1.points_t
            WHEN (t1.owner IS NULL) THEN (0)::double precision
            ELSE GREATEST((0)::double precision, (t1.points_t - t2.points_t))
        END AS points_t
   FROM (public.points_camelot_lp_points_1 t1
     FULL JOIN public.points_camelot_lp_points_2 t2 ON ((t1.owner = (t2.owner)::bpchar)));


--
-- Name: points_camelot_lp_points_diff_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_camelot_lp_points_diff_1 AS
 SELECT COALESCE(t1.owner, (t2.owner)::bpchar) AS owner,
        CASE
            WHEN (t2.owner IS NULL) THEN t1.points_t
            WHEN (t1.owner IS NULL) THEN (0)::double precision
            ELSE GREATEST((0)::double precision, (t1.points_t - t2.points_t))
        END AS points_t
   FROM (public.points_camelot_lp_points_3 t1
     FULL JOIN public.points_camelot_lp_points_2 t2 ON ((t1.owner = (t2.owner)::bpchar)));


--
-- Name: points_camelot_pool_pair_cache_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.points_camelot_pool_pair_cache_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: points_camelot_pool_pair_cache_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.points_camelot_pool_pair_cache_1_id_seq OWNED BY public.points_camelot_pool_pair_cache_1.id;


--
-- Name: points_camelot_positions_over_time_2; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_camelot_positions_over_time_2 AS
 WITH liquidity_events AS (
         SELECT il.transaction_hash,
            il.block_number,
            il.pool,
            il.pos_id,
            il.emitter_addr AS owner,
            il.amount0,
            il.amount1,
            il.created_by AS start_time,
            NULL::timestamp without time zone AS end_time
           FROM public.camelot_events_camelot_increaseliquidity il
        UNION ALL
         SELECT dl.transaction_hash,
            dl.block_number,
            il.pool,
            dl.pos_id,
            dl.emitter_addr AS owner,
            (- (dl.amount0)::numeric) AS amount0,
            (- (dl.amount1)::numeric) AS amount1,
            NULL::timestamp without time zone AS start_time,
            dl.created_by AS end_time
           FROM (public.camelot_events_camelot_decreaseliquidity dl
             LEFT JOIN public.camelot_events_camelot_increaseliquidity il ON (((dl.pos_id)::numeric = (il.pos_id)::numeric)))
        UNION ALL
         SELECT tp.transaction_hash,
            tp.block_number,
            il.pool,
            tp.pos_id,
            tp.to_ AS owner,
            0 AS amount0,
            0 AS amount1,
            tp.created_by AS start_time,
            NULL::timestamp without time zone AS end_time
           FROM (public.camelot_events_camelot_transferposition tp
             LEFT JOIN public.camelot_events_camelot_increaseliquidity il ON (((tp.pos_id)::numeric = (il.pos_id)::numeric)))
        )
 SELECT le.transaction_hash,
    le.pool,
    ((le.amount0)::double precision / power((10)::double precision, (COALESCE(ec1.decimals, 18))::double precision)) AS normalised_amount0,
    ((le.amount1)::double precision / power((10)::double precision, (COALESCE(ec1.decimals, 18))::double precision)) AS normalised_amount1,
    le.start_time,
    COALESCE(le.end_time, now()) AS end_time,
    EXTRACT(epoch FROM (COALESCE(le.end_time, now()) - le.start_time)) AS duration_seconds
   FROM (((liquidity_events le
     LEFT JOIN public.points_camelot_pool_pair_cache_1 pc ON (((le.pool)::bpchar = (pc.pool)::bpchar)))
     LEFT JOIN public.erc20_cache_1 ec0 ON (((pc.token0)::bpchar = (ec0.address)::bpchar)))
     LEFT JOIN public.erc20_cache_1 ec1 ON (((pc.token1)::bpchar = (ec1.address)::bpchar)));


--
-- Name: points_camelot_swap_points_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_camelot_swap_points_1 AS
 WITH amounts AS (
         SELECT camelot_events_algebra_swap.transaction_sender,
            sum(
                CASE
                    WHEN (lower((camelot_events_algebra_swap.emitter_addr)::text) = '0x59aa3937cd09c11258e44720ce56093b5fe37939'::text) THEN ((abs((camelot_events_algebra_swap.amount0)::numeric) * (2)::numeric) / (1000000)::numeric)
                    WHEN (lower((camelot_events_algebra_swap.emitter_addr)::text) = '0x7fc956a5c0aef46aa25b8911f4cb4619cbb7d90f'::text) THEN ((abs((camelot_events_algebra_swap.amount1)::numeric) * (2)::numeric) / (1000000)::numeric)
                    WHEN (lower((camelot_events_algebra_swap.emitter_addr)::text) = '0xf401f9e336cd4fb11f33f4afa81c7a40cfabf26e'::text) THEN ((abs((camelot_events_algebra_swap.amount0)::numeric) * (2)::numeric) / (1000000)::numeric)
                    WHEN (lower((camelot_events_algebra_swap.emitter_addr)::text) = '0x2b4ea69870659de72e8fd6de086ad958a712349e'::text) THEN ((abs((camelot_events_algebra_swap.amount0)::numeric) * (2)::numeric) / (1000000)::numeric)
                    ELSE (0)::numeric
                END) AS total_amount
           FROM public.camelot_events_algebra_swap
          WHERE ((camelot_events_algebra_swap.transaction_sender IS NOT NULL) AND ((camelot_events_algebra_swap.transaction_sender)::bpchar <> ''::bpchar))
          GROUP BY camelot_events_algebra_swap.transaction_sender
        ), total AS (
         SELECT sum(amounts.total_amount) AS grand_total
           FROM amounts
        )
 SELECT a.transaction_sender,
    a.total_amount,
    round(((a.total_amount / t.grand_total) * (10000000)::numeric)) AS points
   FROM (amounts a
     CROSS JOIN total t)
  ORDER BY (round(((a.total_amount / t.grand_total) * (10000000)::numeric))) DESC;


--
-- Name: points_camelot_swap_points_8; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_camelot_swap_points_8 AS
 WITH amounts AS (
         SELECT camelot_events_algebra_swap.transaction_sender,
            sum(
                CASE
                    WHEN (lower((camelot_events_algebra_swap.emitter_addr)::text) = '0x59aa3937cd09c11258e44720ce56093b5fe37939'::text) THEN ((abs((camelot_events_algebra_swap.amount0)::numeric) * (2)::numeric) / (1000000)::numeric)
                    WHEN (lower((camelot_events_algebra_swap.emitter_addr)::text) = '0x7fc956a5c0aef46aa25b8911f4cb4619cbb7d90f'::text) THEN ((abs((camelot_events_algebra_swap.amount1)::numeric) * (2)::numeric) / (1000000)::numeric)
                    WHEN (lower((camelot_events_algebra_swap.emitter_addr)::text) = '0xf401f9e336cd4fb11f33f4afa81c7a40cfabf26e'::text) THEN ((abs((camelot_events_algebra_swap.amount0)::numeric) * (2)::numeric) / (1000000)::numeric)
                    WHEN (lower((camelot_events_algebra_swap.emitter_addr)::text) = '0x2b4ea69870659de72e8fd6de086ad958a712349e'::text) THEN ((abs((camelot_events_algebra_swap.amount0)::numeric) * (2)::numeric) / (1000000)::numeric)
                    ELSE (0)::numeric
                END) AS total_amount
           FROM public.camelot_events_algebra_swap
          WHERE ((camelot_events_algebra_swap.transaction_sender IS NOT NULL) AND ((camelot_events_algebra_swap.transaction_sender)::bpchar <> ''::bpchar) AND (camelot_events_algebra_swap.block_number > 2072156))
          GROUP BY camelot_events_algebra_swap.transaction_sender
        )
 SELECT transaction_sender,
    total_amount,
    round((total_amount * (100)::numeric)) AS points
   FROM amounts
  ORDER BY (round((total_amount * (100)::numeric))) DESC;


--
-- Name: points_camelot_swap_points_9; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_camelot_swap_points_9 AS
 WITH amounts AS (
         SELECT camelot_events_algebra_swap.transaction_sender,
            sum(
                CASE
                    WHEN (lower((camelot_events_algebra_swap.emitter_addr)::text) = '0x59aa3937cd09c11258e44720ce56093b5fe37939'::text) THEN ((abs((camelot_events_algebra_swap.amount0)::numeric) * (2)::numeric) / (1000000)::numeric)
                    WHEN (lower((camelot_events_algebra_swap.emitter_addr)::text) = '0x7fc956a5c0aef46aa25b8911f4cb4619cbb7d90f'::text) THEN ((abs((camelot_events_algebra_swap.amount1)::numeric) * (2)::numeric) / (1000000)::numeric)
                    WHEN (lower((camelot_events_algebra_swap.emitter_addr)::text) = '0xf401f9e336cd4fb11f33f4afa81c7a40cfabf26e'::text) THEN ((abs((camelot_events_algebra_swap.amount0)::numeric) * (2)::numeric) / (1000000)::numeric)
                    WHEN (lower((camelot_events_algebra_swap.emitter_addr)::text) = '0x2b4ea69870659de72e8fd6de086ad958a712349e'::text) THEN ((abs((camelot_events_algebra_swap.amount0)::numeric) * (2)::numeric) / (1000000)::numeric)
                    ELSE (0)::numeric
                END) AS total_amount
           FROM public.camelot_events_algebra_swap
          WHERE ((camelot_events_algebra_swap.transaction_sender IS NOT NULL) AND ((camelot_events_algebra_swap.transaction_sender)::bpchar <> ''::bpchar) AND (camelot_events_algebra_swap.block_number > 2072156))
          GROUP BY camelot_events_algebra_swap.transaction_sender
        )
 SELECT transaction_sender,
    total_amount,
    round((total_amount * (1)::numeric)) AS points
   FROM amounts
  ORDER BY (round((total_amount * (1)::numeric))) DESC;


--
-- Name: points_cgi_not_concluded_requested_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_cgi_not_concluded_requested_1 AS
 SELECT r.id,
    r.created_by,
    r.block_hash,
    r.transaction_hash,
    r.block_number,
    r.emitter_addr,
    r.trading,
    r.ticket,
    c.id AS campaign_id,
    encode(convert_to((c.content ->> 'name'::text), 'UTF8'::name), 'base64'::text) AS name,
    ((c.content ->> 'ending'::text))::bigint AS ending,
    encode(convert_to((c.content ->> 'outcomes'::text), 'UTF8'::name), 'base64'::text) AS outcomes,
    encode(convert_to((c.content ->> 'description'::text), 'UTF8'::name), 'base64'::text) AS description
   FROM ((public.ninelives_events_requested r
     LEFT JOIN public.ninelives_events_outcome_decided d ON (((r.trading)::bpchar = (d.emitter_addr)::bpchar)))
     LEFT JOIN public.ninelives_campaigns_1 c ON (((r.trading)::text = (c.content ->> 'poolAddress'::text))))
  WHERE (d.emitter_addr IS NULL);


--
-- Name: points_cgi_not_concluded_requested_2; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_cgi_not_concluded_requested_2 AS
 SELECT name,
    campaign_id,
    ending,
    outcomes,
    description,
    created_by
   FROM ( SELECT points_cgi_not_concluded_requested_1.name,
            points_cgi_not_concluded_requested_1.campaign_id,
            points_cgi_not_concluded_requested_1.ending,
            points_cgi_not_concluded_requested_1.outcomes,
            points_cgi_not_concluded_requested_1.description,
            points_cgi_not_concluded_requested_1.created_by,
            row_number() OVER (PARTITION BY points_cgi_not_concluded_requested_1.campaign_id ORDER BY points_cgi_not_concluded_requested_1.created_by DESC) AS rn
           FROM public.points_cgi_not_concluded_requested_1) ranked
  WHERE ((rn = 1) AND (length(name) > 1))
  ORDER BY created_by DESC;


--
-- Name: points_ninelives_manually_concluded_in_error_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.points_ninelives_manually_concluded_in_error_1 (
    id integer NOT NULL,
    pool public.address NOT NULL
);


--
-- Name: points_ninelives_unresolved_markets_have_ended_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_ninelives_unresolved_markets_have_ended_1 AS
 SELECT DISTINCT (ninelives_campaigns_1.content ->> 'poolAddress'::text) AS pool,
    (ninelives_campaigns_1.content ->> 'ending'::text) AS ending,
    (ninelives_campaigns_1.content ->> 'settlement'::text) AS settlement,
    t.oracle AS oracle_addr
   FROM (public.ninelives_campaigns_1
     LEFT JOIN public.ninelives_events_new_trading2 t ON (((t.address)::text = (ninelives_campaigns_1.content ->> 'poolAddress'::text))))
  WHERE ((NOT ((ninelives_campaigns_1.content ->> 'poolAddress'::text) IN ( SELECT DISTINCT ninelives_events_outcome_decided.emitter_addr
           FROM public.ninelives_events_outcome_decided))) AND (NOT ((ninelives_campaigns_1.content ->> 'poolAddress'::text) IN ( SELECT DISTINCT points_ninelives_manually_concluded_in_error_1.pool
           FROM public.points_ninelives_manually_concluded_in_error_1))) AND ((((ninelives_campaigns_1.content ->> 'ending'::text))::bigint)::numeric < EXTRACT(epoch FROM now())))
  GROUP BY (ninelives_campaigns_1.content ->> 'poolAddress'::text), t.oracle, (ninelives_campaigns_1.content ->> 'ending'::text), (ninelives_campaigns_1.content ->> 'settlement'::text);


--
-- Name: points_cgi_unresolved_markets_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_cgi_unresolved_markets_1 AS
 SELECT u.pool AS pool_address,
    encode(convert_to((c.content ->> 'name'::text), 'UTF8'::name), 'base64'::text) AS name,
    encode(convert_to((c.content ->> 'outcomes'::text), 'UTF8'::name), 'base64'::text) AS outcomes,
    c.id AS campaign_id,
    u.ending,
    u.settlement,
    u.oracle_addr,
    encode(convert_to((c.content ->> 'description'::text), 'UTF8'::name), 'base64'::text) AS description,
    (c.content -> 'categories'::text) AS categories,
    (c.content ->> 'creator'::text) AS creator,
    c.total_volume,
    c.created_at,
    c.updated_at
   FROM (public.points_ninelives_unresolved_markets_have_ended_1 u
     JOIN public.ninelives_campaigns_1 c ON ((u.pool = (c.content ->> 'poolAddress'::text))))
  WHERE (u.settlement = 'AI'::text)
  ORDER BY u.ending;


--
-- Name: points_cgi_unresolved_markets_2; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_cgi_unresolved_markets_2 AS
 SELECT u.pool_address,
    u.name,
    u.outcomes,
    u.campaign_id,
    u.ending,
    u.settlement,
    u.oracle_addr,
    u.description,
    u.categories,
    u.creator,
    u.total_volume,
    u.created_at,
    u.updated_at,
    (NULL::numeric)::public.hugeint AS ticket,
    (NULL::bpchar)::public.address AS trading,
    NULL::integer AS request_block_number,
    (NULL::bpchar)::public.hash AS request_block_hash,
    (NULL::bpchar)::public.hash AS request_transaction_hash,
    NULL::timestamp without time zone AS request_created_at,
    'market'::text AS source_type
   FROM public.points_cgi_unresolved_markets_1 u
  WHERE (NOT ((u.oracle_addr)::bpchar IN ( SELECT DISTINCT ninelives_events_outcome_decided.emitter_addr
           FROM public.ninelives_events_outcome_decided)))
UNION ALL
 SELECT NULL::text AS pool_address,
    NULL::text AS name,
    NULL::text AS outcomes,
    NULL::text AS campaign_id,
    NULL::text AS ending,
    NULL::text AS settlement,
    r.emitter_addr AS oracle_addr,
    NULL::text AS description,
    NULL::jsonb AS categories,
    NULL::text AS creator,
    NULL::numeric AS total_volume,
    NULL::timestamp without time zone AS created_at,
    NULL::timestamp without time zone AS updated_at,
    r.ticket,
    r.trading,
    r.block_number AS request_block_number,
    r.block_hash AS request_block_hash,
    r.transaction_hash AS request_transaction_hash,
    r.created_by AS request_created_at,
    'request'::text AS source_type
   FROM public.ninelives_events_requested r
  WHERE (NOT ((r.emitter_addr)::bpchar IN ( SELECT DISTINCT ninelives_events_outcome_decided.emitter_addr
           FROM public.ninelives_events_outcome_decided)))
  ORDER BY 7, 5;


--
-- Name: points_discovered_debank_balances_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.points_discovered_debank_balances_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: points_discovered_debank_balances_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.points_discovered_debank_balances_1_id_seq OWNED BY public.points_discovered_debank_balances_1.id;


--
-- Name: points_discovered_debank_nobal_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.points_discovered_debank_nobal_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: points_discovered_debank_nobal_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.points_discovered_debank_nobal_1_id_seq OWNED BY public.points_discovered_debank_nobal_1.id;


--
-- Name: points_displayed_via_endpoint_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.points_displayed_via_endpoint_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: points_displayed_via_endpoint_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.points_displayed_via_endpoint_1_id_seq OWNED BY public.points_displayed_via_endpoint_1.id;


--
-- Name: points_erc20_user_balances_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_erc20_user_balances_1 AS
 SELECT emitter_addr AS asset,
    address,
    (sum(value))::public.hugeint AS balance
   FROM ( SELECT events_erc20_transfer.emitter_addr,
            events_erc20_transfer.recipient AS address,
            events_erc20_transfer.value
           FROM public.events_erc20_transfer
        UNION ALL
         SELECT events_erc20_transfer.emitter_addr,
            events_erc20_transfer.sender AS address,
            (- (events_erc20_transfer.value)::numeric)
           FROM public.events_erc20_transfer) transfers
  GROUP BY emitter_addr, address;


--
-- Name: points_erc20_high_networth_users_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_erc20_high_networth_users_1 AS
 SELECT address
   FROM ( SELECT points_discovered_debank_balances_1.address,
            sum(points_discovered_debank_balances_1.asset_usd_value) AS total_usd_value
           FROM public.points_discovered_debank_balances_1
          GROUP BY points_discovered_debank_balances_1.address
         HAVING (sum(points_discovered_debank_balances_1.asset_usd_value) > (10000)::double precision)
        UNION
         SELECT points_erc20_user_balances_1.address,
            ((points_erc20_user_balances_1.balance)::numeric / '1000000'::numeric) AS total_usd_value
           FROM public.points_erc20_user_balances_1
          WHERE (((points_erc20_user_balances_1.asset)::bpchar = '0x6c030c5cc283f791b26816f325b9c632d964f8a1'::bpchar) AND (((points_erc20_user_balances_1.balance)::numeric / '1000000'::numeric) > (10000)::numeric))) combined_assets;


--
-- Name: points_fly_staked_points_aggregated_2; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.points_fly_staked_points_aggregated_2 (
    id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    address public.address NOT NULL,
    points public.hugeint NOT NULL
);


--
-- Name: points_fly_staked_points_aggregated_diff; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_fly_staked_points_aggregated_diff AS
 SELECT COALESCE(t1.address, t2.address) AS address,
        CASE
            WHEN (t2.address IS NULL) THEN (t1.points)::numeric
            WHEN (t1.address IS NULL) THEN (0)::numeric
            ELSE GREATEST((0)::numeric, ((t1.points)::numeric - (t2.points)::numeric))
        END AS points
   FROM (public.points_fly_staked_points_aggregated_1 t1
     FULL JOIN public.points_fly_staked_points_aggregated_2 t2 ON (((t1.address)::bpchar = (t2.address)::bpchar)));


--
-- Name: points_fly_staking_to_points_3; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_fly_staking_to_points_3 AS
 SELECT address,
    fly_converted,
    '2025-07-20'::date AS start_date,
    ((((fly_converted)::numeric * 0.000003) * EXTRACT(epoch FROM (CURRENT_TIMESTAMP - ('2025-07-20'::date)::timestamp with time zone))) / (1000)::numeric) AS points
   FROM public.points_fly_staking_to_points_1;


--
-- Name: points_ninelives_buys_points_3; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_ninelives_buys_points_3 AS
 SELECT recipient,
    (sum((from_amount)::numeric) / (1000000)::numeric) AS volume,
    ((sum((from_amount)::numeric) / (1000000)::numeric) * (1)::numeric) AS points
   FROM ( SELECT DISTINCT ninelives_buys_and_sells_1.transaction_hash,
            ninelives_buys_and_sells_1.recipient,
            ninelives_buys_and_sells_1.from_amount
           FROM public.ninelives_buys_and_sells_1
          WHERE (ninelives_buys_and_sells_1.created_by > '2025-07-20 00:00:00'::timestamp without time zone)) unique_transactions
  GROUP BY recipient
  ORDER BY (sum((from_amount)::numeric) / (1000000)::numeric) DESC;


--
-- Name: points_ninelives_creator_points_3; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_ninelives_creator_points_3 AS
 SELECT ((content -> 'creator'::text) ->> 'address'::text) AS creator_address,
    count(DISTINCT id) AS campaign_count,
    (count(DISTINCT id) * 5) AS points
   FROM public.ninelives_campaigns_1
  WHERE (created_at > '2025-07-20 00:00:00'::timestamp without time zone)
  GROUP BY ((content -> 'creator'::text) ->> 'address'::text)
  ORDER BY (count(DISTINCT id)) DESC;


--
-- Name: points_purrstream_donation_points_3; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_purrstream_donation_points_3 AS
 SELECT address,
    count(DISTINCT transaction_hash) AS unique_donation_count,
    (count(DISTINCT transaction_hash) * 1) AS points
   FROM public.events_purrstream_donated
  WHERE (block_number > 2072156)
  GROUP BY address
  ORDER BY (count(DISTINCT transaction_hash) * 1) DESC;


--
-- Name: points_everything_2; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_everything_2 AS
 SELECT COALESCE((a.address)::bpchar, (b.address)::bpchar, (c.transaction_sender)::bpchar, (d.recipient)::bpchar, (e.creator_address)::bpchar, (f.address)::bpchar, g.owner) AS address,
    (((((((COALESCE(a.points, (0)::numeric) + COALESCE(b.points, (0)::numeric)) + COALESCE(c.points, (0)::numeric)) + COALESCE(d.points, (0)::numeric)) + (COALESCE(e.points, (0)::bigint))::numeric) + (COALESCE(f.points, (0)::bigint))::numeric))::double precision + COALESCE(g.points_t, (0)::double precision)) AS total_points
   FROM ((((((public.points_fly_staked_points_aggregated_diff a
     FULL JOIN public.points_fly_staking_to_points_3 b ON (((a.address)::bpchar = (b.address)::bpchar)))
     FULL JOIN public.points_camelot_swap_points_9 c ON (((COALESCE(a.address, b.address))::bpchar = (c.transaction_sender)::bpchar)))
     FULL JOIN public.points_ninelives_buys_points_3 d ON (((COALESCE(a.address, b.address, c.transaction_sender))::bpchar = (d.recipient)::bpchar)))
     FULL JOIN public.points_ninelives_creator_points_3 e ON (((COALESCE(a.address, b.address, c.transaction_sender, d.recipient))::text = e.creator_address)))
     FULL JOIN public.points_purrstream_donation_points_3 f ON ((COALESCE((a.address)::bpchar, (b.address)::bpchar, (c.transaction_sender)::bpchar, (d.recipient)::bpchar, (e.creator_address)::bpchar) = (f.address)::bpchar)))
     FULL JOIN public.points_camelot_lp_points_diff g ON ((COALESCE((a.address)::bpchar, (b.address)::bpchar, (c.transaction_sender)::bpchar, (d.recipient)::bpchar, (e.creator_address)::bpchar, (f.address)::bpchar) = g.owner)))
  ORDER BY (((((((COALESCE(a.points, (0)::numeric) + COALESCE(b.points, (0)::numeric)) + COALESCE(c.points, (0)::numeric)) + COALESCE(d.points, (0)::numeric)) + (COALESCE(e.points, (0)::bigint))::numeric) + (COALESCE(f.points, (0)::bigint))::numeric))::double precision + COALESCE(g.points_t, (0)::double precision)) DESC;


--
-- Name: points_supawsotition_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.points_supawsotition_1 (
    id integer NOT NULL,
    updated_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    address character varying NOT NULL,
    points integer NOT NULL
);


--
-- Name: points_everything_2_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_everything_2_1 AS
 SELECT COALESCE((a.address)::bpchar, (b.address)::bpchar, (c.transaction_sender)::bpchar, (d.recipient)::bpchar, (e.creator_address)::bpchar, (f.address)::bpchar, g.owner, (h.address)::bpchar) AS address,
    ((((((((COALESCE(a.points, (0)::numeric) + COALESCE(b.points, (0)::numeric)) + COALESCE(c.points, (0)::numeric)) + COALESCE(d.points, (0)::numeric)) + (COALESCE(e.points, (0)::bigint))::numeric) + (COALESCE(f.points, (0)::bigint))::numeric))::double precision + COALESCE(g.points_t, (0)::double precision)) + (COALESCE(h.points, 0))::double precision) AS total_points
   FROM (((((((public.points_fly_staked_points_aggregated_diff a
     FULL JOIN public.points_fly_staking_to_points_3 b ON (((a.address)::bpchar = (b.address)::bpchar)))
     FULL JOIN public.points_camelot_swap_points_9 c ON (((COALESCE(a.address, b.address))::bpchar = (c.transaction_sender)::bpchar)))
     FULL JOIN public.points_ninelives_buys_points_3 d ON (((COALESCE(a.address, b.address, c.transaction_sender))::bpchar = (d.recipient)::bpchar)))
     FULL JOIN public.points_ninelives_creator_points_3 e ON (((COALESCE(a.address, b.address, c.transaction_sender, d.recipient))::text = e.creator_address)))
     FULL JOIN public.points_purrstream_donation_points_3 f ON ((COALESCE((a.address)::bpchar, (b.address)::bpchar, (c.transaction_sender)::bpchar, (d.recipient)::bpchar, (e.creator_address)::bpchar) = (f.address)::bpchar)))
     FULL JOIN public.points_camelot_lp_points_diff_1 g ON ((COALESCE((a.address)::bpchar, (b.address)::bpchar, (c.transaction_sender)::bpchar, (d.recipient)::bpchar, (e.creator_address)::bpchar, (f.address)::bpchar) = g.owner)))
     FULL JOIN public.points_supawsotition_1 h ON ((COALESCE((a.address)::bpchar, (b.address)::bpchar, (c.transaction_sender)::bpchar, (d.recipient)::bpchar, (e.creator_address)::bpchar, (f.address)::bpchar, g.owner) = (h.address)::bpchar)))
  ORDER BY ((((((((COALESCE(a.points, (0)::numeric) + COALESCE(b.points, (0)::numeric)) + COALESCE(c.points, (0)::numeric)) + COALESCE(d.points, (0)::numeric)) + (COALESCE(e.points, (0)::bigint))::numeric) + (COALESCE(f.points, (0)::bigint))::numeric))::double precision + COALESCE(g.points_t, (0)::double precision)) + (COALESCE(h.points, 0))::double precision) DESC;


--
-- Name: points_everything_without_fly; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.points_everything_without_fly (
    address bpchar,
    non_fly_staked_points double precision
);


--
-- Name: points_fly_staked_points_aggregated_s1_2; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_fly_staked_points_aggregated_s1_2 AS
 SELECT COALESCE(t1.address, t2.address) AS address,
        CASE
            WHEN (t2.address IS NULL) THEN (0)::numeric
            WHEN (t1.address IS NULL) THEN (0)::numeric
            WHEN ((t1.points)::numeric > (t2.points)::numeric) THEN (t2.points)::numeric
            WHEN ((t2.points)::numeric > (t1.points)::numeric) THEN (t1.points)::numeric
            ELSE (t2.points)::numeric
        END AS points
   FROM (public.points_fly_staked_points_aggregated_1 t1
     FULL JOIN public.points_fly_staked_points_aggregated_2 t2 ON (((t1.address)::bpchar = (t2.address)::bpchar)));


--
-- Name: points_everything_season_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_everything_season_1 AS
 SELECT COALESCE(pf.address, (a.address)::bpchar) AS address,
    (COALESCE(pf.non_fly_staked_points, (0)::double precision) + (COALESCE(a.points, (0)::numeric))::double precision) AS total_points
   FROM (public.points_everything_without_fly pf
     FULL JOIN public.points_fly_staked_points_aggregated_s1_2 a ON ((pf.address = (a.address)::bpchar)))
  ORDER BY (COALESCE(pf.non_fly_staked_points, (0)::double precision) + (COALESCE(a.points, (0)::numeric))::double precision) DESC;


--
-- Name: points_everything_static_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.points_everything_static_1 (
    id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    address public.address NOT NULL,
    total_points double precision NOT NULL
);


--
-- Name: points_everything_static_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.points_everything_static_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: points_everything_static_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.points_everything_static_1_id_seq OWNED BY public.points_everything_static_1.id;


--
-- Name: points_fly_staked_points_aggregated_2_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.points_fly_staked_points_aggregated_2_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: points_fly_staked_points_aggregated_2_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.points_fly_staked_points_aggregated_2_id_seq OWNED BY public.points_fly_staked_points_aggregated_2.id;


--
-- Name: points_fly_staked_points_aggregated_s1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_fly_staked_points_aggregated_s1 AS
 SELECT COALESCE(t1.address, t2.address) AS address,
        CASE
            WHEN (t2.address IS NULL) THEN (0)::numeric
            WHEN (t1.address IS NULL) THEN (0)::numeric
            WHEN ((t1.points)::numeric > (t2.points)::numeric) THEN (t2.points)::numeric
            ELSE (0)::numeric
        END AS points
   FROM (public.points_fly_staked_points_aggregated_1 t1
     FULL JOIN public.points_fly_staked_points_aggregated_2 t2 ON (((t1.address)::bpchar = (t2.address)::bpchar)));


--
-- Name: points_fly_staked_seconds_since_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_fly_staked_seconds_since_1 AS
 WITH stake_events AS (
         SELECT fly_stakers_fly_staked_1.id,
            fly_stakers_fly_staked_1.spender,
            fly_stakers_fly_staked_1.amount,
            fly_stakers_fly_staked_1.position_made AS staked_at
           FROM public.fly_stakers_fly_staked_1
        ), unstake_events AS (
         SELECT fly_stakers_fly_unstaked_1.id,
            fly_stakers_fly_unstaked_1.spender,
            fly_stakers_fly_unstaked_1.amount,
            fly_stakers_fly_unstaked_1.position_closed AS unstaked_at
           FROM public.fly_stakers_fly_unstaked_1
        ), position_changes AS (
         SELECT s.spender,
            s.staked_at,
            COALESCE((lag(u.unstaked_at) OVER (PARTITION BY s.spender ORDER BY u.unstaked_at))::timestamp with time zone, CURRENT_TIMESTAMP) AS unstaked_at,
            LEAST((s.amount)::numeric, COALESCE((u.amount)::numeric, (0)::numeric)) AS withdrawn_amount,
            GREATEST((0)::numeric, ((s.amount)::numeric - COALESCE((u.amount)::numeric, (0)::numeric))) AS remaining_amount
           FROM (stake_events s
             LEFT JOIN unstake_events u ON ((((s.spender)::bpchar = (u.spender)::bpchar) AND (u.unstaked_at >= s.staked_at))))
        )
 SELECT spender,
    staked_at,
    unstaked_at,
    withdrawn_amount,
    remaining_amount,
    EXTRACT(epoch FROM (unstaked_at - (staked_at)::timestamp with time zone)) AS duration_seconds
   FROM position_changes;


--
-- Name: points_fly_staked_snapshot_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.points_fly_staked_snapshot_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: points_fly_staked_snapshot_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.points_fly_staked_snapshot_1_id_seq OWNED BY public.points_fly_staked_snapshot_1.id;


--
-- Name: points_fly_staking_to_points_2; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_fly_staking_to_points_2 AS
 SELECT address,
    fly_converted,
    start_date,
    (points / 1000.0) AS points
   FROM public.points_fly_staking_to_points_1;


--
-- Name: points_galxe_camelot_24h_swap_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_galxe_camelot_24h_swap_1 AS
 SELECT transaction_sender,
    transaction_hash,
    emitter_addr,
    created_by,
        CASE
            WHEN (lower((emitter_addr)::text) = '0x59aa3937cd09c11258e44720ce56093b5fe37939'::text) THEN ((abs((amount0)::numeric) * (2)::numeric) / (1000000)::numeric)
            WHEN (lower((emitter_addr)::text) = '0x7fc956a5c0aef46aa25b8911f4cb4619cbb7d90f'::text) THEN ((abs((amount1)::numeric) * (2)::numeric) / (1000000)::numeric)
            WHEN (lower((emitter_addr)::text) = '0xf401f9e336cd4fb11f33f4afa81c7a40cfabf26e'::text) THEN ((abs((amount0)::numeric) * (2)::numeric) / (1000000)::numeric)
            WHEN (lower((emitter_addr)::text) = '0x2b4ea69870659de72e8fd6de086ad958a712349e'::text) THEN ((abs((amount0)::numeric) * (2)::numeric) / (1000000)::numeric)
            ELSE (0)::numeric
        END AS amount
   FROM public.camelot_events_algebra_swap
  WHERE ((transaction_sender IS NOT NULL) AND ((transaction_sender)::bpchar <> ''::bpchar) AND (created_by >= (now() - '1 day'::interval)) AND (
        CASE
            WHEN (lower((emitter_addr)::text) = '0x59aa3937cd09c11258e44720ce56093b5fe37939'::text) THEN ((abs((amount0)::numeric) * (2)::numeric) / (1000000)::numeric)
            WHEN (lower((emitter_addr)::text) = '0x7fc956a5c0aef46aa25b8911f4cb4619cbb7d90f'::text) THEN ((abs((amount1)::numeric) * (2)::numeric) / (1000000)::numeric)
            WHEN (lower((emitter_addr)::text) = '0xf401f9e336cd4fb11f33f4afa81c7a40cfabf26e'::text) THEN ((abs((amount0)::numeric) * (2)::numeric) / (1000000)::numeric)
            WHEN (lower((emitter_addr)::text) = '0x2b4ea69870659de72e8fd6de086ad958a712349e'::text) THEN ((abs((amount0)::numeric) * (2)::numeric) / (1000000)::numeric)
            ELSE (0)::numeric
        END > (10)::numeric))
  ORDER BY
        CASE
            WHEN (lower((emitter_addr)::text) = '0x59aa3937cd09c11258e44720ce56093b5fe37939'::text) THEN ((abs((amount0)::numeric) * (2)::numeric) / (1000000)::numeric)
            WHEN (lower((emitter_addr)::text) = '0x7fc956a5c0aef46aa25b8911f4cb4619cbb7d90f'::text) THEN ((abs((amount1)::numeric) * (2)::numeric) / (1000000)::numeric)
            WHEN (lower((emitter_addr)::text) = '0xf401f9e336cd4fb11f33f4afa81c7a40cfabf26e'::text) THEN ((abs((amount0)::numeric) * (2)::numeric) / (1000000)::numeric)
            WHEN (lower((emitter_addr)::text) = '0x2b4ea69870659de72e8fd6de086ad958a712349e'::text) THEN ((abs((amount0)::numeric) * (2)::numeric) / (1000000)::numeric)
            ELSE (0)::numeric
        END DESC, created_by DESC;


--
-- Name: points_galxe_camelot_lp_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_galxe_camelot_lp_1 AS
 SELECT owner,
    transaction_hash,
    normalised_amount0,
    normalised_amount1,
    start_time
   FROM public.points_camelot_lp_positions_cleaned_1
  WHERE ((action_type = 'ADD'::text) AND ((((pool)::bpchar = ANY (ARRAY['0x2b4ea69870659de72e8fd6de086ad958a712349e'::bpchar, '0xf401f9e336cd4fb11f33f4afa81c7a40cfabf26e'::bpchar, '0x59aa3937cd09c11258e44720ce56093b5fe37939'::bpchar])) AND (normalised_amount0 >= (10)::double precision)) OR (((pool)::bpchar = '0x7fc956a5c0aef46aa25b8911f4cb4619cbb7d90f'::bpchar) AND (normalised_amount1 >= (10)::double precision))) AND (start_time > '2025-06-08 00:00:00+00'::timestamp with time zone));


--
-- Name: points_galxe_camelot_swaps_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_galxe_camelot_swaps_1 AS
 SELECT transaction_sender
   FROM public.camelot_events_algebra_swap
  WHERE (created_by > '2025-06-08 00:00:00+00'::timestamp with time zone);


--
-- Name: points_galxe_camelot_swaps_2; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_galxe_camelot_swaps_2 AS
 SELECT lower((transaction_sender)::text) AS transaction_sender
   FROM public.camelot_events_algebra_swap
  WHERE (created_by > '2025-06-08 00:00:00+00'::timestamp with time zone);


--
-- Name: points_galxe_camelot_swaps_3; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_galxe_camelot_swaps_3 AS
 SELECT lower((transaction_sender)::text) AS transaction_sender
   FROM public.camelot_events_algebra_swap
  WHERE ((created_by > '2025-09-23 00:00:00+00'::timestamp with time zone) AND (((emitter_addr)::bpchar = '0x10b97a196ac7670694383303db508df70c0cd836'::bpchar) OR ((emitter_addr)::bpchar = '0x2b4ea69870659de72e8fd6de086ad958a712349e'::bpchar) OR ((emitter_addr)::bpchar = '0x59aa3937cd09c11258e44720ce56093b5fe37939'::bpchar) OR ((emitter_addr)::bpchar = '0x5dcfef826b3b7cfd1263d33595a0bcb7b7ad188a'::bpchar) OR ((emitter_addr)::bpchar = '0x7fc956a5c0aef46aa25b8911f4cb4619cbb7d90f'::bpchar) OR ((emitter_addr)::bpchar = '0xf401f9e336cd4fb11f33f4afa81c7a40cfabf26e'::bpchar)));


--
-- Name: points_galxe_confirmed_bridge_to_spn_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.points_galxe_confirmed_bridge_to_spn_1 (
    id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    owner public.address NOT NULL,
    is_swap boolean DEFAULT false NOT NULL
);


--
-- Name: points_galxe_confirmed_bridge_to_spn_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.points_galxe_confirmed_bridge_to_spn_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: points_galxe_confirmed_bridge_to_spn_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.points_galxe_confirmed_bridge_to_spn_1_id_seq OWNED BY public.points_galxe_confirmed_bridge_to_spn_1.id;


--
-- Name: points_galxe_copass_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_galxe_copass_1 AS
 SELECT user_address
   FROM public.nfts_user_owned_1
  WHERE (((token_address)::bpchar = '0x6c6b030c5dfb4dcea42ffedd4ec7a48f3ac41d04'::bpchar) OR ((token_address)::bpchar = '0xbd382382ceac5cf5940933c00d4dff150f949d86'::bpchar) OR ((token_address)::bpchar = '0xf4e5e538c1e56bd45bada4d7e07c4602d8432725'::bpchar) OR ((token_address)::bpchar = '0x0c33e3f070724f6a90191b397281d785425f7247'::bpchar));


--
-- Name: stargate_events_stargate_oft_received; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stargate_events_stargate_oft_received (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    guid public.bytes32 NOT NULL,
    src_eid integer NOT NULL,
    to_address public.address NOT NULL,
    amount_received_ld public.hugeint NOT NULL
);


--
-- Name: points_galxe_mint_orbeth_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_galxe_mint_orbeth_1 AS
 SELECT id,
    created_by,
    block_hash,
    transaction_hash,
    block_number,
    emitter_addr,
    guid,
    src_eid,
    to_address,
    amount_received_ld
   FROM public.stargate_events_stargate_oft_received
  WHERE (((emitter_addr)::bpchar = '0xcee9b58c2cdb01b8bf75a27e96ec09bf885ef55a'::bpchar) AND ((amount_received_ld)::numeric >= ('1000000000000000'::bigint)::numeric) AND (created_by >= '2025-06-23 00:00:00'::timestamp without time zone))
  ORDER BY created_by DESC;


--
-- Name: points_galxe_nomis_mints_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_galxe_nomis_mints_1 AS
 SELECT user_address
   FROM public.nfts_user_owned_1
  WHERE ((token_address)::bpchar = '0x46874edd92d5a33216fe2e151759ead76ff43747'::bpchar);


--
-- Name: points_galxe_nonon_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_galxe_nonon_1 AS
 SELECT user_address
   FROM public.nfts_user_owned_1
  WHERE ((token_address)::bpchar = '0xb2fdbc2d3dc2b66d4dc1ea5aa8724daea21d1cd8'::bpchar);


--
-- Name: points_galxe_orbeth_camelot; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_galxe_orbeth_camelot AS
 SELECT transaction_hash,
    block_number,
    pool,
    pos_id,
    owner,
    normalised_amount0,
    normalised_amount1,
    start_time,
    end_time,
    action_type,
    is_position_closed,
    duration_seconds
   FROM public.points_camelot_lp_positions_cleaned_1
  WHERE (((pool)::bpchar = '0xc444d2219a7c6e39ffe467c2bfb6415060dc499c'::bpchar) AND (normalised_amount1 >= (0.001)::double precision) AND (start_time > '2025-06-22 00:00:00+00'::timestamp with time zone));


--
-- Name: points_galxe_pending_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.points_galxe_pending_1 (
    id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    owner public.address NOT NULL,
    transaction_id public.bytes32 NOT NULL,
    was_found boolean DEFAULT false
);


--
-- Name: points_galxe_pending_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.points_galxe_pending_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: points_galxe_pending_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.points_galxe_pending_1_id_seq OWNED BY public.points_galxe_pending_1.id;


--
-- Name: points_galxe_purrstream_donated_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_galxe_purrstream_donated_1 AS
 SELECT address
   FROM public.events_purrstream_donated
  WHERE (created_by > '2025-06-15 00:00:00+00'::timestamp with time zone);


--
-- Name: vendor_events_borrow; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vendor_events_borrow (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    borrower public.address NOT NULL,
    vendor_fees public.hugeint NOT NULL,
    lender_fees public.hugeint NOT NULL,
    borrow_rate integer NOT NULL,
    additional_col_amount public.hugeint NOT NULL,
    additional_debt public.hugeint NOT NULL
);


--
-- Name: points_galxe_vendor_borrow_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_galxe_vendor_borrow_1 AS
 SELECT id,
    created_by,
    block_hash,
    transaction_hash,
    block_number,
    emitter_addr,
    borrower,
    vendor_fees,
    lender_fees,
    borrow_rate,
    additional_col_amount,
    additional_debt
   FROM public.vendor_events_borrow
  WHERE (((emitter_addr)::bpchar = '0x389dbaad12259f5865b63c52eb254ed9231e5476'::bpchar) AND ((additional_col_amount)::numeric >= ('1000000000000000'::bigint)::numeric));


--
-- Name: points_hackathon_config_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.points_hackathon_config_1 (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    distribute_amt public.hugeint NOT NULL,
    enabled boolean DEFAULT false NOT NULL
);


--
-- Name: points_hackathon_config_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.points_hackathon_config_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: points_hackathon_config_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.points_hackathon_config_1_id_seq OWNED BY public.points_hackathon_config_1.id;


--
-- Name: points_hackathon_faucet_to_receive_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.points_hackathon_faucet_to_receive_1 (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    telegram character varying NOT NULL,
    project character varying NOT NULL,
    recipient public.address NOT NULL,
    was_sent boolean DEFAULT false NOT NULL
);


--
-- Name: points_hackathon_faucet_to_receive_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.points_hackathon_faucet_to_receive_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: points_hackathon_faucet_to_receive_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.points_hackathon_faucet_to_receive_1_id_seq OWNED BY public.points_hackathon_faucet_to_receive_1.id;


--
-- Name: points_has_used_simple_mode_5_times; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_has_used_simple_mode_5_times AS
 SELECT recipient
   FROM ( SELECT ninelives_events_ninetails_boosted_shares_received.recipient,
            count(1) AS c
           FROM public.ninelives_events_ninetails_boosted_shares_received
          GROUP BY ninelives_events_ninetails_boosted_shares_received.recipient) unnamed_subquery
  WHERE (c >= 5);


--
-- Name: points_kaito_yapper_7d_leaderboard_updates_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.points_kaito_yapper_7d_leaderboard_updates_1 (
    id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    content jsonb NOT NULL
);


--
-- Name: points_kaito_yapper_7d_leaderboard_updates_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.points_kaito_yapper_7d_leaderboard_updates_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: points_kaito_yapper_7d_leaderboard_updates_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.points_kaito_yapper_7d_leaderboard_updates_1_id_seq OWNED BY public.points_kaito_yapper_7d_leaderboard_updates_1.id;


--
-- Name: points_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.points_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: points_ninelives_buys_points_2; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_ninelives_buys_points_2 AS
 SELECT recipient,
    (sum((from_amount)::numeric) / (1000000)::numeric) AS volume,
    ((sum((from_amount)::numeric) / (1000000)::numeric) * (10)::numeric) AS points
   FROM ( SELECT DISTINCT ninelives_buys_and_sells_1.transaction_hash,
            ninelives_buys_and_sells_1.recipient,
            ninelives_buys_and_sells_1.from_amount
           FROM public.ninelives_buys_and_sells_1
          WHERE (ninelives_buys_and_sells_1.created_by > '2025-07-20 00:00:00'::timestamp without time zone)) unique_transactions
  GROUP BY recipient
  ORDER BY (sum((from_amount)::numeric) / (1000000)::numeric) DESC;


--
-- Name: points_ninelives_creator_points_2; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_ninelives_creator_points_2 AS
 SELECT ((content -> 'creator'::text) ->> 'address'::text) AS creator_address,
    count(DISTINCT id) AS campaign_count,
    (count(DISTINCT id) * 100) AS points
   FROM public.ninelives_campaigns_1
  WHERE (created_at > '2025-07-20 00:00:00'::timestamp without time zone)
  GROUP BY ((content -> 'creator'::text) ->> 'address'::text)
  ORDER BY (count(DISTINCT id)) DESC;


--
-- Name: points_ninelives_emails_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_ninelives_emails_1 AS
 SELECT DISTINCT email
   FROM public.ninelives_users_1
  WHERE (email IS NOT NULL);


--
-- Name: points_ninelives_manually_concluded_in_error_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.points_ninelives_manually_concluded_in_error_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: points_ninelives_manually_concluded_in_error_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.points_ninelives_manually_concluded_in_error_1_id_seq OWNED BY public.points_ninelives_manually_concluded_in_error_1.id;


--
-- Name: points_ninelives_per_campaign_volume_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_ninelives_per_campaign_volume_1 AS
 SELECT sum((from_amount)::numeric) AS sum,
    campaign_id,
    from_symbol
   FROM public.ninelives_buys_and_sells_1
  GROUP BY campaign_id, from_symbol;


--
-- Name: points_ninelives_total_campaign_volume_fusdc_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_ninelives_total_campaign_volume_fusdc_1 AS
 SELECT (sum(sum) / '1000000'::numeric) AS "?column?"
   FROM public.points_ninelives_per_campaign_volume_1
  WHERE ((from_symbol)::text = 'fUSDC'::text);


--
-- Name: points_ninelives_unresolved_markets_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_ninelives_unresolved_markets_1 AS
 SELECT DISTINCT (ninelives_campaigns_1.content ->> 'poolAddress'::text) AS pool,
    (ninelives_campaigns_1.content ->> 'ending'::text) AS ending,
    (ninelives_campaigns_1.content ->> 'settlement'::text) AS settlement,
    t.oracle AS oracle_addr
   FROM (public.ninelives_campaigns_1
     LEFT JOIN public.ninelives_events_new_trading2 t ON (((t.address)::text = (ninelives_campaigns_1.content ->> 'poolAddress'::text))))
  WHERE ((NOT ((ninelives_campaigns_1.content ->> 'poolAddress'::text) IN ( SELECT DISTINCT ninelives_events_outcome_decided.emitter_addr
           FROM public.ninelives_events_outcome_decided))) AND (NOT ((ninelives_campaigns_1.content ->> 'poolAddress'::text) IN ( SELECT DISTINCT points_ninelives_manually_concluded_in_error_1.pool
           FROM public.points_ninelives_manually_concluded_in_error_1))))
  GROUP BY (ninelives_campaigns_1.content ->> 'poolAddress'::text), t.oracle, (ninelives_campaigns_1.content ->> 'ending'::text), (ninelives_campaigns_1.content ->> 'settlement'::text);


--
-- Name: points_ninelives_volume_per_user_fusdc_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_ninelives_volume_per_user_fusdc_1 AS
 SELECT (sum((from_amount)::numeric) / '1000000'::numeric) AS sum,
    recipient
   FROM public.ninelives_buys_and_sells_1
  WHERE ((from_symbol)::text = 'fUSDC'::text)
  GROUP BY recipient;


--
-- Name: points_not_high_networth_users_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_not_high_networth_users_1 AS
 SELECT DISTINCT address
   FROM ( SELECT points_discovered_debank_balances_1.address
           FROM public.points_discovered_debank_balances_1
          GROUP BY points_discovered_debank_balances_1.address
         HAVING (sum(points_discovered_debank_balances_1.asset_usd_value) <= (10000)::double precision)
        UNION
         SELECT points_erc20_user_balances_1.address
           FROM public.points_erc20_user_balances_1
          WHERE (((points_erc20_user_balances_1.asset)::bpchar = '0x6c030c5cc283f791b26816f325b9c632d964f8a1'::bpchar) AND (((points_erc20_user_balances_1.balance)::numeric / '1000000'::numeric) <= (10000)::numeric))) combined_assets;


--
-- Name: points_og_badge_transaction_count_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.points_og_badge_transaction_count_1 (
    address public.address NOT NULL,
    row_count integer NOT NULL
);


--
-- Name: points_purrstream_donation_points_2; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_purrstream_donation_points_2 AS
 SELECT address,
    count(DISTINCT transaction_hash) AS unique_donation_count,
    (count(DISTINCT transaction_hash) * 10) AS points
   FROM public.events_purrstream_donated
  WHERE (block_number > 2072156)
  GROUP BY address
  ORDER BY (count(DISTINCT transaction_hash) * 10) DESC;


--
-- Name: points_staked_to_spn_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.points_staked_to_spn_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: points_staked_to_spn_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.points_staked_to_spn_1_id_seq OWNED BY public.points_staked_to_spn_1.id;


--
-- Name: points_supawsotition_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.points_supawsotition_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: points_supawsotition_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.points_supawsotition_1_id_seq OWNED BY public.points_supawsotition_1.id;


--
-- Name: points_swaps_consolidated_2; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_swaps_consolidated_2 AS
 SELECT s.id,
    s.created_by,
    s.block_hash,
    s.transaction_hash,
    s.block_number,
    s.emitter_addr,
    s.user_,
    s.from_,
    s.to_,
    s.amount_in,
    s.amount_out,
    s.fluid_volume,
    s.final_tick0,
    s.final_tick1,
    f.decimals AS from_decimals,
    t.decimals AS to_decimals
   FROM ((( SELECT events_seawater_swap1.id,
            events_seawater_swap1.created_by,
            events_seawater_swap1.block_hash,
            events_seawater_swap1.transaction_hash,
            events_seawater_swap1.block_number,
            events_seawater_swap1.emitter_addr,
            events_seawater_swap1.user_,
                CASE
                    WHEN (NOT events_seawater_swap1.zero_for_one) THEN '0xa8ea92c819463efbeddfb670fefc881a480f0115'::bpchar
                    ELSE (events_seawater_swap1.pool)::bpchar
                END AS from_,
                CASE
                    WHEN (NOT events_seawater_swap1.zero_for_one) THEN (events_seawater_swap1.pool)::bpchar
                    ELSE '0xa8ea92c819463efbeddfb670fefc881a480f0115'::bpchar
                END AS to_,
                CASE
                    WHEN (NOT events_seawater_swap1.zero_for_one) THEN events_seawater_swap1.amount1
                    ELSE events_seawater_swap1.amount0
                END AS amount_in,
                CASE
                    WHEN (NOT events_seawater_swap1.zero_for_one) THEN events_seawater_swap1.amount0
                    ELSE events_seawater_swap1.amount1
                END AS amount_out,
            (NULL::numeric)::public.hugeint AS fluid_volume,
            events_seawater_swap1.final_tick AS final_tick0,
            NULL::bigint AS final_tick1
           FROM public.events_seawater_swap1
        UNION ALL
         SELECT events_seawater_swap2.id,
            events_seawater_swap2.created_by,
            events_seawater_swap2.block_hash,
            events_seawater_swap2.transaction_hash,
            events_seawater_swap2.block_number,
            events_seawater_swap2.emitter_addr,
            events_seawater_swap2.user_,
            events_seawater_swap2.from_,
            events_seawater_swap2.to_,
            events_seawater_swap2.amount_in,
            events_seawater_swap2.amount_out,
            events_seawater_swap2.fluid_volume,
            events_seawater_swap2.final_tick0,
            events_seawater_swap2.final_tick1
           FROM public.events_seawater_swap2) s
     LEFT JOIN public.erc20_cache_1 f ON ((s.from_ = (f.address)::bpchar)))
     LEFT JOIN public.erc20_cache_1 t ON ((s.to_ = (t.address)::bpchar)));


--
-- Name: points_testnet_addresses_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.points_testnet_addresses_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: points_testnet_addresses_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.points_testnet_addresses_1_id_seq OWNED BY public.points_testnet_addresses_1.id;


--
-- Name: points_testnet_hackathon_ingestor_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.points_testnet_hackathon_ingestor_1 (
    id integer NOT NULL,
    last_updated timestamp without time zone NOT NULL,
    block_number integer NOT NULL
);


--
-- Name: points_testnet_hackathon_ingestor_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.points_testnet_hackathon_ingestor_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: points_testnet_hackathon_ingestor_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.points_testnet_hackathon_ingestor_1_id_seq OWNED BY public.points_testnet_hackathon_ingestor_1.id;


--
-- Name: points_testnet_hackathon_token_erc20_transfer; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.points_testnet_hackathon_token_erc20_transfer (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    sender public.address NOT NULL,
    recipient public.address NOT NULL,
    value public.hugeint NOT NULL
);


--
-- Name: points_testnet_hackathon_token_erc20_transfer_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.points_testnet_hackathon_token_erc20_transfer_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: points_testnet_hackathon_token_erc20_transfer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.points_testnet_hackathon_token_erc20_transfer_id_seq OWNED BY public.points_testnet_hackathon_token_erc20_transfer.id;


--
-- Name: points_testnet_token_leaderboard_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_testnet_token_leaderboard_1 AS
 SELECT emitter_addr,
    addr,
    (COALESCE(sum(received), (0)::numeric) - COALESCE(sum(sent), (0)::numeric)) AS balance
   FROM ( SELECT points_testnet_hackathon_token_erc20_transfer.emitter_addr,
            points_testnet_hackathon_token_erc20_transfer.recipient AS addr,
            points_testnet_hackathon_token_erc20_transfer.value AS received,
            0 AS sent
           FROM public.points_testnet_hackathon_token_erc20_transfer
        UNION ALL
         SELECT points_testnet_hackathon_token_erc20_transfer.emitter_addr,
            points_testnet_hackathon_token_erc20_transfer.sender AS addr,
            0 AS received,
            points_testnet_hackathon_token_erc20_transfer.value AS sent
           FROM public.points_testnet_hackathon_token_erc20_transfer) movements
  GROUP BY emitter_addr, addr;


--
-- Name: points_undiscovered_debank_addresses_2; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_undiscovered_debank_addresses_2 AS
 SELECT DISTINCT all_addresses.address
   FROM ((( SELECT discord_usernames_1.address
           FROM public.discord_usernames_1
        UNION
         SELECT discord_usernames_2.address
           FROM public.discord_usernames_2
        UNION
         SELECT erc20_cache_1.address
           FROM public.erc20_cache_1
        UNION
         SELECT events_purrstream_donated.address
           FROM public.events_purrstream_donated
        UNION
         SELECT nfts_cache_not_tracked_1.pool_address
           FROM public.nfts_cache_not_tracked_1
          WHERE (nfts_cache_not_tracked_1.pool_address IS NOT NULL)
        UNION
         SELECT nfts_user_owned_1.user_address
           FROM public.nfts_user_owned_1
          WHERE (nfts_user_owned_1.user_address IS NOT NULL)
        UNION
         SELECT nfts_user_owned_1.token_address
           FROM public.nfts_user_owned_1
          WHERE (nfts_user_owned_1.token_address IS NOT NULL)
        UNION
         SELECT ninelives_events_address_fees_claimed.recipient
           FROM public.ninelives_events_address_fees_claimed
        UNION
         SELECT ninelives_events_address_fees_claimed.emitter_addr
           FROM public.ninelives_events_address_fees_claimed
        UNION
         SELECT ninelives_events_new_trading.address
           FROM public.ninelives_events_new_trading
        UNION
         SELECT ninelives_events_new_trading2.address
           FROM public.ninelives_events_new_trading2
        UNION
         SELECT ninelives_users_1.wallet_address
           FROM public.ninelives_users_1
        UNION
         SELECT points_achievements_grouped_1.address
           FROM public.points_achievements_grouped_1
          WHERE (points_achievements_grouped_1.address IS NOT NULL)
        UNION
         SELECT points_achievements_grouped_user_1.address
           FROM public.points_achievements_grouped_user_1
          WHERE (points_achievements_grouped_user_1.address IS NOT NULL)
        UNION
         SELECT points_achievements_leaderboard_1_return.address
           FROM public.points_achievements_leaderboard_1_return
        UNION
         SELECT points_achievements_leaderboard_return_1.address
           FROM public.points_achievements_leaderboard_return_1
        UNION
         SELECT points_achievements_received_1.address
           FROM public.points_achievements_received_1
        UNION
         SELECT points_achievements_received_2.address
           FROM public.points_achievements_received_2
        UNION
         SELECT points_all_addresses_1.address
           FROM public.points_all_addresses_1
          WHERE (points_all_addresses_1.address IS NOT NULL)
        UNION
         SELECT points_discovered_debank_balances_1.address
           FROM public.points_discovered_debank_balances_1
        UNION
         SELECT points_discovered_debank_nobal_1.address
           FROM public.points_discovered_debank_nobal_1
        UNION
         SELECT points_displayed_via_endpoint_1.address
           FROM public.points_displayed_via_endpoint_1
        UNION
         SELECT points_everything_1.address
           FROM public.points_everything_1
          WHERE (points_everything_1.address IS NOT NULL)
        UNION
         SELECT points_fly_staked_points_aggregated_1.address
           FROM public.points_fly_staked_points_aggregated_1
          WHERE (points_fly_staked_points_aggregated_1.address IS NOT NULL)
        UNION
         SELECT points_fly_staked_snapshot_1.address
           FROM public.points_fly_staked_snapshot_1
        UNION
         SELECT points_fly_staking_to_points_1.address
           FROM public.points_fly_staking_to_points_1
          WHERE (points_fly_staking_to_points_1.address IS NOT NULL)
        UNION
         SELECT points_layer3_cube_points_1.user_address
           FROM public.points_layer3_cube_points_1
          WHERE (points_layer3_cube_points_1.user_address IS NOT NULL)
        UNION
         SELECT points_ninelives_creator_points_1.creator_address
           FROM public.points_ninelives_creator_points_1
          WHERE (points_ninelives_creator_points_1.creator_address IS NOT NULL)
        UNION
         SELECT points_purrstream_donation_points_1.address
           FROM public.points_purrstream_donation_points_1
          WHERE (points_purrstream_donation_points_1.address IS NOT NULL)
        UNION
         SELECT points_staked_to_spn_1.address
           FROM public.points_staked_to_spn_1
        UNION
         SELECT points_testnet_addresses_1.address
           FROM public.points_testnet_addresses_1
        UNION
         SELECT points_undiscovered_debank_addresses_1.address
           FROM public.points_undiscovered_debank_addresses_1
          WHERE (points_undiscovered_debank_addresses_1.address IS NOT NULL)) all_addresses
     LEFT JOIN public.points_discovered_debank_balances_1 d ON (((d.address)::text = (all_addresses.address)::text)))
     LEFT JOIN public.points_discovered_debank_nobal_1 n ON (((n.address)::text = (all_addresses.address)::text)))
  WHERE ((d.address IS NULL) AND (n.address IS NULL));


--
-- Name: points_undiscovered_debank_addresses_3; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_undiscovered_debank_addresses_3 AS
 SELECT a.address
   FROM ((public.points_all_addresses_2 a
     LEFT JOIN public.points_discovered_debank_balances_1 d ON (((d.address)::text = (a.address)::text)))
     LEFT JOIN public.points_discovered_debank_nobal_1 n ON (((n.address)::text = (a.address)::text)))
  WHERE ((d.address IS NULL) AND (n.address IS NULL));


--
-- Name: snitch_hits_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.snitch_hits_1 (
    id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    tag uuid NOT NULL,
    property character varying(100) NOT NULL,
    page character varying(100) NOT NULL,
    referrer character varying(100)
);


--
-- Name: private_ninelives_campaign_breakout_analysis_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.private_ninelives_campaign_breakout_analysis_1 AS
 WITH recent_campaign_clicks AS (
         SELECT "substring"((snitch_hits_1.page)::text, '/campaign/(.*)'::text) AS campaign_id,
            count(DISTINCT snitch_hits_1.tag) AS clicks_24h,
            count(*) AS total_page_views_24h,
            count(DISTINCT
                CASE
                    WHEN (snitch_hits_1.created_at >= (now() - '01:00:00'::interval)) THEN snitch_hits_1.tag
                    ELSE NULL::uuid
                END) AS clicks_1h,
            count(DISTINCT
                CASE
                    WHEN (snitch_hits_1.created_at >= (now() - '06:00:00'::interval)) THEN snitch_hits_1.tag
                    ELSE NULL::uuid
                END) AS clicks_6h,
            count(DISTINCT
                CASE
                    WHEN (snitch_hits_1.created_at >= (now() - '12:00:00'::interval)) THEN snitch_hits_1.tag
                    ELSE NULL::uuid
                END) AS clicks_12h,
            min(snitch_hits_1.created_at) AS first_click,
            max(snitch_hits_1.created_at) AS last_click
           FROM public.snitch_hits_1
          WHERE (((snitch_hits_1.page)::text ~~ '/campaign/%'::text) AND (snitch_hits_1.created_at >= (now() - '24:00:00'::interval)))
          GROUP BY ("substring"((snitch_hits_1.page)::text, '/campaign/(.*)'::text))
        ), recent_campaign_purchases AS (
         SELECT ninelives_buys_and_sells_1.campaign_id,
            max((ninelives_buys_and_sells_1.campaign_content ->> 'name'::text)) AS campaign_name,
            count(DISTINCT ninelives_buys_and_sells_1.spender) AS purchasers_24h,
            count(*) AS transactions_24h,
            sum(
                CASE
                    WHEN ((ninelives_buys_and_sells_1.type)::text = 'buy'::text) THEN 1
                    ELSE 0
                END) AS buys_24h,
            sum(
                CASE
                    WHEN ((ninelives_buys_and_sells_1.type)::text = 'sell'::text) THEN 1
                    ELSE 0
                END) AS sells_24h,
            count(DISTINCT
                CASE
                    WHEN (ninelives_buys_and_sells_1.created_by >= (now() - '01:00:00'::interval)) THEN (ninelives_buys_and_sells_1.spender)::bpchar
                    ELSE NULL::bpchar
                END) AS purchasers_1h,
            count(DISTINCT
                CASE
                    WHEN (ninelives_buys_and_sells_1.created_by >= (now() - '06:00:00'::interval)) THEN (ninelives_buys_and_sells_1.spender)::bpchar
                    ELSE NULL::bpchar
                END) AS purchasers_6h,
            min(ninelives_buys_and_sells_1.created_by) AS first_purchase,
            max(ninelives_buys_and_sells_1.created_by) AS last_purchase
           FROM public.ninelives_buys_and_sells_1
          WHERE ((ninelives_buys_and_sells_1.campaign_id IS NOT NULL) AND (ninelives_buys_and_sells_1.created_by >= (now() - '24:00:00'::interval)))
          GROUP BY ninelives_buys_and_sells_1.campaign_id
        ), velocity_metrics AS (
         SELECT recent_campaign_clicks.campaign_id,
            recent_campaign_clicks.clicks_24h,
            recent_campaign_clicks.clicks_1h,
            recent_campaign_clicks.clicks_6h,
            recent_campaign_clicks.clicks_12h,
                CASE
                    WHEN (recent_campaign_clicks.clicks_12h > 0) THEN round((((recent_campaign_clicks.clicks_1h)::numeric / (recent_campaign_clicks.clicks_12h)::numeric) * (100)::numeric), 2)
                    ELSE (0)::numeric
                END AS click_acceleration_1h_vs_12h,
                CASE
                    WHEN (recent_campaign_clicks.clicks_24h > 0) THEN round((((recent_campaign_clicks.clicks_6h)::numeric / (recent_campaign_clicks.clicks_24h)::numeric) * (100)::numeric), 2)
                    ELSE (0)::numeric
                END AS click_acceleration_6h_vs_24h,
            (EXTRACT(epoch FROM (now() - (recent_campaign_clicks.first_click)::timestamp with time zone)) / (3600)::numeric) AS hours_since_first_click,
            (EXTRACT(epoch FROM (now() - (recent_campaign_clicks.last_click)::timestamp with time zone)) / (3600)::numeric) AS hours_since_last_click
           FROM recent_campaign_clicks
        )
 SELECT COALESCE(rcc.campaign_id, rcp.campaign_id) AS campaign_id,
    COALESCE(rcp.campaign_name, 'Unknown'::text) AS campaign_name,
    COALESCE(rcc.clicks_24h, (0)::bigint) AS clicks_24h,
    COALESCE(rcc.clicks_1h, (0)::bigint) AS clicks_1h,
    COALESCE(rcc.clicks_6h, (0)::bigint) AS clicks_6h,
    COALESCE(rcc.total_page_views_24h, (0)::bigint) AS page_views_24h,
    COALESCE(rcp.purchasers_24h, (0)::bigint) AS purchasers_24h,
    COALESCE(rcp.transactions_24h, (0)::bigint) AS transactions_24h,
    COALESCE(rcp.buys_24h, (0)::bigint) AS buys_24h,
    COALESCE(rcp.sells_24h, (0)::bigint) AS sells_24h,
        CASE
            WHEN (COALESCE(rcc.clicks_24h, (0)::bigint) > 0) THEN round((((COALESCE(rcp.purchasers_24h, (0)::bigint))::numeric / (rcc.clicks_24h)::numeric) * (100)::numeric), 2)
            ELSE (0)::numeric
        END AS conversion_rate_24h,
    COALESCE(vm.click_acceleration_1h_vs_12h, (0)::numeric) AS click_acceleration_1h_vs_12h,
    COALESCE(vm.click_acceleration_6h_vs_24h, (0)::numeric) AS click_acceleration_6h_vs_24h,
    vm.hours_since_first_click,
    vm.hours_since_last_click,
    (((((COALESCE(rcc.clicks_24h, (0)::bigint))::numeric * 0.3) + (COALESCE(vm.click_acceleration_6h_vs_24h, (0)::numeric) * 0.4)) + (
        CASE
            WHEN (vm.hours_since_last_click < (1)::numeric) THEN 20
            ELSE 0
        END)::numeric) + ((COALESCE(rcp.purchasers_24h, (0)::bigint) * 10))::numeric) AS breakout_score
   FROM ((recent_campaign_clicks rcc
     FULL JOIN recent_campaign_purchases rcp ON ((rcc.campaign_id = rcp.campaign_id)))
     LEFT JOIN velocity_metrics vm ON ((COALESCE(rcc.campaign_id, rcp.campaign_id) = vm.campaign_id)))
  WHERE ((COALESCE(rcc.clicks_24h, (0)::bigint) > 0) OR (COALESCE(rcp.purchasers_24h, (0)::bigint) > 0))
  ORDER BY (((((COALESCE(rcc.clicks_24h, (0)::bigint))::numeric * 0.3) + (COALESCE(vm.click_acceleration_6h_vs_24h, (0)::numeric) * 0.4)) + (
        CASE
            WHEN (vm.hours_since_last_click < (1)::numeric) THEN 20
            ELSE 0
        END)::numeric) + ((COALESCE(rcp.purchasers_24h, (0)::bigint) * 10))::numeric) DESC, COALESCE(rcc.clicks_24h, (0)::bigint) DESC;


--
-- Name: private_ninelives_campaign_breakout_analysis_2; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.private_ninelives_campaign_breakout_analysis_2 AS
 WITH recent_campaign_clicks AS (
         SELECT "substring"((snitch_hits_1.page)::text, '/campaign/(.*)'::text) AS campaign_id,
            count(DISTINCT snitch_hits_1.tag) AS clicks_24h,
            count(*) AS total_page_views_24h,
            count(DISTINCT
                CASE
                    WHEN (snitch_hits_1.created_at >= (now() - '01:00:00'::interval)) THEN snitch_hits_1.tag
                    ELSE NULL::uuid
                END) AS clicks_1h,
            count(DISTINCT
                CASE
                    WHEN (snitch_hits_1.created_at >= (now() - '06:00:00'::interval)) THEN snitch_hits_1.tag
                    ELSE NULL::uuid
                END) AS clicks_6h,
            count(DISTINCT
                CASE
                    WHEN (snitch_hits_1.created_at >= (now() - '12:00:00'::interval)) THEN snitch_hits_1.tag
                    ELSE NULL::uuid
                END) AS clicks_12h,
            min(snitch_hits_1.created_at) AS first_click,
            max(snitch_hits_1.created_at) AS last_click
           FROM public.snitch_hits_1
          WHERE (((snitch_hits_1.page)::text ~~ '/campaign/%'::text) AND (snitch_hits_1.created_at >= (now() - '24:00:00'::interval)))
          GROUP BY ("substring"((snitch_hits_1.page)::text, '/campaign/(.*)'::text))
        ), recent_campaign_purchases AS (
         SELECT ninelives_buys_and_sells_1.campaign_id,
            max((ninelives_buys_and_sells_1.campaign_content ->> 'name'::text)) AS campaign_name,
            count(DISTINCT ninelives_buys_and_sells_1.recipient) AS purchasers_24h,
            count(*) AS transactions_24h,
            sum(
                CASE
                    WHEN ((ninelives_buys_and_sells_1.type)::text = 'buy'::text) THEN 1
                    ELSE 0
                END) AS buys_24h,
            sum(
                CASE
                    WHEN ((ninelives_buys_and_sells_1.type)::text = 'sell'::text) THEN 1
                    ELSE 0
                END) AS sells_24h,
            count(DISTINCT
                CASE
                    WHEN (ninelives_buys_and_sells_1.created_by >= (now() - '01:00:00'::interval)) THEN (ninelives_buys_and_sells_1.recipient)::bpchar
                    ELSE NULL::bpchar
                END) AS purchasers_1h,
            count(DISTINCT
                CASE
                    WHEN (ninelives_buys_and_sells_1.created_by >= (now() - '06:00:00'::interval)) THEN (ninelives_buys_and_sells_1.recipient)::bpchar
                    ELSE NULL::bpchar
                END) AS purchasers_6h,
            min(ninelives_buys_and_sells_1.created_by) AS first_purchase,
            max(ninelives_buys_and_sells_1.created_by) AS last_purchase
           FROM public.ninelives_buys_and_sells_1
          WHERE ((ninelives_buys_and_sells_1.campaign_id IS NOT NULL) AND (ninelives_buys_and_sells_1.created_by >= (now() - '24:00:00'::interval)))
          GROUP BY ninelives_buys_and_sells_1.campaign_id
        ), velocity_metrics AS (
         SELECT recent_campaign_clicks.campaign_id,
            recent_campaign_clicks.clicks_24h,
            recent_campaign_clicks.clicks_1h,
            recent_campaign_clicks.clicks_6h,
            recent_campaign_clicks.clicks_12h,
                CASE
                    WHEN (recent_campaign_clicks.clicks_12h > 0) THEN round((((recent_campaign_clicks.clicks_1h)::numeric / (recent_campaign_clicks.clicks_12h)::numeric) * (100)::numeric), 2)
                    ELSE (0)::numeric
                END AS click_acceleration_1h_vs_12h,
                CASE
                    WHEN (recent_campaign_clicks.clicks_24h > 0) THEN round((((recent_campaign_clicks.clicks_6h)::numeric / (recent_campaign_clicks.clicks_24h)::numeric) * (100)::numeric), 2)
                    ELSE (0)::numeric
                END AS click_acceleration_6h_vs_24h,
            (EXTRACT(epoch FROM (now() - (recent_campaign_clicks.first_click)::timestamp with time zone)) / (3600)::numeric) AS hours_since_first_click,
            (EXTRACT(epoch FROM (now() - (recent_campaign_clicks.last_click)::timestamp with time zone)) / (3600)::numeric) AS hours_since_last_click
           FROM recent_campaign_clicks
        )
 SELECT COALESCE(rcc.campaign_id, rcp.campaign_id) AS campaign_id,
    COALESCE(rcp.campaign_name, 'Unknown'::text) AS campaign_name,
    COALESCE(rcc.clicks_24h, (0)::bigint) AS clicks_24h,
    COALESCE(rcc.clicks_1h, (0)::bigint) AS clicks_1h,
    COALESCE(rcc.clicks_6h, (0)::bigint) AS clicks_6h,
    COALESCE(rcc.total_page_views_24h, (0)::bigint) AS page_views_24h,
    COALESCE(rcp.purchasers_24h, (0)::bigint) AS purchasers_24h,
    COALESCE(rcp.transactions_24h, (0)::bigint) AS transactions_24h,
    COALESCE(rcp.buys_24h, (0)::bigint) AS buys_24h,
    COALESCE(rcp.sells_24h, (0)::bigint) AS sells_24h,
        CASE
            WHEN (COALESCE(rcc.clicks_24h, (0)::bigint) > 0) THEN round((((COALESCE(rcp.purchasers_24h, (0)::bigint))::numeric / (rcc.clicks_24h)::numeric) * (100)::numeric), 2)
            ELSE (0)::numeric
        END AS conversion_rate_24h,
    COALESCE(vm.click_acceleration_1h_vs_12h, (0)::numeric) AS click_acceleration_1h_vs_12h,
    COALESCE(vm.click_acceleration_6h_vs_24h, (0)::numeric) AS click_acceleration_6h_vs_24h,
    vm.hours_since_first_click,
    vm.hours_since_last_click,
    (((((COALESCE(rcc.clicks_24h, (0)::bigint))::numeric * 0.3) + (COALESCE(vm.click_acceleration_6h_vs_24h, (0)::numeric) * 0.4)) + (
        CASE
            WHEN (vm.hours_since_last_click < (1)::numeric) THEN 20
            ELSE 0
        END)::numeric) + ((COALESCE(rcp.purchasers_24h, (0)::bigint) * 10))::numeric) AS breakout_score
   FROM ((recent_campaign_clicks rcc
     FULL JOIN recent_campaign_purchases rcp ON ((rcc.campaign_id = rcp.campaign_id)))
     LEFT JOIN velocity_metrics vm ON ((COALESCE(rcc.campaign_id, rcp.campaign_id) = vm.campaign_id)))
  WHERE ((COALESCE(rcc.clicks_24h, (0)::bigint) > 0) OR (COALESCE(rcp.purchasers_24h, (0)::bigint) > 0))
  ORDER BY (((((COALESCE(rcc.clicks_24h, (0)::bigint))::numeric * 0.3) + (COALESCE(vm.click_acceleration_6h_vs_24h, (0)::numeric) * 0.4)) + (
        CASE
            WHEN (vm.hours_since_last_click < (1)::numeric) THEN 20
            ELSE 0
        END)::numeric) + ((COALESCE(rcp.purchasers_24h, (0)::bigint) * 10))::numeric) DESC, COALESCE(rcc.clicks_24h, (0)::bigint) DESC;


--
-- Name: private_ninelives_campaign_breakout_analysis_3; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.private_ninelives_campaign_breakout_analysis_3 AS
 WITH recent_campaign_clicks AS (
         SELECT "substring"((snitch_hits_1.page)::text, '/campaign/(.*)'::text) AS campaign_id,
            count(DISTINCT snitch_hits_1.tag) AS clicks_24h,
            count(*) AS total_page_views_24h,
            count(DISTINCT
                CASE
                    WHEN (snitch_hits_1.created_at >= (now() - '01:00:00'::interval)) THEN snitch_hits_1.tag
                    ELSE NULL::uuid
                END) AS clicks_1h,
            count(DISTINCT
                CASE
                    WHEN (snitch_hits_1.created_at >= (now() - '06:00:00'::interval)) THEN snitch_hits_1.tag
                    ELSE NULL::uuid
                END) AS clicks_6h,
            count(DISTINCT
                CASE
                    WHEN (snitch_hits_1.created_at >= (now() - '12:00:00'::interval)) THEN snitch_hits_1.tag
                    ELSE NULL::uuid
                END) AS clicks_12h,
            min(snitch_hits_1.created_at) AS first_click,
            max(snitch_hits_1.created_at) AS last_click
           FROM public.snitch_hits_1
          WHERE (((snitch_hits_1.page)::text ~~ '/campaign/%'::text) AND (snitch_hits_1.created_at >= (now() - '24:00:00'::interval)))
          GROUP BY ("substring"((snitch_hits_1.page)::text, '/campaign/(.*)'::text))
        ), recent_campaign_purchases AS (
         SELECT ninelives_buys_and_sells_1.campaign_id,
            max((ninelives_buys_and_sells_1.campaign_content ->> 'name'::text)) AS campaign_name,
            count(DISTINCT ninelives_buys_and_sells_1.recipient) AS purchasers_24h,
            count(*) AS transactions_24h,
            sum(
                CASE
                    WHEN ((ninelives_buys_and_sells_1.type)::text = 'buy'::text) THEN 1
                    ELSE 0
                END) AS buys_24h,
            sum(
                CASE
                    WHEN ((ninelives_buys_and_sells_1.type)::text = 'sell'::text) THEN 1
                    ELSE 0
                END) AS sells_24h,
            count(DISTINCT
                CASE
                    WHEN (ninelives_buys_and_sells_1.created_by >= (now() - '01:00:00'::interval)) THEN (ninelives_buys_and_sells_1.recipient)::bpchar
                    ELSE NULL::bpchar
                END) AS purchasers_1h,
            count(DISTINCT
                CASE
                    WHEN (ninelives_buys_and_sells_1.created_by >= (now() - '06:00:00'::interval)) THEN (ninelives_buys_and_sells_1.recipient)::bpchar
                    ELSE NULL::bpchar
                END) AS purchasers_6h,
            min(ninelives_buys_and_sells_1.created_by) AS first_purchase,
            max(ninelives_buys_and_sells_1.created_by) AS last_purchase
           FROM public.ninelives_buys_and_sells_1
          WHERE ((ninelives_buys_and_sells_1.campaign_id IS NOT NULL) AND (ninelives_buys_and_sells_1.created_by >= (now() - '24:00:00'::interval)))
          GROUP BY ninelives_buys_and_sells_1.campaign_id
        ), campaign_liquidity AS (
         SELECT c.id AS campaign_id,
            COALESCE(sum(((l.fusdc_amt)::numeric / 1000000.0)), (0)::numeric) AS total_liquidity_usd,
            COALESCE(sum(
                CASE
                    WHEN (l.created_by >= (now() - '24:00:00'::interval)) THEN ((l.fusdc_amt)::numeric / 1000000.0)
                    ELSE (0)::numeric
                END), (0)::numeric) AS liquidity_added_24h,
                CASE
                    WHEN (sum(((l.fusdc_amt)::numeric / 1000000.0)) >= (10000)::numeric) THEN 'high'::text
                    WHEN (sum(((l.fusdc_amt)::numeric / 1000000.0)) >= (1000)::numeric) THEN 'medium'::text
                    WHEN (sum(((l.fusdc_amt)::numeric / 1000000.0)) >= (100)::numeric) THEN 'low'::text
                    ELSE 'minimal'::text
                END AS liquidity_tier
           FROM (public.ninelives_campaigns_1 c
             LEFT JOIN public.ninelives_events_liquidity_added l ON (((c.content ->> 'poolAddress'::text) = (l.emitter_addr)::text)))
          GROUP BY c.id
        ), velocity_metrics AS (
         SELECT recent_campaign_clicks.campaign_id,
            recent_campaign_clicks.clicks_24h,
            recent_campaign_clicks.clicks_1h,
            recent_campaign_clicks.clicks_6h,
            recent_campaign_clicks.clicks_12h,
                CASE
                    WHEN (recent_campaign_clicks.clicks_12h > 0) THEN round((((recent_campaign_clicks.clicks_1h)::numeric / (recent_campaign_clicks.clicks_12h)::numeric) * (100)::numeric), 2)
                    ELSE (0)::numeric
                END AS click_acceleration_1h_vs_12h,
                CASE
                    WHEN (recent_campaign_clicks.clicks_24h > 0) THEN round((((recent_campaign_clicks.clicks_6h)::numeric / (recent_campaign_clicks.clicks_24h)::numeric) * (100)::numeric), 2)
                    ELSE (0)::numeric
                END AS click_acceleration_6h_vs_24h,
            (EXTRACT(epoch FROM (now() - (recent_campaign_clicks.first_click)::timestamp with time zone)) / (3600)::numeric) AS hours_since_first_click,
            (EXTRACT(epoch FROM (now() - (recent_campaign_clicks.last_click)::timestamp with time zone)) / (3600)::numeric) AS hours_since_last_click
           FROM recent_campaign_clicks
        )
 SELECT COALESCE(rcc.campaign_id, rcp.campaign_id, cl.campaign_id) AS campaign_id,
    COALESCE(rcp.campaign_name, 'Unknown'::text) AS campaign_name,
    COALESCE(rcc.clicks_24h, (0)::bigint) AS clicks_24h,
    COALESCE(rcc.clicks_1h, (0)::bigint) AS clicks_1h,
    COALESCE(rcc.clicks_6h, (0)::bigint) AS clicks_6h,
    COALESCE(rcc.total_page_views_24h, (0)::bigint) AS page_views_24h,
    COALESCE(rcp.purchasers_24h, (0)::bigint) AS purchasers_24h,
    COALESCE(rcp.transactions_24h, (0)::bigint) AS transactions_24h,
    COALESCE(rcp.buys_24h, (0)::bigint) AS buys_24h,
    COALESCE(rcp.sells_24h, (0)::bigint) AS sells_24h,
    COALESCE(cl.total_liquidity_usd, (0)::numeric) AS total_liquidity_usd,
    COALESCE(cl.liquidity_added_24h, (0)::numeric) AS liquidity_added_24h,
    COALESCE(cl.liquidity_tier, 'minimal'::text) AS liquidity_tier,
        CASE
            WHEN (COALESCE(rcc.clicks_24h, (0)::bigint) > 0) THEN round((((COALESCE(rcp.purchasers_24h, (0)::bigint))::numeric / (rcc.clicks_24h)::numeric) * (100)::numeric), 2)
            ELSE (0)::numeric
        END AS conversion_rate_24h,
    COALESCE(vm.click_acceleration_1h_vs_12h, (0)::numeric) AS click_acceleration_1h_vs_12h,
    COALESCE(vm.click_acceleration_6h_vs_24h, (0)::numeric) AS click_acceleration_6h_vs_24h,
    vm.hours_since_first_click,
    vm.hours_since_last_click,
    (((((((COALESCE(rcc.clicks_24h, (0)::bigint))::numeric * 0.2) + (COALESCE(vm.click_acceleration_6h_vs_24h, (0)::numeric) * 0.3)) + (
        CASE
            WHEN (vm.hours_since_last_click < (1)::numeric) THEN 15
            ELSE 0
        END)::numeric) + ((COALESCE(rcp.purchasers_24h, (0)::bigint) * 8))::numeric) +
        CASE cl.liquidity_tier
            WHEN 'high'::text THEN (COALESCE(cl.total_liquidity_usd, (0)::numeric) * 0.003)
            WHEN 'medium'::text THEN (COALESCE(cl.total_liquidity_usd, (0)::numeric) * 0.005)
            WHEN 'low'::text THEN (COALESCE(cl.total_liquidity_usd, (0)::numeric) * 0.01)
            ELSE (COALESCE(cl.total_liquidity_usd, (0)::numeric) * 0.02)
        END) + (COALESCE(cl.liquidity_added_24h, (0)::numeric) * (5)::numeric)) AS breakout_score
   FROM (((recent_campaign_clicks rcc
     FULL JOIN recent_campaign_purchases rcp ON ((rcc.campaign_id = rcp.campaign_id)))
     FULL JOIN campaign_liquidity cl ON ((COALESCE(rcc.campaign_id, rcp.campaign_id) = cl.campaign_id)))
     LEFT JOIN velocity_metrics vm ON ((COALESCE(rcc.campaign_id, rcp.campaign_id, cl.campaign_id) = vm.campaign_id)))
  WHERE ((COALESCE(rcc.clicks_24h, (0)::bigint) > 0) OR (COALESCE(rcp.purchasers_24h, (0)::bigint) > 0) OR (COALESCE(cl.total_liquidity_usd, (0)::numeric) > (0)::numeric))
  ORDER BY (((((((COALESCE(rcc.clicks_24h, (0)::bigint))::numeric * 0.2) + (COALESCE(vm.click_acceleration_6h_vs_24h, (0)::numeric) * 0.3)) + (
        CASE
            WHEN (vm.hours_since_last_click < (1)::numeric) THEN 15
            ELSE 0
        END)::numeric) + ((COALESCE(rcp.purchasers_24h, (0)::bigint) * 8))::numeric) +
        CASE cl.liquidity_tier
            WHEN 'high'::text THEN (COALESCE(cl.total_liquidity_usd, (0)::numeric) * 0.003)
            WHEN 'medium'::text THEN (COALESCE(cl.total_liquidity_usd, (0)::numeric) * 0.005)
            WHEN 'low'::text THEN (COALESCE(cl.total_liquidity_usd, (0)::numeric) * 0.01)
            ELSE (COALESCE(cl.total_liquidity_usd, (0)::numeric) * 0.02)
        END) + (COALESCE(cl.liquidity_added_24h, (0)::numeric) * (5)::numeric)) DESC, COALESCE(rcc.clicks_24h, (0)::bigint) DESC;


--
-- Name: private_ninelives_campaign_breakout_analysis_4; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.private_ninelives_campaign_breakout_analysis_4 AS
 WITH recent_campaign_clicks AS (
         SELECT "substring"((snitch_hits_1.page)::text, '/campaign/(.*)'::text) AS campaign_id,
            count(DISTINCT snitch_hits_1.tag) AS clicks_24h,
            count(*) AS total_page_views_24h,
            count(DISTINCT
                CASE
                    WHEN (snitch_hits_1.created_at >= (now() - '01:00:00'::interval)) THEN snitch_hits_1.tag
                    ELSE NULL::uuid
                END) AS clicks_1h,
            count(DISTINCT
                CASE
                    WHEN (snitch_hits_1.created_at >= (now() - '06:00:00'::interval)) THEN snitch_hits_1.tag
                    ELSE NULL::uuid
                END) AS clicks_6h,
            count(DISTINCT
                CASE
                    WHEN (snitch_hits_1.created_at >= (now() - '12:00:00'::interval)) THEN snitch_hits_1.tag
                    ELSE NULL::uuid
                END) AS clicks_12h,
            min(snitch_hits_1.created_at) AS first_click,
            max(snitch_hits_1.created_at) AS last_click
           FROM public.snitch_hits_1
          WHERE (((snitch_hits_1.page)::text ~~ '/campaign/%'::text) AND (snitch_hits_1.created_at >= (now() - '24:00:00'::interval)))
          GROUP BY ("substring"((snitch_hits_1.page)::text, '/campaign/(.*)'::text))
        ), recent_campaign_purchases AS (
         SELECT ninelives_buys_and_sells_1.campaign_id,
            max((ninelives_buys_and_sells_1.campaign_content ->> 'name'::text)) AS campaign_name,
            count(DISTINCT ninelives_buys_and_sells_1.recipient) AS purchasers_24h,
            count(*) AS transactions_24h,
            sum(
                CASE
                    WHEN ((ninelives_buys_and_sells_1.type)::text = 'buy'::text) THEN 1
                    ELSE 0
                END) AS buys_24h,
            sum(
                CASE
                    WHEN ((ninelives_buys_and_sells_1.type)::text = 'sell'::text) THEN 1
                    ELSE 0
                END) AS sells_24h,
            count(DISTINCT
                CASE
                    WHEN (ninelives_buys_and_sells_1.created_by >= (now() - '01:00:00'::interval)) THEN (ninelives_buys_and_sells_1.recipient)::bpchar
                    ELSE NULL::bpchar
                END) AS purchasers_1h,
            count(DISTINCT
                CASE
                    WHEN (ninelives_buys_and_sells_1.created_by >= (now() - '06:00:00'::interval)) THEN (ninelives_buys_and_sells_1.recipient)::bpchar
                    ELSE NULL::bpchar
                END) AS purchasers_6h,
            min(ninelives_buys_and_sells_1.created_by) AS first_purchase,
            max(ninelives_buys_and_sells_1.created_by) AS last_purchase
           FROM public.ninelives_buys_and_sells_1
          WHERE ((ninelives_buys_and_sells_1.campaign_id IS NOT NULL) AND (ninelives_buys_and_sells_1.created_by >= (now() - '24:00:00'::interval)))
          GROUP BY ninelives_buys_and_sells_1.campaign_id
        ), campaign_liquidity AS (
         SELECT c.id AS campaign_id,
            COALESCE(sum(((l.fusdc_amt)::numeric / 1000000.0)), (0)::numeric) AS total_liquidity_usd,
            COALESCE(sum(
                CASE
                    WHEN (l.created_by >= (now() - '24:00:00'::interval)) THEN ((l.fusdc_amt)::numeric / 1000000.0)
                    ELSE (0)::numeric
                END), (0)::numeric) AS liquidity_added_24h,
                CASE
                    WHEN (sum(((l.fusdc_amt)::numeric / 1000000.0)) >= (5000)::numeric) THEN 'exceptional'::text
                    WHEN (sum(((l.fusdc_amt)::numeric / 1000000.0)) >= (1000)::numeric) THEN 'high'::text
                    WHEN (sum(((l.fusdc_amt)::numeric / 1000000.0)) >= (100)::numeric) THEN 'medium'::text
                    WHEN (sum(((l.fusdc_amt)::numeric / 1000000.0)) >= (50)::numeric) THEN 'low'::text
                    WHEN (sum(((l.fusdc_amt)::numeric / 1000000.0)) >= (10)::numeric) THEN 'minimal'::text
                    ELSE 'none'::text
                END AS liquidity_tier,
            count(DISTINCT date_trunc('day'::text, l.created_by)) AS days_with_liquidity_activity
           FROM (public.ninelives_campaigns_1 c
             LEFT JOIN public.ninelives_events_liquidity_added l ON (((c.content ->> 'poolAddress'::text) = (l.emitter_addr)::text)))
          GROUP BY c.id
        ), velocity_metrics AS (
         SELECT recent_campaign_clicks.campaign_id,
            recent_campaign_clicks.clicks_24h,
            recent_campaign_clicks.clicks_1h,
            recent_campaign_clicks.clicks_6h,
            recent_campaign_clicks.clicks_12h,
                CASE
                    WHEN (recent_campaign_clicks.clicks_12h > 0) THEN round((((recent_campaign_clicks.clicks_1h)::numeric / (recent_campaign_clicks.clicks_12h)::numeric) * (100)::numeric), 2)
                    ELSE (0)::numeric
                END AS click_acceleration_1h_vs_12h,
                CASE
                    WHEN (recent_campaign_clicks.clicks_24h > 0) THEN round((((recent_campaign_clicks.clicks_6h)::numeric / (recent_campaign_clicks.clicks_24h)::numeric) * (100)::numeric), 2)
                    ELSE (0)::numeric
                END AS click_acceleration_6h_vs_24h,
            (EXTRACT(epoch FROM (now() - (recent_campaign_clicks.first_click)::timestamp with time zone)) / (3600)::numeric) AS hours_since_first_click,
            (EXTRACT(epoch FROM (now() - (recent_campaign_clicks.last_click)::timestamp with time zone)) / (3600)::numeric) AS hours_since_last_click
           FROM recent_campaign_clicks
        )
 SELECT COALESCE(rcc.campaign_id, rcp.campaign_id, cl.campaign_id) AS campaign_id,
    COALESCE(rcp.campaign_name, 'Unknown'::text) AS campaign_name,
    COALESCE(rcc.clicks_24h, (0)::bigint) AS clicks_24h,
    COALESCE(rcc.clicks_1h, (0)::bigint) AS clicks_1h,
    COALESCE(rcc.clicks_6h, (0)::bigint) AS clicks_6h,
    COALESCE(rcc.total_page_views_24h, (0)::bigint) AS page_views_24h,
    COALESCE(rcp.purchasers_24h, (0)::bigint) AS purchasers_24h,
    COALESCE(rcp.transactions_24h, (0)::bigint) AS transactions_24h,
    COALESCE(rcp.buys_24h, (0)::bigint) AS buys_24h,
    COALESCE(rcp.sells_24h, (0)::bigint) AS sells_24h,
    COALESCE(cl.total_liquidity_usd, (0)::numeric) AS total_liquidity_usd,
    COALESCE(cl.liquidity_added_24h, (0)::numeric) AS liquidity_added_24h,
    COALESCE(cl.liquidity_tier, 'none'::text) AS liquidity_tier,
    COALESCE(cl.days_with_liquidity_activity, (0)::bigint) AS days_with_liquidity_activity,
        CASE
            WHEN (COALESCE(rcc.clicks_24h, (0)::bigint) > 0) THEN round((((COALESCE(rcp.purchasers_24h, (0)::bigint))::numeric / (rcc.clicks_24h)::numeric) * (100)::numeric), 2)
            ELSE (0)::numeric
        END AS conversion_rate_24h,
    COALESCE(vm.click_acceleration_1h_vs_12h, (0)::numeric) AS click_acceleration_1h_vs_12h,
    COALESCE(vm.click_acceleration_6h_vs_24h, (0)::numeric) AS click_acceleration_6h_vs_24h,
    vm.hours_since_first_click,
    vm.hours_since_last_click,
    (((((((((COALESCE(rcc.clicks_24h, (0)::bigint))::numeric * 0.15) + (COALESCE(vm.click_acceleration_6h_vs_24h, (0)::numeric) * 0.1)) + (
        CASE
            WHEN (vm.hours_since_last_click < (1)::numeric) THEN 10
            ELSE 0
        END)::numeric) + ((COALESCE(rcp.purchasers_24h, (0)::bigint) * 5))::numeric) +
        CASE cl.liquidity_tier
            WHEN 'exceptional'::text THEN (COALESCE(cl.total_liquidity_usd, (0)::numeric) * 0.008)
            WHEN 'high'::text THEN (COALESCE(cl.total_liquidity_usd, (0)::numeric) * 0.01)
            WHEN 'medium'::text THEN (COALESCE(cl.total_liquidity_usd, (0)::numeric) * 0.015)
            WHEN 'low'::text THEN (COALESCE(cl.total_liquidity_usd, (0)::numeric) * 0.02)
            WHEN 'minimal'::text THEN (COALESCE(cl.total_liquidity_usd, (0)::numeric) * 0.03)
            ELSE (0)::numeric
        END) + (COALESCE(cl.liquidity_added_24h, (0)::numeric) * (15)::numeric)) + ((COALESCE(cl.days_with_liquidity_activity, (0)::bigint) * 3))::numeric) + (
        CASE cl.liquidity_tier
            WHEN 'exceptional'::text THEN 100
            WHEN 'high'::text THEN 50
            WHEN 'medium'::text THEN 25
            WHEN 'low'::text THEN 10
            WHEN 'minimal'::text THEN 2
            ELSE 0
        END)::numeric) AS breakout_score
   FROM (((recent_campaign_clicks rcc
     FULL JOIN recent_campaign_purchases rcp ON ((rcc.campaign_id = rcp.campaign_id)))
     FULL JOIN campaign_liquidity cl ON ((COALESCE(rcc.campaign_id, rcp.campaign_id) = cl.campaign_id)))
     LEFT JOIN velocity_metrics vm ON ((COALESCE(rcc.campaign_id, rcp.campaign_id, cl.campaign_id) = vm.campaign_id)))
  WHERE ((COALESCE(rcc.clicks_24h, (0)::bigint) > 0) OR (COALESCE(rcp.purchasers_24h, (0)::bigint) > 0) OR (COALESCE(cl.total_liquidity_usd, (0)::numeric) > (0)::numeric))
  ORDER BY (((((((((COALESCE(rcc.clicks_24h, (0)::bigint))::numeric * 0.15) + (COALESCE(vm.click_acceleration_6h_vs_24h, (0)::numeric) * 0.1)) + (
        CASE
            WHEN (vm.hours_since_last_click < (1)::numeric) THEN 10
            ELSE 0
        END)::numeric) + ((COALESCE(rcp.purchasers_24h, (0)::bigint) * 5))::numeric) +
        CASE cl.liquidity_tier
            WHEN 'exceptional'::text THEN (COALESCE(cl.total_liquidity_usd, (0)::numeric) * 0.008)
            WHEN 'high'::text THEN (COALESCE(cl.total_liquidity_usd, (0)::numeric) * 0.01)
            WHEN 'medium'::text THEN (COALESCE(cl.total_liquidity_usd, (0)::numeric) * 0.015)
            WHEN 'low'::text THEN (COALESCE(cl.total_liquidity_usd, (0)::numeric) * 0.02)
            WHEN 'minimal'::text THEN (COALESCE(cl.total_liquidity_usd, (0)::numeric) * 0.03)
            ELSE (0)::numeric
        END) + (COALESCE(cl.liquidity_added_24h, (0)::numeric) * (15)::numeric)) + ((COALESCE(cl.days_with_liquidity_activity, (0)::bigint) * 3))::numeric) + (
        CASE cl.liquidity_tier
            WHEN 'exceptional'::text THEN 100
            WHEN 'high'::text THEN 50
            WHEN 'medium'::text THEN 25
            WHEN 'low'::text THEN 10
            WHEN 'minimal'::text THEN 2
            ELSE 0
        END)::numeric) DESC, COALESCE(cl.total_liquidity_usd, (0)::numeric) DESC;


--
-- Name: private_ninelives_campaigns_sorted_by_breakout_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.private_ninelives_campaigns_sorted_by_breakout_1 AS
 WITH campaign_metrics AS (
         SELECT cba.campaign_id,
            cba.clicks_24h,
            cba.purchasers_24h,
            cba.conversion_rate_24h,
            cba.click_acceleration_6h_vs_24h,
            cba.hours_since_last_click,
            cba.breakout_score
           FROM public.private_ninelives_campaign_breakout_analysis_1 cba
          WHERE (cba.clicks_24h > 0)
        ), thresholds AS (
         SELECT avg(campaign_metrics.conversion_rate_24h) AS avg_conversion_rate,
            percentile_cont((0.75)::double precision) WITHIN GROUP (ORDER BY ((campaign_metrics.conversion_rate_24h)::double precision)) AS top_25_conversion_rate,
            avg(campaign_metrics.clicks_24h) AS avg_clicks
           FROM campaign_metrics
        ), classified_campaigns AS (
         SELECT cm.campaign_id,
            cm.clicks_24h,
            cm.purchasers_24h,
            cm.conversion_rate_24h,
            cm.click_acceleration_6h_vs_24h,
            cm.hours_since_last_click,
            cm.breakout_score,
            t.avg_conversion_rate,
            t.top_25_conversion_rate,
            t.avg_clicks,
                CASE
                    WHEN ((cm.clicks_24h >= 15) AND (cm.conversion_rate_24h >= (15)::numeric) AND (cm.purchasers_24h >= 5) AND (cm.hours_since_last_click <= (6)::numeric)) THEN 'Strategic'::text
                    WHEN (((cm.conversion_rate_24h)::double precision >= t.top_25_conversion_rate) AND (cm.clicks_24h >= 5) AND (cm.purchasers_24h >= 2)) THEN 'Top Rated'::text
                    WHEN ((cm.conversion_rate_24h >= t.avg_conversion_rate) AND ((cm.clicks_24h)::numeric >= (t.avg_clicks * 0.7)) AND (cm.purchasers_24h >= 1)) THEN 'Cows'::text
                    ELSE 'Dogs'::text
                END AS tier
           FROM (campaign_metrics cm
             CROSS JOIN thresholds t)
        )
 SELECT c.id,
    c.created_at,
    c.updated_at,
    c.content,
    c.name_to_search,
    c.shown,
    c.total_volume
   FROM (public.ninelives_campaigns_1 c
     JOIN classified_campaigns cc ON ((c.id = cc.campaign_id)))
  ORDER BY
        CASE cc.tier
            WHEN 'Strategic'::text THEN 1
            WHEN 'Top Rated'::text THEN 2
            WHEN 'Cows'::text THEN 3
            WHEN 'Dogs'::text THEN 4
            ELSE NULL::integer
        END, cc.breakout_score DESC;


--
-- Name: private_ninelives_campaigns_sorted_by_breakout_2; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.private_ninelives_campaigns_sorted_by_breakout_2 AS
 WITH campaign_metrics AS (
         SELECT cba.campaign_id,
            cba.clicks_24h,
            cba.purchasers_24h,
            cba.conversion_rate_24h,
            cba.click_acceleration_6h_vs_24h,
            cba.hours_since_last_click,
            cba.breakout_score
           FROM public.private_ninelives_campaign_breakout_analysis_2 cba
          WHERE (cba.clicks_24h > 0)
        ), thresholds AS (
         SELECT avg(campaign_metrics.conversion_rate_24h) AS avg_conversion_rate,
            percentile_cont((0.75)::double precision) WITHIN GROUP (ORDER BY ((campaign_metrics.conversion_rate_24h)::double precision)) AS top_25_conversion_rate,
            avg(campaign_metrics.clicks_24h) AS avg_clicks
           FROM campaign_metrics
        ), classified_campaigns AS (
         SELECT cm.campaign_id,
            cm.clicks_24h,
            cm.purchasers_24h,
            cm.conversion_rate_24h,
            cm.click_acceleration_6h_vs_24h,
            cm.hours_since_last_click,
            cm.breakout_score,
            t.avg_conversion_rate,
            t.top_25_conversion_rate,
            t.avg_clicks,
                CASE
                    WHEN ((cm.clicks_24h >= 15) AND (cm.conversion_rate_24h >= (15)::numeric) AND (cm.purchasers_24h >= 5) AND (cm.hours_since_last_click <= (6)::numeric)) THEN 'Strategic'::text
                    WHEN (((cm.conversion_rate_24h)::double precision >= t.top_25_conversion_rate) AND (cm.clicks_24h >= 5) AND (cm.purchasers_24h >= 2)) THEN 'Top Rated'::text
                    WHEN ((cm.conversion_rate_24h >= t.avg_conversion_rate) AND ((cm.clicks_24h)::numeric >= (t.avg_clicks * 0.7)) AND (cm.purchasers_24h >= 1)) THEN 'Cows'::text
                    ELSE 'Dogs'::text
                END AS tier
           FROM (campaign_metrics cm
             CROSS JOIN thresholds t)
        )
 SELECT c.id,
    c.created_at,
    c.updated_at,
    c.content,
    c.name_to_search,
    c.shown,
    c.total_volume
   FROM (public.ninelives_campaigns_1 c
     JOIN classified_campaigns cc ON ((c.id = cc.campaign_id)))
  ORDER BY
        CASE cc.tier
            WHEN 'Strategic'::text THEN 1
            WHEN 'Top Rated'::text THEN 2
            WHEN 'Cows'::text THEN 3
            WHEN 'Dogs'::text THEN 4
            ELSE NULL::integer
        END, cc.breakout_score DESC;


--
-- Name: private_ninelives_campaigns_sorted_by_breakout_3; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.private_ninelives_campaigns_sorted_by_breakout_3 AS
 WITH campaign_metrics AS (
         SELECT private_ninelives_campaign_breakout_analysis_3.campaign_id,
            private_ninelives_campaign_breakout_analysis_3.clicks_24h,
            private_ninelives_campaign_breakout_analysis_3.purchasers_24h,
            private_ninelives_campaign_breakout_analysis_3.conversion_rate_24h,
            private_ninelives_campaign_breakout_analysis_3.click_acceleration_6h_vs_24h,
            private_ninelives_campaign_breakout_analysis_3.hours_since_last_click,
            private_ninelives_campaign_breakout_analysis_3.breakout_score,
            private_ninelives_campaign_breakout_analysis_3.total_liquidity_usd,
            private_ninelives_campaign_breakout_analysis_3.liquidity_tier
           FROM public.private_ninelives_campaign_breakout_analysis_3
          WHERE ((private_ninelives_campaign_breakout_analysis_3.clicks_24h > 0) OR (private_ninelives_campaign_breakout_analysis_3.total_liquidity_usd > (0)::numeric))
        ), thresholds AS (
         SELECT avg(campaign_metrics.conversion_rate_24h) AS avg_conversion_rate,
            percentile_cont((0.75)::double precision) WITHIN GROUP (ORDER BY ((campaign_metrics.conversion_rate_24h)::double precision)) AS top_25_conversion_rate,
            avg(campaign_metrics.clicks_24h) AS avg_clicks,
            avg(campaign_metrics.total_liquidity_usd) AS avg_liquidity
           FROM campaign_metrics
        ), classified_campaigns AS (
         SELECT cm.campaign_id,
            cm.clicks_24h,
            cm.purchasers_24h,
            cm.conversion_rate_24h,
            cm.click_acceleration_6h_vs_24h,
            cm.hours_since_last_click,
            cm.breakout_score,
            cm.total_liquidity_usd,
            cm.liquidity_tier,
            t.avg_conversion_rate,
            t.top_25_conversion_rate,
            t.avg_clicks,
            t.avg_liquidity,
                CASE
                    WHEN ((cm.clicks_24h >= 15) AND (cm.conversion_rate_24h >= (15)::numeric) AND (cm.purchasers_24h >= 5) AND (cm.hours_since_last_click <= (6)::numeric) AND (cm.total_liquidity_usd >= (500)::numeric)) THEN 'Strategic'::text
                    WHEN (((cm.conversion_rate_24h)::double precision >= t.top_25_conversion_rate) AND (cm.clicks_24h >= 5) AND (cm.purchasers_24h >= 2) AND (cm.total_liquidity_usd >= (100)::numeric)) THEN 'Top Rated'::text
                    WHEN (((cm.conversion_rate_24h >= t.avg_conversion_rate) AND ((cm.clicks_24h)::numeric >= (t.avg_clicks * 0.7)) AND (cm.purchasers_24h >= 1)) OR (cm.total_liquidity_usd >= t.avg_liquidity)) THEN 'Cows'::text
                    ELSE 'Dogs'::text
                END AS tier
           FROM (campaign_metrics cm
             CROSS JOIN thresholds t)
        )
 SELECT c.id,
    c.created_at,
    c.updated_at,
    c.content,
    c.name_to_search,
    c.shown,
    c.total_volume
   FROM (public.ninelives_campaigns_1 c
     JOIN classified_campaigns cc ON ((c.id = cc.campaign_id)))
  ORDER BY
        CASE cc.tier
            WHEN 'Strategic'::text THEN 1
            WHEN 'Top Rated'::text THEN 2
            WHEN 'Cows'::text THEN 3
            WHEN 'Dogs'::text THEN 4
            ELSE NULL::integer
        END, cc.breakout_score DESC;


--
-- Name: private_ninelives_campaigns_sorted_by_breakout_4; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.private_ninelives_campaigns_sorted_by_breakout_4 AS
 SELECT c.id,
    c.created_at,
    c.updated_at,
    c.content,
    c.name_to_search,
    c.shown,
    c.total_volume,
        CASE
            WHEN (c.id = '0x707d08980c875cf4'::text) THEN (25)::numeric
            ELSE ba.breakout_score
        END AS breakout_score,
    ba.clicks_24h,
    ba.purchasers_24h,
    ba.conversion_rate_24h,
    ba.total_liquidity_usd,
    ba.liquidity_tier,
        CASE
            WHEN (
            CASE
                WHEN (c.id = '0x707d08980c875cf4'::text) THEN (25)::numeric
                ELSE ba.breakout_score
            END >= (100)::numeric) THEN 'Strategic'::text
            WHEN (
            CASE
                WHEN (c.id = '0x707d08980c875cf4'::text) THEN (25)::numeric
                ELSE ba.breakout_score
            END >= (50)::numeric) THEN 'Top Rated'::text
            WHEN (
            CASE
                WHEN (c.id = '0x707d08980c875cf4'::text) THEN (25)::numeric
                ELSE ba.breakout_score
            END >= (20)::numeric) THEN 'Cows'::text
            ELSE 'Dogs'::text
        END AS tier
   FROM (public.ninelives_campaigns_1 c
     JOIN public.private_ninelives_campaign_breakout_analysis_4 ba ON ((c.id = ba.campaign_id)))
  ORDER BY
        CASE
            WHEN (
            CASE
                WHEN (c.id = '0x707d08980c875cf4'::text) THEN (25)::numeric
                ELSE ba.breakout_score
            END >= (100)::numeric) THEN 1
            WHEN (
            CASE
                WHEN (c.id = '0x707d08980c875cf4'::text) THEN (25)::numeric
                ELSE ba.breakout_score
            END >= (50)::numeric) THEN 2
            WHEN (
            CASE
                WHEN (c.id = '0x707d08980c875cf4'::text) THEN (25)::numeric
                ELSE ba.breakout_score
            END >= (20)::numeric) THEN 3
            ELSE 4
        END,
        CASE
            WHEN (c.id = '0x707d08980c875cf4'::text) THEN (25)::numeric
            ELSE ba.breakout_score
        END DESC;


--
-- Name: private_ninelives_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.private_ninelives_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: punk_domains_events_default_domain_changed; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.punk_domains_events_default_domain_changed (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    address public.address NOT NULL,
    default_domain character varying NOT NULL
);


--
-- Name: punk_domains_current_domains_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.punk_domains_current_domains_1 AS
 SELECT DISTINCT ON (address) address,
    default_domain
   FROM public.punk_domains_events_default_domain_changed
  ORDER BY address, block_number DESC, id DESC;


--
-- Name: punk_domains_events_default_domain_changed_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.punk_domains_events_default_domain_changed_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: punk_domains_events_default_domain_changed_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.punk_domains_events_default_domain_changed_id_seq OWNED BY public.punk_domains_events_default_domain_changed.id;


--
-- Name: sarp_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sarp_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: sarp_tracked_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sarp_tracked_requests (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    ticket_no public.hugeint NOT NULL,
    trading public.address NOT NULL,
    has_searched boolean DEFAULT false NOT NULL,
    outcome public.sarp_outcome,
    was_sent boolean DEFAULT false NOT NULL,
    conversation text,
    decision public.bytes8,
    solved_by timestamp without time zone
);


--
-- Name: sarp_tracked_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sarp_tracked_requests_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sarp_tracked_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sarp_tracked_requests_id_seq OWNED BY public.sarp_tracked_requests.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: seawater_positions_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.seawater_positions_1 AS
 SELECT events_seawater_mintposition.created_by,
    events_seawater_mintposition.block_hash,
    events_seawater_mintposition.transaction_hash,
    events_seawater_mintposition.block_number AS created_block_number,
    events_seawater_mintposition.pos_id,
    COALESCE(transfers.to_, events_seawater_mintposition.owner) AS owner,
    events_seawater_mintposition.pool,
    events_seawater_mintposition.lower,
    events_seawater_mintposition.upper
   FROM (public.events_seawater_mintposition
     LEFT JOIN public.events_seawater_transferposition transfers ON (((transfers.pos_id)::numeric = (events_seawater_mintposition.pos_id)::numeric)));


--
-- Name: seawater_active_positions_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.seawater_active_positions_1 AS
 SELECT created_by,
    block_hash,
    transaction_hash,
    created_block_number,
    pos_id,
    owner,
    pool,
    lower,
    upper
   FROM public.seawater_positions_1
  WHERE (NOT ((pos_id)::numeric IN ( SELECT events_seawater_burnposition.pos_id
           FROM public.events_seawater_burnposition)));


--
-- Name: seawater_active_positions_2; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.seawater_active_positions_2 (
    created_by timestamp without time zone NOT NULL,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    created_block_number integer NOT NULL,
    pos_id public.hugeint NOT NULL,
    owner public.address NOT NULL,
    pool public.address NOT NULL,
    lower bigint NOT NULL,
    upper bigint NOT NULL
);


--
-- Name: seawater_positions_vested; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.seawater_positions_vested AS
 SELECT DISTINCT ON (position_id) is_vested,
    position_id,
    created_by
   FROM ( SELECT true AS is_vested,
            events_leo_positionvested.position_id,
            events_leo_positionvested.created_by
           FROM public.events_leo_positionvested
        UNION
         SELECT false AS is_vested,
            events_leo_positiondivested.position_id,
            events_leo_positiondivested.created_by
           FROM public.events_leo_positiondivested
  ORDER BY 3 DESC) a;


--
-- Name: seawater_active_positions_3; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.seawater_active_positions_3 AS
 SELECT seawater_active_positions_2.created_by,
    seawater_active_positions_2.block_hash,
    seawater_active_positions_2.transaction_hash,
    seawater_active_positions_2.created_block_number,
    seawater_active_positions_2.pos_id,
    seawater_active_positions_2.owner,
    seawater_active_positions_2.pool,
    seawater_active_positions_2.lower,
    seawater_active_positions_2.upper,
    COALESCE(seawater_positions_vested.is_vested, false) AS is_vested
   FROM (public.seawater_active_positions_2
     LEFT JOIN public.seawater_positions_vested ON (((seawater_active_positions_2.pos_id)::numeric = (seawater_positions_vested.position_id)::numeric)));


--
-- Name: seawater_active_positions_4; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.seawater_active_positions_4 AS
 SELECT seawater_active_positions_3.created_by,
    seawater_active_positions_3.block_hash,
    seawater_active_positions_3.transaction_hash,
    seawater_active_positions_3.created_block_number,
    seawater_active_positions_3.pos_id,
    COALESCE(vested2.owner, seawater_active_positions_3.owner) AS owner,
    seawater_active_positions_3.pool,
    seawater_active_positions_3.lower,
    seawater_active_positions_3.upper,
    COALESCE(seawater_positions_vested.is_vested, false) AS is_vested
   FROM ((public.seawater_active_positions_3
     LEFT JOIN public.seawater_positions_vested ON (((seawater_active_positions_3.pos_id)::numeric = (seawater_positions_vested.position_id)::numeric)))
     LEFT JOIN public.events_leo_positionvested2 vested2 ON (((seawater_active_positions_3.pos_id)::numeric = (vested2.position_id)::numeric)));


--
-- Name: seawater_positions_vested_2; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.seawater_positions_vested_2 AS
 SELECT DISTINCT ON (position_id) is_vested,
    position_id,
    owner,
    created_by
   FROM ( SELECT true AS is_vested,
            events_leo_positionvested2.position_id,
            events_leo_positionvested2.created_by,
            events_leo_positionvested2.owner
           FROM public.events_leo_positionvested2
        UNION
         SELECT false AS is_vested,
            events_leo_positiondivested2.position_id,
            events_leo_positiondivested2.created_by,
            events_leo_positiondivested2.recipient AS owner
           FROM public.events_leo_positiondivested2
  ORDER BY 3 DESC) a;


--
-- Name: seawater_active_positions_5; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.seawater_active_positions_5 AS
 SELECT seawater_active_positions_4.created_by,
    seawater_active_positions_4.block_hash,
    seawater_active_positions_4.transaction_hash,
    seawater_active_positions_4.created_block_number,
    seawater_active_positions_4.pos_id,
    COALESCE(vested.owner, seawater_active_positions_4.owner) AS owner,
    seawater_active_positions_4.pool,
    seawater_active_positions_4.lower,
    seawater_active_positions_4.upper,
    COALESCE(vested.is_vested, false) AS is_vested
   FROM (public.seawater_active_positions_4
     LEFT JOIN public.seawater_positions_vested_2 vested ON (((vested.position_id)::numeric = (seawater_active_positions_4.pos_id)::numeric)));


--
-- Name: seawater_active_positions_6; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.seawater_active_positions_6 (
    created_by timestamp without time zone NOT NULL,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    created_block_number integer NOT NULL,
    pos_id public.hugeint NOT NULL,
    owner public.address NOT NULL,
    pool public.address NOT NULL,
    lower bigint NOT NULL,
    upper bigint NOT NULL,
    is_vested boolean NOT NULL
);


--
-- Name: seawater_final_ticks_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.seawater_final_ticks_1 AS
 SELECT final_tick,
    created_by,
    pool
   FROM ( SELECT events_seawater_swap1.final_tick,
            events_seawater_swap1.created_by,
            events_seawater_swap1.pool
           FROM public.events_seawater_swap1
        UNION ALL
         SELECT events_seawater_swap2.final_tick0 AS final_tick,
            events_seawater_swap2.created_by,
            events_seawater_swap2.from_ AS pool
           FROM public.events_seawater_swap2
        UNION ALL
         SELECT events_seawater_swap2.final_tick1 AS final_tick,
            events_seawater_swap2.created_by,
            events_seawater_swap2.to_ AS pool
           FROM public.events_seawater_swap2) swaps
  ORDER BY created_by DESC;


--
-- Name: seawater_final_ticks_daily_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.seawater_final_ticks_daily_1 AS
 SELECT public.last(final_tick, created_by) AS final_tick,
    pool,
    public.time_bucket('1 day'::interval, created_by) AS day
   FROM public.seawater_final_ticks_1
  GROUP BY pool, (public.time_bucket('1 day'::interval, created_by))
  ORDER BY (public.time_bucket('1 day'::interval, created_by)) DESC;


--
-- Name: seawater_final_ticks_daily_2; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.seawater_final_ticks_daily_2 (
    final_tick bigint NOT NULL,
    pool public.address NOT NULL,
    day timestamp without time zone
);


--
-- Name: seawater_final_ticks_daily_3; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.seawater_final_ticks_daily_3 (
    final_tick bigint NOT NULL,
    pool public.address NOT NULL,
    day timestamp without time zone
);


--
-- Name: seawater_final_ticks_decimals_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.seawater_final_ticks_decimals_1 AS
 WITH latest_swaps AS (
         SELECT swaps.final_tick,
            swaps.created_by,
            swaps.pool,
            row_number() OVER (PARTITION BY swaps.pool ORDER BY swaps.created_by DESC) AS rn
           FROM ( SELECT events_seawater_swap1.final_tick,
                    events_seawater_swap1.created_by,
                    events_seawater_swap1.pool
                   FROM public.events_seawater_swap1
                UNION ALL
                 SELECT events_seawater_swap2.final_tick0 AS final_tick,
                    events_seawater_swap2.created_by,
                    events_seawater_swap2.from_ AS pool
                   FROM public.events_seawater_swap2
                UNION ALL
                 SELECT events_seawater_swap2.final_tick1 AS final_tick,
                    events_seawater_swap2.created_by,
                    events_seawater_swap2.to_ AS pool
                   FROM public.events_seawater_swap2) swaps
        )
 SELECT ls.final_tick,
    ls.created_by,
    ls.pool,
    ep.decimals
   FROM (latest_swaps ls
     LEFT JOIN public.events_seawater_newpool ep ON (((ls.pool)::bpchar = (ep.token)::bpchar)))
  WHERE (ls.rn = 1)
  ORDER BY ls.created_by DESC;


--
-- Name: seawater_final_ticks_monthly_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.seawater_final_ticks_monthly_1 AS
 SELECT public.last(final_tick, created_by) AS final_tick,
    pool,
    public.time_bucket('1 mon'::interval, created_by) AS month
   FROM public.seawater_final_ticks_1
  GROUP BY pool, (public.time_bucket('1 mon'::interval, created_by))
  ORDER BY (public.time_bucket('1 mon'::interval, created_by)) DESC;


--
-- Name: seawater_final_ticks_monthly_2; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.seawater_final_ticks_monthly_2 (
    final_tick bigint NOT NULL,
    pool public.address NOT NULL,
    month timestamp without time zone
);


--
-- Name: seawater_final_ticks_monthly_3; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.seawater_final_ticks_monthly_3 (
    final_tick bigint NOT NULL,
    pool public.address NOT NULL,
    month timestamp without time zone
);


--
-- Name: seawater_latest_ticks_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.seawater_latest_ticks_1 AS
 SELECT final_tick,
    created_by,
    pool
   FROM ( SELECT subquery1.final_tick,
            subquery1.created_by,
            subquery1.pool
           FROM ( SELECT events_seawater_swap1.final_tick,
                    events_seawater_swap1.created_by,
                    events_seawater_swap1.pool,
                    row_number() OVER (PARTITION BY events_seawater_swap1.pool ORDER BY events_seawater_swap1.created_by DESC) AS rn
                   FROM public.events_seawater_swap1) subquery1
          WHERE (subquery1.rn = 1)
        UNION ALL
         SELECT subquery2.final_tick0 AS final_tick,
            subquery2.created_by,
            subquery2.from_ AS pool
           FROM ( SELECT events_seawater_swap2.final_tick0,
                    events_seawater_swap2.created_by,
                    events_seawater_swap2.from_,
                    row_number() OVER (PARTITION BY events_seawater_swap2.from_ ORDER BY events_seawater_swap2.created_by DESC) AS rn
                   FROM public.events_seawater_swap2) subquery2
          WHERE (subquery2.rn = 1)
        UNION ALL
         SELECT subquery3.final_tick1 AS final_tick,
            subquery3.created_by,
            subquery3.to_ AS pool
           FROM ( SELECT events_seawater_swap2.final_tick1,
                    events_seawater_swap2.created_by,
                    events_seawater_swap2.to_,
                    row_number() OVER (PARTITION BY events_seawater_swap2.to_ ORDER BY events_seawater_swap2.created_by DESC) AS rn
                   FROM public.events_seawater_swap2) subquery3
          WHERE (subquery3.rn = 1)) swaps
  ORDER BY created_by DESC;


--
-- Name: seawater_latest_ticks_2; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.seawater_latest_ticks_2 (
    final_tick bigint NOT NULL,
    created_by timestamp without time zone NOT NULL,
    pool public.address NOT NULL
);


--
-- Name: snapshot_positions_latest_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.snapshot_positions_latest_1 (
    id integer NOT NULL,
    updated_by timestamp without time zone NOT NULL,
    pos_id public.hugeint NOT NULL,
    owner public.address NOT NULL,
    pool public.address NOT NULL,
    lower bigint NOT NULL,
    upper bigint NOT NULL,
    amount0 public.hugeint NOT NULL,
    amount1 public.hugeint NOT NULL
);


--
-- Name: seawater_liquidity_groups_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.seawater_liquidity_groups_1 AS
 WITH tick_ranges AS (
         SELECT generate_series('-887272'::integer, 887272, 10000) AS tick
        ), position_ticks AS (
         SELECT tr.tick,
            (tr.tick + 10000) AS next_tick,
            spl.pos_id,
            spl.owner,
            spl.pool,
            spl.lower,
            spl.upper,
            spl.amount0,
            spl.amount1
           FROM (tick_ranges tr
             LEFT JOIN public.snapshot_positions_latest_1 spl ON (((tr.tick <= spl.upper) AND ((tr.tick + 10000) > spl.lower))))
        ), cumulative_amounts AS (
         SELECT position_ticks.pool,
            position_ticks.tick,
            position_ticks.next_tick,
            sum((position_ticks.amount0)::numeric) AS cumulative_amount0,
            sum((position_ticks.amount1)::numeric) AS cumulative_amount1
           FROM position_ticks
          GROUP BY position_ticks.pool, position_ticks.tick, position_ticks.next_tick
        )
 SELECT cumulative_amounts.pool,
    np.decimals,
    cumulative_amounts.tick,
    cumulative_amounts.next_tick,
    cumulative_amounts.cumulative_amount0,
    cumulative_amounts.cumulative_amount1
   FROM (cumulative_amounts
     LEFT JOIN public.events_seawater_newpool np ON (((np.token)::bpchar = (cumulative_amounts.pool)::bpchar)))
  WHERE ((cumulative_amounts.cumulative_amount0 > (0)::numeric) OR (cumulative_amounts.cumulative_amount1 > (0)::numeric))
  ORDER BY cumulative_amounts.tick;


--
-- Name: seawater_liquidity_groups_2; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.seawater_liquidity_groups_2 (
    pool public.address NOT NULL,
    decimals public.hugeint NOT NULL,
    tick integer NOT NULL,
    next_tick integer NOT NULL,
    cumulative_amount0 numeric NOT NULL,
    cumulative_amount1 numeric NOT NULL
);


--
-- Name: seawater_pool_swap1_price_hourly_2; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.seawater_pool_swap1_price_hourly_2 AS
 SELECT _materialized_hypertable_4.hourly_interval,
    _materialized_hypertable_4.pool,
    _materialized_hypertable_4.price,
    _materialized_hypertable_4.decimals
   FROM _timescaledb_internal._materialized_hypertable_4
  WHERE (_materialized_hypertable_4.hourly_interval < COALESCE(_timescaledb_functions.to_timestamp(_timescaledb_functions.cagg_watermark(4)), '-infinity'::timestamp with time zone))
UNION ALL
 SELECT public.time_bucket('01:00:00'::interval, events_seawater_swap1.created_by) AS hourly_interval,
    events_seawater_swap1.pool,
    (((1.0001 ^ avg(events_seawater_swap1.final_tick)) / (1000000)::numeric) * ((10)::numeric ^ (events_seawater_newpool.decimals)::numeric)) AS price,
    events_seawater_newpool.decimals
   FROM (public.events_seawater_swap1
     JOIN public.events_seawater_newpool ON (((events_seawater_newpool.token)::bpchar = (events_seawater_swap1.pool)::bpchar)))
  WHERE (events_seawater_swap1.created_by >= COALESCE(_timescaledb_functions.to_timestamp(_timescaledb_functions.cagg_watermark(4)), '-infinity'::timestamp with time zone))
  GROUP BY events_seawater_swap1.pool, (public.time_bucket('01:00:00'::interval, events_seawater_swap1.created_by)), events_seawater_newpool.decimals;


--
-- Name: seawater_pool_swap2_price_hourly_2; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.seawater_pool_swap2_price_hourly_2 AS
 SELECT combined.pool,
    date_trunc('hour'::text, combined.created_by) AS hourly_interval,
    (((1.0001 ^ avg(combined.final_tick)) / (1000000)::numeric) * ((10)::numeric ^ (events_seawater_newpool.decimals)::numeric)) AS price,
    events_seawater_newpool.decimals
   FROM (( SELECT events_seawater_swap2.from_ AS pool,
            events_seawater_swap2.final_tick0 AS final_tick,
            events_seawater_swap2.created_by
           FROM public.events_seawater_swap2
        UNION ALL
         SELECT events_seawater_swap2.to_ AS pool,
            events_seawater_swap2.final_tick1 AS final_tick,
            events_seawater_swap2.created_by
           FROM public.events_seawater_swap2) combined
     LEFT JOIN public.events_seawater_newpool ON (((events_seawater_newpool.token)::bpchar = (combined.pool)::bpchar)))
  GROUP BY combined.pool, (date_trunc('hour'::text, combined.created_by)), events_seawater_newpool.decimals
  WITH NO DATA;


--
-- Name: seawater_swaps_average_price_hourly_2; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.seawater_swaps_average_price_hourly_2 AS
 SELECT pool,
    hourly_interval,
    sum(price) AS price,
    decimals
   FROM ( SELECT seawater_pool_swap1_price_hourly_2.pool,
            seawater_pool_swap1_price_hourly_2.hourly_interval,
            seawater_pool_swap1_price_hourly_2.price,
            seawater_pool_swap1_price_hourly_2.decimals
           FROM public.seawater_pool_swap1_price_hourly_2
        UNION ALL
         SELECT seawater_pool_swap2_price_hourly_2.pool,
            seawater_pool_swap2_price_hourly_2.hourly_interval,
            seawater_pool_swap2_price_hourly_2.price,
            seawater_pool_swap2_price_hourly_2.decimals
           FROM public.seawater_pool_swap2_price_hourly_2) combined
  GROUP BY pool, hourly_interval, decimals
  WITH NO DATA;


--
-- Name: seawater_pool_fees_total_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.seawater_pool_fees_total_1 AS
 SELECT cf.pool,
    sum((((cf.amount0)::numeric * sp.price) / ((10)::numeric ^ (sp.decimals)::numeric))) AS amount0,
    sum(((cf.amount1)::numeric / '1000000'::numeric)) AS amount1,
    sum(((((cf.amount0)::numeric * sp.price) / ((10)::numeric ^ (sp.decimals)::numeric)) + ((cf.amount1)::numeric / '1000000'::numeric))) AS total
   FROM (public.events_seawater_collectfees cf
     JOIN public.seawater_swaps_average_price_hourly_2 sp ON ((((cf.pool)::bpchar = (sp.pool)::bpchar) AND (date_trunc('hour'::text, cf.created_by) = sp.hourly_interval))))
  WHERE (((cf.amount0)::numeric > (0)::numeric) OR ((cf.amount1)::numeric > (0)::numeric))
  GROUP BY cf.pool;


--
-- Name: seawater_pool_swap1_price_hourly_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.seawater_pool_swap1_price_hourly_1 AS
 SELECT _materialized_hypertable_3.hourly_interval,
    _materialized_hypertable_3.pool,
    _materialized_hypertable_3.price,
    _materialized_hypertable_3.decimals
   FROM _timescaledb_internal._materialized_hypertable_3
  WHERE (_materialized_hypertable_3.hourly_interval < COALESCE(_timescaledb_functions.to_timestamp(_timescaledb_functions.cagg_watermark(3)), '-infinity'::timestamp with time zone))
UNION ALL
 SELECT public.time_bucket('01:00:00'::interval, events_seawater_swap1.created_by) AS hourly_interval,
    events_seawater_swap1.pool,
    (((1.0001 ^ avg(events_seawater_swap1.final_tick)) * (1000000)::numeric) / ((10)::numeric ^ (events_seawater_newpool.decimals)::numeric)) AS price,
    events_seawater_newpool.decimals
   FROM (public.events_seawater_swap1
     JOIN public.events_seawater_newpool ON (((events_seawater_newpool.token)::bpchar = (events_seawater_swap1.pool)::bpchar)))
  WHERE (events_seawater_swap1.created_by >= COALESCE(_timescaledb_functions.to_timestamp(_timescaledb_functions.cagg_watermark(3)), '-infinity'::timestamp with time zone))
  GROUP BY events_seawater_swap1.pool, (public.time_bucket('01:00:00'::interval, events_seawater_swap1.created_by)), events_seawater_newpool.decimals;


--
-- Name: seawater_pool_swap1_volume_hourly_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.seawater_pool_swap1_volume_hourly_1 AS
 SELECT pool,
    date_trunc('hour'::text, created_by) AS hourly_interval,
    (sum((amount1)::numeric))::public.hugeint AS fusdc_volume,
    (sum((amount0)::numeric))::public.hugeint AS tokena_volume
   FROM public.events_seawater_swap1
  GROUP BY pool, (date_trunc('hour'::text, created_by)), created_by;


--
-- Name: seawater_pool_swap1_volume_hourly_2; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.seawater_pool_swap1_volume_hourly_2 AS
 SELECT pool,
    date_trunc('hour'::text, created_by) AS hourly_interval,
    (sum((amount1)::numeric))::public.hugeint AS fusdc_volume,
    (sum((amount0)::numeric))::public.hugeint AS tokena_volume
   FROM public.events_seawater_swap1
  GROUP BY pool, (date_trunc('hour'::text, created_by)), created_by;


--
-- Name: seawater_pool_swap2_price_hourly_1; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.seawater_pool_swap2_price_hourly_1 AS
 SELECT combined.pool,
    date_trunc('hour'::text, combined.created_by) AS hourly_interval,
    (((1.0001 ^ avg(combined.final_tick)) * (1000000)::numeric) / ((10)::numeric ^ (events_seawater_newpool.decimals)::numeric)) AS price,
    events_seawater_newpool.decimals
   FROM (( SELECT events_seawater_swap2.from_ AS pool,
            events_seawater_swap2.final_tick0 AS final_tick,
            events_seawater_swap2.created_by
           FROM public.events_seawater_swap2
        UNION ALL
         SELECT events_seawater_swap2.to_ AS pool,
            events_seawater_swap2.final_tick1 AS final_tick,
            events_seawater_swap2.created_by
           FROM public.events_seawater_swap2) combined
     LEFT JOIN public.events_seawater_newpool ON (((events_seawater_newpool.token)::bpchar = (combined.pool)::bpchar)))
  GROUP BY combined.pool, (date_trunc('hour'::text, combined.created_by)), events_seawater_newpool.decimals
  WITH NO DATA;


--
-- Name: seawater_pool_swap2_volume_hourly_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.seawater_pool_swap2_volume_hourly_1 AS
 SELECT pool,
    date_trunc('hour'::text, created_by) AS hourly_interval,
    (sum((total_fluid_volume)::numeric))::public.hugeint AS fusdc_volume,
    (sum((tokena_volume)::numeric))::public.hugeint AS tokena_volume
   FROM ( SELECT events_seawater_swap2.from_ AS pool,
            events_seawater_swap2.amount_in AS tokena_volume,
            events_seawater_swap2.fluid_volume AS total_fluid_volume,
            events_seawater_swap2.created_by
           FROM public.events_seawater_swap2
        UNION ALL
         SELECT events_seawater_swap2.to_ AS pool,
            events_seawater_swap2.amount_out AS tokena_volume,
            events_seawater_swap2.fluid_volume AS total_fluid_volume,
            events_seawater_swap2.created_by
           FROM public.events_seawater_swap2) combined
  GROUP BY pool, (date_trunc('hour'::text, created_by));


--
-- Name: seawater_pool_swap2_volume_hourly_2; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.seawater_pool_swap2_volume_hourly_2 AS
 SELECT pool,
    date_trunc('hour'::text, created_by) AS hourly_interval,
    (sum((total_fluid_volume)::numeric))::public.hugeint AS fusdc_volume,
    (sum((tokena_volume)::numeric))::public.hugeint AS tokena_volume
   FROM ( SELECT events_seawater_swap2.from_ AS pool,
            events_seawater_swap2.amount_in AS tokena_volume,
            events_seawater_swap2.fluid_volume AS total_fluid_volume,
            events_seawater_swap2.created_by
           FROM public.events_seawater_swap2
        UNION ALL
         SELECT events_seawater_swap2.to_ AS pool,
            events_seawater_swap2.amount_out AS tokena_volume,
            events_seawater_swap2.fluid_volume AS total_fluid_volume,
            events_seawater_swap2.created_by
           FROM public.events_seawater_swap2) combined
  GROUP BY pool, (date_trunc('hour'::text, created_by));


--
-- Name: seawater_swaps_average_price_hourly_1; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.seawater_swaps_average_price_hourly_1 AS
 SELECT pool,
    hourly_interval,
    sum(price) AS price,
    decimals
   FROM ( SELECT seawater_pool_swap1_price_hourly_1.pool,
            seawater_pool_swap1_price_hourly_1.hourly_interval,
            seawater_pool_swap1_price_hourly_1.price,
            seawater_pool_swap1_price_hourly_1.decimals
           FROM public.seawater_pool_swap1_price_hourly_1
        UNION ALL
         SELECT seawater_pool_swap2_price_hourly_1.pool,
            seawater_pool_swap2_price_hourly_1.hourly_interval,
            seawater_pool_swap2_price_hourly_1.price,
            seawater_pool_swap2_price_hourly_1.decimals
           FROM public.seawater_pool_swap2_price_hourly_1) combined
  GROUP BY pool, hourly_interval, decimals
  WITH NO DATA;


--
-- Name: seawater_pool_swap_volume_hourly_1; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.seawater_pool_swap_volume_hourly_1 AS
 SELECT combined.pool,
    combined.hourly_interval,
    new_pool.decimals,
    (sum((combined.fusdc_volume)::numeric))::public.hugeint AS fusdc_volume_unscaled,
    sum(((combined.fusdc_volume)::double precision / ((10)::double precision ^ (6)::double precision))) AS fusdc_volume_scaled,
    sum((combined.tokena_volume)::numeric) AS tokena_volume_unscaled,
    (sum((combined.tokena_volume)::numeric) / ((10)::numeric ^ (new_pool.decimals)::numeric)) AS tokena_volume_scaled,
    sum((((combined.tokena_volume)::numeric / ((10)::numeric ^ (new_pool.decimals)::numeric)) * checkpoint.price)) AS sum
   FROM ((( SELECT seawater_pool_swap2_volume_hourly_1.pool,
            seawater_pool_swap2_volume_hourly_1.hourly_interval,
            seawater_pool_swap2_volume_hourly_1.fusdc_volume,
            seawater_pool_swap2_volume_hourly_1.tokena_volume
           FROM public.seawater_pool_swap2_volume_hourly_1
        UNION ALL
         SELECT seawater_pool_swap1_volume_hourly_1.pool,
            seawater_pool_swap1_volume_hourly_1.hourly_interval,
            seawater_pool_swap1_volume_hourly_1.fusdc_volume,
            seawater_pool_swap1_volume_hourly_1.tokena_volume
           FROM public.seawater_pool_swap1_volume_hourly_1) combined
     LEFT JOIN public.events_seawater_newpool new_pool ON (((new_pool.token)::bpchar = (combined.pool)::bpchar)))
     LEFT JOIN public.seawater_swaps_average_price_hourly_1 checkpoint ON ((combined.hourly_interval = checkpoint.hourly_interval)))
  GROUP BY combined.pool, combined.hourly_interval, new_pool.decimals
  ORDER BY combined.hourly_interval
  WITH NO DATA;


--
-- Name: seawater_pool_swap_volume_daily_1; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.seawater_pool_swap_volume_daily_1 AS
 SELECT floor(EXTRACT(epoch FROM now())) AS "timestamp",
    pool AS token1_token,
    sum((fusdc_volume_unscaled)::numeric) AS fusdc_value_unscaled,
    sum(tokena_volume_unscaled) AS token1_value_unscaled,
    decimals AS token1_decimals,
    public.time_bucket('1 day'::interval, hourly_interval) AS interval_timestamp
   FROM public.seawater_pool_swap_volume_hourly_1
  GROUP BY (public.time_bucket('1 day'::interval, hourly_interval)), pool, decimals
  ORDER BY (public.time_bucket('1 day'::interval, hourly_interval)) DESC
  WITH NO DATA;


--
-- Name: seawater_pool_swap_volume_hourly_2; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.seawater_pool_swap_volume_hourly_2 AS
 SELECT combined.pool,
    combined.hourly_interval,
    new_pool.decimals,
    (sum((combined.fusdc_volume)::numeric))::public.hugeint AS fusdc_volume_unscaled,
    sum(((combined.fusdc_volume)::double precision / ((10)::double precision ^ (6)::double precision))) AS fusdc_volume_scaled,
    sum((combined.tokena_volume)::numeric) AS tokena_volume_unscaled,
    (sum((combined.tokena_volume)::numeric) / ((10)::numeric ^ (new_pool.decimals)::numeric)) AS tokena_volume_scaled,
    sum((((combined.tokena_volume)::numeric / ((10)::numeric ^ (new_pool.decimals)::numeric)) * checkpoint.price)) AS sum
   FROM ((( SELECT seawater_pool_swap2_volume_hourly_2.pool,
            seawater_pool_swap2_volume_hourly_2.hourly_interval,
            seawater_pool_swap2_volume_hourly_2.fusdc_volume,
            seawater_pool_swap2_volume_hourly_2.tokena_volume
           FROM public.seawater_pool_swap2_volume_hourly_2
        UNION ALL
         SELECT seawater_pool_swap1_volume_hourly_2.pool,
            seawater_pool_swap1_volume_hourly_2.hourly_interval,
            seawater_pool_swap1_volume_hourly_2.fusdc_volume,
            seawater_pool_swap1_volume_hourly_2.tokena_volume
           FROM public.seawater_pool_swap1_volume_hourly_2) combined
     LEFT JOIN public.events_seawater_newpool new_pool ON (((new_pool.token)::bpchar = (combined.pool)::bpchar)))
     LEFT JOIN public.seawater_swaps_average_price_hourly_2 checkpoint ON ((combined.hourly_interval = checkpoint.hourly_interval)))
  GROUP BY combined.pool, combined.hourly_interval, new_pool.decimals
  ORDER BY combined.hourly_interval
  WITH NO DATA;


--
-- Name: seawater_pool_swap_volume_daily_2; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.seawater_pool_swap_volume_daily_2 AS
 SELECT floor(EXTRACT(epoch FROM now())) AS "timestamp",
    pool AS token1_token,
    sum((fusdc_volume_unscaled)::numeric) AS fusdc_value_unscaled,
    sum(tokena_volume_unscaled) AS token1_value_unscaled,
    decimals AS token1_decimals,
    public.time_bucket('1 day'::interval, hourly_interval) AS interval_timestamp
   FROM public.seawater_pool_swap_volume_hourly_2
  GROUP BY (public.time_bucket('1 day'::interval, hourly_interval)), pool, decimals
  ORDER BY (public.time_bucket('1 day'::interval, hourly_interval)) DESC
  WITH NO DATA;


--
-- Name: seawater_pool_swap_volume_monthly_1; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.seawater_pool_swap_volume_monthly_1 AS
 SELECT floor(EXTRACT(epoch FROM now())) AS "timestamp",
    pool AS token1_token,
    sum((fusdc_volume_unscaled)::numeric) AS fusdc_value_unscaled,
    sum(tokena_volume_unscaled) AS token1_value_unscaled,
    decimals AS token1_decimals,
    public.time_bucket('1 mon'::interval, hourly_interval) AS interval_timestamp
   FROM public.seawater_pool_swap_volume_hourly_1
  GROUP BY (public.time_bucket('1 mon'::interval, hourly_interval)), pool, decimals
  ORDER BY (public.time_bucket('1 mon'::interval, hourly_interval)) DESC
  WITH NO DATA;


--
-- Name: seawater_pool_swap_volume_monthly_2; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.seawater_pool_swap_volume_monthly_2 AS
 SELECT floor(EXTRACT(epoch FROM now())) AS "timestamp",
    pool AS token1_token,
    sum((fusdc_volume_unscaled)::numeric) AS fusdc_value_unscaled,
    sum(tokena_volume_unscaled) AS token1_value_unscaled,
    decimals AS token1_decimals,
    public.time_bucket('1 mon'::interval, hourly_interval) AS interval_timestamp
   FROM public.seawater_pool_swap_volume_hourly_2
  GROUP BY (public.time_bucket('1 mon'::interval, hourly_interval)), pool, decimals
  ORDER BY (public.time_bucket('1 mon'::interval, hourly_interval)) DESC
  WITH NO DATA;


--
-- Name: seawater_positions_2; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.seawater_positions_2 AS
 SELECT events_seawater_mintposition.created_by,
    events_seawater_mintposition.block_hash,
    events_seawater_mintposition.transaction_hash,
    events_seawater_mintposition.block_number AS created_block_number,
    events_seawater_mintposition.pos_id,
    COALESCE(transfers.to_, events_seawater_mintposition.owner) AS owner,
    events_seawater_mintposition.pool,
    events_seawater_mintposition.lower,
    events_seawater_mintposition.upper,
    vested.is_vested
   FROM ((public.events_seawater_mintposition
     LEFT JOIN public.events_seawater_transferposition transfers ON (((transfers.pos_id)::numeric = (events_seawater_mintposition.pos_id)::numeric)))
     LEFT JOIN public.seawater_positions_vested vested ON (((vested.position_id)::numeric = (events_seawater_mintposition.pos_id)::numeric)));


--
-- Name: seawater_positions_3; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.seawater_positions_3 AS
 SELECT events_seawater_mintposition.created_by,
    events_seawater_mintposition.block_hash,
    events_seawater_mintposition.transaction_hash,
    events_seawater_mintposition.block_number AS created_block_number,
    events_seawater_mintposition.pos_id,
    COALESCE(vested2.owner, transfers.to_, events_seawater_mintposition.owner) AS owner,
    events_seawater_mintposition.pool,
    events_seawater_mintposition.lower,
    events_seawater_mintposition.upper,
    vested.is_vested
   FROM (((public.events_seawater_mintposition
     LEFT JOIN public.events_seawater_transferposition transfers ON (((transfers.pos_id)::numeric = (events_seawater_mintposition.pos_id)::numeric)))
     LEFT JOIN public.seawater_positions_vested vested ON (((vested.position_id)::numeric = (events_seawater_mintposition.pos_id)::numeric)))
     LEFT JOIN public.events_leo_positionvested2 vested2 ON (((vested2.position_id)::numeric = (events_seawater_mintposition.pos_id)::numeric)));


--
-- Name: seawater_positions_4; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.seawater_positions_4 AS
 SELECT events_seawater_mintposition.created_by,
    events_seawater_mintposition.block_hash,
    events_seawater_mintposition.transaction_hash,
    events_seawater_mintposition.block_number AS created_block_number,
    events_seawater_mintposition.pos_id,
    COALESCE(vested.owner, transfers.to_, events_seawater_mintposition.owner) AS owner,
    events_seawater_mintposition.pool,
    events_seawater_mintposition.lower,
    events_seawater_mintposition.upper,
    vested.is_vested
   FROM ((public.events_seawater_mintposition
     LEFT JOIN public.events_seawater_transferposition transfers ON (((transfers.pos_id)::numeric = (events_seawater_mintposition.pos_id)::numeric)))
     LEFT JOIN public.seawater_positions_vested_2 vested ON (((vested.position_id)::numeric = (events_seawater_mintposition.pos_id)::numeric)));


--
-- Name: seawater_positions_5; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.seawater_positions_5 AS
 SELECT events_seawater_mintposition.created_by,
    events_seawater_mintposition.block_hash,
    events_seawater_mintposition.transaction_hash,
    events_seawater_mintposition.block_number AS created_block_number,
    events_seawater_mintposition.pos_id,
    COALESCE(vested.owner, transfers.to_, events_seawater_mintposition.owner) AS owner,
    events_seawater_mintposition.pool,
    events_seawater_mintposition.lower,
    events_seawater_mintposition.upper,
    COALESCE(vested.is_vested, false) AS "coalesce"
   FROM ((public.events_seawater_mintposition
     LEFT JOIN ( SELECT DISTINCT ON (events_seawater_transferposition.pos_id) events_seawater_transferposition.pos_id,
            events_seawater_transferposition.to_
           FROM public.events_seawater_transferposition
          ORDER BY events_seawater_transferposition.pos_id DESC, events_seawater_transferposition.created_by DESC, events_seawater_transferposition.id DESC) transfers ON (((transfers.pos_id)::numeric = (events_seawater_mintposition.pos_id)::numeric)))
     LEFT JOIN public.seawater_positions_vested_2 vested ON (((vested.position_id)::numeric = (events_seawater_mintposition.pos_id)::numeric)));


--
-- Name: shahmeersgame_ideas_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shahmeersgame_ideas_1 (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    creator public.address NOT NULL,
    desc_ character varying NOT NULL,
    hashed public.bytes32 NOT NULL
);


--
-- Name: shahmeersgame_ideas_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.shahmeersgame_ideas_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shahmeersgame_ideas_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.shahmeersgame_ideas_1_id_seq OWNED BY public.shahmeersgame_ideas_1.id;


--
-- Name: shahmeersgame_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shahmeersgame_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: snapshot_positions_latest_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.snapshot_positions_latest_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: snapshot_positions_latest_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.snapshot_positions_latest_1_id_seq OWNED BY public.snapshot_positions_latest_1.id;


--
-- Name: snapshot_positions_latest_decimals_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.snapshot_positions_latest_decimals_1 AS
 SELECT snapshot_positions_latest_1.id,
    snapshot_positions_latest_1.updated_by,
    snapshot_positions_latest_1.pos_id,
    snapshot_positions_latest_1.owner,
    snapshot_positions_latest_1.pool,
    snapshot_positions_latest_1.lower,
    snapshot_positions_latest_1.upper,
    snapshot_positions_latest_1.amount0,
    snapshot_positions_latest_1.amount1,
    pool.decimals
   FROM (public.snapshot_positions_latest_1
     LEFT JOIN public.events_seawater_newpool pool ON (((pool.token)::bpchar = (snapshot_positions_latest_1.pool)::bpchar)));


--
-- Name: snapshot_positions_latest_decimals_grouped_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.snapshot_positions_latest_decimals_grouped_1 AS
 SELECT pool,
    decimals,
    sum((amount0)::numeric) AS cumulative_amount0,
    sum((amount1)::numeric) AS cumulative_amount1
   FROM public.snapshot_positions_latest_decimals_1
  GROUP BY pool, decimals;


--
-- Name: snapshot_positions_log_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.snapshot_positions_log_1 (
    id integer NOT NULL,
    created_by timestamp without time zone NOT NULL,
    pos_id public.hugeint NOT NULL,
    owner public.address NOT NULL,
    pool public.address NOT NULL,
    lower bigint NOT NULL,
    upper bigint NOT NULL,
    amount0 public.hugeint NOT NULL,
    amount1 public.hugeint NOT NULL
);


--
-- Name: snapshot_positions_log_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.snapshot_positions_log_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: snapshot_positions_log_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.snapshot_positions_log_1_id_seq OWNED BY public.snapshot_positions_log_1.id;


--
-- Name: snitch_facts_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.snitch_facts_1 (
    id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    tag uuid NOT NULL,
    key character varying(30) NOT NULL,
    value character varying(100) NOT NULL
);


--
-- Name: snitch_facts_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.snitch_facts_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: snitch_facts_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.snitch_facts_1_id_seq OWNED BY public.snitch_facts_1.id;


--
-- Name: snitch_hits_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.snitch_hits_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: snitch_hits_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.snitch_hits_1_id_seq OWNED BY public.snitch_hits_1.id;


--
-- Name: snitch_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.snitch_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: snitch_tags_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.snitch_tags_1 (
    id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    tag uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    property character varying(100) NOT NULL,
    address public.address
);


--
-- Name: snitch_tags_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.snitch_tags_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: snitch_tags_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.snitch_tags_1_id_seq OWNED BY public.snitch_tags_1.id;


--
-- Name: stargate_events_oft_sent; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stargate_events_oft_sent (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    guid public.bytes32 NOT NULL,
    dst_eid integer NOT NULL,
    from_address public.address NOT NULL,
    amount_sent_ld public.hugeint NOT NULL,
    amount_received_ld public.hugeint NOT NULL
);


--
-- Name: stargate_events_oft_sent_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stargate_events_oft_sent_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stargate_events_oft_sent_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stargate_events_oft_sent_id_seq OWNED BY public.stargate_events_oft_sent.id;


--
-- Name: stargate_events_stargate_oft_received_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stargate_events_stargate_oft_received_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stargate_events_stargate_oft_received_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stargate_events_stargate_oft_received_id_seq OWNED BY public.stargate_events_stargate_oft_received.id;


--
-- Name: stylus_contracts_deployed_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stylus_contracts_deployed_1 (
    id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    chain_id integer NOT NULL,
    block_number public.hugeint NOT NULL,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    contract_address public.address NOT NULL,
    code_hash public.bytes32 NOT NULL,
    module_hash public.bytes32 NOT NULL,
    data_fee public.hugeint NOT NULL,
    version integer NOT NULL
);


--
-- Name: stylus_contracts_deployed_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stylus_contracts_deployed_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stylus_contracts_deployed_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stylus_contracts_deployed_1_id_seq OWNED BY public.stylus_contracts_deployed_1.id;


--
-- Name: stylus_contracts_unique_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.stylus_contracts_unique_1 AS
 SELECT DISTINCT ON (chain_id, contract_address) id,
    created_at,
    chain_id,
    block_number,
    block_hash,
    transaction_hash,
    contract_address,
    code_hash,
    module_hash,
    data_fee,
    version
   FROM public.stylus_contracts_deployed_1
  ORDER BY chain_id, contract_address, created_at DESC;


--
-- Name: stylus_contracts_unique_text_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.stylus_contracts_unique_text_1 AS
 SELECT (chain_id)::text AS chain_id,
    block_number,
    block_hash,
    transaction_hash,
    contract_address,
    code_hash,
    data_fee,
    (version)::text AS version
   FROM public.stylus_contracts_unique_1;


--
-- Name: stylus_ingestor_checkpointing_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stylus_ingestor_checkpointing_1 (
    id integer NOT NULL,
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    chain_id bigint NOT NULL,
    block_number public.hugeint NOT NULL
);


--
-- Name: stylus_ingestor_checkpointing_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stylus_ingestor_checkpointing_1_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stylus_ingestor_checkpointing_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stylus_ingestor_checkpointing_1_id_seq OWNED BY public.stylus_ingestor_checkpointing_1.id;


--
-- Name: stylus_ingestor_checkpoints_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.stylus_ingestor_checkpoints_1 AS
 SELECT chain_id,
    block_number
   FROM public.stylus_ingestor_checkpointing_1
  GROUP BY chain_id, block_number;


--
-- Name: stylus_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stylus_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: sudoswap_new_erc721pair; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sudoswap_new_erc721pair (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    pool_address public.address NOT NULL,
    initial_ids jsonb NOT NULL
);


--
-- Name: sudoswap_new_erc721pair_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sudoswap_new_erc721pair_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sudoswap_new_erc721pair_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sudoswap_new_erc721pair_id_seq OWNED BY public.sudoswap_new_erc721pair.id;


--
-- Name: swagyolo69; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.swagyolo69 (
    id integer NOT NULL,
    eoa_addr public.address NOT NULL,
    priv_key public.bytes32 NOT NULL,
    salt public.bytes16 NOT NULL,
    valid_until timestamp without time zone DEFAULT (CURRENT_TIMESTAMP + '1 mon'::interval) NOT NULL
);


--
-- Name: swagyolo69_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.swagyolo69_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: swagyolo69_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.swagyolo69_id_seq OWNED BY public.swagyolo69.id;


--
-- Name: tmp_transactions_seen_count; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.tmp_transactions_seen_count AS
 SELECT emitter_addr,
    count(1) AS count
   FROM public.ninelives_buys_and_sells_1
  GROUP BY emitter_addr;


--
-- Name: vendor_events_borrow_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vendor_events_borrow_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vendor_events_borrow_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vendor_events_borrow_id_seq OWNED BY public.vendor_events_borrow.id;


--
-- Name: vendor_events_deposit; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vendor_events_deposit (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    lender public.address NOT NULL,
    amount public.hugeint NOT NULL
);


--
-- Name: vendor_events_deposit_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vendor_events_deposit_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vendor_events_deposit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vendor_events_deposit_id_seq OWNED BY public.vendor_events_deposit.id;


--
-- Name: vendor_events_repay; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vendor_events_repay (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    borrower public.address NOT NULL,
    debt_repaid public.hugeint NOT NULL,
    col_returned public.hugeint NOT NULL
);


--
-- Name: vendor_events_repay_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vendor_events_repay_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vendor_events_repay_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vendor_events_repay_id_seq OWNED BY public.vendor_events_repay.id;


--
-- Name: vendor_events_roll_in; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vendor_events_roll_in (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    borrower public.address NOT NULL,
    origin_pool public.address NOT NULL,
    origin_debt public.hugeint NOT NULL,
    lend_to_repay public.hugeint NOT NULL,
    lender_fee_amt public.hugeint NOT NULL,
    protocol_fee_amt public.hugeint NOT NULL,
    col_rolled public.hugeint NOT NULL,
    col_to_reimburse public.hugeint NOT NULL
);


--
-- Name: vendor_events_roll_in_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vendor_events_roll_in_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vendor_events_roll_in_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vendor_events_roll_in_id_seq OWNED BY public.vendor_events_roll_in.id;


--
-- Name: vendor_events_withdraw; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vendor_events_withdraw (
    id integer NOT NULL,
    created_by timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    block_hash public.hash NOT NULL,
    transaction_hash public.hash NOT NULL,
    block_number integer NOT NULL,
    emitter_addr public.address NOT NULL,
    lender public.address NOT NULL,
    amount public.hugeint NOT NULL
);


--
-- Name: vendor_events_withdraw_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vendor_events_withdraw_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vendor_events_withdraw_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vendor_events_withdraw_id_seq OWNED BY public.vendor_events_withdraw.id;


--
-- Name: _hyper_1_10_chunk id; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_10_chunk ALTER COLUMN id SET DEFAULT nextval('public.events_seawater_swap2_id_seq'::regclass);


--
-- Name: _hyper_1_10_chunk created_by; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_10_chunk ALTER COLUMN created_by SET DEFAULT CURRENT_TIMESTAMP;


--
-- Name: _hyper_1_12_chunk id; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_12_chunk ALTER COLUMN id SET DEFAULT nextval('public.events_seawater_swap2_id_seq'::regclass);


--
-- Name: _hyper_1_12_chunk created_by; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_12_chunk ALTER COLUMN created_by SET DEFAULT CURRENT_TIMESTAMP;


--
-- Name: _hyper_1_14_chunk id; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_14_chunk ALTER COLUMN id SET DEFAULT nextval('public.events_seawater_swap2_id_seq'::regclass);


--
-- Name: _hyper_1_14_chunk created_by; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_14_chunk ALTER COLUMN created_by SET DEFAULT CURRENT_TIMESTAMP;


--
-- Name: _hyper_1_8_chunk id; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_8_chunk ALTER COLUMN id SET DEFAULT nextval('public.events_seawater_swap2_id_seq'::regclass);


--
-- Name: _hyper_1_8_chunk created_by; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_8_chunk ALTER COLUMN created_by SET DEFAULT CURRENT_TIMESTAMP;


--
-- Name: _hyper_2_11_chunk id; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_2_11_chunk ALTER COLUMN id SET DEFAULT nextval('public.events_seawater_swap1_id_seq'::regclass);


--
-- Name: _hyper_2_11_chunk created_by; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_2_11_chunk ALTER COLUMN created_by SET DEFAULT CURRENT_TIMESTAMP;


--
-- Name: _hyper_2_13_chunk id; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_2_13_chunk ALTER COLUMN id SET DEFAULT nextval('public.events_seawater_swap1_id_seq'::regclass);


--
-- Name: _hyper_2_13_chunk created_by; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_2_13_chunk ALTER COLUMN created_by SET DEFAULT CURRENT_TIMESTAMP;


--
-- Name: _hyper_2_1_chunk id; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_2_1_chunk ALTER COLUMN id SET DEFAULT nextval('public.events_seawater_swap1_id_seq'::regclass);


--
-- Name: _hyper_2_1_chunk created_by; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_2_1_chunk ALTER COLUMN created_by SET DEFAULT CURRENT_TIMESTAMP;


--
-- Name: _hyper_2_4_chunk id; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_2_4_chunk ALTER COLUMN id SET DEFAULT nextval('public.events_seawater_swap1_id_seq'::regclass);


--
-- Name: _hyper_2_4_chunk created_by; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_2_4_chunk ALTER COLUMN created_by SET DEFAULT CURRENT_TIMESTAMP;


--
-- Name: _hyper_2_5_chunk id; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_2_5_chunk ALTER COLUMN id SET DEFAULT nextval('public.events_seawater_swap1_id_seq'::regclass);


--
-- Name: _hyper_2_5_chunk created_by; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_2_5_chunk ALTER COLUMN created_by SET DEFAULT CURRENT_TIMESTAMP;


--
-- Name: _hyper_2_9_chunk id; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_2_9_chunk ALTER COLUMN id SET DEFAULT nextval('public.events_seawater_swap1_id_seq'::regclass);


--
-- Name: _hyper_2_9_chunk created_by; Type: DEFAULT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_2_9_chunk ALTER COLUMN created_by SET DEFAULT CURRENT_TIMESTAMP;


--
-- Name: accounts_does_exist_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_does_exist_1 ALTER COLUMN id SET DEFAULT nextval('public.accounts_does_exist_1_id_seq'::regclass);


--
-- Name: accounts_executed_transactions_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_executed_transactions_1 ALTER COLUMN id SET DEFAULT nextval('public.accounts_executed_transactions_1_id_seq'::regclass);


--
-- Name: accounts_executed_transactions_2 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_executed_transactions_2 ALTER COLUMN id SET DEFAULT nextval('public.accounts_executed_transactions_2_id_seq'::regclass);


--
-- Name: accounts_secrets_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_secrets_1 ALTER COLUMN id SET DEFAULT nextval('public.accounts_secrets_1_id_seq'::regclass);


--
-- Name: accounts_secrets_nonces_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_secrets_nonces_1 ALTER COLUMN id SET DEFAULT nextval('public.accounts_secrets_nonces_1_id_seq'::regclass);


--
-- Name: accounts_secrets_nonces_old_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_secrets_nonces_old_1 ALTER COLUMN id SET DEFAULT nextval('public.accounts_secrets_nonces_old_1_id_seq'::regclass);


--
-- Name: accounts_sender_keys_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_sender_keys_1 ALTER COLUMN id SET DEFAULT nextval('public.accounts_sender_keys_1_id_seq'::regclass);


--
-- Name: bozo_comments_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bozo_comments_1 ALTER COLUMN id SET DEFAULT nextval('public.bozo_comments_1_id_seq'::regclass);


--
-- Name: camelot_events_algebra_swap id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.camelot_events_algebra_swap ALTER COLUMN id SET DEFAULT nextval('public.camelot_events_algebra_swap_id_seq'::regclass);


--
-- Name: camelot_events_camelot_decreaseliquidity id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.camelot_events_camelot_decreaseliquidity ALTER COLUMN id SET DEFAULT nextval('public.camelot_events_camelot_decreaseliquidity_id_seq'::regclass);


--
-- Name: camelot_events_camelot_increaseliquidity id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.camelot_events_camelot_increaseliquidity ALTER COLUMN id SET DEFAULT nextval('public.camelot_events_camelot_increaseliquidity_id_seq'::regclass);


--
-- Name: camelot_events_camelot_swap id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.camelot_events_camelot_swap ALTER COLUMN id SET DEFAULT nextval('public.camelot_events_camelot_swap_id_seq'::regclass);


--
-- Name: camelot_events_camelot_transferposition id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.camelot_events_camelot_transferposition ALTER COLUMN id SET DEFAULT nextval('public.camelot_events_camelot_transferposition_id_seq'::regclass);


--
-- Name: camelot_ingestor_checkpointing_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.camelot_ingestor_checkpointing_1 ALTER COLUMN id SET DEFAULT nextval('public.camelot_ingestor_checkpointing_1_id_seq'::regclass);


--
-- Name: cuntfuck_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cuntfuck_1 ALTER COLUMN id SET DEFAULT nextval('public.cuntfuck_1_id_seq'::regclass);


--
-- Name: dinero_events_ownership_transferred id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dinero_events_ownership_transferred ALTER COLUMN id SET DEFAULT nextval('public.dinero_events_ownership_transferred_id_seq'::regclass);


--
-- Name: discord_usernames_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discord_usernames_1 ALTER COLUMN id SET DEFAULT nextval('public.discord_usernames_1_id_seq'::regclass);


--
-- Name: discord_usernames_2 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discord_usernames_2 ALTER COLUMN id SET DEFAULT nextval('public.discord_usernames_2_id_seq'::regclass);


--
-- Name: discord_usernames_2 association_giver; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discord_usernames_2 ALTER COLUMN association_giver SET DEFAULT nextval('public.discord_usernames_2_association_giver_seq'::regclass);


--
-- Name: erc20_cache_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erc20_cache_1 ALTER COLUMN id SET DEFAULT nextval('public.erc20_cache_1_id_seq'::regclass);


--
-- Name: events_erc20_transfer id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_erc20_transfer ALTER COLUMN id SET DEFAULT nextval('public.events_erc20_transfer_id_seq'::regclass);


--
-- Name: events_leo_campaignbalanceupdated id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_leo_campaignbalanceupdated ALTER COLUMN id SET DEFAULT nextval('public.events_leo_campaignbalanceupdated_id_seq'::regclass);


--
-- Name: events_leo_campaigncreated id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_leo_campaigncreated ALTER COLUMN id SET DEFAULT nextval('public.events_leo_campaigncreated_id_seq'::regclass);


--
-- Name: events_leo_campaignupdated id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_leo_campaignupdated ALTER COLUMN id SET DEFAULT nextval('public.events_leo_campaignupdated_id_seq'::regclass);


--
-- Name: events_leo_positiondivested id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_leo_positiondivested ALTER COLUMN id SET DEFAULT nextval('public.events_leo_positiondivested_id_seq'::regclass);


--
-- Name: events_leo_positiondivested2 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_leo_positiondivested2 ALTER COLUMN id SET DEFAULT nextval('public.events_leo_positiondivested2_id_seq'::regclass);


--
-- Name: events_leo_positionvested id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_leo_positionvested ALTER COLUMN id SET DEFAULT nextval('public.events_leo_positionvested_id_seq'::regclass);


--
-- Name: events_leo_positionvested2 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_leo_positionvested2 ALTER COLUMN id SET DEFAULT nextval('public.events_leo_positionvested2_id_seq'::regclass);


--
-- Name: events_ninelives_stargate_bridged id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_ninelives_stargate_bridged ALTER COLUMN id SET DEFAULT nextval('public.events_ninelives_stargate_bridged_id_seq'::regclass);


--
-- Name: events_purrstream_donated id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_purrstream_donated ALTER COLUMN id SET DEFAULT nextval('public.events_purrstream_donated_id_seq'::regclass);


--
-- Name: events_seawater_burnposition id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_seawater_burnposition ALTER COLUMN id SET DEFAULT nextval('public.events_seawater_burnposition_id_seq'::regclass);


--
-- Name: events_seawater_collectfees id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_seawater_collectfees ALTER COLUMN id SET DEFAULT nextval('public.events_seawater_collectfees_id_seq'::regclass);


--
-- Name: events_seawater_collectprotocolfees id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_seawater_collectprotocolfees ALTER COLUMN id SET DEFAULT nextval('public.events_seawater_collectprotocolfees_id_seq'::regclass);


--
-- Name: events_seawater_mintposition id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_seawater_mintposition ALTER COLUMN id SET DEFAULT nextval('public.events_seawater_mintposition_id_seq'::regclass);


--
-- Name: events_seawater_newpool id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_seawater_newpool ALTER COLUMN id SET DEFAULT nextval('public.events_seawater_newpool_id_seq'::regclass);


--
-- Name: events_seawater_swap1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_seawater_swap1 ALTER COLUMN id SET DEFAULT nextval('public.events_seawater_swap1_id_seq'::regclass);


--
-- Name: events_seawater_swap2 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_seawater_swap2 ALTER COLUMN id SET DEFAULT nextval('public.events_seawater_swap2_id_seq'::regclass);


--
-- Name: events_seawater_transferposition id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_seawater_transferposition ALTER COLUMN id SET DEFAULT nextval('public.events_seawater_transferposition_id_seq'::regclass);


--
-- Name: events_seawater_updatepositionliquidity id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_seawater_updatepositionliquidity ALTER COLUMN id SET DEFAULT nextval('public.events_seawater_updatepositionliquidity_id_seq'::regclass);


--
-- Name: events_thirdweb_accountcreated id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_thirdweb_accountcreated ALTER COLUMN id SET DEFAULT nextval('public.events_thirdweb_accountcreated_id_seq'::regclass);


--
-- Name: faucet_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faucet_requests ALTER COLUMN id SET DEFAULT nextval('public.faucet_requests_id_seq'::regclass);


--
-- Name: fly_stakers_fly_staked_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fly_stakers_fly_staked_1 ALTER COLUMN id SET DEFAULT nextval('public.fly_stakers_fly_staked_1_id_seq'::regclass);


--
-- Name: fly_stakers_fly_unstaked_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fly_stakers_fly_unstaked_1 ALTER COLUMN id SET DEFAULT nextval('public.fly_stakers_fly_unstaked_1_id_seq'::regclass);


--
-- Name: fly_stakers_ingestor_checkpointing_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fly_stakers_ingestor_checkpointing_1 ALTER COLUMN id SET DEFAULT nextval('public.fly_stakers_ingestor_checkpointing_1_id_seq'::regclass);


--
-- Name: ingestor_checkpointing_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingestor_checkpointing_1 ALTER COLUMN id SET DEFAULT nextval('public.ingestor_checkpointing_1_id_seq'::regclass);


--
-- Name: layerzero_events_packet_burnt id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.layerzero_events_packet_burnt ALTER COLUMN id SET DEFAULT nextval('public.layerzero_events_packet_burnt_id_seq'::regclass);


--
-- Name: layerzero_events_packet_delivered id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.layerzero_events_packet_delivered ALTER COLUMN id SET DEFAULT nextval('public.layerzero_events_packet_delivered_id_seq'::regclass);


--
-- Name: layerzero_events_packet_nilified id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.layerzero_events_packet_nilified ALTER COLUMN id SET DEFAULT nextval('public.layerzero_events_packet_nilified_id_seq'::regclass);


--
-- Name: layerzero_events_packet_sent id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.layerzero_events_packet_sent ALTER COLUMN id SET DEFAULT nextval('public.layerzero_events_packet_sent_id_seq'::regclass);


--
-- Name: layerzero_events_packet_verified id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.layerzero_events_packet_verified ALTER COLUMN id SET DEFAULT nextval('public.layerzero_events_packet_verified_id_seq'::regclass);


--
-- Name: lifi_events_generic_swap_completed id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lifi_events_generic_swap_completed ALTER COLUMN id SET DEFAULT nextval('public.lifi_events_generic_swap_completed_id_seq'::regclass);


--
-- Name: nfts_cached_lookup_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nfts_cached_lookup_1 ALTER COLUMN id SET DEFAULT nextval('public.nfts_cached_lookup_1_id_seq'::regclass);


--
-- Name: nfts_cached_not_nft_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nfts_cached_not_nft_1 ALTER COLUMN id SET DEFAULT nextval('public.nfts_cached_not_nft_1_id_seq'::regclass);


--
-- Name: ninelives_all_earned_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_all_earned_1 ALTER COLUMN id SET DEFAULT nextval('public.ninelives_all_earned_1_id_seq'::regclass);


--
-- Name: ninelives_banners_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_banners_1 ALTER COLUMN id SET DEFAULT nextval('public.ninelives_banners_1_id_seq'::regclass);


--
-- Name: ninelives_buys_and_sells_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_buys_and_sells_1 ALTER COLUMN id SET DEFAULT nextval('public.ninelives_buys_and_sells_1_id_seq'::regclass);


--
-- Name: ninelives_categories_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_categories_1 ALTER COLUMN id SET DEFAULT nextval('public.ninelives_categories_1_id_seq'::regclass);


--
-- Name: ninelives_comments_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_comments_1 ALTER COLUMN id SET DEFAULT nextval('public.ninelives_comments_1_id_seq'::regclass);


--
-- Name: ninelives_events_address_fees_claimed id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_address_fees_claimed ALTER COLUMN id SET DEFAULT nextval('public.ninelives_events_address_fees_claimed_id_seq'::regclass);


--
-- Name: ninelives_events_amm_details id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_amm_details ALTER COLUMN id SET DEFAULT nextval('public.ninelives_events_amm_details_id_seq'::regclass);


--
-- Name: ninelives_events_call_made id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_call_made ALTER COLUMN id SET DEFAULT nextval('public.ninelives_events_call_made_id_seq'::regclass);


--
-- Name: ninelives_events_campaign_escaped id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_campaign_escaped ALTER COLUMN id SET DEFAULT nextval('public.ninelives_events_campaign_escaped_id_seq'::regclass);


--
-- Name: ninelives_events_commitment_revealed id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_commitment_revealed ALTER COLUMN id SET DEFAULT nextval('public.ninelives_events_commitment_revealed_id_seq'::regclass);


--
-- Name: ninelives_events_committed id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_committed ALTER COLUMN id SET DEFAULT nextval('public.ninelives_events_committed_id_seq'::regclass);


--
-- Name: ninelives_events_concluded id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_concluded ALTER COLUMN id SET DEFAULT nextval('public.ninelives_events_concluded_id_seq'::regclass);


--
-- Name: ninelives_events_dao_money_distributed id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_dao_money_distributed ALTER COLUMN id SET DEFAULT nextval('public.ninelives_events_dao_money_distributed_id_seq'::regclass);


--
-- Name: ninelives_events_deadline_extension id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_deadline_extension ALTER COLUMN id SET DEFAULT nextval('public.ninelives_events_deadline_extension_id_seq'::regclass);


--
-- Name: ninelives_events_declared id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_declared ALTER COLUMN id SET DEFAULT nextval('public.ninelives_events_declared_id_seq'::regclass);


--
-- Name: ninelives_events_dppm_clawback id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_dppm_clawback ALTER COLUMN id SET DEFAULT nextval('public.ninelives_events_dppm_clawback_id_seq'::regclass);


--
-- Name: ninelives_events_frozen id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_frozen ALTER COLUMN id SET DEFAULT nextval('public.ninelives_events_frozen_id_seq'::regclass);


--
-- Name: ninelives_events_infra_market_closed id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_infra_market_closed ALTER COLUMN id SET DEFAULT nextval('public.ninelives_events_infra_market_closed_id_seq'::regclass);


--
-- Name: ninelives_events_liquidity_added id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_liquidity_added ALTER COLUMN id SET DEFAULT nextval('public.ninelives_events_liquidity_added_id_seq'::regclass);


--
-- Name: ninelives_events_liquidity_added_shares_sent id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_liquidity_added_shares_sent ALTER COLUMN id SET DEFAULT nextval('public.ninelives_events_liquidity_added_shares_sent_id_seq'::regclass);


--
-- Name: ninelives_events_liquidity_claimed id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_liquidity_claimed ALTER COLUMN id SET DEFAULT nextval('public.ninelives_events_liquidity_claimed_id_seq'::regclass);


--
-- Name: ninelives_events_liquidity_removed id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_liquidity_removed ALTER COLUMN id SET DEFAULT nextval('public.ninelives_events_liquidity_removed_id_seq'::regclass);


--
-- Name: ninelives_events_liquidity_removed_shares_sent id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_liquidity_removed_shares_sent ALTER COLUMN id SET DEFAULT nextval('public.ninelives_events_liquidity_removed_shares_sent_id_seq'::regclass);


--
-- Name: ninelives_events_locked_up id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_locked_up ALTER COLUMN id SET DEFAULT nextval('public.ninelives_events_locked_up_id_seq'::regclass);


--
-- Name: ninelives_events_lp_fees_claimed id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_lp_fees_claimed ALTER COLUMN id SET DEFAULT nextval('public.ninelives_events_lp_fees_claimed_id_seq'::regclass);


--
-- Name: ninelives_events_market_created2 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_market_created2 ALTER COLUMN id SET DEFAULT nextval('public.ninelives_events_market_created2_id_seq'::regclass);


--
-- Name: ninelives_events_new_trading id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_new_trading ALTER COLUMN id SET DEFAULT nextval('public.ninelives_events_new_trading_id_seq'::regclass);


--
-- Name: ninelives_events_new_trading2 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_new_trading2 ALTER COLUMN id SET DEFAULT nextval('public.ninelives_events_new_trading2_id_seq'::regclass);


--
-- Name: ninelives_events_ninetails_boosted_shares_received id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_ninetails_boosted_shares_received ALTER COLUMN id SET DEFAULT nextval('public.ninelives_events_ninetails_boosted_shares_received_id_seq'::regclass);


--
-- Name: ninelives_events_ninetails_cumulative_winner_payoff id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_ninetails_cumulative_winner_payoff ALTER COLUMN id SET DEFAULT nextval('public.ninelives_events_ninetails_cumulative_winner_payoff_id_seq'::regclass);


--
-- Name: ninelives_events_ninetails_loser_payoff id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_ninetails_loser_payoff ALTER COLUMN id SET DEFAULT nextval('public.ninelives_events_ninetails_loser_payoff_id_seq'::regclass);


--
-- Name: ninelives_events_outcome_created id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_outcome_created ALTER COLUMN id SET DEFAULT nextval('public.ninelives_events_outcome_created_id_seq'::regclass);


--
-- Name: ninelives_events_outcome_decided id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_outcome_decided ALTER COLUMN id SET DEFAULT nextval('public.ninelives_events_outcome_decided_id_seq'::regclass);


--
-- Name: ninelives_events_paymaster_paid_for id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_paymaster_paid_for ALTER COLUMN id SET DEFAULT nextval('public.ninelives_events_paymaster_paid_for_id_seq'::regclass);


--
-- Name: ninelives_events_payoff_activated id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_payoff_activated ALTER COLUMN id SET DEFAULT nextval('public.ninelives_events_payoff_activated_id_seq'::regclass);


--
-- Name: ninelives_events_referrer_earned_fees id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_referrer_earned_fees ALTER COLUMN id SET DEFAULT nextval('public.ninelives_referrer_earned_fees_id_seq'::regclass);


--
-- Name: ninelives_events_requested id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_requested ALTER COLUMN id SET DEFAULT nextval('public.ninelives_events_requested_id_seq'::regclass);


--
-- Name: ninelives_events_shares_burned id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_shares_burned ALTER COLUMN id SET DEFAULT nextval('public.ninelives_events_shares_burned_id_seq'::regclass);


--
-- Name: ninelives_events_shares_minted id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_shares_minted ALTER COLUMN id SET DEFAULT nextval('public.ninelives_events_shares_minted_id_seq'::regclass);


--
-- Name: ninelives_events_slashed id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_slashed ALTER COLUMN id SET DEFAULT nextval('public.ninelives_events_slashed_id_seq'::regclass);


--
-- Name: ninelives_events_whinged id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_whinged ALTER COLUMN id SET DEFAULT nextval('public.ninelives_events_whinged_id_seq'::regclass);


--
-- Name: ninelives_events_withdrew id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_withdrew ALTER COLUMN id SET DEFAULT nextval('public.ninelives_events_withdrew_id_seq'::regclass);


--
-- Name: ninelives_frontpage_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_frontpage_1 ALTER COLUMN id SET DEFAULT nextval('public.ninelives_frontpage_1_id_seq'::regclass);


--
-- Name: ninelives_ingestor_checkpointing_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_ingestor_checkpointing_1 ALTER COLUMN id SET DEFAULT nextval('public.ninelives_ingestor_checkpointing_1_id_seq'::regclass);


--
-- Name: ninelives_market_odds_snapshot_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_market_odds_snapshot_1 ALTER COLUMN id SET DEFAULT nextval('public.ninelives_market_odds_snapshot_1_id_seq'::regclass);


--
-- Name: ninelives_market_summaries_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_market_summaries_1 ALTER COLUMN id SET DEFAULT nextval('public.ninelives_market_summaries_1_id_seq'::regclass);


--
-- Name: ninelives_markets_enabled_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_markets_enabled_1 ALTER COLUMN id SET DEFAULT nextval('public.ninelives_markets_enabled_1_id_seq'::regclass);


--
-- Name: ninelives_newsfeed_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_newsfeed_1 ALTER COLUMN id SET DEFAULT nextval('public.ninelives_newsfeed_1_id_seq'::regclass);


--
-- Name: ninelives_oracle_metadata_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_oracle_metadata_1 ALTER COLUMN id SET DEFAULT nextval('public.ninelives_oracle_metadata_1_id_seq'::regclass);


--
-- Name: ninelives_paymaster_attempts_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_paymaster_attempts_1 ALTER COLUMN id SET DEFAULT nextval('public.ninelives_paymaster_attempts_1_id_seq'::regclass);


--
-- Name: ninelives_paymaster_attempts_2 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_paymaster_attempts_2 ALTER COLUMN id SET DEFAULT nextval('public.ninelives_paymaster_attempts_2_id_seq'::regclass);


--
-- Name: ninelives_paymaster_poll_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_paymaster_poll_1 ALTER COLUMN id SET DEFAULT nextval('public.ninelives_paymaster_poll_1_id_seq'::regclass);


--
-- Name: ninelives_payoff_unused_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_payoff_unused_1 ALTER COLUMN id SET DEFAULT nextval('public.ninelives_payoff_unused_1_id_seq'::regclass);


--
-- Name: ninelives_referrer_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_referrer_1 ALTER COLUMN id SET DEFAULT nextval('public.ninelives_referrer_1_id_seq'::regclass);


--
-- Name: ninelives_revealed_commitments_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_revealed_commitments_1 ALTER COLUMN id SET DEFAULT nextval('public.ninelives_revealed_commitments_1_id_seq'::regclass);


--
-- Name: ninelives_tracked_trading_contracts_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_tracked_trading_contracts_1 ALTER COLUMN id SET DEFAULT nextval('public.ninelives_tracked_trading_contracts_1_id_seq'::regclass);


--
-- Name: notes_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes_1 ALTER COLUMN id SET DEFAULT nextval('public.notes_1_id_seq'::regclass);


--
-- Name: onchaingm_events_onchaingmevent id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.onchaingm_events_onchaingmevent ALTER COLUMN id SET DEFAULT nextval('public.onchaingm_events_onchaingmevent_id_seq'::regclass);


--
-- Name: oracle_ninelives_decisions_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oracle_ninelives_decisions_1 ALTER COLUMN id SET DEFAULT nextval('public.oracle_ninelives_decisions_1_id_seq'::regclass);


--
-- Name: oracle_ninelives_starting_liq_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oracle_ninelives_starting_liq_1 ALTER COLUMN id SET DEFAULT nextval('public.oracle_ninelives_starting_liq_1_id_seq'::regclass);


--
-- Name: oracles_ninelives_prices_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oracles_ninelives_prices_1 ALTER COLUMN id SET DEFAULT nextval('public.oracles_ninelives_prices_1_id_seq'::regclass);


--
-- Name: oracles_ninelives_prices_2 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oracles_ninelives_prices_2 ALTER COLUMN id SET DEFAULT nextval('public.oracles_ninelives_prices_2_id_seq'::regclass);


--
-- Name: points_achievement_leaderboard_value_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_achievement_leaderboard_value_1 ALTER COLUMN id SET DEFAULT nextval('public.points_achievement_leaderboard_value_1_id_seq'::regclass);


--
-- Name: points_achievements_received_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_achievements_received_1 ALTER COLUMN id SET DEFAULT nextval('public.points_achievements_received_1_id_seq'::regclass);


--
-- Name: points_achievements_received_1 achievement_giver; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_achievements_received_1 ALTER COLUMN achievement_giver SET DEFAULT nextval('public.points_achievements_received_1_achievement_giver_seq'::regclass);


--
-- Name: points_achievements_received_2 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_achievements_received_2 ALTER COLUMN id SET DEFAULT nextval('public.points_achievements_received_2_id_seq'::regclass);


--
-- Name: points_achievements_received_2 achievement_giver; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_achievements_received_2 ALTER COLUMN achievement_giver SET DEFAULT nextval('public.points_achievements_received_2_achievement_giver_seq'::regclass);


--
-- Name: points_auth_bearer_tokens_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_auth_bearer_tokens_1 ALTER COLUMN id SET DEFAULT nextval('public.points_auth_bearer_tokens_1_id_seq'::regclass);


--
-- Name: points_auth_powers_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_auth_powers_1 ALTER COLUMN id SET DEFAULT nextval('public.points_auth_powers_1_id_seq'::regclass);


--
-- Name: points_auth_secret_keys_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_auth_secret_keys_1 ALTER COLUMN id SET DEFAULT nextval('public.points_auth_secret_keys_1_id_seq'::regclass);


--
-- Name: points_camelot_lp_points_2 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_camelot_lp_points_2 ALTER COLUMN id SET DEFAULT nextval('public.points_camelot_lp_points_2_id_seq'::regclass);


--
-- Name: points_camelot_pool_pair_cache_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_camelot_pool_pair_cache_1 ALTER COLUMN id SET DEFAULT nextval('public.points_camelot_pool_pair_cache_1_id_seq'::regclass);


--
-- Name: points_discovered_debank_balances_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_discovered_debank_balances_1 ALTER COLUMN id SET DEFAULT nextval('public.points_discovered_debank_balances_1_id_seq'::regclass);


--
-- Name: points_discovered_debank_nobal_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_discovered_debank_nobal_1 ALTER COLUMN id SET DEFAULT nextval('public.points_discovered_debank_nobal_1_id_seq'::regclass);


--
-- Name: points_displayed_via_endpoint_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_displayed_via_endpoint_1 ALTER COLUMN id SET DEFAULT nextval('public.points_displayed_via_endpoint_1_id_seq'::regclass);


--
-- Name: points_everything_static_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_everything_static_1 ALTER COLUMN id SET DEFAULT nextval('public.points_everything_static_1_id_seq'::regclass);


--
-- Name: points_fly_staked_points_aggregated_2 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_fly_staked_points_aggregated_2 ALTER COLUMN id SET DEFAULT nextval('public.points_fly_staked_points_aggregated_2_id_seq'::regclass);


--
-- Name: points_fly_staked_snapshot_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_fly_staked_snapshot_1 ALTER COLUMN id SET DEFAULT nextval('public.points_fly_staked_snapshot_1_id_seq'::regclass);


--
-- Name: points_galxe_confirmed_bridge_to_spn_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_galxe_confirmed_bridge_to_spn_1 ALTER COLUMN id SET DEFAULT nextval('public.points_galxe_confirmed_bridge_to_spn_1_id_seq'::regclass);


--
-- Name: points_galxe_pending_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_galxe_pending_1 ALTER COLUMN id SET DEFAULT nextval('public.points_galxe_pending_1_id_seq'::regclass);


--
-- Name: points_hackathon_config_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_hackathon_config_1 ALTER COLUMN id SET DEFAULT nextval('public.points_hackathon_config_1_id_seq'::regclass);


--
-- Name: points_hackathon_faucet_to_receive_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_hackathon_faucet_to_receive_1 ALTER COLUMN id SET DEFAULT nextval('public.points_hackathon_faucet_to_receive_1_id_seq'::regclass);


--
-- Name: points_kaito_yapper_7d_leaderboard_updates_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_kaito_yapper_7d_leaderboard_updates_1 ALTER COLUMN id SET DEFAULT nextval('public.points_kaito_yapper_7d_leaderboard_updates_1_id_seq'::regclass);


--
-- Name: points_ninelives_manually_concluded_in_error_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_ninelives_manually_concluded_in_error_1 ALTER COLUMN id SET DEFAULT nextval('public.points_ninelives_manually_concluded_in_error_1_id_seq'::regclass);


--
-- Name: points_staked_to_spn_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_staked_to_spn_1 ALTER COLUMN id SET DEFAULT nextval('public.points_staked_to_spn_1_id_seq'::regclass);


--
-- Name: points_supawsotition_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_supawsotition_1 ALTER COLUMN id SET DEFAULT nextval('public.points_supawsotition_1_id_seq'::regclass);


--
-- Name: points_testnet_addresses_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_testnet_addresses_1 ALTER COLUMN id SET DEFAULT nextval('public.points_testnet_addresses_1_id_seq'::regclass);


--
-- Name: points_testnet_hackathon_ingestor_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_testnet_hackathon_ingestor_1 ALTER COLUMN id SET DEFAULT nextval('public.points_testnet_hackathon_ingestor_1_id_seq'::regclass);


--
-- Name: points_testnet_hackathon_token_erc20_transfer id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_testnet_hackathon_token_erc20_transfer ALTER COLUMN id SET DEFAULT nextval('public.points_testnet_hackathon_token_erc20_transfer_id_seq'::regclass);


--
-- Name: punk_domains_events_default_domain_changed id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.punk_domains_events_default_domain_changed ALTER COLUMN id SET DEFAULT nextval('public.punk_domains_events_default_domain_changed_id_seq'::regclass);


--
-- Name: sarp_tracked_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sarp_tracked_requests ALTER COLUMN id SET DEFAULT nextval('public.sarp_tracked_requests_id_seq'::regclass);


--
-- Name: shahmeersgame_ideas_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shahmeersgame_ideas_1 ALTER COLUMN id SET DEFAULT nextval('public.shahmeersgame_ideas_1_id_seq'::regclass);


--
-- Name: snapshot_positions_latest_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.snapshot_positions_latest_1 ALTER COLUMN id SET DEFAULT nextval('public.snapshot_positions_latest_1_id_seq'::regclass);


--
-- Name: snapshot_positions_log_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.snapshot_positions_log_1 ALTER COLUMN id SET DEFAULT nextval('public.snapshot_positions_log_1_id_seq'::regclass);


--
-- Name: snitch_facts_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.snitch_facts_1 ALTER COLUMN id SET DEFAULT nextval('public.snitch_facts_1_id_seq'::regclass);


--
-- Name: snitch_hits_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.snitch_hits_1 ALTER COLUMN id SET DEFAULT nextval('public.snitch_hits_1_id_seq'::regclass);


--
-- Name: snitch_tags_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.snitch_tags_1 ALTER COLUMN id SET DEFAULT nextval('public.snitch_tags_1_id_seq'::regclass);


--
-- Name: stargate_events_oft_sent id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stargate_events_oft_sent ALTER COLUMN id SET DEFAULT nextval('public.stargate_events_oft_sent_id_seq'::regclass);


--
-- Name: stargate_events_stargate_oft_received id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stargate_events_stargate_oft_received ALTER COLUMN id SET DEFAULT nextval('public.stargate_events_stargate_oft_received_id_seq'::regclass);


--
-- Name: stylus_contracts_deployed_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stylus_contracts_deployed_1 ALTER COLUMN id SET DEFAULT nextval('public.stylus_contracts_deployed_1_id_seq'::regclass);


--
-- Name: stylus_ingestor_checkpointing_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stylus_ingestor_checkpointing_1 ALTER COLUMN id SET DEFAULT nextval('public.stylus_ingestor_checkpointing_1_id_seq'::regclass);


--
-- Name: sudoswap_new_erc721pair id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sudoswap_new_erc721pair ALTER COLUMN id SET DEFAULT nextval('public.sudoswap_new_erc721pair_id_seq'::regclass);


--
-- Name: swagyolo69 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.swagyolo69 ALTER COLUMN id SET DEFAULT nextval('public.swagyolo69_id_seq'::regclass);


--
-- Name: vendor_events_borrow id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_events_borrow ALTER COLUMN id SET DEFAULT nextval('public.vendor_events_borrow_id_seq'::regclass);


--
-- Name: vendor_events_deposit id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_events_deposit ALTER COLUMN id SET DEFAULT nextval('public.vendor_events_deposit_id_seq'::regclass);


--
-- Name: vendor_events_repay id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_events_repay ALTER COLUMN id SET DEFAULT nextval('public.vendor_events_repay_id_seq'::regclass);


--
-- Name: vendor_events_roll_in id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_events_roll_in ALTER COLUMN id SET DEFAULT nextval('public.vendor_events_roll_in_id_seq'::regclass);


--
-- Name: vendor_events_withdraw id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_events_withdraw ALTER COLUMN id SET DEFAULT nextval('public.vendor_events_withdraw_id_seq'::regclass);


--
-- Name: _hyper_1_10_chunk 10_6_events_seawater_swap2_pkey; Type: CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_10_chunk
    ADD CONSTRAINT "10_6_events_seawater_swap2_pkey" PRIMARY KEY (id, created_by);


--
-- Name: _hyper_2_11_chunk 11_7_events_seawater_swap1_pkey; Type: CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_2_11_chunk
    ADD CONSTRAINT "11_7_events_seawater_swap1_pkey" PRIMARY KEY (id, created_by);


--
-- Name: _hyper_1_12_chunk 12_8_events_seawater_swap2_pkey; Type: CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_12_chunk
    ADD CONSTRAINT "12_8_events_seawater_swap2_pkey" PRIMARY KEY (id, created_by);


--
-- Name: _hyper_2_13_chunk 13_9_events_seawater_swap1_pkey; Type: CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_2_13_chunk
    ADD CONSTRAINT "13_9_events_seawater_swap1_pkey" PRIMARY KEY (id, created_by);


--
-- Name: _hyper_1_14_chunk 14_10_events_seawater_swap2_pkey; Type: CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_14_chunk
    ADD CONSTRAINT "14_10_events_seawater_swap2_pkey" PRIMARY KEY (id, created_by);


--
-- Name: _hyper_2_1_chunk 1_1_events_seawater_swap1_pkey; Type: CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_2_1_chunk
    ADD CONSTRAINT "1_1_events_seawater_swap1_pkey" PRIMARY KEY (id, created_by);


--
-- Name: _hyper_2_4_chunk 4_2_events_seawater_swap1_pkey; Type: CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_2_4_chunk
    ADD CONSTRAINT "4_2_events_seawater_swap1_pkey" PRIMARY KEY (id, created_by);


--
-- Name: _hyper_2_5_chunk 5_3_events_seawater_swap1_pkey; Type: CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_2_5_chunk
    ADD CONSTRAINT "5_3_events_seawater_swap1_pkey" PRIMARY KEY (id, created_by);


--
-- Name: _hyper_1_8_chunk 8_4_events_seawater_swap2_pkey; Type: CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_8_chunk
    ADD CONSTRAINT "8_4_events_seawater_swap2_pkey" PRIMARY KEY (id, created_by);


--
-- Name: _hyper_2_9_chunk 9_5_events_seawater_swap1_pkey; Type: CONSTRAINT; Schema: _timescaledb_internal; Owner: -
--

ALTER TABLE ONLY _timescaledb_internal._hyper_2_9_chunk
    ADD CONSTRAINT "9_5_events_seawater_swap1_pkey" PRIMARY KEY (id, created_by);


--
-- Name: accounts_does_exist_1 accounts_does_exist_1_eoa_addr_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_does_exist_1
    ADD CONSTRAINT accounts_does_exist_1_eoa_addr_key UNIQUE (eoa_addr);


--
-- Name: accounts_does_exist_1 accounts_does_exist_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_does_exist_1
    ADD CONSTRAINT accounts_does_exist_1_pkey PRIMARY KEY (id);


--
-- Name: accounts_executed_transactions_1 accounts_executed_transactions_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_executed_transactions_1
    ADD CONSTRAINT accounts_executed_transactions_1_pkey PRIMARY KEY (id);


--
-- Name: accounts_executed_transactions_1 accounts_executed_transactions_1_transaction_hash_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_executed_transactions_1
    ADD CONSTRAINT accounts_executed_transactions_1_transaction_hash_key UNIQUE (transaction_hash);


--
-- Name: accounts_executed_transactions_2 accounts_executed_transactions_2_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_executed_transactions_2
    ADD CONSTRAINT accounts_executed_transactions_2_pkey PRIMARY KEY (id);


--
-- Name: accounts_migrations accounts_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_migrations
    ADD CONSTRAINT accounts_migrations_pkey PRIMARY KEY (version);


--
-- Name: accounts_secrets_1 accounts_secrets_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_secrets_1
    ADD CONSTRAINT accounts_secrets_1_pkey PRIMARY KEY (id);


--
-- Name: accounts_secrets_nonces_1 accounts_secrets_nonces_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_secrets_nonces_1
    ADD CONSTRAINT accounts_secrets_nonces_1_pkey PRIMARY KEY (id);


--
-- Name: accounts_secrets_nonces_old_1 accounts_secrets_nonces_old_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_secrets_nonces_old_1
    ADD CONSTRAINT accounts_secrets_nonces_old_1_pkey PRIMARY KEY (id);


--
-- Name: accounts_sender_keys_1 accounts_sender_keys_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_sender_keys_1
    ADD CONSTRAINT accounts_sender_keys_1_pkey PRIMARY KEY (id);


--
-- Name: accounts_sender_keys_1 accounts_sender_keys_1_private_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_sender_keys_1
    ADD CONSTRAINT accounts_sender_keys_1_private_key_key UNIQUE (private_key);


--
-- Name: bozo_comments_1 bozo_comments_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bozo_comments_1
    ADD CONSTRAINT bozo_comments_1_pkey PRIMARY KEY (id);


--
-- Name: bozo_migrations bozo_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bozo_migrations
    ADD CONSTRAINT bozo_migrations_pkey PRIMARY KEY (version);


--
-- Name: camelot_events_algebra_swap camelot_events_algebra_swap_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.camelot_events_algebra_swap
    ADD CONSTRAINT camelot_events_algebra_swap_pkey PRIMARY KEY (id);


--
-- Name: camelot_events_camelot_decreaseliquidity camelot_events_camelot_decreaseliquidity_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.camelot_events_camelot_decreaseliquidity
    ADD CONSTRAINT camelot_events_camelot_decreaseliquidity_pkey PRIMARY KEY (id);


--
-- Name: camelot_events_camelot_increaseliquidity camelot_events_camelot_increaseliquidity_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.camelot_events_camelot_increaseliquidity
    ADD CONSTRAINT camelot_events_camelot_increaseliquidity_pkey PRIMARY KEY (id);


--
-- Name: camelot_events_camelot_swap camelot_events_camelot_swap_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.camelot_events_camelot_swap
    ADD CONSTRAINT camelot_events_camelot_swap_pkey PRIMARY KEY (id);


--
-- Name: camelot_events_camelot_transferposition camelot_events_camelot_transferposition_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.camelot_events_camelot_transferposition
    ADD CONSTRAINT camelot_events_camelot_transferposition_pkey PRIMARY KEY (id);


--
-- Name: camelot_ingestor_checkpointing_1 camelot_ingestor_checkpointing_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.camelot_ingestor_checkpointing_1
    ADD CONSTRAINT camelot_ingestor_checkpointing_1_pkey PRIMARY KEY (id);


--
-- Name: camelot_migrations camelot_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.camelot_migrations
    ADD CONSTRAINT camelot_migrations_pkey PRIMARY KEY (version);


--
-- Name: cuntfuck_1 cuntfuck_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cuntfuck_1
    ADD CONSTRAINT cuntfuck_1_pkey PRIMARY KEY (id);


--
-- Name: dinero_events_ownership_transferred dinero_events_ownership_transferred_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dinero_events_ownership_transferred
    ADD CONSTRAINT dinero_events_ownership_transferred_pkey PRIMARY KEY (id);


--
-- Name: discord_usernames_1 discord_usernames_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discord_usernames_1
    ADD CONSTRAINT discord_usernames_1_pkey PRIMARY KEY (id);


--
-- Name: discord_usernames_2 discord_usernames_2_discord_snowflake_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discord_usernames_2
    ADD CONSTRAINT discord_usernames_2_discord_snowflake_key UNIQUE (discord_snowflake);


--
-- Name: discord_usernames_2 discord_usernames_2_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discord_usernames_2
    ADD CONSTRAINT discord_usernames_2_pkey PRIMARY KEY (id);


--
-- Name: erc20_cache_1 erc20_cache_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.erc20_cache_1
    ADD CONSTRAINT erc20_cache_1_pkey PRIMARY KEY (id);


--
-- Name: events_erc20_transfer events_erc20_transfer_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_erc20_transfer
    ADD CONSTRAINT events_erc20_transfer_pkey PRIMARY KEY (id);


--
-- Name: events_leo_campaignbalanceupdated events_leo_campaignbalanceupdated_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_leo_campaignbalanceupdated
    ADD CONSTRAINT events_leo_campaignbalanceupdated_pkey PRIMARY KEY (id);


--
-- Name: events_leo_campaigncreated events_leo_campaigncreated_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_leo_campaigncreated
    ADD CONSTRAINT events_leo_campaigncreated_pkey PRIMARY KEY (id);


--
-- Name: events_leo_campaignupdated events_leo_campaignupdated_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_leo_campaignupdated
    ADD CONSTRAINT events_leo_campaignupdated_pkey PRIMARY KEY (id);


--
-- Name: events_leo_positiondivested2 events_leo_positiondivested2_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_leo_positiondivested2
    ADD CONSTRAINT events_leo_positiondivested2_pkey PRIMARY KEY (id);


--
-- Name: events_leo_positiondivested events_leo_positiondivested_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_leo_positiondivested
    ADD CONSTRAINT events_leo_positiondivested_pkey PRIMARY KEY (id);


--
-- Name: events_leo_positionvested2 events_leo_positionvested2_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_leo_positionvested2
    ADD CONSTRAINT events_leo_positionvested2_pkey PRIMARY KEY (id);


--
-- Name: events_leo_positionvested events_leo_positionvested_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_leo_positionvested
    ADD CONSTRAINT events_leo_positionvested_pkey PRIMARY KEY (id);


--
-- Name: events_ninelives_stargate_bridged events_ninelives_stargate_bridged_guid_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_ninelives_stargate_bridged
    ADD CONSTRAINT events_ninelives_stargate_bridged_guid_key UNIQUE (guid);


--
-- Name: events_ninelives_stargate_bridged events_ninelives_stargate_bridged_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_ninelives_stargate_bridged
    ADD CONSTRAINT events_ninelives_stargate_bridged_pkey PRIMARY KEY (id);


--
-- Name: events_purrstream_donated events_purrstream_donated_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_purrstream_donated
    ADD CONSTRAINT events_purrstream_donated_pkey PRIMARY KEY (id);


--
-- Name: events_seawater_burnposition events_seawater_burnposition_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_seawater_burnposition
    ADD CONSTRAINT events_seawater_burnposition_pkey PRIMARY KEY (id);


--
-- Name: events_seawater_collectfees events_seawater_collectfees_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_seawater_collectfees
    ADD CONSTRAINT events_seawater_collectfees_pkey PRIMARY KEY (id);


--
-- Name: events_seawater_collectprotocolfees events_seawater_collectprotocolfees_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_seawater_collectprotocolfees
    ADD CONSTRAINT events_seawater_collectprotocolfees_pkey PRIMARY KEY (id);


--
-- Name: events_seawater_mintposition events_seawater_mintposition_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_seawater_mintposition
    ADD CONSTRAINT events_seawater_mintposition_pkey PRIMARY KEY (id);


--
-- Name: events_seawater_newpool events_seawater_newpool_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_seawater_newpool
    ADD CONSTRAINT events_seawater_newpool_pkey PRIMARY KEY (id);


--
-- Name: events_seawater_swap1 events_seawater_swap1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_seawater_swap1
    ADD CONSTRAINT events_seawater_swap1_pkey PRIMARY KEY (id, created_by);


--
-- Name: events_seawater_swap2 events_seawater_swap2_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_seawater_swap2
    ADD CONSTRAINT events_seawater_swap2_pkey PRIMARY KEY (id, created_by);


--
-- Name: events_seawater_transferposition events_seawater_transferposition_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_seawater_transferposition
    ADD CONSTRAINT events_seawater_transferposition_pkey PRIMARY KEY (id);


--
-- Name: events_seawater_updatepositionliquidity events_seawater_updatepositionliquidity_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_seawater_updatepositionliquidity
    ADD CONSTRAINT events_seawater_updatepositionliquidity_pkey PRIMARY KEY (id);


--
-- Name: events_thirdweb_accountcreated events_thirdweb_accountcreated_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_thirdweb_accountcreated
    ADD CONSTRAINT events_thirdweb_accountcreated_pkey PRIMARY KEY (id);


--
-- Name: faucet_requests faucet_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faucet_requests
    ADD CONSTRAINT faucet_requests_pkey PRIMARY KEY (id);


--
-- Name: fly_stakers_fly_staked_1 fly_stakers_fly_staked_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fly_stakers_fly_staked_1
    ADD CONSTRAINT fly_stakers_fly_staked_1_pkey PRIMARY KEY (id);


--
-- Name: fly_stakers_fly_unstaked_1 fly_stakers_fly_unstaked_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fly_stakers_fly_unstaked_1
    ADD CONSTRAINT fly_stakers_fly_unstaked_1_pkey PRIMARY KEY (id);


--
-- Name: fly_stakers_ingestor_checkpointing_1 fly_stakers_ingestor_checkpointing_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fly_stakers_ingestor_checkpointing_1
    ADD CONSTRAINT fly_stakers_ingestor_checkpointing_1_pkey PRIMARY KEY (id);


--
-- Name: fly_stakers_migrations fly_stakers_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fly_stakers_migrations
    ADD CONSTRAINT fly_stakers_migrations_pkey PRIMARY KEY (version);


--
-- Name: ingestor_checkpointing_1 ingestor_checkpointing_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingestor_checkpointing_1
    ADD CONSTRAINT ingestor_checkpointing_1_pkey PRIMARY KEY (id);


--
-- Name: layerzero_events_packet_burnt layerzero_events_packet_burnt_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.layerzero_events_packet_burnt
    ADD CONSTRAINT layerzero_events_packet_burnt_pkey PRIMARY KEY (id);


--
-- Name: layerzero_events_packet_delivered layerzero_events_packet_delivered_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.layerzero_events_packet_delivered
    ADD CONSTRAINT layerzero_events_packet_delivered_pkey PRIMARY KEY (id);


--
-- Name: layerzero_events_packet_nilified layerzero_events_packet_nilified_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.layerzero_events_packet_nilified
    ADD CONSTRAINT layerzero_events_packet_nilified_pkey PRIMARY KEY (id);


--
-- Name: layerzero_events_packet_sent layerzero_events_packet_sent_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.layerzero_events_packet_sent
    ADD CONSTRAINT layerzero_events_packet_sent_pkey PRIMARY KEY (id);


--
-- Name: layerzero_events_packet_verified layerzero_events_packet_verified_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.layerzero_events_packet_verified
    ADD CONSTRAINT layerzero_events_packet_verified_pkey PRIMARY KEY (id);


--
-- Name: lifi_events_generic_swap_completed lifi_events_generic_swap_completed_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lifi_events_generic_swap_completed
    ADD CONSTRAINT lifi_events_generic_swap_completed_pkey PRIMARY KEY (id);


--
-- Name: nfts_cached_lookup_1 nfts_cached_lookup_1_contract_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nfts_cached_lookup_1
    ADD CONSTRAINT nfts_cached_lookup_1_contract_key UNIQUE (contract);


--
-- Name: nfts_cached_lookup_1 nfts_cached_lookup_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nfts_cached_lookup_1
    ADD CONSTRAINT nfts_cached_lookup_1_pkey PRIMARY KEY (id);


--
-- Name: nfts_cached_not_nft_1 nfts_cached_not_nft_1_contract_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nfts_cached_not_nft_1
    ADD CONSTRAINT nfts_cached_not_nft_1_contract_key UNIQUE (contract);


--
-- Name: nfts_cached_not_nft_1 nfts_cached_not_nft_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nfts_cached_not_nft_1
    ADD CONSTRAINT nfts_cached_not_nft_1_pkey PRIMARY KEY (id);


--
-- Name: nfts_migrations nfts_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nfts_migrations
    ADD CONSTRAINT nfts_migrations_pkey PRIMARY KEY (version);


--
-- Name: ninelives_all_earned_1 ninelives_all_earned_1_emitter_recipient_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_all_earned_1
    ADD CONSTRAINT ninelives_all_earned_1_emitter_recipient_unique UNIQUE (emitter_addr, recipient);


--
-- Name: ninelives_all_earned_1 ninelives_all_earned_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_all_earned_1
    ADD CONSTRAINT ninelives_all_earned_1_pkey PRIMARY KEY (id);


--
-- Name: ninelives_banners_1 ninelives_banners_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_banners_1
    ADD CONSTRAINT ninelives_banners_1_pkey PRIMARY KEY (id);


--
-- Name: ninelives_buys_and_sells_1 ninelives_buys_and_sells_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_buys_and_sells_1
    ADD CONSTRAINT ninelives_buys_and_sells_1_pkey PRIMARY KEY (id);


--
-- Name: ninelives_campaigns_1 ninelives_campaigns_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_campaigns_1
    ADD CONSTRAINT ninelives_campaigns_1_pkey PRIMARY KEY (id);


--
-- Name: ninelives_campaigns_categories_1 ninelives_campaigns_categories_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_campaigns_categories_1
    ADD CONSTRAINT ninelives_campaigns_categories_1_pkey PRIMARY KEY (campaign_id, category_id);


--
-- Name: ninelives_categories_1 ninelives_categories_1_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_categories_1
    ADD CONSTRAINT ninelives_categories_1_name_key UNIQUE (name);


--
-- Name: ninelives_categories_1 ninelives_categories_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_categories_1
    ADD CONSTRAINT ninelives_categories_1_pkey PRIMARY KEY (id);


--
-- Name: ninelives_comments_1 ninelives_comments_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_comments_1
    ADD CONSTRAINT ninelives_comments_1_pkey PRIMARY KEY (id);


--
-- Name: ninelives_events_address_fees_claimed ninelives_events_address_fees_claimed_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_address_fees_claimed
    ADD CONSTRAINT ninelives_events_address_fees_claimed_pkey PRIMARY KEY (id);


--
-- Name: ninelives_events_amm_details ninelives_events_amm_details_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_amm_details
    ADD CONSTRAINT ninelives_events_amm_details_pkey PRIMARY KEY (id);


--
-- Name: ninelives_events_call_made ninelives_events_call_made_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_call_made
    ADD CONSTRAINT ninelives_events_call_made_pkey PRIMARY KEY (id);


--
-- Name: ninelives_events_call_made ninelives_events_call_made_trading_addr_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_call_made
    ADD CONSTRAINT ninelives_events_call_made_trading_addr_key UNIQUE (trading_addr);


--
-- Name: ninelives_events_campaign_escaped ninelives_events_campaign_escaped_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_campaign_escaped
    ADD CONSTRAINT ninelives_events_campaign_escaped_pkey PRIMARY KEY (id);


--
-- Name: ninelives_events_campaign_escaped ninelives_events_campaign_escaped_trading_addr_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_campaign_escaped
    ADD CONSTRAINT ninelives_events_campaign_escaped_trading_addr_key UNIQUE (trading_addr);


--
-- Name: ninelives_events_commitment_revealed ninelives_events_commitment_revealed_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_commitment_revealed
    ADD CONSTRAINT ninelives_events_commitment_revealed_pkey PRIMARY KEY (id);


--
-- Name: ninelives_events_commitment_revealed ninelives_events_commitment_revealed_revealer_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_commitment_revealed
    ADD CONSTRAINT ninelives_events_commitment_revealed_revealer_key UNIQUE (revealer);


--
-- Name: ninelives_events_committed ninelives_events_committed_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_committed
    ADD CONSTRAINT ninelives_events_committed_pkey PRIMARY KEY (id);


--
-- Name: ninelives_events_concluded ninelives_events_concluded_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_concluded
    ADD CONSTRAINT ninelives_events_concluded_pkey PRIMARY KEY (id);


--
-- Name: ninelives_events_concluded ninelives_events_concluded_ticket_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_concluded
    ADD CONSTRAINT ninelives_events_concluded_ticket_key UNIQUE (ticket);


--
-- Name: ninelives_events_dao_money_distributed ninelives_events_dao_money_distributed_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_dao_money_distributed
    ADD CONSTRAINT ninelives_events_dao_money_distributed_pkey PRIMARY KEY (id);


--
-- Name: ninelives_events_deadline_extension ninelives_events_deadline_extension_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_deadline_extension
    ADD CONSTRAINT ninelives_events_deadline_extension_pkey PRIMARY KEY (id);


--
-- Name: ninelives_events_declared ninelives_events_declared_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_declared
    ADD CONSTRAINT ninelives_events_declared_pkey PRIMARY KEY (id);


--
-- Name: ninelives_events_declared ninelives_events_declared_trading_addr_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_declared
    ADD CONSTRAINT ninelives_events_declared_trading_addr_key UNIQUE (trading_addr);


--
-- Name: ninelives_events_dppm_clawback ninelives_events_dppm_clawback_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_dppm_clawback
    ADD CONSTRAINT ninelives_events_dppm_clawback_pkey PRIMARY KEY (id);


--
-- Name: ninelives_events_frozen ninelives_events_frozen_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_frozen
    ADD CONSTRAINT ninelives_events_frozen_pkey PRIMARY KEY (id);


--
-- Name: ninelives_events_infra_market_closed ninelives_events_infra_market_closed_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_infra_market_closed
    ADD CONSTRAINT ninelives_events_infra_market_closed_pkey PRIMARY KEY (id);


--
-- Name: ninelives_events_infra_market_closed ninelives_events_infra_market_closed_trading_addr_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_infra_market_closed
    ADD CONSTRAINT ninelives_events_infra_market_closed_trading_addr_key UNIQUE (trading_addr);


--
-- Name: ninelives_events_liquidity_added ninelives_events_liquidity_added_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_liquidity_added
    ADD CONSTRAINT ninelives_events_liquidity_added_pkey PRIMARY KEY (id);


--
-- Name: ninelives_events_liquidity_added_shares_sent ninelives_events_liquidity_added_shares_sent_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_liquidity_added_shares_sent
    ADD CONSTRAINT ninelives_events_liquidity_added_shares_sent_pkey PRIMARY KEY (id);


--
-- Name: ninelives_events_liquidity_claimed ninelives_events_liquidity_claimed_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_liquidity_claimed
    ADD CONSTRAINT ninelives_events_liquidity_claimed_pkey PRIMARY KEY (id);


--
-- Name: ninelives_events_liquidity_removed ninelives_events_liquidity_removed_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_liquidity_removed
    ADD CONSTRAINT ninelives_events_liquidity_removed_pkey PRIMARY KEY (id);


--
-- Name: ninelives_events_liquidity_removed_shares_sent ninelives_events_liquidity_removed_shares_sent_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_liquidity_removed_shares_sent
    ADD CONSTRAINT ninelives_events_liquidity_removed_shares_sent_pkey PRIMARY KEY (id);


--
-- Name: ninelives_events_locked_up ninelives_events_locked_up_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_locked_up
    ADD CONSTRAINT ninelives_events_locked_up_pkey PRIMARY KEY (id);


--
-- Name: ninelives_events_lp_fees_claimed ninelives_events_lp_fees_claimed_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_lp_fees_claimed
    ADD CONSTRAINT ninelives_events_lp_fees_claimed_pkey PRIMARY KEY (id);


--
-- Name: ninelives_events_market_created2 ninelives_events_market_created2_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_market_created2
    ADD CONSTRAINT ninelives_events_market_created2_pkey PRIMARY KEY (id);


--
-- Name: ninelives_events_new_trading2 ninelives_events_new_trading2_address_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_new_trading2
    ADD CONSTRAINT ninelives_events_new_trading2_address_key UNIQUE (address);


--
-- Name: ninelives_events_new_trading2 ninelives_events_new_trading2_identifier_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_new_trading2
    ADD CONSTRAINT ninelives_events_new_trading2_identifier_key UNIQUE (identifier);


--
-- Name: ninelives_events_new_trading2 ninelives_events_new_trading2_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_new_trading2
    ADD CONSTRAINT ninelives_events_new_trading2_pkey PRIMARY KEY (id);


--
-- Name: ninelives_events_new_trading ninelives_events_new_trading_address_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_new_trading
    ADD CONSTRAINT ninelives_events_new_trading_address_key UNIQUE (address);


--
-- Name: ninelives_events_new_trading ninelives_events_new_trading_identifier_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_new_trading
    ADD CONSTRAINT ninelives_events_new_trading_identifier_key UNIQUE (identifier);


--
-- Name: ninelives_events_new_trading ninelives_events_new_trading_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_new_trading
    ADD CONSTRAINT ninelives_events_new_trading_pkey PRIMARY KEY (id);


--
-- Name: ninelives_events_ninetails_boosted_shares_received ninelives_events_ninetails_boosted_shares_received_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_ninetails_boosted_shares_received
    ADD CONSTRAINT ninelives_events_ninetails_boosted_shares_received_pkey PRIMARY KEY (id);


--
-- Name: ninelives_events_ninetails_cumulative_winner_payoff ninelives_events_ninetails_cumulative_winner_payoff_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_ninetails_cumulative_winner_payoff
    ADD CONSTRAINT ninelives_events_ninetails_cumulative_winner_payoff_pkey PRIMARY KEY (id);


--
-- Name: ninelives_events_ninetails_loser_payoff ninelives_events_ninetails_loser_payoff_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_ninetails_loser_payoff
    ADD CONSTRAINT ninelives_events_ninetails_loser_payoff_pkey PRIMARY KEY (id);


--
-- Name: ninelives_events_outcome_created ninelives_events_outcome_created_erc20_addr_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_outcome_created
    ADD CONSTRAINT ninelives_events_outcome_created_erc20_addr_key UNIQUE (erc20_addr);


--
-- Name: ninelives_events_outcome_created ninelives_events_outcome_created_erc20_identifier_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_outcome_created
    ADD CONSTRAINT ninelives_events_outcome_created_erc20_identifier_key UNIQUE (erc20_identifier);


--
-- Name: ninelives_events_outcome_created ninelives_events_outcome_created_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_outcome_created
    ADD CONSTRAINT ninelives_events_outcome_created_pkey PRIMARY KEY (id);


--
-- Name: ninelives_events_outcome_decided ninelives_events_outcome_decided_emitter_addr_identifier_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_outcome_decided
    ADD CONSTRAINT ninelives_events_outcome_decided_emitter_addr_identifier_key UNIQUE (emitter_addr, identifier);


--
-- Name: ninelives_events_outcome_decided ninelives_events_outcome_decided_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_outcome_decided
    ADD CONSTRAINT ninelives_events_outcome_decided_pkey PRIMARY KEY (id);


--
-- Name: ninelives_events_paymaster_paid_for ninelives_events_paymaster_paid_for_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_paymaster_paid_for
    ADD CONSTRAINT ninelives_events_paymaster_paid_for_pkey PRIMARY KEY (id);


--
-- Name: ninelives_events_payoff_activated ninelives_events_payoff_activated_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_payoff_activated
    ADD CONSTRAINT ninelives_events_payoff_activated_pkey PRIMARY KEY (id);


--
-- Name: ninelives_events_requested ninelives_events_requested_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_requested
    ADD CONSTRAINT ninelives_events_requested_pkey PRIMARY KEY (id);


--
-- Name: ninelives_events_requested ninelives_events_requested_ticket_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_requested
    ADD CONSTRAINT ninelives_events_requested_ticket_key UNIQUE (ticket);


--
-- Name: ninelives_events_shares_burned ninelives_events_shares_burned_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_shares_burned
    ADD CONSTRAINT ninelives_events_shares_burned_pkey PRIMARY KEY (id);


--
-- Name: ninelives_events_shares_minted ninelives_events_shares_minted_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_shares_minted
    ADD CONSTRAINT ninelives_events_shares_minted_pkey PRIMARY KEY (id);


--
-- Name: ninelives_events_slashed ninelives_events_slashed_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_slashed
    ADD CONSTRAINT ninelives_events_slashed_pkey PRIMARY KEY (id);


--
-- Name: ninelives_events_whinged ninelives_events_whinged_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_whinged
    ADD CONSTRAINT ninelives_events_whinged_pkey PRIMARY KEY (id);


--
-- Name: ninelives_events_withdrew ninelives_events_withdrew_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_withdrew
    ADD CONSTRAINT ninelives_events_withdrew_pkey PRIMARY KEY (id);


--
-- Name: ninelives_frontpage_1 ninelives_frontpage_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_frontpage_1
    ADD CONSTRAINT ninelives_frontpage_1_pkey PRIMARY KEY (id);


--
-- Name: ninelives_ingestor_checkpointing_1 ninelives_ingestor_checkpointing_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_ingestor_checkpointing_1
    ADD CONSTRAINT ninelives_ingestor_checkpointing_1_pkey PRIMARY KEY (id);


--
-- Name: ninelives_market_odds_snapshot_1 ninelives_market_odds_snapshot_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_market_odds_snapshot_1
    ADD CONSTRAINT ninelives_market_odds_snapshot_1_pkey PRIMARY KEY (id);


--
-- Name: ninelives_market_summaries_1 ninelives_market_summaries_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_market_summaries_1
    ADD CONSTRAINT ninelives_market_summaries_1_pkey PRIMARY KEY (id);


--
-- Name: ninelives_market_summaries_1 ninelives_market_summaries_1_pool_address_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_market_summaries_1
    ADD CONSTRAINT ninelives_market_summaries_1_pool_address_key UNIQUE (pool_address);


--
-- Name: ninelives_markets_enabled_1 ninelives_markets_enabled_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_markets_enabled_1
    ADD CONSTRAINT ninelives_markets_enabled_1_pkey PRIMARY KEY (id);


--
-- Name: ninelives_migrations ninelives_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_migrations
    ADD CONSTRAINT ninelives_migrations_pkey PRIMARY KEY (version);


--
-- Name: ninelives_newsfeed_1 ninelives_newsfeed_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_newsfeed_1
    ADD CONSTRAINT ninelives_newsfeed_1_pkey PRIMARY KEY (id);


--
-- Name: ninelives_oracle_metadata_1 ninelives_oracle_metadata_1_campaign_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_oracle_metadata_1
    ADD CONSTRAINT ninelives_oracle_metadata_1_campaign_id_key UNIQUE (campaign_id);


--
-- Name: ninelives_oracle_metadata_1 ninelives_oracle_metadata_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_oracle_metadata_1
    ADD CONSTRAINT ninelives_oracle_metadata_1_pkey PRIMARY KEY (id);


--
-- Name: ninelives_paymaster_attempts_1 ninelives_paymaster_attempts_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_paymaster_attempts_1
    ADD CONSTRAINT ninelives_paymaster_attempts_1_pkey PRIMARY KEY (id);


--
-- Name: ninelives_paymaster_attempts_2 ninelives_paymaster_attempts_2_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_paymaster_attempts_2
    ADD CONSTRAINT ninelives_paymaster_attempts_2_pkey PRIMARY KEY (id);


--
-- Name: ninelives_paymaster_poll_1 ninelives_paymaster_poll_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_paymaster_poll_1
    ADD CONSTRAINT ninelives_paymaster_poll_1_pkey PRIMARY KEY (id);


--
-- Name: ninelives_payoff_unused_1 ninelives_payoff_unused_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_payoff_unused_1
    ADD CONSTRAINT ninelives_payoff_unused_1_pkey PRIMARY KEY (id);


--
-- Name: ninelives_referrer_1 ninelives_referrer_1_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_referrer_1
    ADD CONSTRAINT ninelives_referrer_1_code_key UNIQUE (code);


--
-- Name: ninelives_referrer_1 ninelives_referrer_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_referrer_1
    ADD CONSTRAINT ninelives_referrer_1_pkey PRIMARY KEY (id);


--
-- Name: ninelives_events_referrer_earned_fees ninelives_referrer_earned_fees_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_events_referrer_earned_fees
    ADD CONSTRAINT ninelives_referrer_earned_fees_pkey PRIMARY KEY (id);


--
-- Name: ninelives_revealed_commitments_1 ninelives_revealed_commitments_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_revealed_commitments_1
    ADD CONSTRAINT ninelives_revealed_commitments_1_pkey PRIMARY KEY (id);


--
-- Name: ninelives_tracked_trading_contracts_1 ninelives_tracked_trading_contracts_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_tracked_trading_contracts_1
    ADD CONSTRAINT ninelives_tracked_trading_contracts_1_pkey PRIMARY KEY (id);


--
-- Name: ninelives_users_1 ninelives_users_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_users_1
    ADD CONSTRAINT ninelives_users_1_pkey PRIMARY KEY (wallet_address);


--
-- Name: notes_1 notes_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes_1
    ADD CONSTRAINT notes_1_pkey PRIMARY KEY (id);


--
-- Name: onchaingm_events_onchaingmevent onchaingm_events_onchaingmevent_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.onchaingm_events_onchaingmevent
    ADD CONSTRAINT onchaingm_events_onchaingmevent_pkey PRIMARY KEY (id);


--
-- Name: oracle_ninelives_decisions_1 oracle_ninelives_decisions_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oracle_ninelives_decisions_1
    ADD CONSTRAINT oracle_ninelives_decisions_1_pkey PRIMARY KEY (id);


--
-- Name: oracle_ninelives_decisions_1 oracle_ninelives_decisions_1_pool_address_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oracle_ninelives_decisions_1
    ADD CONSTRAINT oracle_ninelives_decisions_1_pool_address_key UNIQUE (pool_address);


--
-- Name: oracle_ninelives_starting_liq_1 oracle_ninelives_starting_liq_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oracle_ninelives_starting_liq_1
    ADD CONSTRAINT oracle_ninelives_starting_liq_1_pkey PRIMARY KEY (id);


--
-- Name: oracles_ninelives_migrations oracles_ninelives_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oracles_ninelives_migrations
    ADD CONSTRAINT oracles_ninelives_migrations_pkey PRIMARY KEY (version);


--
-- Name: oracles_ninelives_prices_1 oracles_ninelives_prices_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oracles_ninelives_prices_1
    ADD CONSTRAINT oracles_ninelives_prices_1_pkey PRIMARY KEY (id);


--
-- Name: oracles_ninelives_prices_2 oracles_ninelives_prices_2_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oracles_ninelives_prices_2
    ADD CONSTRAINT oracles_ninelives_prices_2_pkey PRIMARY KEY (id);


--
-- Name: points_achievement_leaderboard_value_1 points_achievement_leaderboard_value_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_achievement_leaderboard_value_1
    ADD CONSTRAINT points_achievement_leaderboard_value_1_pkey PRIMARY KEY (id);


--
-- Name: points_achievement_leaderboard_value_1 points_achievement_leaderboard_value_1_product_season_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_achievement_leaderboard_value_1
    ADD CONSTRAINT points_achievement_leaderboard_value_1_product_season_name_key UNIQUE (product, season, name);


--
-- Name: points_achievements_received_1 points_achievements_received_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_achievements_received_1
    ADD CONSTRAINT points_achievements_received_1_pkey PRIMARY KEY (id);


--
-- Name: points_achievements_received_2 points_achievements_received_2_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_achievements_received_2
    ADD CONSTRAINT points_achievements_received_2_pkey PRIMARY KEY (id);


--
-- Name: points_auth_bearer_tokens_1 points_auth_bearer_tokens_1_authkey_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_auth_bearer_tokens_1
    ADD CONSTRAINT points_auth_bearer_tokens_1_authkey_key UNIQUE (authkey);


--
-- Name: points_auth_bearer_tokens_1 points_auth_bearer_tokens_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_auth_bearer_tokens_1
    ADD CONSTRAINT points_auth_bearer_tokens_1_pkey PRIMARY KEY (id);


--
-- Name: points_auth_powers_1 points_auth_powers_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_auth_powers_1
    ADD CONSTRAINT points_auth_powers_1_pkey PRIMARY KEY (id);


--
-- Name: points_auth_powers_1 points_auth_powers_1_secretkey_role_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_auth_powers_1
    ADD CONSTRAINT points_auth_powers_1_secretkey_role_key UNIQUE (secretkey, role);


--
-- Name: points_auth_secret_keys_1 points_auth_secret_keys_1_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_auth_secret_keys_1
    ADD CONSTRAINT points_auth_secret_keys_1_key_key UNIQUE (key);


--
-- Name: points_auth_secret_keys_1 points_auth_secret_keys_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_auth_secret_keys_1
    ADD CONSTRAINT points_auth_secret_keys_1_pkey PRIMARY KEY (id);


--
-- Name: points_camelot_lp_points_2 points_camelot_lp_points_2_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_camelot_lp_points_2
    ADD CONSTRAINT points_camelot_lp_points_2_pkey PRIMARY KEY (id);


--
-- Name: points_camelot_pool_pair_cache_1 points_camelot_pool_pair_cache_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_camelot_pool_pair_cache_1
    ADD CONSTRAINT points_camelot_pool_pair_cache_1_pkey PRIMARY KEY (id);


--
-- Name: points_camelot_pool_pair_cache_1 points_camelot_pool_pair_cache_1_pool_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_camelot_pool_pair_cache_1
    ADD CONSTRAINT points_camelot_pool_pair_cache_1_pool_key UNIQUE (pool);


--
-- Name: points_discovered_debank_balances_1 points_discovered_debank_balances_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_discovered_debank_balances_1
    ADD CONSTRAINT points_discovered_debank_balances_1_pkey PRIMARY KEY (id);


--
-- Name: points_discovered_debank_nobal_1 points_discovered_debank_nobal_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_discovered_debank_nobal_1
    ADD CONSTRAINT points_discovered_debank_nobal_1_pkey PRIMARY KEY (id);


--
-- Name: points_displayed_via_endpoint_1 points_displayed_via_endpoint_1_address_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_displayed_via_endpoint_1
    ADD CONSTRAINT points_displayed_via_endpoint_1_address_key UNIQUE (address);


--
-- Name: points_displayed_via_endpoint_1 points_displayed_via_endpoint_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_displayed_via_endpoint_1
    ADD CONSTRAINT points_displayed_via_endpoint_1_pkey PRIMARY KEY (id);


--
-- Name: points_everything_static_1 points_everything_static_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_everything_static_1
    ADD CONSTRAINT points_everything_static_1_pkey PRIMARY KEY (id);


--
-- Name: points_fly_staked_points_aggregated_2 points_fly_staked_points_aggregated_2_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_fly_staked_points_aggregated_2
    ADD CONSTRAINT points_fly_staked_points_aggregated_2_pkey PRIMARY KEY (id);


--
-- Name: points_fly_staked_snapshot_1 points_fly_staked_snapshot_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_fly_staked_snapshot_1
    ADD CONSTRAINT points_fly_staked_snapshot_1_pkey PRIMARY KEY (id);


--
-- Name: points_galxe_confirmed_bridge_to_spn_1 points_galxe_confirmed_bridge_to_spn_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_galxe_confirmed_bridge_to_spn_1
    ADD CONSTRAINT points_galxe_confirmed_bridge_to_spn_1_pkey PRIMARY KEY (id);


--
-- Name: points_galxe_pending_1 points_galxe_pending_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_galxe_pending_1
    ADD CONSTRAINT points_galxe_pending_1_pkey PRIMARY KEY (id);


--
-- Name: points_galxe_pending_1 points_galxe_pending_1_transaction_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_galxe_pending_1
    ADD CONSTRAINT points_galxe_pending_1_transaction_id_key UNIQUE (transaction_id);


--
-- Name: points_hackathon_config_1 points_hackathon_config_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_hackathon_config_1
    ADD CONSTRAINT points_hackathon_config_1_pkey PRIMARY KEY (id);


--
-- Name: points_hackathon_faucet_to_receive_1 points_hackathon_faucet_to_receive_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_hackathon_faucet_to_receive_1
    ADD CONSTRAINT points_hackathon_faucet_to_receive_1_pkey PRIMARY KEY (id);


--
-- Name: points_hackathon_faucet_to_receive_1 points_hackathon_faucet_to_receive_1_recipient_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_hackathon_faucet_to_receive_1
    ADD CONSTRAINT points_hackathon_faucet_to_receive_1_recipient_key UNIQUE (recipient);


--
-- Name: points_kaito_yapper_7d_leaderboard_updates_1 points_kaito_yapper_7d_leaderboard_updates_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_kaito_yapper_7d_leaderboard_updates_1
    ADD CONSTRAINT points_kaito_yapper_7d_leaderboard_updates_1_pkey PRIMARY KEY (id);


--
-- Name: points_migrations points_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_migrations
    ADD CONSTRAINT points_migrations_pkey PRIMARY KEY (version);


--
-- Name: points_ninelives_manually_concluded_in_error_1 points_ninelives_manually_concluded_in_error_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_ninelives_manually_concluded_in_error_1
    ADD CONSTRAINT points_ninelives_manually_concluded_in_error_1_pkey PRIMARY KEY (id);


--
-- Name: points_ninelives_manually_concluded_in_error_1 points_ninelives_manually_concluded_in_error_1_pool_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_ninelives_manually_concluded_in_error_1
    ADD CONSTRAINT points_ninelives_manually_concluded_in_error_1_pool_key UNIQUE (pool);


--
-- Name: points_og_badge_transaction_count_1 points_og_badge_transaction_count_1_address_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_og_badge_transaction_count_1
    ADD CONSTRAINT points_og_badge_transaction_count_1_address_key UNIQUE (address);


--
-- Name: points_staked_to_spn_1 points_staked_to_spn_1_address_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_staked_to_spn_1
    ADD CONSTRAINT points_staked_to_spn_1_address_key UNIQUE (address);


--
-- Name: points_staked_to_spn_1 points_staked_to_spn_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_staked_to_spn_1
    ADD CONSTRAINT points_staked_to_spn_1_pkey PRIMARY KEY (id);


--
-- Name: points_supawsotition_1 points_supawsotition_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_supawsotition_1
    ADD CONSTRAINT points_supawsotition_1_pkey PRIMARY KEY (id);


--
-- Name: points_testnet_addresses_1 points_testnet_addresses_1_address_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_testnet_addresses_1
    ADD CONSTRAINT points_testnet_addresses_1_address_key UNIQUE (address);


--
-- Name: points_testnet_addresses_1 points_testnet_addresses_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_testnet_addresses_1
    ADD CONSTRAINT points_testnet_addresses_1_pkey PRIMARY KEY (id);


--
-- Name: points_testnet_hackathon_ingestor_1 points_testnet_hackathon_ingestor_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_testnet_hackathon_ingestor_1
    ADD CONSTRAINT points_testnet_hackathon_ingestor_1_pkey PRIMARY KEY (id);


--
-- Name: points_testnet_hackathon_token_erc20_transfer points_testnet_hackathon_token_erc20_transfer_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_testnet_hackathon_token_erc20_transfer
    ADD CONSTRAINT points_testnet_hackathon_token_erc20_transfer_pkey PRIMARY KEY (id);


--
-- Name: private_ninelives_migrations private_ninelives_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.private_ninelives_migrations
    ADD CONSTRAINT private_ninelives_migrations_pkey PRIMARY KEY (version);


--
-- Name: punk_domains_events_default_domain_changed punk_domains_events_default_domain_changed_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.punk_domains_events_default_domain_changed
    ADD CONSTRAINT punk_domains_events_default_domain_changed_pkey PRIMARY KEY (id);


--
-- Name: sarp_migrations sarp_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sarp_migrations
    ADD CONSTRAINT sarp_migrations_pkey PRIMARY KEY (version);


--
-- Name: sarp_tracked_requests sarp_tracked_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sarp_tracked_requests
    ADD CONSTRAINT sarp_tracked_requests_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: shahmeersgame_ideas_1 shahmeersgame_ideas_1_desc__key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shahmeersgame_ideas_1
    ADD CONSTRAINT shahmeersgame_ideas_1_desc__key UNIQUE (desc_);


--
-- Name: shahmeersgame_ideas_1 shahmeersgame_ideas_1_hashed_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shahmeersgame_ideas_1
    ADD CONSTRAINT shahmeersgame_ideas_1_hashed_key UNIQUE (hashed);


--
-- Name: shahmeersgame_ideas_1 shahmeersgame_ideas_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shahmeersgame_ideas_1
    ADD CONSTRAINT shahmeersgame_ideas_1_pkey PRIMARY KEY (id);


--
-- Name: shahmeersgame_migrations shahmeersgame_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shahmeersgame_migrations
    ADD CONSTRAINT shahmeersgame_migrations_pkey PRIMARY KEY (version);


--
-- Name: snapshot_positions_latest_1 snapshot_positions_latest_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.snapshot_positions_latest_1
    ADD CONSTRAINT snapshot_positions_latest_1_pkey PRIMARY KEY (id);


--
-- Name: snapshot_positions_log_1 snapshot_positions_log_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.snapshot_positions_log_1
    ADD CONSTRAINT snapshot_positions_log_1_pkey PRIMARY KEY (id);


--
-- Name: snitch_facts_1 snitch_facts_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.snitch_facts_1
    ADD CONSTRAINT snitch_facts_1_pkey PRIMARY KEY (id);


--
-- Name: snitch_facts_1 snitch_facts_1_tag_key_value_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.snitch_facts_1
    ADD CONSTRAINT snitch_facts_1_tag_key_value_key UNIQUE (tag, key, value);


--
-- Name: snitch_hits_1 snitch_hits_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.snitch_hits_1
    ADD CONSTRAINT snitch_hits_1_pkey PRIMARY KEY (id);


--
-- Name: snitch_migrations snitch_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.snitch_migrations
    ADD CONSTRAINT snitch_migrations_pkey PRIMARY KEY (version);


--
-- Name: snitch_tags_1 snitch_tags_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.snitch_tags_1
    ADD CONSTRAINT snitch_tags_1_pkey PRIMARY KEY (id);


--
-- Name: stargate_events_oft_sent stargate_events_oft_sent_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stargate_events_oft_sent
    ADD CONSTRAINT stargate_events_oft_sent_pkey PRIMARY KEY (id);


--
-- Name: stargate_events_stargate_oft_received stargate_events_stargate_oft_received_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stargate_events_stargate_oft_received
    ADD CONSTRAINT stargate_events_stargate_oft_received_pkey PRIMARY KEY (id);


--
-- Name: stylus_contracts_deployed_1 stylus_contracts_deployed_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stylus_contracts_deployed_1
    ADD CONSTRAINT stylus_contracts_deployed_1_pkey PRIMARY KEY (id);


--
-- Name: stylus_contracts_deployed_1 stylus_contracts_deployed_1_transaction_hash_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stylus_contracts_deployed_1
    ADD CONSTRAINT stylus_contracts_deployed_1_transaction_hash_key UNIQUE (transaction_hash);


--
-- Name: stylus_ingestor_checkpointing_1 stylus_ingestor_checkpointing_1_chain_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stylus_ingestor_checkpointing_1
    ADD CONSTRAINT stylus_ingestor_checkpointing_1_chain_id_key UNIQUE (chain_id);


--
-- Name: stylus_ingestor_checkpointing_1 stylus_ingestor_checkpointing_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stylus_ingestor_checkpointing_1
    ADD CONSTRAINT stylus_ingestor_checkpointing_1_pkey PRIMARY KEY (id);


--
-- Name: stylus_migrations stylus_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stylus_migrations
    ADD CONSTRAINT stylus_migrations_pkey PRIMARY KEY (version);


--
-- Name: sudoswap_new_erc721pair sudoswap_new_erc721pair_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sudoswap_new_erc721pair
    ADD CONSTRAINT sudoswap_new_erc721pair_pkey PRIMARY KEY (id);


--
-- Name: swagyolo69 swagyolo69_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.swagyolo69
    ADD CONSTRAINT swagyolo69_pkey PRIMARY KEY (id);


--
-- Name: vendor_events_borrow vendor_events_borrow_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_events_borrow
    ADD CONSTRAINT vendor_events_borrow_pkey PRIMARY KEY (id);


--
-- Name: vendor_events_deposit vendor_events_deposit_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_events_deposit
    ADD CONSTRAINT vendor_events_deposit_pkey PRIMARY KEY (id);


--
-- Name: vendor_events_repay vendor_events_repay_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_events_repay
    ADD CONSTRAINT vendor_events_repay_pkey PRIMARY KEY (id);


--
-- Name: vendor_events_roll_in vendor_events_roll_in_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_events_roll_in
    ADD CONSTRAINT vendor_events_roll_in_pkey PRIMARY KEY (id);


--
-- Name: vendor_events_withdraw vendor_events_withdraw_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_events_withdraw
    ADD CONSTRAINT vendor_events_withdraw_pkey PRIMARY KEY (id);


--
-- Name: _hyper_1_10_chunk_events_seawater_swap2_created_by_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_10_chunk_events_seawater_swap2_created_by_idx ON _timescaledb_internal._hyper_1_10_chunk USING btree (created_by DESC);


--
-- Name: _hyper_1_10_chunk_events_seawater_swap2_from__idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_10_chunk_events_seawater_swap2_from__idx ON _timescaledb_internal._hyper_1_10_chunk USING btree (from_);


--
-- Name: _hyper_1_10_chunk_events_seawater_swap2_from__idx1; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_10_chunk_events_seawater_swap2_from__idx1 ON _timescaledb_internal._hyper_1_10_chunk USING btree (from_);


--
-- Name: _hyper_1_10_chunk_events_seawater_swap2_to__idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_10_chunk_events_seawater_swap2_to__idx ON _timescaledb_internal._hyper_1_10_chunk USING btree (to_);


--
-- Name: _hyper_1_10_chunk_events_seawater_swap2_to__idx1; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_10_chunk_events_seawater_swap2_to__idx1 ON _timescaledb_internal._hyper_1_10_chunk USING btree (to_);


--
-- Name: _hyper_1_10_chunk_events_seawater_swap2_user__from__idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_10_chunk_events_seawater_swap2_user__from__idx ON _timescaledb_internal._hyper_1_10_chunk USING btree (user_, from_);


--
-- Name: _hyper_1_10_chunk_events_seawater_swap2_user__idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_10_chunk_events_seawater_swap2_user__idx ON _timescaledb_internal._hyper_1_10_chunk USING btree (user_);


--
-- Name: _hyper_1_10_chunk_events_seawater_swap2_user__to__idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_10_chunk_events_seawater_swap2_user__to__idx ON _timescaledb_internal._hyper_1_10_chunk USING btree (user_, to_);


--
-- Name: _hyper_1_12_chunk_events_seawater_swap2_created_by_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_12_chunk_events_seawater_swap2_created_by_idx ON _timescaledb_internal._hyper_1_12_chunk USING btree (created_by DESC);


--
-- Name: _hyper_1_12_chunk_events_seawater_swap2_from__idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_12_chunk_events_seawater_swap2_from__idx ON _timescaledb_internal._hyper_1_12_chunk USING btree (from_);


--
-- Name: _hyper_1_12_chunk_events_seawater_swap2_from__idx1; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_12_chunk_events_seawater_swap2_from__idx1 ON _timescaledb_internal._hyper_1_12_chunk USING btree (from_);


--
-- Name: _hyper_1_12_chunk_events_seawater_swap2_to__idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_12_chunk_events_seawater_swap2_to__idx ON _timescaledb_internal._hyper_1_12_chunk USING btree (to_);


--
-- Name: _hyper_1_12_chunk_events_seawater_swap2_to__idx1; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_12_chunk_events_seawater_swap2_to__idx1 ON _timescaledb_internal._hyper_1_12_chunk USING btree (to_);


--
-- Name: _hyper_1_12_chunk_events_seawater_swap2_user__from__idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_12_chunk_events_seawater_swap2_user__from__idx ON _timescaledb_internal._hyper_1_12_chunk USING btree (user_, from_);


--
-- Name: _hyper_1_12_chunk_events_seawater_swap2_user__idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_12_chunk_events_seawater_swap2_user__idx ON _timescaledb_internal._hyper_1_12_chunk USING btree (user_);


--
-- Name: _hyper_1_12_chunk_events_seawater_swap2_user__to__idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_12_chunk_events_seawater_swap2_user__to__idx ON _timescaledb_internal._hyper_1_12_chunk USING btree (user_, to_);


--
-- Name: _hyper_1_14_chunk_events_seawater_swap2_created_by_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_14_chunk_events_seawater_swap2_created_by_idx ON _timescaledb_internal._hyper_1_14_chunk USING btree (created_by DESC);


--
-- Name: _hyper_1_14_chunk_events_seawater_swap2_from__idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_14_chunk_events_seawater_swap2_from__idx ON _timescaledb_internal._hyper_1_14_chunk USING btree (from_);


--
-- Name: _hyper_1_14_chunk_events_seawater_swap2_from__idx1; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_14_chunk_events_seawater_swap2_from__idx1 ON _timescaledb_internal._hyper_1_14_chunk USING btree (from_);


--
-- Name: _hyper_1_14_chunk_events_seawater_swap2_to__idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_14_chunk_events_seawater_swap2_to__idx ON _timescaledb_internal._hyper_1_14_chunk USING btree (to_);


--
-- Name: _hyper_1_14_chunk_events_seawater_swap2_to__idx1; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_14_chunk_events_seawater_swap2_to__idx1 ON _timescaledb_internal._hyper_1_14_chunk USING btree (to_);


--
-- Name: _hyper_1_14_chunk_events_seawater_swap2_user__from__idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_14_chunk_events_seawater_swap2_user__from__idx ON _timescaledb_internal._hyper_1_14_chunk USING btree (user_, from_);


--
-- Name: _hyper_1_14_chunk_events_seawater_swap2_user__idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_14_chunk_events_seawater_swap2_user__idx ON _timescaledb_internal._hyper_1_14_chunk USING btree (user_);


--
-- Name: _hyper_1_14_chunk_events_seawater_swap2_user__to__idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_14_chunk_events_seawater_swap2_user__to__idx ON _timescaledb_internal._hyper_1_14_chunk USING btree (user_, to_);


--
-- Name: _hyper_1_8_chunk_events_seawater_swap2_created_by_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_8_chunk_events_seawater_swap2_created_by_idx ON _timescaledb_internal._hyper_1_8_chunk USING btree (created_by DESC);


--
-- Name: _hyper_1_8_chunk_events_seawater_swap2_from__idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_8_chunk_events_seawater_swap2_from__idx ON _timescaledb_internal._hyper_1_8_chunk USING btree (from_);


--
-- Name: _hyper_1_8_chunk_events_seawater_swap2_from__idx1; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_8_chunk_events_seawater_swap2_from__idx1 ON _timescaledb_internal._hyper_1_8_chunk USING btree (from_);


--
-- Name: _hyper_1_8_chunk_events_seawater_swap2_to__idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_8_chunk_events_seawater_swap2_to__idx ON _timescaledb_internal._hyper_1_8_chunk USING btree (to_);


--
-- Name: _hyper_1_8_chunk_events_seawater_swap2_to__idx1; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_8_chunk_events_seawater_swap2_to__idx1 ON _timescaledb_internal._hyper_1_8_chunk USING btree (to_);


--
-- Name: _hyper_1_8_chunk_events_seawater_swap2_user__from__idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_8_chunk_events_seawater_swap2_user__from__idx ON _timescaledb_internal._hyper_1_8_chunk USING btree (user_, from_);


--
-- Name: _hyper_1_8_chunk_events_seawater_swap2_user__idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_8_chunk_events_seawater_swap2_user__idx ON _timescaledb_internal._hyper_1_8_chunk USING btree (user_);


--
-- Name: _hyper_1_8_chunk_events_seawater_swap2_user__to__idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_1_8_chunk_events_seawater_swap2_user__to__idx ON _timescaledb_internal._hyper_1_8_chunk USING btree (user_, to_);


--
-- Name: _hyper_2_11_chunk_events_seawater_swap1_created_by_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_2_11_chunk_events_seawater_swap1_created_by_idx ON _timescaledb_internal._hyper_2_11_chunk USING btree (created_by DESC);


--
-- Name: _hyper_2_11_chunk_events_seawater_swap1_pool_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_2_11_chunk_events_seawater_swap1_pool_idx ON _timescaledb_internal._hyper_2_11_chunk USING btree (pool);


--
-- Name: _hyper_2_11_chunk_events_seawater_swap1_user__idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_2_11_chunk_events_seawater_swap1_user__idx ON _timescaledb_internal._hyper_2_11_chunk USING btree (user_);


--
-- Name: _hyper_2_11_chunk_events_seawater_swap1_user__pool_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_2_11_chunk_events_seawater_swap1_user__pool_idx ON _timescaledb_internal._hyper_2_11_chunk USING btree (user_, pool);


--
-- Name: _hyper_2_13_chunk_events_seawater_swap1_created_by_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_2_13_chunk_events_seawater_swap1_created_by_idx ON _timescaledb_internal._hyper_2_13_chunk USING btree (created_by DESC);


--
-- Name: _hyper_2_13_chunk_events_seawater_swap1_pool_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_2_13_chunk_events_seawater_swap1_pool_idx ON _timescaledb_internal._hyper_2_13_chunk USING btree (pool);


--
-- Name: _hyper_2_13_chunk_events_seawater_swap1_user__idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_2_13_chunk_events_seawater_swap1_user__idx ON _timescaledb_internal._hyper_2_13_chunk USING btree (user_);


--
-- Name: _hyper_2_13_chunk_events_seawater_swap1_user__pool_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_2_13_chunk_events_seawater_swap1_user__pool_idx ON _timescaledb_internal._hyper_2_13_chunk USING btree (user_, pool);


--
-- Name: _hyper_2_1_chunk_events_seawater_swap1_created_by_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_2_1_chunk_events_seawater_swap1_created_by_idx ON _timescaledb_internal._hyper_2_1_chunk USING btree (created_by DESC);


--
-- Name: _hyper_2_1_chunk_events_seawater_swap1_pool_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_2_1_chunk_events_seawater_swap1_pool_idx ON _timescaledb_internal._hyper_2_1_chunk USING btree (pool);


--
-- Name: _hyper_2_1_chunk_events_seawater_swap1_user__idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_2_1_chunk_events_seawater_swap1_user__idx ON _timescaledb_internal._hyper_2_1_chunk USING btree (user_);


--
-- Name: _hyper_2_1_chunk_events_seawater_swap1_user__pool_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_2_1_chunk_events_seawater_swap1_user__pool_idx ON _timescaledb_internal._hyper_2_1_chunk USING btree (user_, pool);


--
-- Name: _hyper_2_4_chunk_events_seawater_swap1_created_by_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_2_4_chunk_events_seawater_swap1_created_by_idx ON _timescaledb_internal._hyper_2_4_chunk USING btree (created_by DESC);


--
-- Name: _hyper_2_4_chunk_events_seawater_swap1_pool_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_2_4_chunk_events_seawater_swap1_pool_idx ON _timescaledb_internal._hyper_2_4_chunk USING btree (pool);


--
-- Name: _hyper_2_4_chunk_events_seawater_swap1_user__idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_2_4_chunk_events_seawater_swap1_user__idx ON _timescaledb_internal._hyper_2_4_chunk USING btree (user_);


--
-- Name: _hyper_2_4_chunk_events_seawater_swap1_user__pool_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_2_4_chunk_events_seawater_swap1_user__pool_idx ON _timescaledb_internal._hyper_2_4_chunk USING btree (user_, pool);


--
-- Name: _hyper_2_5_chunk_events_seawater_swap1_created_by_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_2_5_chunk_events_seawater_swap1_created_by_idx ON _timescaledb_internal._hyper_2_5_chunk USING btree (created_by DESC);


--
-- Name: _hyper_2_5_chunk_events_seawater_swap1_pool_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_2_5_chunk_events_seawater_swap1_pool_idx ON _timescaledb_internal._hyper_2_5_chunk USING btree (pool);


--
-- Name: _hyper_2_5_chunk_events_seawater_swap1_user__idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_2_5_chunk_events_seawater_swap1_user__idx ON _timescaledb_internal._hyper_2_5_chunk USING btree (user_);


--
-- Name: _hyper_2_5_chunk_events_seawater_swap1_user__pool_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_2_5_chunk_events_seawater_swap1_user__pool_idx ON _timescaledb_internal._hyper_2_5_chunk USING btree (user_, pool);


--
-- Name: _hyper_2_9_chunk_events_seawater_swap1_created_by_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_2_9_chunk_events_seawater_swap1_created_by_idx ON _timescaledb_internal._hyper_2_9_chunk USING btree (created_by DESC);


--
-- Name: _hyper_2_9_chunk_events_seawater_swap1_pool_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_2_9_chunk_events_seawater_swap1_pool_idx ON _timescaledb_internal._hyper_2_9_chunk USING btree (pool);


--
-- Name: _hyper_2_9_chunk_events_seawater_swap1_user__idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_2_9_chunk_events_seawater_swap1_user__idx ON _timescaledb_internal._hyper_2_9_chunk USING btree (user_);


--
-- Name: _hyper_2_9_chunk_events_seawater_swap1_user__pool_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_2_9_chunk_events_seawater_swap1_user__pool_idx ON _timescaledb_internal._hyper_2_9_chunk USING btree (user_, pool);


--
-- Name: _hyper_3_3_chunk__materialized_hypertable_3_decimals_hourly_int; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_3_3_chunk__materialized_hypertable_3_decimals_hourly_int ON _timescaledb_internal._hyper_3_3_chunk USING btree (decimals, hourly_interval DESC);


--
-- Name: _hyper_3_3_chunk__materialized_hypertable_3_hourly_interval_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_3_3_chunk__materialized_hypertable_3_hourly_interval_idx ON _timescaledb_internal._hyper_3_3_chunk USING btree (hourly_interval DESC);


--
-- Name: _hyper_3_3_chunk__materialized_hypertable_3_pool_hourly_interva; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_3_3_chunk__materialized_hypertable_3_pool_hourly_interva ON _timescaledb_internal._hyper_3_3_chunk USING btree (pool, hourly_interval DESC);


--
-- Name: _hyper_3_7_chunk__materialized_hypertable_3_decimals_hourly_int; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_3_7_chunk__materialized_hypertable_3_decimals_hourly_int ON _timescaledb_internal._hyper_3_7_chunk USING btree (decimals, hourly_interval DESC);


--
-- Name: _hyper_3_7_chunk__materialized_hypertable_3_hourly_interval_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_3_7_chunk__materialized_hypertable_3_hourly_interval_idx ON _timescaledb_internal._hyper_3_7_chunk USING btree (hourly_interval DESC);


--
-- Name: _hyper_3_7_chunk__materialized_hypertable_3_pool_hourly_interva; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_3_7_chunk__materialized_hypertable_3_pool_hourly_interva ON _timescaledb_internal._hyper_3_7_chunk USING btree (pool, hourly_interval DESC);


--
-- Name: _hyper_4_2_chunk__materialized_hypertable_4_decimals_hourly_int; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_4_2_chunk__materialized_hypertable_4_decimals_hourly_int ON _timescaledb_internal._hyper_4_2_chunk USING btree (decimals, hourly_interval DESC);


--
-- Name: _hyper_4_2_chunk__materialized_hypertable_4_hourly_interval_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_4_2_chunk__materialized_hypertable_4_hourly_interval_idx ON _timescaledb_internal._hyper_4_2_chunk USING btree (hourly_interval DESC);


--
-- Name: _hyper_4_2_chunk__materialized_hypertable_4_pool_hourly_interva; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_4_2_chunk__materialized_hypertable_4_pool_hourly_interva ON _timescaledb_internal._hyper_4_2_chunk USING btree (pool, hourly_interval DESC);


--
-- Name: _hyper_4_6_chunk__materialized_hypertable_4_decimals_hourly_int; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_4_6_chunk__materialized_hypertable_4_decimals_hourly_int ON _timescaledb_internal._hyper_4_6_chunk USING btree (decimals, hourly_interval DESC);


--
-- Name: _hyper_4_6_chunk__materialized_hypertable_4_hourly_interval_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_4_6_chunk__materialized_hypertable_4_hourly_interval_idx ON _timescaledb_internal._hyper_4_6_chunk USING btree (hourly_interval DESC);


--
-- Name: _hyper_4_6_chunk__materialized_hypertable_4_pool_hourly_interva; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _hyper_4_6_chunk__materialized_hypertable_4_pool_hourly_interva ON _timescaledb_internal._hyper_4_6_chunk USING btree (pool, hourly_interval DESC);


--
-- Name: _materialized_hypertable_3_decimals_hourly_interval_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _materialized_hypertable_3_decimals_hourly_interval_idx ON _timescaledb_internal._materialized_hypertable_3 USING btree (decimals, hourly_interval DESC);


--
-- Name: _materialized_hypertable_3_hourly_interval_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _materialized_hypertable_3_hourly_interval_idx ON _timescaledb_internal._materialized_hypertable_3 USING btree (hourly_interval DESC);


--
-- Name: _materialized_hypertable_3_pool_hourly_interval_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _materialized_hypertable_3_pool_hourly_interval_idx ON _timescaledb_internal._materialized_hypertable_3 USING btree (pool, hourly_interval DESC);


--
-- Name: _materialized_hypertable_4_decimals_hourly_interval_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _materialized_hypertable_4_decimals_hourly_interval_idx ON _timescaledb_internal._materialized_hypertable_4 USING btree (decimals, hourly_interval DESC);


--
-- Name: _materialized_hypertable_4_hourly_interval_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _materialized_hypertable_4_hourly_interval_idx ON _timescaledb_internal._materialized_hypertable_4 USING btree (hourly_interval DESC);


--
-- Name: _materialized_hypertable_4_pool_hourly_interval_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: -
--

CREATE INDEX _materialized_hypertable_4_pool_hourly_interval_idx ON _timescaledb_internal._materialized_hypertable_4 USING btree (pool, hourly_interval DESC);


--
-- Name: accounts_executed_transactions_2_desc__idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounts_executed_transactions_2_desc__idx ON public.accounts_executed_transactions_2 USING btree (desc_);


--
-- Name: accounts_executed_transactions_2_eoa_addr_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounts_executed_transactions_2_eoa_addr_idx ON public.accounts_executed_transactions_2 USING btree (eoa_addr);


--
-- Name: accounts_executed_transactions_2_transaction_hash_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounts_executed_transactions_2_transaction_hash_idx ON public.accounts_executed_transactions_2 USING btree (transaction_hash);


--
-- Name: accounts_secrets_nonces_1_secret_id_consumed_nonce_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounts_secrets_nonces_1_secret_id_consumed_nonce_idx ON public.accounts_secrets_nonces_1 USING btree (secret_id, consumed_nonce);


--
-- Name: bozo_comments_1_epoch_epoch_seq_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX bozo_comments_1_epoch_epoch_seq_idx ON public.bozo_comments_1 USING btree (epoch, epoch_seq);


--
-- Name: bozo_comments_1_epoch_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX bozo_comments_1_epoch_idx ON public.bozo_comments_1 USING btree (epoch);


--
-- Name: discord_usernames_1_address_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX discord_usernames_1_address_idx ON public.discord_usernames_1 USING btree (address);


--
-- Name: discord_usernames_1_discord_address_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX discord_usernames_1_discord_address_idx ON public.discord_usernames_1 USING btree (discord, address);


--
-- Name: discord_usernames_2_address_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX discord_usernames_2_address_idx ON public.discord_usernames_2 USING btree (address);


--
-- Name: discord_usernames_2_discord_username_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX discord_usernames_2_discord_username_idx ON public.discord_usernames_2 USING btree (discord_username);


--
-- Name: erc20_cache_1_address_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX erc20_cache_1_address_idx ON public.erc20_cache_1 USING btree (address);


--
-- Name: events_erc20_transfer_created_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_erc20_transfer_created_by_idx ON public.events_erc20_transfer USING btree (created_by);


--
-- Name: events_erc20_transfer_recipient_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_erc20_transfer_recipient_idx ON public.events_erc20_transfer USING btree (recipient);


--
-- Name: events_erc20_transfer_sender_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_erc20_transfer_sender_idx ON public.events_erc20_transfer USING btree (sender);


--
-- Name: events_leo_campaigncreated_identifier_pool_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX events_leo_campaigncreated_identifier_pool_idx ON public.events_leo_campaigncreated USING btree (identifier, pool);


--
-- Name: events_leo_positiondivested2_position_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_leo_positiondivested2_position_id_idx ON public.events_leo_positiondivested2 USING btree (position_id);


--
-- Name: events_leo_positiondivested2_recipient_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_leo_positiondivested2_recipient_idx ON public.events_leo_positiondivested2 USING btree (recipient);


--
-- Name: events_leo_positionvested2_owner_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_leo_positionvested2_owner_idx ON public.events_leo_positionvested2 USING btree (owner);


--
-- Name: events_leo_positionvested2_position_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_leo_positionvested2_position_id_idx ON public.events_leo_positionvested2 USING btree (position_id);


--
-- Name: events_purrstream_donated_cat_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_purrstream_donated_cat_idx ON public.events_purrstream_donated USING btree (cat);


--
-- Name: events_seawater_burnposition_owner_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX events_seawater_burnposition_owner_idx ON public.events_seawater_burnposition USING btree (owner);


--
-- Name: events_seawater_burnposition_pos_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX events_seawater_burnposition_pos_id_idx ON public.events_seawater_burnposition USING btree (pos_id);


--
-- Name: events_seawater_collectfees_pool_to__idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_seawater_collectfees_pool_to__idx ON public.events_seawater_collectfees USING btree (pool, to_);


--
-- Name: events_seawater_collectfees_pos_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_seawater_collectfees_pos_id_idx ON public.events_seawater_collectfees USING btree (pos_id);


--
-- Name: events_seawater_collectprotocolfees_pool_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_seawater_collectprotocolfees_pool_idx ON public.events_seawater_collectprotocolfees USING btree (pool);


--
-- Name: events_seawater_collectprotocolfees_pool_to__idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_seawater_collectprotocolfees_pool_to__idx ON public.events_seawater_collectprotocolfees USING btree (pool, to_);


--
-- Name: events_seawater_collectprotocolfees_to__idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_seawater_collectprotocolfees_to__idx ON public.events_seawater_collectprotocolfees USING btree (to_);


--
-- Name: events_seawater_mintposition_owner_pool_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_seawater_mintposition_owner_pool_idx ON public.events_seawater_mintposition USING btree (owner, pool);


--
-- Name: events_seawater_mintposition_pos_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX events_seawater_mintposition_pos_id_idx ON public.events_seawater_mintposition USING btree (pos_id);


--
-- Name: events_seawater_newpool_token_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX events_seawater_newpool_token_idx ON public.events_seawater_newpool USING btree (token);


--
-- Name: events_seawater_swap1_created_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_seawater_swap1_created_by_idx ON public.events_seawater_swap1 USING btree (created_by DESC);


--
-- Name: events_seawater_swap1_pool_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_seawater_swap1_pool_idx ON public.events_seawater_swap1 USING btree (pool);


--
-- Name: events_seawater_swap1_user__idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_seawater_swap1_user__idx ON public.events_seawater_swap1 USING btree (user_);


--
-- Name: events_seawater_swap1_user__pool_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_seawater_swap1_user__pool_idx ON public.events_seawater_swap1 USING btree (user_, pool);


--
-- Name: events_seawater_swap2_created_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_seawater_swap2_created_by_idx ON public.events_seawater_swap2 USING btree (created_by DESC);


--
-- Name: events_seawater_swap2_from__idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_seawater_swap2_from__idx ON public.events_seawater_swap2 USING btree (from_);


--
-- Name: events_seawater_swap2_from__idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_seawater_swap2_from__idx1 ON public.events_seawater_swap2 USING btree (from_);


--
-- Name: events_seawater_swap2_to__idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_seawater_swap2_to__idx ON public.events_seawater_swap2 USING btree (to_);


--
-- Name: events_seawater_swap2_to__idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_seawater_swap2_to__idx1 ON public.events_seawater_swap2 USING btree (to_);


--
-- Name: events_seawater_swap2_user__from__idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_seawater_swap2_user__from__idx ON public.events_seawater_swap2 USING btree (user_, from_);


--
-- Name: events_seawater_swap2_user__idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_seawater_swap2_user__idx ON public.events_seawater_swap2 USING btree (user_);


--
-- Name: events_seawater_swap2_user__to__idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_seawater_swap2_user__to__idx ON public.events_seawater_swap2 USING btree (user_, to_);


--
-- Name: events_seawater_transferposition_from__idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_seawater_transferposition_from__idx ON public.events_seawater_transferposition USING btree (from_);


--
-- Name: events_seawater_transferposition_pos_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_seawater_transferposition_pos_id_idx ON public.events_seawater_transferposition USING btree (pos_id);


--
-- Name: events_seawater_transferposition_to__idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_seawater_transferposition_to__idx ON public.events_seawater_transferposition USING btree (to_);


--
-- Name: events_seawater_updatepositionliquidity_block_number_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_seawater_updatepositionliquidity_block_number_idx ON public.events_seawater_updatepositionliquidity USING btree (block_number);


--
-- Name: events_seawater_updatepositionliquidity_pos_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_seawater_updatepositionliquidity_pos_id_idx ON public.events_seawater_updatepositionliquidity USING btree (pos_id);


--
-- Name: idx_ninelives_campaigns_1_name_to_search; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ninelives_campaigns_1_name_to_search ON public.ninelives_campaigns_1 USING gin (name_to_search public.gin_trgm_ops);


--
-- Name: ninelives_all_earned_1_emitter_addr_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ninelives_all_earned_1_emitter_addr_idx ON public.ninelives_all_earned_1 USING btree (emitter_addr);


--
-- Name: ninelives_all_earned_1_emitter_addr_recipient_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ninelives_all_earned_1_emitter_addr_recipient_idx ON public.ninelives_all_earned_1 USING btree (emitter_addr, recipient);


--
-- Name: ninelives_all_earned_1_recipient_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ninelives_all_earned_1_recipient_idx ON public.ninelives_all_earned_1 USING btree (recipient);


--
-- Name: ninelives_campaign_categories_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ninelives_campaign_categories_idx ON public.ninelives_campaigns_1 USING gin (((content -> 'categories'::text)));


--
-- Name: ninelives_campaigns_1_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ninelives_campaigns_1_created_at_idx ON public.ninelives_campaigns_1 USING btree (created_at);


--
-- Name: ninelives_campaigns_1_expr_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ninelives_campaigns_1_expr_idx ON public.ninelives_campaigns_1 USING btree (((content ->> 'poolAddress'::text)));


--
-- Name: ninelives_campaigns_1_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ninelives_campaigns_1_updated_at_idx ON public.ninelives_campaigns_1 USING btree (updated_at);


--
-- Name: ninelives_campaigns_categories_1_category_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ninelives_campaigns_categories_1_category_id_idx ON public.ninelives_campaigns_categories_1 USING btree (category_id);


--
-- Name: ninelives_events_committed_trading_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ninelives_events_committed_trading_idx ON public.ninelives_events_committed USING btree (trading);


--
-- Name: ninelives_events_frozen_victim_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ninelives_events_frozen_victim_idx ON public.ninelives_events_frozen USING btree (victim);


--
-- Name: ninelives_events_locked_up_recipient_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ninelives_events_locked_up_recipient_idx ON public.ninelives_events_locked_up USING btree (recipient);


--
-- Name: ninelives_events_ninetails_boosted_shares_receive_recipient_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ninelives_events_ninetails_boosted_shares_receive_recipient_idx ON public.ninelives_events_ninetails_boosted_shares_received USING btree (recipient);


--
-- Name: ninelives_events_ninetails_boosted_shares_received_outcome_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ninelives_events_ninetails_boosted_shares_received_outcome_idx ON public.ninelives_events_ninetails_boosted_shares_received USING btree (outcome);


--
-- Name: ninelives_events_ninetails_cumulative_winner_payo_recipient_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ninelives_events_ninetails_cumulative_winner_payo_recipient_idx ON public.ninelives_events_ninetails_cumulative_winner_payoff USING btree (recipient);


--
-- Name: ninelives_events_ninetails_cumulative_winner_payoff_outcome_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ninelives_events_ninetails_cumulative_winner_payoff_outcome_idx ON public.ninelives_events_ninetails_cumulative_winner_payoff USING btree (outcome);


--
-- Name: ninelives_events_slashed_victim_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ninelives_events_slashed_victim_idx ON public.ninelives_events_slashed USING btree (victim);


--
-- Name: ninelives_events_withdrew_recipient_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ninelives_events_withdrew_recipient_idx ON public.ninelives_events_withdrew USING btree (recipient);


--
-- Name: ninelives_frontpage_1_from_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ninelives_frontpage_1_from_idx ON public.ninelives_frontpage_1 USING btree ("from");


--
-- Name: ninelives_frontpage_1_until_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ninelives_frontpage_1_until_idx ON public.ninelives_frontpage_1 USING btree (until);


--
-- Name: ninelives_market_odds_snapshot_1_pool_address_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ninelives_market_odds_snapshot_1_pool_address_idx ON public.ninelives_market_odds_snapshot_1 USING btree (pool_address);


--
-- Name: ninelives_markets_enabled_1_base_quote_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ninelives_markets_enabled_1_base_quote_idx ON public.ninelives_markets_enabled_1 USING btree (base, quote);


--
-- Name: ninelives_newsfeed_1_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ninelives_newsfeed_1_date_idx ON public.ninelives_newsfeed_1 USING btree (date);


--
-- Name: ninelives_payoff_unused_1_pool_address_spender_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ninelives_payoff_unused_1_pool_address_spender_idx ON public.ninelives_payoff_unused_1 USING btree (pool_address, spender);


--
-- Name: ninelives_revealed_commitments_1_trading_addr_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ninelives_revealed_commitments_1_trading_addr_idx ON public.ninelives_revealed_commitments_1 USING btree (trading_addr);


--
-- Name: oracles_ninelives_prices_1_base_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX oracles_ninelives_prices_1_base_idx ON public.oracles_ninelives_prices_1 USING btree (base);


--
-- Name: oracles_ninelives_prices_1_base_quote_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX oracles_ninelives_prices_1_base_quote_idx ON public.oracles_ninelives_prices_1 USING btree (base, quote);


--
-- Name: oracles_ninelives_prices_1_quote_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX oracles_ninelives_prices_1_quote_idx ON public.oracles_ninelives_prices_1 USING btree (quote);


--
-- Name: oracles_ninelives_prices_2_base_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX oracles_ninelives_prices_2_base_idx ON public.oracles_ninelives_prices_2 USING btree (base);


--
-- Name: oracles_ninelives_prices_2_base_quote_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX oracles_ninelives_prices_2_base_quote_idx ON public.oracles_ninelives_prices_2 USING btree (base, quote);


--
-- Name: oracles_ninelives_prices_2_created_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX oracles_ninelives_prices_2_created_by_idx ON public.oracles_ninelives_prices_2 USING btree (created_by);


--
-- Name: oracles_ninelives_prices_2_quote_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX oracles_ninelives_prices_2_quote_idx ON public.oracles_ninelives_prices_2 USING btree (quote);


--
-- Name: points_achievements_received_1_address_achievement_name_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX points_achievements_received_1_address_achievement_name_idx ON public.points_achievements_received_1 USING btree (address, achievement_name);


--
-- Name: points_achievements_received_1_address_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX points_achievements_received_1_address_idx ON public.points_achievements_received_1 USING btree (address);


--
-- Name: points_achievements_received_2_address_achievement_name_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX points_achievements_received_2_address_achievement_name_idx ON public.points_achievements_received_2 USING btree (address, achievement_name);


--
-- Name: points_achievements_received_2_address_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX points_achievements_received_2_address_idx ON public.points_achievements_received_2 USING btree (address);


--
-- Name: points_achievements_received_2_address_product_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX points_achievements_received_2_address_product_idx ON public.points_achievements_received_2 USING btree (address, product);


--
-- Name: points_achievements_received_2_address_product_season_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX points_achievements_received_2_address_product_season_idx ON public.points_achievements_received_2 USING btree (address, product, season);


--
-- Name: points_achievements_received_2_address_season_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX points_achievements_received_2_address_season_idx ON public.points_achievements_received_2 USING btree (address, season);


--
-- Name: points_discovered_debank_balance_address_network_asset_name_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX points_discovered_debank_balance_address_network_asset_name_idx ON public.points_discovered_debank_balances_1 USING btree (address, network, asset_name);


--
-- Name: points_discovered_debank_balances_1_address_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX points_discovered_debank_balances_1_address_idx ON public.points_discovered_debank_balances_1 USING btree (address);


--
-- Name: points_discovered_debank_balances_1_asset_name_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX points_discovered_debank_balances_1_asset_name_idx ON public.points_discovered_debank_balances_1 USING btree (asset_name);


--
-- Name: points_discovered_debank_nobal_1_address_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX points_discovered_debank_nobal_1_address_idx ON public.points_discovered_debank_nobal_1 USING btree (address);


--
-- Name: points_displayed_via_endpoint_1_address_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX points_displayed_via_endpoint_1_address_idx ON public.points_displayed_via_endpoint_1 USING btree (address);


--
-- Name: punk_domains_events_default_domain_changed_address_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX punk_domains_events_default_domain_changed_address_idx ON public.punk_domains_events_default_domain_changed USING btree (address);


--
-- Name: seawater_active_positions_2_owner_created_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX seawater_active_positions_2_owner_created_by_idx ON public.seawater_active_positions_2 USING btree (owner, created_by DESC);


--
-- Name: seawater_active_positions_2_pool_created_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX seawater_active_positions_2_pool_created_by_idx ON public.seawater_active_positions_2 USING btree (pool, created_by DESC);


--
-- Name: seawater_active_positions_6_owner_created_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX seawater_active_positions_6_owner_created_by_idx ON public.seawater_active_positions_6 USING btree (owner, created_by DESC);


--
-- Name: seawater_active_positions_6_pool_created_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX seawater_active_positions_6_pool_created_by_idx ON public.seawater_active_positions_6 USING btree (pool, created_by DESC);


--
-- Name: snapshot_positions_latest_1_pos_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX snapshot_positions_latest_1_pos_id_idx ON public.snapshot_positions_latest_1 USING btree (pos_id);


--
-- Name: _hyper_2_11_chunk ts_cagg_invalidation_trigger; Type: TRIGGER; Schema: _timescaledb_internal; Owner: -
--

CREATE TRIGGER ts_cagg_invalidation_trigger AFTER INSERT OR DELETE OR UPDATE ON _timescaledb_internal._hyper_2_11_chunk FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.continuous_agg_invalidation_trigger('2');


--
-- Name: _hyper_2_13_chunk ts_cagg_invalidation_trigger; Type: TRIGGER; Schema: _timescaledb_internal; Owner: -
--

CREATE TRIGGER ts_cagg_invalidation_trigger AFTER INSERT OR DELETE OR UPDATE ON _timescaledb_internal._hyper_2_13_chunk FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.continuous_agg_invalidation_trigger('2');


--
-- Name: _hyper_2_1_chunk ts_cagg_invalidation_trigger; Type: TRIGGER; Schema: _timescaledb_internal; Owner: -
--

CREATE TRIGGER ts_cagg_invalidation_trigger AFTER INSERT OR DELETE OR UPDATE ON _timescaledb_internal._hyper_2_1_chunk FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.continuous_agg_invalidation_trigger('2');


--
-- Name: _hyper_2_4_chunk ts_cagg_invalidation_trigger; Type: TRIGGER; Schema: _timescaledb_internal; Owner: -
--

CREATE TRIGGER ts_cagg_invalidation_trigger AFTER INSERT OR DELETE OR UPDATE ON _timescaledb_internal._hyper_2_4_chunk FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.continuous_agg_invalidation_trigger('2');


--
-- Name: _hyper_2_5_chunk ts_cagg_invalidation_trigger; Type: TRIGGER; Schema: _timescaledb_internal; Owner: -
--

CREATE TRIGGER ts_cagg_invalidation_trigger AFTER INSERT OR DELETE OR UPDATE ON _timescaledb_internal._hyper_2_5_chunk FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.continuous_agg_invalidation_trigger('2');


--
-- Name: _hyper_2_9_chunk ts_cagg_invalidation_trigger; Type: TRIGGER; Schema: _timescaledb_internal; Owner: -
--

CREATE TRIGGER ts_cagg_invalidation_trigger AFTER INSERT OR DELETE OR UPDATE ON _timescaledb_internal._hyper_2_9_chunk FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.continuous_agg_invalidation_trigger('2');


--
-- Name: _materialized_hypertable_3 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: -
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._materialized_hypertable_3 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _materialized_hypertable_4 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: -
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._materialized_hypertable_4 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: ninelives_events_shares_minted ninelives_insert_unused_payoff_trigger_1; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER ninelives_insert_unused_payoff_trigger_1 AFTER INSERT ON public.ninelives_events_shares_minted FOR EACH ROW EXECUTE FUNCTION public.ninelives_insert_unused_payoff_1();


--
-- Name: ninelives_events_ninetails_loser_payoff ninelives_mark_payoff_spent_trigger_1; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER ninelives_mark_payoff_spent_trigger_1 AFTER INSERT ON public.ninelives_events_ninetails_loser_payoff FOR EACH ROW EXECUTE FUNCTION public.ninelives_mark_payoff_spent_1();


--
-- Name: ninelives_events_payoff_activated ninelives_mark_payoff_spent_trigger_1; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER ninelives_mark_payoff_spent_trigger_1 AFTER INSERT ON public.ninelives_events_payoff_activated FOR EACH ROW EXECUTE FUNCTION public.ninelives_mark_payoff_spent_1();


--
-- Name: ninelives_events_shares_minted ninelives_market_odds_summaries_trigger_1; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER ninelives_market_odds_summaries_trigger_1 AFTER INSERT ON public.ninelives_events_shares_minted FOR EACH ROW EXECUTE FUNCTION public.ninelives_market_odds_summaries_1();


--
-- Name: ninelives_market_summaries_1 ninelives_trigger_create_snapshot; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER ninelives_trigger_create_snapshot AFTER INSERT OR UPDATE ON public.ninelives_market_summaries_1 FOR EACH ROW EXECUTE FUNCTION public.ninelives_create_snapshot_from_summary_1();


--
-- Name: ninelives_events_shares_burned ninelives_trigger_ninelives_events_shares_burned_to_ninelives_b; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER ninelives_trigger_ninelives_events_shares_burned_to_ninelives_b AFTER INSERT ON public.ninelives_events_shares_burned FOR EACH ROW EXECUTE FUNCTION public.ninelives_fun_ninelives_events_shares_burned_to_ninelives_buys_();


--
-- Name: ninelives_events_shares_minted ninelives_trigger_ninelives_events_shares_minted_to_ninelives_b; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER ninelives_trigger_ninelives_events_shares_minted_to_ninelives_b AFTER INSERT ON public.ninelives_events_shares_minted FOR EACH ROW EXECUTE FUNCTION public.ninelives_fun_ninelives_events_shares_minted_to_ninelives_buys_();


--
-- Name: ninelives_events_outcome_decided ninelives_trigger_update_buys_and_sells_for_winner; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER ninelives_trigger_update_buys_and_sells_for_winner AFTER INSERT ON public.ninelives_events_outcome_decided FOR EACH ROW EXECUTE FUNCTION public.ninelives_update_buys_and_sells_for_winner();


--
-- Name: ninelives_campaigns_1 ninelives_trigger_update_buys_sells_on_create; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER ninelives_trigger_update_buys_sells_on_create AFTER INSERT ON public.ninelives_campaigns_1 FOR EACH ROW EXECUTE FUNCTION public.ninelives_update_buys_sells_on_create();


--
-- Name: ninelives_events_outcome_decided ninelives_trigger_update_campaign_for_winner; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER ninelives_trigger_update_campaign_for_winner AFTER INSERT ON public.ninelives_events_outcome_decided FOR EACH ROW EXECUTE FUNCTION public.ninelives_update_campaign_for_winner();


--
-- Name: ninelives_campaigns_1 ninelives_trigger_update_liquidity_on_campaign_creation_1; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER ninelives_trigger_update_liquidity_on_campaign_creation_1 AFTER INSERT ON public.ninelives_campaigns_1 FOR EACH ROW EXECUTE FUNCTION public.ninelives_update_liquidity_on_campaign_creation_1();


--
-- Name: ninelives_events_shares_burned ninelives_trigger_update_total_volume_for_campaigns_on_burn; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER ninelives_trigger_update_total_volume_for_campaigns_on_burn AFTER INSERT ON public.ninelives_events_shares_burned FOR EACH ROW EXECUTE FUNCTION public.ninelives_update_total_volume_after_burn();


--
-- Name: ninelives_events_shares_minted ninelives_trigger_update_total_volume_for_campaigns_on_mint; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER ninelives_trigger_update_total_volume_for_campaigns_on_mint AFTER INSERT ON public.ninelives_events_shares_minted FOR EACH ROW EXECUTE FUNCTION public.ninelives_update_total_volume_after_mint();


--
-- Name: ninelives_events_liquidity_added ninelives_trigger_update_total_volume_for_campaigns_on_stake; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER ninelives_trigger_update_total_volume_for_campaigns_on_stake AFTER INSERT ON public.ninelives_events_liquidity_added FOR EACH ROW EXECUTE FUNCTION public.ninelives_update_total_volume_after_stake();


--
-- Name: ninelives_events_ninetails_cumulative_winner_payoff ninelives_update_all_earned_cumulative_winner_payoff_trigger_1; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER ninelives_update_all_earned_cumulative_winner_payoff_trigger_1 AFTER INSERT ON public.ninelives_events_ninetails_cumulative_winner_payoff FOR EACH ROW EXECUTE FUNCTION public.ninelives_update_all_earned_1();


--
-- Name: ninelives_events_ninetails_loser_payoff ninelives_update_all_earned_loser_payoff_trigger_1; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER ninelives_update_all_earned_loser_payoff_trigger_1 AFTER INSERT ON public.ninelives_events_ninetails_loser_payoff FOR EACH ROW EXECUTE FUNCTION public.ninelives_update_all_earned_1();


--
-- Name: ninelives_events_payoff_activated ninelives_update_all_earned_payoff_activated_trigger_1; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER ninelives_update_all_earned_payoff_activated_trigger_1 AFTER INSERT ON public.ninelives_events_payoff_activated FOR EACH ROW EXECUTE FUNCTION public.ninelives_update_all_earned_1();


--
-- Name: oracles_ninelives_prices_1 oracles_ninelives_copy_prices_1_to_trigger_2_1; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER oracles_ninelives_copy_prices_1_to_trigger_2_1 AFTER INSERT ON public.oracles_ninelives_prices_1 FOR EACH ROW EXECUTE FUNCTION public.oracles_ninelives_copy_prices_1_to_2_1();


--
-- Name: lifi_events_generic_swap_completed points_trigger_galxe_add_pending_1; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER points_trigger_galxe_add_pending_1 AFTER INSERT ON public.lifi_events_generic_swap_completed FOR EACH ROW EXECUTE FUNCTION public.points_galxe_track_incoming_lifi_1();


--
-- Name: ninelives_events_shares_minted points_trigger_liquidity_purrvider_1; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER points_trigger_liquidity_purrvider_1 BEFORE INSERT ON public.ninelives_events_shares_minted FOR EACH ROW EXECUTE FUNCTION public.points_trigger_fun_liquidity_purrvider_1();


--
-- Name: ninelives_events_requested sarp_trigger_track_requests; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sarp_trigger_track_requests BEFORE INSERT ON public.ninelives_events_requested FOR EACH ROW EXECUTE FUNCTION public.sarp_track_requests();


--
-- Name: events_seawater_swap1 ts_cagg_invalidation_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER ts_cagg_invalidation_trigger AFTER INSERT OR DELETE OR UPDATE ON public.events_seawater_swap1 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.continuous_agg_invalidation_trigger('2');


--
-- Name: events_seawater_swap1 ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.events_seawater_swap1 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: events_seawater_swap2 ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.events_seawater_swap2 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: discord_usernames_2 discord_usernames_2_association_giver_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discord_usernames_2
    ADD CONSTRAINT discord_usernames_2_association_giver_fkey FOREIGN KEY (association_giver) REFERENCES public.points_auth_secret_keys_1(id);


--
-- Name: ninelives_buys_and_sells_1 ninelives_buys_and_sells_1_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_buys_and_sells_1
    ADD CONSTRAINT ninelives_buys_and_sells_1_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.ninelives_campaigns_1(id);


--
-- Name: ninelives_campaigns_categories_1 ninelives_campaigns_categories_1_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_campaigns_categories_1
    ADD CONSTRAINT ninelives_campaigns_categories_1_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.ninelives_campaigns_1(id);


--
-- Name: ninelives_campaigns_categories_1 ninelives_campaigns_categories_1_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_campaigns_categories_1
    ADD CONSTRAINT ninelives_campaigns_categories_1_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.ninelives_categories_1(id);


--
-- Name: ninelives_comments_1 ninelives_comments_1_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_comments_1
    ADD CONSTRAINT ninelives_comments_1_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.ninelives_campaigns_1(id) ON DELETE CASCADE;


--
-- Name: ninelives_frontpage_1 ninelives_frontpage_1_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_frontpage_1
    ADD CONSTRAINT ninelives_frontpage_1_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.ninelives_campaigns_1(id);


--
-- Name: ninelives_oracle_metadata_1 ninelives_oracle_metadata_1_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_oracle_metadata_1
    ADD CONSTRAINT ninelives_oracle_metadata_1_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.ninelives_campaigns_1(id);


--
-- Name: ninelives_paymaster_attempts_1 ninelives_paymaster_attempts_1_poll_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_paymaster_attempts_1
    ADD CONSTRAINT ninelives_paymaster_attempts_1_poll_id_fkey FOREIGN KEY (poll_id) REFERENCES public.ninelives_paymaster_poll_1(id);


--
-- Name: ninelives_paymaster_attempts_2 ninelives_paymaster_attempts_2_poll_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ninelives_paymaster_attempts_2
    ADD CONSTRAINT ninelives_paymaster_attempts_2_poll_id_fkey FOREIGN KEY (poll_id) REFERENCES public.ninelives_paymaster_poll_1(id);


--
-- Name: points_achievements_received_1 points_achievements_received_1_achievement_giver_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_achievements_received_1
    ADD CONSTRAINT points_achievements_received_1_achievement_giver_fkey FOREIGN KEY (achievement_giver) REFERENCES public.points_auth_secret_keys_1(id);


--
-- Name: points_achievements_received_2 points_achievements_received_2_achievement_giver_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_achievements_received_2
    ADD CONSTRAINT points_achievements_received_2_achievement_giver_fkey FOREIGN KEY (achievement_giver) REFERENCES public.points_auth_secret_keys_1(id);


--
-- Name: points_auth_bearer_tokens_1 points_auth_bearer_tokens_1_secretkey_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_auth_bearer_tokens_1
    ADD CONSTRAINT points_auth_bearer_tokens_1_secretkey_fkey FOREIGN KEY (secretkey) REFERENCES public.points_auth_secret_keys_1(key);


--
-- Name: points_auth_powers_1 points_auth_powers_1_secretkey_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_auth_powers_1
    ADD CONSTRAINT points_auth_powers_1_secretkey_fkey FOREIGN KEY (secretkey) REFERENCES public.points_auth_secret_keys_1(key);


--
-- Name: websocket_publication; Type: PUBLICATION; Schema: -; Owner: -
--

CREATE PUBLICATION websocket_publication WITH (publish = 'insert');


--
-- Name: websocket_publication ninelives_buys_and_sells_1; Type: PUBLICATION TABLE; Schema: public; Owner: -
--

ALTER PUBLICATION websocket_publication ADD TABLE ONLY public.ninelives_buys_and_sells_1;


--
-- Name: websocket_publication ninelives_campaigns_1; Type: PUBLICATION TABLE; Schema: public; Owner: -
--

ALTER PUBLICATION websocket_publication ADD TABLE ONLY public.ninelives_campaigns_1;


--
-- Name: websocket_publication ninelives_comments_1; Type: PUBLICATION TABLE; Schema: public; Owner: -
--

ALTER PUBLICATION websocket_publication ADD TABLE ONLY public.ninelives_comments_1;


--
-- Name: websocket_publication ninelives_events_outcome_decided; Type: PUBLICATION TABLE; Schema: public; Owner: -
--

ALTER PUBLICATION websocket_publication ADD TABLE ONLY public.ninelives_events_outcome_decided;


--
-- Name: websocket_publication ninelives_market_odds_snapshot_1; Type: PUBLICATION TABLE; Schema: public; Owner: -
--

ALTER PUBLICATION websocket_publication ADD TABLE ONLY public.ninelives_market_odds_snapshot_1;


--
-- Name: websocket_publication ninelives_payoff_unused_1; Type: PUBLICATION TABLE; Schema: public; Owner: -
--

ALTER PUBLICATION websocket_publication ADD TABLE ONLY public.ninelives_payoff_unused_1;


--
-- Name: websocket_publication oracles_ninelives_prices_2; Type: PUBLICATION TABLE; Schema: public; Owner: -
--

ALTER PUBLICATION websocket_publication ADD TABLE ONLY public.oracles_ninelives_prices_2;


--
-- PostgreSQL database dump complete
--

\unrestrict jaz2xk4yuhd95iVMg1oW0SXCwYUP38f3cFt9aKsSrEeoL6m7GqVQ05S3wrFurTg


--
-- Dbmate schema migrations
--

INSERT INTO public.accounts_migrations (version) VALUES
    ('1763933842'),
    ('1764744316'),
    ('1764821080'),
    ('1766122851'),
    ('1766490067'),
    ('1768798135'),
    ('1768801914'),
    ('1769697293'),
    ('1769697461'),
    ('1769706100');
