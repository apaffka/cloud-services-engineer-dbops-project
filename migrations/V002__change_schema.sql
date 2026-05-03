-- 1. Добавляем цену товара в product
ALTER TABLE product
ADD COLUMN price DOUBLE PRECISION;

-- 2. Переносим данные о цене из product_info в product
UPDATE product p
SET price = pi.price
FROM product_info pi
WHERE p.id = pi.product_id;

-- 3. Добавляем дату создания заказа в orders
ALTER TABLE orders
ADD COLUMN date_created DATE DEFAULT CURRENT_DATE;

-- 4. Переносим дату создания из orders_date в orders
UPDATE orders o
SET date_created = od.date_created
FROM orders_date od
WHERE o.id = od.order_id;

-- 5. Добавляем первичные ключи
ALTER TABLE product
ADD CONSTRAINT pk_product PRIMARY KEY (id);

ALTER TABLE orders
ADD CONSTRAINT pk_orders PRIMARY KEY (id);

-- 6. Добавляем внешние ключи для order_product
ALTER TABLE order_product
ADD CONSTRAINT fk_order_product_order
FOREIGN KEY (order_id)
REFERENCES orders(id);

ALTER TABLE order_product
ADD CONSTRAINT fk_order_product_product
FOREIGN KEY (product_id)
REFERENCES product(id);

-- 7. Удаляем неиспользуемые
DROP TABLE product_info;

DROP TABLE orders_date;
