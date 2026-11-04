from flask import Flask
import os
import psycopg2

app = Flask(__name__)

DB_HOST = os.getenv("DB_HOST", "localhost")
DB_NAME = os.getenv("POSTGRES_DB", "appdb")
DB_USER = os.getenv("POSTGRES_USER", "appuser")
DB_PASSWORD = os.getenv("POSTGRES_PASSWORD", "password")

@app.route("/health")
def health():
    return "OK", 200

@app.route("/")
def index():
    conn = psycopg2.connect(
        host=DB_HOST,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD
    )

    cur = conn.cursor()

    cur.execute("""
        CREATE TABLE IF NOT EXISTS counter (
            id INTEGER PRIMARY KEY,
            value INTEGER NOT NULL
        )
    """)

    cur.execute("""
        INSERT INTO counter (id, value)
        VALUES (1, 0)
        ON CONFLICT (id) DO NOTHING
    """)

    cur.execute("""
        UPDATE counter
        SET value = value + 1
        WHERE id = 1
        RETURNING value
    """)

    value = cur.fetchone()[0]

    conn.commit()
    cur.close()
    conn.close()

    return f"Counter: {value}\n"
