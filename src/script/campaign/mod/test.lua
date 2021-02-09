-- workaround to get core object accessible in required ui file
_G.core = core;
_G.find_uicomponent = find_uicomponent

local debug = require("tw-debug")("mk:test")
local getProvincesData = require("provinces/data").getProvincesData
local ui = require("provinces/ui")

local function init()
    debug("Init Test")
    local data = getProvincesData()
    debug("Data => ", data)

    ui.build()
end

cm:add_first_tick_callback(init)