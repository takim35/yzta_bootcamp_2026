import sqlite3

def alter_db():
    conn = sqlite3.connect('socialMedia_backend/dijital_gardrop.db')
    try:
        conn.execute("ALTER TABLE users ADD COLUMN profile_visibility TEXT NOT NULL DEFAULT 'public';")
        conn.commit()
        print("Column added successfully.")
    except sqlite3.OperationalError as e:
        print("Error or already added:", e)
    finally:
        conn.close()

if __name__ == '__main__':
    alter_db()
