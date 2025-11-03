USE ecommerce_db;

-- Views
CREATE OR REPLACE VIEW vw_top_sold_products AS
SELECT p.product_id, p.name, SUM(oi.quantity) AS total_sold, SUM(oi.item_total) AS revenue
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
GROUP BY p.product_id, p.name
ORDER BY total_sold DESC;

CREATE OR REPLACE VIEW vw_seller_sales AS
SELECT u.user_id AS seller_id, u.username AS seller_name,
       COUNT(DISTINCT o.order_id) AS num_orders,
       SUM(oi.quantity) AS total_items_sold,
       SUM(oi.item_total) AS total_revenue
FROM users u
LEFT JOIN order_items oi ON u.user_id = oi.seller_id
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE u.user_type = 'seller'
GROUP BY u.user_id, u.username;

-- Example queries
-- Top 5 selling products
SELECT * FROM vw_top_sold_products LIMIT 5;

-- Sellers ranked by revenue
SELECT * FROM vw_seller_sales ORDER BY total_revenue DESC;

-- Products low in stock
SELECT product_id, name, stock_qty FROM products WHERE stock_qty <= 10;

-- Monthly revenue trend
SELECT DATE_FORMAT(placed_at,'%Y-%m') AS month, SUM(total_amount) AS revenue
FROM orders
GROUP BY month
ORDER BY month;
