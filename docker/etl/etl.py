import pandas as pd
import psycopg2
from pymongo import MongoClient
import time

# Attendre que les bases soient prêtes
time.sleep(5)

# --- Données fictives ---
data = {
    "order_id": range(1, 11),
    "product": ["Laptop", "Phone", "Tablet", "Monitor", "Keyboard",
                 "Mouse", "Headset", "Webcam", "Desk", "Chair"],
    "amount": [1200, 800, 450, 300, 80, 40, 150, 90, 350, 500],
    "city": ["Abidjan", "Dakar", "Accra", "Lagos", "Abidjan",
              "Dakar", "Abidjan", "Accra", "Lagos", "Abidjan"]
}
df = pd.DataFrame(data)

# --- PostgreSQL ---
conn = psycopg2.connect(
    host="postgres",
    database="mohdatashop",
    user="postgres",
    password="mohdata123"
)
cur = conn.cursor()
cur.execute("""
    CREATE TABLE IF NOT EXISTS orders (
        order_id INT PRIMARY KEY,
        product VARCHAR(100),
        amount NUMERIC,
        city VARCHAR(50)
    )
""")
for _, row in df.iterrows():
    cur.execute(
        "INSERT INTO orders VALUES (%s, %s, %s, %s) ON CONFLICT DO NOTHING",
        tuple(row)
    )
conn.commit()
cur.close()
conn.close()
print(f"PostgreSQL : {len(df)} commandes insérées")

# --- MongoDB ---
client = MongoClient("mongodb://mongodb:27017/")
db = client["mohdatashop"]
col = db["orders"]
col.delete_many({})
col.insert_many(df.to_dict("records"))
print(f"MongoDB    : {len(df)} commandes insérées")
