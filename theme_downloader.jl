using DotEnv
using HTTP
using EzXML
using SQLite

DotEnv.config()

ID = ENV["ID"]
PASSWORD = ENV["PASSWORD"]
HOST = "https://card.dartslive.com"
USER_THEMES_URI = "/t/coinstore/theme/theme_favorite_opponent.jsp?card_id="
THEME_URI = "/t/coinstore/theme/theme_buy_confirm.jsp?set_id="
IMAGE_DIR = "images"
DB_FILE_NAME = "DartsLive.sqlite"

db = SQLite.DB(DB_FILE_NAME)

response = HTTP.request("POST", "$HOST/entry/login/doLogin.jsp", ["Content-Type" => "application/x-www-form-urlencoded"], "id=$ID&ps=$PASSWORD", cookies=true)

get_users_query = "SELECT user_id FROM users WHERE themes_checked = 0"
existing_check_query = "SELECT 1 FROM themes WHERE theme_id = ?"
insert_theme_query = "INSERT INTO themes (theme_id, name, url, image_file_name, price) VALUES(?, ?, ?, ?, ?)"
check_user_themes_query = "UPDATE users SET themes_checked = 1 WHERE user_id = ?"

for row in SQLite.DBInterface.execute(db, get_users_query)
    user_id = SQLite.Tables.getcolumn(row, 1)

    response = HTTP.request("GET", "$HOST$USER_THEMES_URI$user_id", cookies=true)
    doc = EzXML.parsehtml(response.body |> String)

    if findfirst("//div[@id='error']", doc.root) != nothing
        println(response.request)
        println("response error")
        break
    end

    for node in findall("//li[@class='player']/a", doc.root)
        theme_url = "$(HOST)/t/coinstore/theme/$(node["href"])"
        theme_id = match(r"set_id=(.*)&", theme_url)[1]

        (SQLite.DBInterface.execute(db, existing_check_query, [theme_id]) |> isempty) || continue

        image_path = findfirst("img", node)["src"]
        image_url = "$HOST$image_path"
        response = HTTP.request("GET", image_url, cookies=true)
        image_name = split(image_path, "/")[end]

        price = findfirst("div/div[@class='price']", node) |> nodecontent
        name = findfirst("div/div[@class='themeName']", node) |> nodecontent

        open("$IMAGE_DIR/$image_name", "w") do image_io
            write(image_io, response.body)
        end

        SQLite.DBInterface.execute(db, insert_theme_query, [theme_id, name, theme_url, image_name, price])

        println("$theme_id,$name")
    end

    SQLite.DBInterface.execute(db, check_user_themes_query, [user_id])
    sleep(1)
end
