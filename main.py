import uuid
import random
from datetime import datetime, timedelta

import psycopg2
from psycopg2.extras import execute_values
from faker import Faker



HOST = 'localhost'
USER = 'postgres'
PASSWORD = '1218'
DATABASE = 'opt_db'
PORT = '5432'


CLIENTS_COUNT = 100_000
PRODUCTS_COUNT = 1_000
ORDERS_COUNT = 1_000_000
CHUNK_SIZE = 10_000

fake = Faker()


def insert_clients(cursor):
    print("Inserting into opt_clients...")

    client_insert_query = """
        INSERT INTO opt_clients
            (id, name, surname, email, phone, address, status)
        VALUES %s
    """

    client_ids = []

    for start in range(0, CLIENTS_COUNT, CHUNK_SIZE):
        current_chunk_size = min(CHUNK_SIZE, CLIENTS_COUNT - start)

        clients_data = []
        for _ in range(current_chunk_size):
            client_id = str(uuid.uuid4())
            client_ids.append(client_id)

            clients_data.append(
                (
                    client_id,
                    fake.first_name(),
                    fake.last_name(),
                    fake.email(),
                    fake.phone_number(),
                    fake.address().replace('\n', ' '),
                    random.choice(["active", "inactive"]),
                )
            )

        execute_values(cursor, client_insert_query, clients_data)
        print(f"Inserted {start + current_chunk_size} rows into opt_clients...")

    print("Inserted into opt_clients.")
    return client_ids


def insert_products(cursor):
    print("Inserting into opt_products...")

    product_insert_query = """
        INSERT INTO opt_products
            (product_name, product_category, description)
        VALUES %s
        RETURNING product_id
    """

    categories = ["Category1", "Category2", "Category3", "Category4", "Category5"]

    products_data = [
        (
            fake.word(),
            random.choice(categories),
            fake.text(max_nb_chars=150),
        )
        for _ in range(PRODUCTS_COUNT)
    ]


    product_ids_tuples = execute_values(cursor, product_insert_query, products_data, fetch=True)
    product_ids = [row[0] for row in product_ids_tuples]

    print("Inserted into opt_products.")
    return product_ids


def insert_orders(cursor, client_ids, product_ids):
    print("Inserting into opt_orders...")

    order_insert_query = """
        INSERT INTO opt_orders
            (order_date, client_id, product_id)
        VALUES %s
    """

    order_date_start = datetime.now() - timedelta(days=365 * 5)

    for start in range(0, ORDERS_COUNT, CHUNK_SIZE):
        current_chunk_size = min(CHUNK_SIZE, ORDERS_COUNT - start)

        orders_data = [
            (
                order_date_start + timedelta(seconds=random.randint(0, 365 * 5 * 24 * 3600)),
                random.choice(client_ids),
                random.choice(product_ids),
            )
            for _ in range(current_chunk_size)
        ]

        execute_values(cursor, order_insert_query, orders_data)
        print(f"Inserted {start + current_chunk_size} rows into opt_orders...")

    print("Inserted into opt_orders.")


def main():
    connection = psycopg2.connect(
        host=HOST,
        user=USER,
        password=PASSWORD,
        dbname=DATABASE,
        port=PORT,
    )

    try:
        with connection:
            with connection.cursor() as cursor:
                client_ids = insert_clients(cursor)
                product_ids = insert_products(cursor)
                insert_orders(cursor, client_ids, product_ids)
        print("\nУСПІХ! Всі дані згенеровано та залито в базу!")
    finally:
        connection.close()


if __name__ == "__main__":
    main()