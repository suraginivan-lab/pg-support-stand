CREATE SCHEMA IF NOT EXISTS shop;

CREATE TABLE shop.customers (
    customer_id bigserial PRIMARY KEY,
    email       text NOT NULL UNIQUE,
    full_name   text NOT NULL,
    created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE shop.orders (
    order_id    bigserial PRIMARY KEY,
    customer_id bigint NOT NULL REFERENCES shop.customers,
    status      text NOT NULL CHECK (status IN ('new','paid','shipped','cancelled')),
    amount      numeric(12,2) NOT NULL CHECK (amount >= 0),
    created_at  timestamptz NOT NULL DEFAULT now()
);
-- Намеренно НЕТ индекса по orders(customer_id) и orders(created_at):
-- это учебный сценарий "медленный запрос" (см. docs/incidents.md, инцидент 2).

CREATE TABLE shop.support_log (
    id         bigserial PRIMARY KEY,
    logged_at  timestamptz NOT NULL DEFAULT now(),
    author     text NOT NULL DEFAULT current_user,
    message    text NOT NULL
);
