using DotEnv
using HTTP
using EzXML
using SQLite

DotEnv.config()

ID = ENV["ID"]
PASSWORD = ENV["PASSWORD"]
HOST = "https://card.dartslive.com"
DB_FILE_NAME = "DartsLive.sqlite"
USER_FRIENDS_URI = "/t/profile/friendList.jsp?u="

db = SQLite.DB(DB_FILE_NAME)

response = HTTP.request("POST", "$HOST/entry/login/doLogin.jsp", ["Content-Type" => "application/x-www-form-urlencoded"], "id=$ID&ps=$PASSWORD", cookies=true)

# Check Ranking
insert_user_query = "INSERT INTO users (user_id) VALUES (?)"
existing_check_query = "SELECT 1 FROM users WHERE user_id = ?"

response = HTTP.request("GET", "$HOST/t/ranking/index.jsp", cookies=true)
doc = EzXML.parsehtml(response.body |> String)
user_ids = findall("//li[contains(@class, 'player')]/a", doc.root) .|> node->split(node["href"], "u=")[end]

for user_id in user_ids
    (SQLite.DBInterface.execute(db, existing_check_query, [user_id]) |> isempty) || continue

    SQLite.DBInterface.execute(db, insert_user_query, [user_id])
end

get_users_query = "SELECT user_id FROM users WHERE friends_checked = 0"
check_user_friends_query = "UPDATE users SET friends_checked = 1 WHERE user_id = ?"

# Scrape friends
for row in SQLite.DBInterface.execute(db, get_users_query)
    user_id = SQLite.Tables.getcolumn(row, 1)

    response = HTTP.request("GET", "$HOST$USER_FRIENDS_URI$user_id", cookies=true)
    doc = EzXML.parsehtml(response.body |> String)

    if findfirst("//div[@id='error']", doc.root) != nothing
        println(response.request)
        println("response error")
        break
    end

    for node in findall("//li[@class='player']/a", doc.root)
        user_id = match(r"u=(.*)", node["href"])[1]

        (SQLite.DBInterface.execute(db, existing_check_query, [user_id]) |> isempty) || continue

        SQLite.DBInterface.execute(db, insert_user_query, [user_id])
        println("$user_id")
    end

    SQLite.DBInterface.execute(db, check_user_friends_query, [user_id])
    sleep(1)
end
