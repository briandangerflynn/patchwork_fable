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
    email VARCHAR(255)
  )"
)
# end


# table for stories
conn.exec("DROP TABLE IF EXISTS fable CASCADE")

conn.exec("CREATE TABLE fable(
    id SERIAL PRIMARY KEY,
    title VARCHAR(255),
    user_id INTEGER REFERENCES user_info(id)
  )"
)
# end

# table for posts within stories
conn.exec("DROP TABLE IF EXISTS posts CASCADE")

conn.exec("CREATE TABLE posts(
    id SERIAL PRIMARY KEY,
    message TEXT NOT NULL,
    user_id INTEGER REFERENCES user_info(id),
    fable_id INTEGER REFERENCES fable(id)
  )"
)
# end

# creates fake data for production testing
conn.exec("INSERT INTO user_info (username, email) VALUES (
    'Brian',
    'bdflynny@gmail.com'
  )"
)

conn.exec("INSERT INTO fable (title, user_id) VALUES (
    'Dragon Story',
    1
  )"
)

conn.exec("INSERT INTO posts (message, user_id, fable_id) VALUES (
    'Once upon a time, there was a lazy dragon...',
    1,
    1
  ),(
    'that dragon liked to eat ramen noodles until he fell asleep!',
    1,
    1
  )"
)


