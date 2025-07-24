-- Insert test data for PostgreSQL
\c app_db;

-- Insert test users
INSERT INTO app_schema.users (username, email) VALUES
    ('admin', 'admin@example.com'),
    ('testuser1', 'user1@example.com'),
    ('testuser2', 'user2@example.com'),
    ('testuser3', 'user3@example.com'),
    ('demouser', 'demo@example.com')
ON CONFLICT (username) DO NOTHING;

-- Insert test posts
INSERT INTO app_schema.posts (user_id, title, content) VALUES
    (1, 'Welcome to PostgreSQL Testing', 'This is a test post to verify PostgreSQL functionality.'),
    (2, 'Database Performance', 'Testing database performance with sample data.'),
    (3, 'Docker Services', 'All services are running in Docker containers.'),
    (1, 'Monitoring Setup', 'Prometheus and Grafana are configured for monitoring.'),
    (4, 'High Availability', 'Redis Sentinel provides high availability for cache.')
ON CONFLICT DO NOTHING;

-- Insert test comments
INSERT INTO app_schema.comments (post_id, user_id, content) VALUES
    (1, 2, 'Great setup! PostgreSQL is working perfectly.'),
    (1, 3, 'Thanks for the detailed testing.'),
    (2, 1, 'Performance looks good so far.'),
    (3, 4, 'Docker makes deployment much easier.'),
    (4, 5, 'Monitoring dashboard is very helpful.'),
    (5, 2, 'HA setup is crucial for production.')
ON CONFLICT DO NOTHING;

-- Create a function for testing
CREATE OR REPLACE FUNCTION app_schema.get_user_post_count(user_id_param INTEGER)
RETURNS INTEGER AS $$
BEGIN
    RETURN (SELECT COUNT(*) FROM app_schema.posts WHERE user_id = user_id_param);
END;
$$ LANGUAGE plpgsql;

-- Create a view for testing
CREATE OR REPLACE VIEW app_schema.user_post_summary AS
SELECT 
    u.id,
    u.username,
    u.email,
    COUNT(p.id) as post_count,
    COUNT(c.id) as comment_count
FROM app_schema.users u
LEFT JOIN app_schema.posts p ON u.id = p.user_id
LEFT JOIN app_schema.comments c ON u.id = c.user_id
GROUP BY u.id, u.username, u.email;

-- Grant permissions on function and view
GRANT EXECUTE ON FUNCTION app_schema.get_user_post_count TO app_user;
GRANT SELECT ON app_schema.user_post_summary TO app_user;
