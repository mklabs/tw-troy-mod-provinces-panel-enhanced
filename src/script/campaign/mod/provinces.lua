-- workaround to get core object accessible in required ui file
_G.core = core;
_G.find_uicomponent = find_uicomponent
_G.is_function = is_function

local debug = require("tw-debug")("mk:provinces")
local getProvincesData = require("provinces/data").getProvincesData
local ui = require("provinces/ui")

-- list of factions for which this mod is not enabled
local IGNORED_FACTIONS = { "troy_amazons_trj_penthesilea" }

local function init()
    local faction = cm:get_local_faction()
    local enabled = true

    for k, v in pairs(IGNORED_FACTIONS) do
        debug("Check %s against %s", faction, v)
        if faction == v then
            debug("Disable mod")
            enabled = false
            break
        end
    end

    if enabled then
        ui.build()
    end
end

cm:add_first_tick_callback(init)