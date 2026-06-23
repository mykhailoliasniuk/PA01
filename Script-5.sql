DROP TABLE IF EXISTS opt_orders;
DROP TABLE IF EXISTS opt_products;
DROP TABLE IF EXISTS opt_clients;

CREATE TABLE opt_clients (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    surname VARCHAR(100) NOT NULL,
    email VARCHAR(150),
    phone VARCHAR(50),
    address TEXT,
    status VARCHAR(20) NOT NULL
);

CREATE TABLE opt_products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(150) NOT NULL,
    product_category VARCHAR(100) NOT NULL,
    description TEXT
);

CREATE TABLE opt_orders (
    order_id SERIAL PRIMARY KEY,
    order_date TIMESTAMP NOT NULL,
    client_id VARCHAR(50) NOT NULL,
    product_id INT NOT NULL,
    FOREIGN KEY (client_id) REFERENCES opt_clients(id),
    FOREIGN KEY (product_id) REFERENCES opt_products(product_id)
);


EXPLAIN ANALYZE
select 
    c.id as client_id,
    c.name,
    c.surname,
    p.product_category,
    count(o.order_id) as category_orders_count
from opt_orders o
join opt_clients c on o.client_id = c.id
join opt_products p on o.product_id = p.product_id
where c.status = 'active' 
  and p.product_category = 'Category1'
group by c.id, c.name, c.surname, p.product_category
having count(o.order_id) > (
    select avg(sub_cnt)
    from (
        select count(o2.order_id) as sub_cnt
        from opt_orders o2
        join opt_products p2 on o2.product_id = p2.product_id
        where o2.client_id = c.id
        group by p2.product_category
    ) sub
)
order by category_orders_count desc
limit 100;

create index idx_orders_client_id on opt_orders(client_id);

create index idx_orders_product_id on opt_orders(product_id);

create index idx_clients_status on opt_clients(status) where status = 'active';

EXPLAIN ANALYZE
with client_category_stats as (
    select 
        o.client_id,
        p.product_category,
        count(o.order_id) as category_orders_count
    from opt_orders o
    join opt_products p on o.product_id = p.product_id
    group by o.client_id, p.product_category
),
client_averages as (
    select 
        client_id,
        product_category,
        category_orders_count,
        avg(category_orders_count) over(partition by client_id) as avg_orders_per_category
    from client_category_stats
)
select 
    c.id as client_id,
    c.name,
    c.surname,
    ca.product_category,
    ca.category_orders_count
from client_averages ca
join opt_clients c on ca.client_id = c.id
where c.status = 'active'
  and ca.product_category = 'Category1'
  and ca.category_orders_count > ca.avg_orders_per_category
order by ca.category_orders_count desc
limit 100;
