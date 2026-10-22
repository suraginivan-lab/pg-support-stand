INSERT INTO shop.customers (email, full_name)
SELECT 'user' || g || '@example.com', 'Клиент ' || g
FROM generate_series(1, 5000) g;

INSERT INTO shop.orders (customer_id, status, amount, created_at)
SELECT 1 + (random() * 4999)::int,
       (ARRAY['new','paid','shipped','cancelled'])[1 + (random()*3)::int],
       round((random() * 10000)::numeric, 2),
       now() - (random() * interval '365 days')
FROM generate_series(1, 200000);

ANALYZE shop.customers;
ANALYZE shop.orders;
