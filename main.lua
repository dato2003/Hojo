local discordia = require("discordia")
local sql = require("sqlite3")
local Client = discordia.Client()

local db = sql.open("Emoji.db")
local SQLCOMMAND
Client:on("ready", function()
    print("Logged in As : " .. Client.user.username)

    local ServerArray = {}
    for k, v in pairs(Client.guilds) do
        table.insert(ServerArray,k)
        SQLCOMMAND = "CREATE TABLE IF NOT EXISTS '" .. k .. "' (Word TEXT, Emoji TEXT)"
        db:exec(SQLCOMMAND)
    end  
    
end)

Client:on("messageCreate", function(message)
    if(string.lower(string.sub(message.content,1,9)) == "&addemoji") then
        local index,_ = string.find(message.content,"|")
        local Word = string.sub(message.content,11,index-1)
        local Emoji = string.sub(message.content,index+1,#message.content)
        local Symbol1,Symbol2
        local Acceptable = 0
        Symbol1 = string.find(Emoji,"'")
        Symbol2 = string.find(Emoji,"\"")
        if(Symbol1 == nil and Symbol2 == nil) then Acceptable = 1 end
        --print(Word)
        local WordList = {}
        local WordIsUsed = 0
        if(Word ~= "&addemoji" and Emoji ~= "&addemoji" and Acceptable == 1 and Word ~= "&help" and Emoji ~= "&help") then
            SQLCOMMAND = "SELECT Word from '" .. message.channel.guild.id .. "'"
            local Rows,errorString = db:exec(SQLCOMMAND)
            if(errorString == 0) then
                SQLCOMMAND = "INSERT into '" .. message.channel.guild.id .. "' (Word,Emoji) values('" .. Word .. "','" .. Emoji .. "');"
                --print(SQLCOMMAND)
                db:exec(SQLCOMMAND)
                message.channel:send("Emoji Added")
                message.author:send("**WORD** : " .. Word .. "\n" .. Emoji)
                message:delete()
            else
                for i,j in pairs(Rows) do
                    if(i == "Word") then
                        WordList = j
                    end
                end
                for m=1, table.getn(WordList) do
                    --print(WordList[m])
                    if(WordList[m] == Word) then
                        WordIsUsed = 1
                    end
                end
                if(WordIsUsed == 0) then
                    SQLCOMMAND = "INSERT into '" .. message.channel.guild.id .. "' (Word,Emoji) values('" .. Word .. "','" .. Emoji .. "');"
                    db:exec(SQLCOMMAND)
                    message.author:send("**WORD** : ")
                    message.author:send(Word)
                    message.author:send("**Emoji** : ")
                    message.author:send(Emoji)
                    message.channel:send("Emoji Added")
                    message:delete()
                else
                    message.channel:send("Keyword Already In Use")
                end
            end
        else
            message.channel:send("addemoji can't be an emoji name and emoji can't contain \' and \" ")
        end
    end
end)

Client:on("messageCreate", function(message)
    if(string.lower(string.sub(message.content,1,1)) == ".") then
        local Word = string.sub(message.content,2,#message.content)
        SQLCOMMAND = "SELECT Emoji from '" .. message.channel.guild.id .. "' Where Word = '" .. Word .. "'"
        local Rows,errorString = db:exec(SQLCOMMAND)
        if(errorString == 0) then
            message.channel:send("No Emoji with that Keyword")
            --message.delete()
        else
            local EmojiList = {}
            for i,j in pairs(Rows) do
                if(i == "Emoji") then
                    EmojiList = j
                end
            end

            for m=1, table.getn(EmojiList) do
                if(EmojiList[m] ~= nil) then
                    --print(EmojiList[m])
                    message.channel:send("```\n" .. EmojiList[m] .. "```")
                    message:delete()
                end
            end
        end
    end
end)

Client:run("Bot ")