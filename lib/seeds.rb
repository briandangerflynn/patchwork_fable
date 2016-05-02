require 'pg'

if ENV["RACK_ENV"] == "production"
    conn = PG.connect(
        dbname: ENV["POSTGRES_DB"],
        host: ENV["POSTGRES_HOST"],
        password: ENV["POSTGRES_PASS"],
        user: ENV["POSTGRES_USER"]
     )
else
    conn = PG.connect(dbname: "patchwork")
end


# table for users
conn.exec("DROP TABLE IF EXISTS user_info CASCADE")

conn.exec("CREATE TABLE user_info(
    id SERIAL PRIMARY KEY,
    username VARCHAR(255),
    password VARCHAR(255),
    email VARCHAR(255)
  )"
)
# end


# table for stories
conn.exec("DROP TABLE IF EXISTS fable CASCADE")

conn.exec("CREATE TABLE fable(
    id SERIAL PRIMARY KEY,
    title VARCHAR(255),
    author VARCHAR(255),
    description TEXT NOT NULL
  )"
)
# end

# table for posts within stories
conn.exec("DROP TABLE IF EXISTS posts CASCADE")

conn.exec("CREATE TABLE posts(
    id SERIAL PRIMARY KEY,
    author VARCHAR(255),
    message TEXT NOT NULL,
    fable_id INTEGER REFERENCES fable(id)
  )"
)
# end

# creates fake data for production testing
conn.exec("INSERT INTO user_info (username, password, email) VALUES (
    'Brian',
    'password',
    'bdflynny@gmail.com'
  )"
)

conn.exec("INSERT INTO fable (title, author, description) VALUES (
    'Dragon Story',
    'Brian',
    'A story about a fat dragon'
  )"
)

conn.exec("INSERT INTO posts (author, message, fable_id) VALUES (
    'Brian',
    'Once upon a time, there was a lazy dragon...',
    1
  ),(
    'Brian',
    'that dragon liked to eat ramen noodles until he fell asleep!',
    1
  )"
)


