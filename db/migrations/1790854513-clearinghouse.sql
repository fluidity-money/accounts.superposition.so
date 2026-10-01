-- migrate:up

CREATE TABLE accounts_clearinghouse_assets_1 (
	id SERIAL PRIMARY KEY,
	created_by TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	asset ADDRESS NOT NULL UNIQUE,
	fee INTEGER NOT NULL,
	tick_spacing INTEGER NOT NULL
);

-- migrate:down
