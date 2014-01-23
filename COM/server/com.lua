--[[
-- The following represents configurable options for this COM Link:
--
-- COM_LINKS: Stores a table of COM Links to establish (by TX/RX port pair), should additional COM links be required (for faster polling), add as a pair below.
--            Each SND_PORT port number should correspond to a RCV_PORT in the GUI configuration file. All port numbers in this file should be unique.
-- MinPollTime: Minimum time between two requests on the same COM link. Shorter polling time means faster polling but packet drop might become an issue.
--              Please note that this is merely a hint value for the GUI and is not actively enforced by the COM module itself.
-- MaxPacketSize: Maximum packet size to use before fragmenting. Values are in bytes, do not set less than 100. This value specifies a maximum and is not a
--                guarantee that packets will be of this size. It is strongly recommended to not decrease this value below default.
--                WARNING: This feature is currently broken and may be fixed in future releases, fragmentation will NOT occur regardless of this value.
-- DynamicLinks: Allows COM links to be dynamically created and closed through the GUI without reloading the module.
-- ProcessGET: Whether or not to process GET directives (obtaining values from server, e.g: get player count, get server time, etc)
-- ProcessDO: Whether or not to process DO directives (actively tell the server to do things, e.g: chat, kick player, ban player, etc)
--]]

-- Default 1 link (SND_PORT = 8001, RCV_PORT = 8002)
local COM_LINKS = {
    {
        SND_PORT = 8001,
        RCV_PORT = 8002
    }
}
-- Default: 75ms
MinPollTime = 75

-- Default: 20000 bytes
MaxPacketSize = 20000

-- Default: false
DynamicLinks = false

-- Default: true
ProcessGET = true

-- Default: true
ProcessDO = true

---- End of configurable options ----

-- Setup --
ActiveLinks = {}
ServVer = "UNKNOWN"

io.stderr:setvbuf("no") -- Disable output buffering
io.stdout:setvbuf("no") -- Disable output buffering

Events:Subscribe("ModuleLoad", 
    function()
        for k in pairs(COM_LINKS) do
            table.insert(ActiveLinks, SERVER_COM(COM_LINKS[k].SND_PORT, COM_LINKS[k].RCV_PORT))
        end
    end
)
Events:Subscribe("ModuleUnload",
    function()
        for k in pairs(ActiveLinks) do
            ActiveLinks[k]:Terminate()
        end
        
        ActiveLinks = {}
    end
)

-- Global Server Data --

tick = 0
deadplayers = 0

Events:Subscribe("PostTick", 
    function()
        tick = tick + 1
    end
)

Events:Subscribe("PlayerDeath", 
    function(args)
        deadplayers = deadplayers + 1
    end
)