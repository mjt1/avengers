-- USER TESTING QUERIES - STUDENT 3 IMPLEMENTATION
-- Contains all user management, test data, and queries in one file

/*********************
 SECTION 1: USER MANAGEMENT
*********************/

-- 1.1 User Roles Creation
CREATE USER 'bookstore_admin'@'localhost' IDENTIFIED BY 'Admin@1234';
GRANT ALL PRIVILEGES ON bookstore.* TO 'bookstore_admin'@'localhost';

CREATE USER 'bookstore_app'@'localhost' IDENTIFIED BY 'App@5678';
GRANT SELECT, INSERT, UPDATE, DELETE ON bookstore.* TO 'bookstore_app'@'localhost';

CREATE USER 'bookstore_report'@'localhost' IDENTIFIED BY 'Report@9101';
GRANT SELECT ON bookstore.* TO 'bookstore_report'@'localhost';

CREATE USER 'bookstore_cs'@'localhost' IDENTIFIED BY 'CS@1121';
GRANT SELECT ON bookstore.customer TO 'bookstore_cs'@'localhost';
GRANT SELECT ON bookstore.address TO 'bookstore_cs'@'localhost';
GRANT SELECT ON bookstore.cust_order TO 'bookstore_cs'@'localhost';
GRANT SELECT ON bookstore.order_history TO 'bookstore_cs'@'localhost';

FLUSH PRIVILEGES;

-- 1.2 Permission Verification
-- (Run these after connecting as each user)
-- Admin test: SELECT * FROM mysql.user;
-- CS test: Try DELETE FROM customer; (should fail)

/*********************
 SECTION 2: TEST DATA
*********************/

-- 2.1 Core Test Data
INSERT INTO order_status (status_id, status_value) VALUES
(1, 'Pending Payment'), (2, 'Processing'), (3, 'Shipped'),
(4, 'Delivered'), (5, 'Cancelled'), (6, 'Returned');

INSERT INTO customer (first_name, last_name, email) VALUES
('John', 'Mnyika', 'jmnyika514@gmail.com'),
('Ryan', 'Kemboi', 'ryankicho@gmail.com'),
('Mercylyne', 'Tuwei', 'mercylynetuwei@gmail.com');

INSERT INTO cust_order (order_date, customer_id, shipping_method_id, dest_address_id) VALUES
(NOW() - INTERVAL 5 DAY, 1, 1, 1),
(NOW() - INTERVAL 3 DAY, 2, 2, 2);

INSERT INTO order_line (order_id, book_id, price) VALUES
(1, 1, 19.99), (1, 2, 24.99), (2, 3, 14.99);

INSERT INTO order_history (order_id, status_id, status_date) VALUES
(1, 1, NOW() - INTERVAL 5 DAY), (1, 2, NOW() - INTERVAL 4 DAY),
(2, 1, NOW() - INTERVAL 3 DAY), (2, 2, NOW() - INTERVAL 2 DAY);

-- 2.2 Edge Cases
INSERT INTO cust_order (order_date, customer_id, shipping_method_id, dest_address_id) 
VALUES (NOW(), 1, 1, 1); -- Empty order

INSERT INTO order_line (order_id, book_id, price) VALUES
(3, 1, 19.99), (3, 1, 19.99); -- Duplicate items

/*********************
 SECTION 3: TEST QUERIES
*********************/

-- 3.1 Order Status Query
SELECT o.order_id, c.first_name, c.last_name, 
       os.status_value AS current_status,
       MAX(oh.status_date) AS last_update
FROM cust_order o
JOIN customer c ON o.customer_id = c.customer_id
JOIN order_history oh ON o.order_id = oh.order_id
JOIN order_status os ON oh.status_id = os.status_id
WHERE oh.status_date = (
    SELECT MAX(status_date) 
    FROM order_history 
    WHERE order_id = o.order_id
)
GROUP BY o.order_id, c.first_name, c.last_name, os.status_value;

-- 3.2 Order Value Analysis
SELECT o.order_id, COUNT(ol.book_id) AS item_count,
       SUM(ol.price) AS total_value
FROM cust_order o
JOIN order_line ol ON o.order_id = ol.order_id
GROUP BY o.order_id;

/*********************
 SECTION 4: PERFORMANCE OPTIMIZATION
*********************/

-- 4.1 Index Creation
CREATE INDEX idx_order_history_order_id ON order_history(order_id);
CREATE INDEX idx_order_history_status_date ON order_history(status_date);

-- 4.2 Query Explanation
EXPLAIN SELECT * FROM order_history WHERE order_id = 1;

/*********************
 SECTION 5: TEST CASES (SQL COMMENTS)
*********************/

/*
TEST CASE 1: User Permissions Verification
- Connect as bookstore_cs
- Try SELECT on customer table (should work)
- Try DELETE on customer table (should fail)

TEST CASE 2: Order Status Flow
- New order should start as 'Pending Payment'
- Status should progress sequentially
- Cannot skip statuses

TEST CASE 3: Order Value Calculation
- Order with items $10 + $20 should total $30
- Empty order should show $0 total
*/