-- PostgreSQL initialization script
-- Create application schema and test data

-- Create application user if not exists
DO
$do$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles
      WHERE  rolname = 'app_user') THEN
      CREATE ROLE app_user LOGIN PASSWORD 'app_pass';
   END IF;
END
$do$;

-- Create application database if not exists
SELECT 'CREATE DATABASE app_db OWNER app_user'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'app_db')\gexec

-- Connect to app_db for further setup
\c app_db;

-- Create schema
CREATE SCHEMA IF NOT EXISTS app_schema AUTHORIZATION app_user;

-- Set search path
ALTER ROLE app_user SET search_path TO app_schema, public;

-- Grant permissions
GRANT ALL PRIVILEGES ON SCHEMA app_schema TO app_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA app_schema TO app_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA app_schema TO app_user;

-- Create test tables
CREATE TABLE IF NOT EXISTS app_schema.users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS app_schema.posts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES app_schema.users(id),
    title VARCHAR(200) NOT NULL,
    content TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS app_schema.comments (
    id SERIAL PRIMARY KEY,
    post_id INTEGER REFERENCES app_schema.posts(id),
    user_id INTEGER REFERENCES app_schema.users(id),
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_users_username ON app_schema.users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON app_schema.users(email);
CREATE INDEX IF NOT EXISTS idx_posts_user_id ON app_schema.posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON app_schema.posts(created_at);
CREATE INDEX IF NOT EXISTS idx_comments_post_id ON app_schema.comments(post_id);
CREATE INDEX IF NOT EXISTS idx_comments_user_id ON app_schema.comments(user_id);

-- Grant permissions on new tables
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA app_schema TO app_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA app_schema TO app_user;
