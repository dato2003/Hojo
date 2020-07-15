local https = require("ssl.https")
local ltn12 = require("ltn12")

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
local file,errorString = io.open("Pic.png","w+")
local res,code,response_headers = https.request{
    url = URLtoIMG,
    sink = ltn12.sink.file(file:write(),errorString)
}