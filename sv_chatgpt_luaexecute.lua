if not SERVER then return end

CreateConVar( "openai_key", "", FCVAR_PROTECTED)


openAIAPIKEY = ""
local ai_key_convar = GetConVar("openai_key")
if not file.Exists("openai_key.txt", "DATA") then
    file.Write("openai_key.txt", "", "DATA")
end
ai_key_convar:SetString(file.Read("openai_key.txt","DATA"))
local lastOpenAIRequest = 0

cvars.AddChangeCallback("openai_key", function(convar_name, value_old, value_new)
    print(convar_name, value_old, value_new)
    file.Write("openai_key.txt", value_new)
end)
function getChatGPTResponse(prompt, model, temperature, max_tokens, cb)
    openAIAPIKEY = ai_key_convar:GetString()
    if not prompt then return end
    datajson = [[
        {"frequency_penalty":0.8,"presence_penalty":1,"max_tokens":]] .. tostring(max_tokens or 20) .. [[,
         "model":"]] .. (model or "text-davinci-003") ..  [[",
         "temperature":]] .. tostring(temperature or 0.8) ..[[,
         "prompt":"]] .. prompt .. [["
        }]]
    print(datajson)
    HTTP({
        url= "https://api.openai.com/v1/completions", 
        method= "POST", 
        headers= { 
            ['Content-Type']= 'application/json',
            ["Authorization"] = "Bearer " .. openAIAPIKEY
        },
        success= function( code, body, headers )
            print(body)
            local decoded = util.JSONToTable(body)
            cb(decoded)
        end, 
        failed = function( err )
            print("error")
            print(err)
        end,
        type = 'application/json',
        body=datajson
    })
end
print('test')
function ai_chatgpt_simple(text, cb, max_tokens, temp)
    if not max_tokens then max_tokens = 30 end
    if not temp then temp = 0.85 end
    getChatGPTResponse(text, "text-davinci-003",temp,max_tokens,function(data)
        print("GOT RESPONSE")
        if not data["choices"] then return end
        cb(data["choices"][1]["text"])
    end)
end

local nextRun = 0 

local function chatGPTDoCode(prompt)
    ai_chatgpt_simple(prompt, function(text)
        print("Runnning code: \n " .. text)
        if string.find(text, "while true do") then
            print("AI is attempting something along the lines of a crash, ABORT ABORT THE DALEKS HAVE ESCAPED (Cancel code)")
            return
        end
        text = string.Replace(text, "<code>", "")
        text = string.Replace(text, "</code>", "")
        local errortext = RunString( "function LocalPlayer() local pl = player.GetAll()[#player.GetAll()]; return pl end " ..  text, "openai_lua", false)
        if errortext then
            print("error: " .. errortext)
            --[[ai_chatgpt_simple("There was an error " .. errortext .. " please redo  this code:" .. text, function(text)
                print("Runnning code: \n " .. text)
                text = RunString( "function LocalPlayer() local pl = nil; for _, ply in ipairs(player.GetAll()) do pl = ply; break; end return pl end" ..  text, "openai_lua", false)
                if text then
                    print("error: " .. text)
                    
                end
            end, 1000)]]
        end
    end, 1000)
end

local function chatGPTDoCodeSpecificIdea(idea)
    idea = string.Replace(idea, "\n", "")
    idea = string.Replace(idea, "\"", "")
    idea = string.Replace(idea, "```lua", "")
    idea = string.Replace(idea, "```", "")
    ai_chatgpt_simple("Generate serverside code to be ran on a garrysmod server with the idea " .. idea .. "." , function(text)
        print("Runnning code: \n " .. text)
        if string.find(text, "while true do") then
            print("AI is attempting something along the lines of a crash, ABORT ABORT THE DALEKS HAVE ESCAPED (Cancel code)")
            return
        end
        local errortext = RunString( "function LocalPlayer() local pl = player.GetAll()[#player.GetAll()]; return pl end " ..  text, "openai_lua", false)
        if errortext then
            print("error: " .. errortext)
            --[[ai_chatgpt_simple("There was an error " .. errortext .. " please redo  this code:" .. text, function(text)
                print("Runnning code: \n " .. text)
                text = RunString( "function LocalPlayer() local pl = nil; for _, ply in ipairs(player.GetAll()) do pl = ply; break; end return pl end" ..  text, "openai_lua", false)
                if text then
                    print("error: " .. text)
                    
                end
            end, 1000)]]
        end
    end, 1000)
end
hook.Add("Think", "openai_execute", function()
    --print("thinking")
    if nextRun == 0 then
        --nextRun = CurTime() + 10
    end
    if CurTime() > nextRun then
        --chatGPTDoCode("Type serverside lua code to be ran on the garrysmod server, don't be afraid to do something wacky like spawn random entities like npcs, cars, props,  set people on fire, start a disaster like a zombie apocolypse, flood, lava etc:")
        chatGPTDoCode("You are able to execute any serverside lua code for a garrysmod server, torment the players by generating code:")
        nextRun = CurTime() + 20
    end
end)
