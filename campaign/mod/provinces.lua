-- workaround to get core object accessible in required ui file
_G.core = core;
_G.find_uicomponent = find_uicomponent
_G.is_function = is_function

local debug = require("tw-debug")("mk:provinces")
local getProvincesData = require("provinces/data").getProvincesData
local ui = require("provinces/ui")

local function init()
    debug("Init")
    ui.build()
end

cm:add_first_tick_callback(init)