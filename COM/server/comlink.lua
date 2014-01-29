local COM_VER = 1.1
local MIN_GUI_VER = 1.1
local VER_WARNING = false
local sid = 0

class 'SERVER_COM'

function SERVER_COM:__init(SND_PORT, RCV_PORT)
    self.id = sid
    self.linked = true
    sid = sid + 1
    self.SND_PORT = SND_PORT
    self.RCV_PORT = RCV_PORT
    self.UseHash = true

    local EstablishCOM = 
        function()
            if unexpected_condition then 
                error()
            end
        
            self.COMLINK = UDPSocket.Create(self.RCV_PORT)
        end
    
    if pcall(EstablishCOM) then
        self:StartHandshake()
    else
        print("Could not bind to port "..RCV_PORT)
    end
end

--[[
-- Sends data across the COM Link
--]]
function SERVER_COM:Send(message)
    if self.linked then
        self.COMLINK:Send("localhost", self.SND_PORT, message)
        return true
    end
    return false
end

--[[
-- Receive handler for the COM Link
--]]
function SERVER_COM:Receive(args)
    local request = string.split(args.text, " ")
    local IsValid = true
    local DestroyLink = false
    
    local Req = {}
    
    -- If the link specifies to use a SHA-256 hash, check the packet against the hash.
    if self.UseHash then
        local hash = SHA256()
        
        hash:Update(request[1])
        
        for i = 2, table.count(request) - 1 do
            hash:Update(" "..request[i])
            
            if i >= 3 then
                Req[i - 2] = request[i]
            end
        end
        
        hash:Final()
    
        IsValid = (hash.digest == request[table.count(request)])
    else
        for i = 3, table.count(request) do
            Req[i - 2] = request[i]
        end
    end

    IsValid = IsValid and (tonumber(request[1]) == 0) -- Currently only support packet type 0

    -- If the packet is valid, continue.
    if IsValid then    
        local ReqID = request[2]
        local response = tostring(Processor.process(Req, ReqID)) -- Process and generate the packet response
            
        if response ~= nil then
            local MPS = math.max((MaxPacketSize - 90), 10) -- Calculated Maximum Packet Size
            local Packets = {}
            
            MPS = 1000000000000 -- Packet fragmentation doesn't work atm.
            
            local PN = math.ceil(response:len() / MPS) -- Packets needed
            
            for i = 1, (PN - 1) do            
                Packets[i] = "1 "..ReqID.." "..((i - 1) * MPS).." "..response:len().." "..request[4].." "..response:sub(1 + ((i - 1) * MPS), i * MPS)
            end
            
            Packets[PN] = "1 "..ReqID.." "..((PN - 1) * MPS).." "..response:len().." "..request[4].." "..response:sub(1 + ((PN - 1) * MPS))
            
            if self.UseHash then
                for i,packet in pairs(Packets) do
                    self:Send(packet.." "..SHA256.ComputeHash(packet))
                end
            else
                for i,packet in pairs(Packets) do
                    self:Send(packet)
                end
            end
        end
        
        -- Special processing needed for CREATE and DESTROY requests.
        if request[3]:upper() == "CREATE" or request[3]:upper() == "DESTROY" then
            if DynamicLinks then
                if request[3]:upper() == "CREATE" then
                    -- Create link here
                    local SNDP = tonumber(request[5])
                    local RCVP = tonumber(request[6])
                    
                    table.insert(ActiveLinks, SERVER_COM(SNDP, RCVP))
                else
                    -- Destroy link here                
                    DestroyLink = true
                end
            end
        end
    end

    if DestroyLink then
        self:Terminate()
        table.remove(ActiveLinks, self.id)
    else
        self.COMLINK:Receive(self, self.Receive)
    end
end

--[[
-- Starts the handshake sequence with the GUI
--]]
function SERVER_COM:StartHandshake()
    local response = nil

    RCV_HANDSHAKE = 
        function(args)
            response = args.text
            
            if string.starts(response, "VALIDATE ") then
                local resp = string.split(response, " ")
                local GUI_VER = resp[2]
                ServVer = tonumber(resp[3])
                self.UseHash = toboolean(resp[4])
                
                if (tonumber(GUI_VER) < MIN_GUI_VER) then
                    if not VER_WARNING then
                        print("GUI is outdated! Please update to v"..MIN_GUI_VER.."!")
                        VER_WARNING = true
                    end
                    self:Terminate()
                else
                    self:Send("VALIDATION OK")
                    
                    self.COMLINK:Receive(self, self.Receive)
                end
            elseif string.starts(response:upper(), "INVALID ") then
                if not VER_WARNING then
                    print("COM Module is outdated! Please update to v"..string.split(response, " ")[2].."!")
                    VER_WARNING = true
                end
                self:Terminate()
            else
                self.COMLINK:Receive(RCV_HANDSHAKE)
            end
        end

    self.COMLINK:Receive(RCV_HANDSHAKE)

    self:Send("VALIDATE "..COM_VER.." "..MinPollTime.." "..tostring(ProcessGET).." "..tostring(ProcessDO).." "..tostring(DynamicLinks).." "..base64enc(tostring(Config:GetValue("Server", "Name"))).." "..base64enc(tostring(Config:GetValue("Server", "Description"))).." "..tostring(Config:GetValue("Server", "Announce")))
end

--[[
-- Terminates the COM Link
--]]
function SERVER_COM:Terminate()
    self.linked = false
    self.COMLINK:Close()
    self.COMLINK = nil
end