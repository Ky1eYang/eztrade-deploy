-- Initialize application schemas and extensions.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Ensure database is available for both star-platform and star-dashboard references.
-- POSTGRES_DB already creates `midplatform`; this file is for future idempotent init needs.
