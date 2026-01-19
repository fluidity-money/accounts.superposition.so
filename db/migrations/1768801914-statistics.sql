-- migrate:up

CREATE VIEW accounts_transaction_statistics_1 AS
	SELECT
		desc_ AS action,
		AVG(CASE WHEN created_at >= NOW() - INTERVAL '24 hours' THEN gas_limit END) AS avg_gas_limit_24_hours,
		AVG(CASE WHEN created_at >= NOW() - INTERVAL '7 days' THEN gas_limit END) AS avg_gas_limit_week,
		AVG(gas_limit) AS avg_gas_limit_all_time,
		COUNT(CASE WHEN created_at >= NOW() - INTERVAL '24 hours' THEN 1 END)::INT AS tx_24_hours,
		COUNT(CASE WHEN created_at >= NOW() - INTERVAL '7 days' THEN 1 END)::INT AS tx_week,
		COUNT(*)::INT AS tx_all_time
	FROM accounts_executed_transactions_2
	GROUP BY desc_;

-- migrate:down
