-- Create database if not exists
SELECT 'CREATE DATABASE cine_vision' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'cine_vision')\gexec

-- Connect to cine_vision database
\c cine_vision

-- Grant privileges to postgres user
GRANT ALL PRIVILEGES ON DATABASE cine_vision TO postgres;
GRANT ALL ON SCHEMA public TO postgres;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO postgres;

-- Create extension if needed
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
