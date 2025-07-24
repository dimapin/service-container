-- Insert test data for MySQL
USE app_db;

-- Insert test users
INSERT IGNORE INTO users (username, email) VALUES
    ('admin', 'admin@example.com'),
    ('testuser1', 'user1@example.com'),
    ('testuser2', 'user2@example.com'),
    ('testuser3', 'user3@example.com'),
    ('demouser', 'demo@example.com');

-- Insert test posts
INSERT IGNORE INTO posts (user_id, title, content) VALUES
    (1, 'Welcome to MySQL Testing', 'This is a test post to verify MySQL functionality.'),
    (2, 'Database Performance', 'Testing database performance with sample data.'),
    (3, 'Docker Services', 'All services are running in Docker containers.'),
    (1, 'Monitoring Setup', 'Prometheus and Grafana are configured for monitoring.'),
    (4, 'High Availability', 'Redis Sentinel provides high availability for cache.');

-- Insert test comments
INSERT IGNORE INTO comments (post_id, user_id, content) VALUES
    (1, 2, 'Great setup! MySQL is working perfectly.'),
    (1, 3, 'Thanks for the detailed testing.'),
    (2, 1, 'Performance looks good so far.'),
    (3, 4, 'Docker makes deployment much easier.'),
    (4, 5, 'Monitoring dashboard is very helpful.'),
    (5, 2, 'HA setup is crucial for production.');

-- Insert performance test data
INSERT INTO performance_test (random_data) VALUES
    (UUID()),
    (UUID()),
    (UUID()),
    (UUID()),
    (UUID());

-- Create a stored procedure for testing
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS GetUserPostCount(IN user_id_param INT, OUT post_count INT)
BEGIN
    SELECT COUNT(*) INTO post_count FROM posts WHERE user_id = user_id_param;
END //
DELIMITER ;

-- Create a view for testing
CREATE OR REPLACE VIEW user_post_summary AS
SELECT 
    u.id,
    u.username,
    u.email,
    COUNT(DISTINCT p.id) as post_count,
    COUNT(DISTINCT c.id) as comment_count
FROM users u
LEFT JOIN posts p ON u.id = p.user_id
LEFT JOIN comments c ON u.id = c.user_id
GROUP BY u.id, u.username, u.email;
