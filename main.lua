local discordia = require("discordia")
local sql = require("sqlite3")
local https = require("ssl.https")
local ltn12 = require("ltn12")

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

function script_path()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
end 

function doesFileExist(fname)
    local results = false
    local filePath = script_path() .. "/" .. fname
    if ( filePath ) then
        local file, errorString = io.open( filePath, "r" )
        if not file then
            print( "File error: " .. errorString )
        else
            print( "File found: " .. fname )
            results = true
            file:close()
        end
    end
    return results
end


function WriteFile(saveData,File)
    local path = script_path() .. "/" .. File
    local file, errorString = io.open( path, "w" )
 
    if not file then
        print( "File error: " .. errorString )
    else
        file:write( saveData )
        io.close( file )
    end
    file = nil
end


function ReadFile(File)
    local path = script_path() .. "/" .. File
    local file, errorString = io.open( path, "r" )
    local contents

    if not file then
        print( "File error: " .. errorString )
    else
        contents = file:read( "*a" )
        io.close( file )
    end
    file = nil
    return contents
end

function Vivi(message) 
    local StartingIndex = 0
    local IDTable = {}
    local TableSize = 0
    for PID = 0, 7 do
        local file,errorString = io.open("index.html","w+")
        local res,code,response_headers = https.request{
            url = "http://rule34.xxx/index.php?page=post&s=list&tags=wa2000_%28girls_frontline%29+&pid=" .. PID*42,
            sink = ltn12.sink.file(file:write(),errorString)
        }
    
        local Content = ReadFile("index.html")
        while true do
            local i,j = string.find(Content,"<a id=",StartingIndex)
            if(i == nil and j == nil) then
                break
            end
            TableSize = TableSize + 1
            IDTable[TableSize] = string.sub(Content,j+3,j+9)
            --print(IDTable[TableSize],i,j)
            StartingIndex = j
        end
        --print(TableSize)
        --print(PID)
        --print("http://rule34.xxx/index.php?page=post&s=list&tags=wa2000_%28girls_frontline%29+&pid=" .. PID*42)
        StartingIndex = 0
    end
    
    math.randomseed(math.random())
    ChosenImgIndex = math.random(TableSize)
    
    ----
    
    local file,errorString = io.open("img.html","w+")
    local res,code,response_headers = https.request{
        url = "http://rule34.xxx/index.php?page=post&s=view&id=" .. IDTable[ChosenImgIndex],
        sink = ltn12.sink.file(file:write(),errorString)
    }
    print(IDTable[ChosenImgIndex])
    
    local Content = ReadFile("img.html")
    local StartIndex,EndIndex = string.find(Content,"Note.toggle()")
    --print(StartIndex,EndIndex)
    local URLtoIMG
    local AEnd
    local BEnd
    local Counter = 0
    for i=StartIndex-1, 0,-1 do
        local C = string.sub(Content,i,i)
    
        if(Counter == 4) then 
            BEnd = i 
            Counter = Counter + 1
        end
        if(Counter == 6) then 
            AEnd = i
            --print(AEnd,BEnd)
            URLtoIMG = string.sub(Content,AEnd+2,BEnd) 
            break  
            --print(URLtoIMG) 
        end
        if(C == "\"") then 
            Counter = Counter + 1 
        end
    end
    print(URLtoIMG)
    --[[local file,errorString = io.open("Pic.png","w+")
    local res,code,response_headers = https.request{
        url = URLtoIMG,
        sink = ltn12.sink.file(file:write(),errorString)
    }
    message.author:send{
        file = "Pic.png"
    }]]
    message.author:send(URLtoIMG)
    message:delete()
end


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

Client:on("messageCreate", function(message)
    if(string.lower(string.sub(message.content,1,1)) == "|") then
        message.channel:send(string.lower(string.sub(message.content,2,#message.content)))    
    end
    if(string.lower(string.sub(message.content,1,#message.content)) == "lykourgos") then
          Vivi(message)
    end
end)

Client:run("Bot Njk4NTQyMDExOTgwMDU0NjQ4.XsUbqQ.xJJhvTKMXRJg3ASvP_1c-Y3s7aQ")