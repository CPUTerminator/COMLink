class 'Processor'

local tick_lastcalltime = 0
local deltaReqID = -1
local playertable = {}

local GeneratePlayerInfo = 
    function(p)
        if p == nil then
            return "null"
        end

        local ip = "null"
        
        if supports("IP") then
            ip = p:GetIP()
        end

        local veh = "null"
        local veh_health = -1

        if p:InVehicle() then
            veh = p:GetVehicle():GetName()
            veh_health = p:GetVehicle():GetHealth()
        end

        local wep = p:GetEquippedWeapon()

        if wep ~= nil then
            wep = wep.id
        else
            wep = -1
        end

        local pos = p:GetPosition()

        return p:GetId()..","
        ..p:GetName()..","
        ..ip..","
        ..tostring(p:GetSteamId())..","
        ..p:GetPing()..","
        ..veh..","
        ..veh_health..","
        ..wep..","
        ..p:GetHealth()..","
        ..tostring(p:GetParachuting())..","
        ..p:GetLinearVelocity():LengthSqr()..","
        ..pos.x..","..pos.y..","..pos.z
    end
    
local GeneratePlayerData = 
    function(p)
        if p == nil then
            return "null"
        end
        
        local ip = "null"
        
        if supports("IP") then
            ip = p:GetIP()
        end
        
        local veh = "null"
        
        if p:InVehicle() then
            veh = p:GetVehicle():GetName()
        end
        
        local pos = p:GetPosition()
        
        return p:GetId()..","
        ..p:GetName()..","
        ..ip..","
        ..tostring(p:GetSteamId())..","
        ..p:GetPing()..","
        ..veh..","
        ..tostring(p:GetParachuting())
    end

function Processor.process(request, ReqID)
    local ReqType = request[1]:upper()
    if ReqType == "GET" then
        if not ProcessGET then
            return "DENIED"
        end

        -- Handle incoming get request

        local command = request[2]:upper()
        
        if command == "PLAYERCOUNT" then
            return Server:GetPlayerCount()
        elseif command == "VEHICLECOUNT" then
            local i = 0
            
            for vehicle in Server:GetVehicles() do
                i = i + 1
            end
        
            return i
        elseif command == "WORLDPLAYERCOUNT" then
            local i = 0
            local dead = 0
            
            for player in DefaultWorld:GetPlayers() do
                if player:GetHealth() <= 0 then
                    dead = dead + 1
                end
                i = i + 1
            end
        
            return i..","..dead
        elseif command == "WORLDVEHICLECOUNT" then
            local i = 0
            local dead = 0
            
            for vehicle in DefaultWorld:GetVehicles() do
                if vehicle:GetHealth() <= 0 then
                    dead = dead + 1
                end
                i = i + 1
            end
        
            return i..","..dead
        elseif command == "TOTALCASH" then
            local total = 0

            for player in Server:GetPlayers() do
                total = total + player:GetMoney()
            end
        
            return total
        elseif command == "TOTALDEATHS" then
            return deadplayers
        elseif command == "PLAYERINFO" then
            if request[3] == nil then
                return "null"
            end
        
            local p = Player.GetById(tonumber(request[3]))
            
            if p ~= nil then
                return GeneratePlayerInfo(p)
            else
                return request[3]..",null"
            end
        elseif command == "PLAYERDATA" then
            local playerdata = ""
            
            playertable = {}
            
            for player in Server:GetPlayers() do
                playertable[player:GetId()] = GeneratePlayerData(player)
                playerdata = playertable[player:GetId()]..","..playerdata
            end
            
            deltaReqID = ReqID

            if table.count(playertable) == 0 then
                return "null"
            else
                return playerdata:sub(0, -2)
            end
        elseif command == "PLAYERDATADELTA" then
            local playerdata = deltaReqID
            
            for player in Server:GetPlayers() do
                local pd = GeneratePlayerData(player)

                if playertable[player:GetId()] ~= pd then
                    playerdata = playerdata..","..pd
                end
            end
            
            return playerdata
        elseif command == "SERVTIME" then
            return Server:GetElapsedSeconds()
        elseif command == "WORLDTIME" then
            return DefaultWorld:GetTime()
        elseif command == "WORLDWEATHERSEVERITY" then
            return DefaultWorld:GetWeatherSeverity()
        elseif command == "TICKTIME" then
            local cur_ticks = tick
            local timediff = Server:GetElapsedSeconds() - tick_lastcalltime

            tick = 0
            tick_lastcalltime = Server:GetElapsedSeconds()

            return cur_ticks..","..timediff
        end
    elseif ReqType == "DO" then
        if not ProcessDO then
            return "DENIED"
        end
        
        -- Handle incoming do request

        local command = request[2]:upper()
        
        if command == "BAN" or command == "KICK" or command == "CHAT" then        
            local p = Player.GetById(tonumber(request[3]))
            local msg = ""
            local hasMsg = true
            local color = nil
            
            if p == nil then
                return "NO_PLAYER"
            end
            
            local cmax = table.count(request)
            
            if command == "CHAT" then
                color = Color(tonumber(request[cmax]))
                cmax = cmax - 1
            end
            
            for i = 4,cmax do
                msg = msg..request[i].." "
            end
            
            if msg == "" then
                hasMsg = false
            else
                msg = msg:sub(0, -2)
            end
            
            if command == "BAN" then
                if hasMsg then
                    p:Ban(msg)
                else
                    p:Ban()
                end

                return "OK"
            elseif command == "KICK" then
                if hasMsg then
                    p:Kick(msg)
                else
                    p:Kick()
                end

                return "OK"
            elseif command == "CHAT" then
                if not hasMsg then
                    return "NO_MESSAGE"
                end

                if color == nil then
                    return "NO_COLOR"
                end

                Chat:Send(p, msg, color)

                return "OK"
            end
        end
    elseif ReqType == "CREATE" or ReqType == "DESTROY" then
        if DynamicLinks then
            return "OK"
        else
            return "DENIED"
        end
    end

    return nil
end