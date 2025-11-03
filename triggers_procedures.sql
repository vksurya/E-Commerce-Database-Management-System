USE ecommerce_db;

-- Trigger: After insert into order_items -> reduce stock and log
DELIMITER $$
CREATE TRIGGER trg_order_item_insert AFTER INSERT ON order_items
FOR EACH ROW
BEGIN
    UPDATE products SET stock_qty = stock_qty - NEW.quantity, updated_at = CURRENT_TIMESTAMP WHERE product_id = NEW.product_id;
    INSERT INTO inventory_transactions (product_id, change_qty, reason) VALUES (NEW.product_id, -NEW.quantity, CONCAT('order #', NEW.order_id));
END$$
DELIMITER ;

-- Trigger: After delete on order_items -> restore stock
DELIMITER $$
CREATE TRIGGER trg_order_item_delete AFTER DELETE ON order_items
FOR EACH ROW
BEGIN
    UPDATE products SET stock_qty = stock_qty + OLD.quantity, updated_at = CURRENT_TIMESTAMP WHERE product_id = OLD.product_id;
    INSERT INTO inventory_transactions (product_id, change_qty, reason) VALUES (OLD.product_id, OLD.quantity, CONCAT('order_item delete order #', OLD.order_id));
END$$
DELIMITER ;

-- Trigger: When order status updated to 'cancelled' or 'returned' -> restock
DELIMITER $$
CREATE TRIGGER trg_order_status_change AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
    IF NEW.order_status IN ('cancelled','returned') AND OLD.order_status <> NEW.order_status THEN
        INSERT INTO inventory_transactions (product_id, change_qty, reason)
        SELECT product_id, SUM(quantity) as change_qty, CONCAT('restock for order ', NEW.order_id) FROM order_items WHERE order_id = NEW.order_id GROUP BY product_id;
        UPDATE products p
        JOIN (SELECT product_id, SUM(quantity) AS qty FROM order_items WHERE order_id = NEW.order_id GROUP BY product_id) oi
        ON p.product_id = oi.product_id
        SET p.stock_qty = p.stock_qty + oi.qty, p.updated_at = CURRENT_TIMESTAMP;
    END IF;
END$$
DELIMITER ;

-- Stored Procedure: place_order_from_cart
DELIMITER $$
CREATE PROCEDURE place_order_from_cart (
    IN p_customer_id INT,
    IN p_address TEXT,
    IN p_payment_method VARCHAR(20),
    IN p_coupon_code VARCHAR(50)
)
BEGIN
    DECLARE v_cart_id BIGINT;
    DECLARE v_total DECIMAL(12,2);
    DECLARE finished INT DEFAULT 0;

    START TRANSACTION;

    SELECT cart_id INTO v_cart_id FROM carts WHERE customer_id = p_customer_id FOR UPDATE;
    IF v_cart_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No cart found for customer';
    END IF;

    SELECT COALESCE(SUM(p.price * ci.quantity * (1 - p.discount_percent/100)),0)
    INTO v_total
    FROM cart_items ci
    JOIN products p ON p.product_id = ci.product_id
    WHERE ci.cart_id = v_cart_id;

    IF v_total <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cart is empty or invalid';
    END IF;

    IF p_coupon_code IS NOT NULL AND p_coupon_code <> '' THEN
        DECLARE v_disc_type ENUM('percent','flat');
        DECLARE v_discount_value DECIMAL(10,2);
        DECLARE v_valid_from DATE;
        DECLARE v_valid_to DATE;
        DECLARE v_min_amount DECIMAL(12,2);
        DECLARE v_max_disc DECIMAL(12,2);

        SELECT discount_type, discount_value, valid_from, valid_to, min_order_amount, max_discount_amount
        INTO v_disc_type, v_discount_value, v_valid_from, v_valid_to, v_min_amount, v_max_disc
        FROM coupons WHERE code = p_coupon_code
        FOR UPDATE;

        IF v_valid_from IS NOT NULL THEN
            IF CURDATE() < v_valid_from OR CURDATE() > v_valid_to THEN
                SET v_disc_type = NULL;
            END IF;
        END IF;

        IF v_disc_type IS NOT NULL THEN
            IF v_total >= COALESCE(v_min_amount,0) THEN
                IF v_disc_type = 'percent' THEN
                    SET v_total = v_total - LEAST((v_total * v_discount_value / 100), COALESCE(v_max_disc, v_total));
                ELSE
                    SET v_total = GREATEST(0, v_total - v_discount_value);
                END IF;
            END IF;
        END IF;
    END IF;

    INSERT INTO orders (customer_id, order_status, total_amount, shipping_address, placed_at, payment_method, shipping_charge)
    VALUES (p_customer_id, 'placed', v_total, p_address, CURRENT_TIMESTAMP, p_payment_method, 0.00);

    DECLARE v_order_id BIGINT;
    SET v_order_id = LAST_INSERT_ID();

    INSERT INTO order_items (order_id, product_id, seller_id, unit_price, quantity, item_total)
    SELECT v_order_id, p.product_id, p.seller_id, p.price * (1 - p.discount_percent/100), ci.quantity, (p.price * (1 - p.discount_percent/100) * ci.quantity)
    FROM cart_items ci
    JOIN products p ON p.product_id = ci.product_id
    WHERE ci.cart_id = v_cart_id;

    UPDATE orders SET total_amount = (SELECT COALESCE(SUM(item_total),0) FROM order_items WHERE order_id = v_order_id) WHERE order_id = v_order_id;

    DELETE FROM cart_items WHERE cart_id = v_cart_id;

    COMMIT;

    SELECT v_order_id AS created_order_id;
END$$
DELIMITER ;

-- Stored Procedure: seller_add_product
DELIMITER $$
CREATE PROCEDURE seller_add_product (
    IN p_seller_id INT,
    IN p_category_id INT,
    IN p_name VARCHAR(200),
    IN p_desc TEXT,
    IN p_price DECIMAL(10,2),
    IN p_discount TINYINT,
    IN p_sku VARCHAR(100),
    IN p_initial_stock INT
)
BEGIN
    INSERT INTO products (seller_id, category_id, name, description, price, discount_percent, sku, stock_qty)
    VALUES (p_seller_id, p_category_id, p_name, p_desc, p_price, p_discount, p_sku, p_initial_stock);
    INSERT INTO inventory_transactions (product_id, change_qty, reason) VALUES (LAST_INSERT_ID(), p_initial_stock, 'initial stock via proc');
END$$
DELIMITER ;
