using SQLite

DB_FILE_NAME = "DartsLive.sqlite"

db = SQLite.DB(DB_FILE_NAME)

get_themes_query = "SELECT * FROM themes"

open("view.html", "w") do io
    write(io, "<table>")

    for row in SQLite.DBInterface.execute(db, get_themes_query)
        table_row = """
            <tr>
            <td><img src="images/$(row[4])"/></td>
            <td>$(row[2])</td>
            <td><a href="$(row[3])">$(row[3])</a></td>
            <td>$(row[5])</td>
            </tr>
        """
        write(io, table_row)
    end

    write(io, "</table>")
end
