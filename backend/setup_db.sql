-- Create database
CREATE DATABASE dental_case_db;

-- Create user
CREATE USER dental_user WITH PASSWORD 'dental_password';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE dental_case_db TO dental_user;

-- Connect to the new database
\c dental_case_db

-- Grant schema privileges
GRANT ALL ON SCHEMA public TO dental_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO dental_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO dental_user;

-- Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO dental_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO dental_user; 