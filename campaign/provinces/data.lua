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
        local regionsList = province:regions()
        local regions = {}

        local activeEdict, selectedEdict, publicOrder
        local highestBuildingLevel = 0
        for j = 0, regionsList:num_items() - 1 do
            local region = regionsList:item_at(j)
            local regionName = region:name()
            local owningFaction = region:owning_faction():name()
            local regionActiveEdict = region:get_active_edict_key()
            local regionSelectedEdict = region:get_selected_edict_key()

            if regionActiveEdict ~= activeEdict then
                activeEdict = regionActiveEdict
            end

            if regionSelectedEdict ~= selectedEdict then
                selectedEdict = regionSelectedEdict
            end

            if owningFaction == faction:name() then
                local settlement = region:settlement()
                local buildingList = settlement:building_list()

                publicOrder = region:public_order()
    
                for k = 0, buildingList:num_items() - 1 do
                    local building = buildingList:item_at(k)
                    local name = building:name()
                    local chain = building:chain()
                    local superchain = building:superchain()
                    
                    local slot = building:slot()
                    local slotType = slot:type()
                    local slotName = slot:name()
                    local slotTemplateKey = slot:template_key()
                    local slotResourceKey = slot:resource_key()
    
                    if slotType == "primary" then
                        local buildingLevel = string.match(name, "_%d$")
                        if not buildingLevel then
                            break
                        end
    
                        buildingLevel = string.gsub(buildingLevel, "^_", "")
                        buildingLevel = tonumber(buildingLevel)
    
                        if buildingLevel > highestBuildingLevel then
                            highestBuildingLevel = buildingLevel
                        end
                    end
                end
            end
        end

        result[name] = {
            name = name, 
            influence = math.floor(influence * 100),
            activeEdict = activeEdict,
            selectedEdict = selectedEdict,
            level = highestBuildingLevel,
            publicOrder = publicOrder
        }
    end

    return result
end

return {
    getProvincesData = getProvincesData
}