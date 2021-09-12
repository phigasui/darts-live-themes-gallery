using SQLite

DB_FILE_NAME = "DartsLive.sqlite"

db = SQLite.DB(DB_FILE_NAME)

create_themes_table_query = """
CREATE TABLE themes (
    theme_id TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    url TEXT,
    image_file_name TEXT,
    price INTEGER
)
"""
SQLite.DBInterface.execute(db, create_themes_table_query)

create_users_table_query = """
CREATE TABLE users (
    user_id TEXT NOT NULL UNIQUE,
    themes_checked INTEGER NOT NULL DEFAULT 0,
    friends_checked INTEGER NOT NULL DEFAULT 0
)
"""
SQLite.DBInterface.execute(db, create_users_table_query)
