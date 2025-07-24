CREATE TABLE test_init (
    id SERIAL PRIMARY KEY,
    message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO test_init (message) VALUES ('PostgreSQL initialization test');
