#!/bin/sh -e

table="accounts_migrations"

dbmate -d migrations --migrations-table "$table" -u "$1" up
