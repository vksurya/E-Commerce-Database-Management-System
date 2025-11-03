USE ecommerce_db;

-- Users: two sellers, two customers, one admin
INSERT INTO users (user_type, username, email, password_hash, phone, address, city, state)
VALUES
('seller','seller_agra','seller1@example.com','hashed_pwd_1','+911234567890','Shop A, Agra','Agra','Uttar Pradesh'),
('seller','seller_tn','seller2@example.com','hashed_pwd_2','+919876543210','Shop B, Chennai','Chennai','Tamil Nadu'),
('customer','alice','alice@example.com','hashed_pwd_3','+919999111222','Flat 5, ABC','Madras','Tamil Nadu'),
('customer','bob','bob@example.com','hashed_pwd_4','+919888222333','House 12','Agra','Uttar Pradesh'),
('admin','admin','admin@example.com','hashed_admin','+910000000000','HQ','Chennai','Tamil Nadu');

-- sample categories
INSERT INTO categories (name, parent_id, description) VALUES
('Electronics', NULL, 'Electronic goods'),
('Mobiles', 1, 'Smartphones and accessories'),
('Home & Kitchen', NULL, 'Household items'),
('Clothing', NULL, 'Apparel');

-- products
INSERT INTO products (seller_id, category_id, name, description, price, discount_percent, sku, stock_qty)
VALUES
(1, 2, 'Android Phone Model A', '4GB RAM, 64GB storage', 9999.00, 10, 'SKU-A001', 50),
(1, 3, 'Stainless Steel Pan 24cm', 'Non-stick', 899.00, 0, 'SKU-PAN24', 120),
(2, 4, 'Men Cotton T-Shirt', 'Size M/L/XL', 399.00, 20, 'SKU-TSHIRT-M01', 200);

-- product images
INSERT INTO product_images (product_id, url, alt_text, is_primary)
VALUES
(1,'/images/phone_a.jpg','Android Phone A',TRUE),
(2,'/images/pan_24.jpg','Stainless Steel Pan',TRUE),
(3,'/images/tshirt_m.jpg','Men Cotton T-Shirt',TRUE);

-- create carts for customers
INSERT INTO carts (customer_id) VALUES (3),(4);

-- add cart items
INSERT INTO cart_items (cart_id, product_id, quantity)
VALUES
(1,1,1),
(1,3,2),
(2,2,1);

-- sample coupons
INSERT INTO coupons (code, description, discount_type, discount_value, valid_from, valid_to, min_order_amount, max_discount_amount, usage_limit)
VALUES
('WELCOME50','50 off up to 50','flat',50.00,'2025-01-01','2026-12-31',0,50.00,1),
('SAVE10','10% off','percent',10.00,'2025-01-01','2026-12-31',500,300,100);

-- sample inventory transactions (initial stock)
INSERT INTO inventory_transactions (product_id, change_qty, reason) VALUES
(1,50,'initial stock'),
(2,120,'initial stock'),
(3,200,'initial stock');
