using DotEnv
using HTTP
using EzXML
using SQLite

ID = ENV["ID"]
PASSWORD = ENV["PASSWORD"]
HOST = "https://card.dartslive.com"
USER_THEMES_URI = "/t/coinstore/theme/theme_favorite_opponent.jsp?card_id="
THEME_URI = "/t/coinstore/theme/theme_buy_confirm.jsp?set_id="
IMAGE_DIR = "images"

response = HTTP.request("POST", "https://card.dartslive.com/entry/login/doLogin.jsp", ["Content-Type" => "application/x-www-form-urlencoded"], "id=$ID&ps=$PASSWORD", cookies=true)
response = HTTP.request("GET", "https://card.dartslive.com/t/ranking/index.jsp", cookies=true)
doc = EzXML.parsehtml(response.body |> String)
user_ids = findall("//li[contains(@class, 'player')]/a", doc.root) .|> node->split(node["href"], "u=")[end]

open("themes.csv", "a") do theme_io
    for user_id in user_ids
        response = HTTP.request("GET", "$HOST$USER_THEMES_URI$user_id", cookies=true)

        doc = EzXML.parsehtml(response.body |> String)

        for node in findall("//li[@class='player']/a", doc.root)
            theme_url = "$(HOST)/t/coinstore/theme/$(node["href"])"
            theme_id = match(r"set_id=(.*)&", theme_url)[1]
            image_path = findfirst("img", node)["src"]
            image_url = "$HOST$image_path"
            response = HTTP.request("GET", image_url, cookies=true)
            image_name = split(image_path, "/")[end]

            price = findfirst("div/div[@class='price']", node) |> nodecontent
            name = findfirst("div/div[@class='themeName']", node) |> nodecontent

            open("$IMAGE_DIR/$image_name", "w") do image_io
                write(image_io, response.body)
            end

            write(theme_io, "$theme_id,$name,$theme_url,$image_name,$price\n")
            println("$theme_id,$name")
        end

        sleep(1)
    end
end


# https://card.dartslive.com/t/coinstore/theme/theme_favorite_opponent.jsp?card_id=1125788826286256

db = SQLite.DB("DartsLive.sqlite")

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
