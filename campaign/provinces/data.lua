local debug = require("tw-debug")("mk:provinces:data")

local function getProvincesData()
    local faction = cm:get_faction(cm:get_local_faction())
    local religion = faction:state_religion()
    local globalProportion = faction:average_religion_proportion(religion)
    
    local provinces = faction:province_list()
    local result = {}
    
    for i = 0, provinces:num_items() - 1 do
        local province = provinces:item_at(i)
        local name = province:name()
        local influence = province:religion_proportion(religion)
        result[name] = math.floor(influence * 100)
    end

    return result
end

return {
    getProvincesData = getProvincesData
}