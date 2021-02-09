local debug = require("tw-debug")("mk:provinces:ui")

local provincialRecords = require("provinces/db/provincial_initiative_records")
local getProvincesData = require("provinces/data").getProvincesData
local getEdictTooltip = require("provinces/edictTooltip").getEdictTooltip

local utils = require("provinces/utils")
local _ = utils._
local destroyComponent = utils.destroyComponent

local activeDisplays = {
    PO = "Public Order / Income",
    influence = "Influence",
    edictsAndTiers = "Edicts / Higher Settlement Level"
}

local activeSort = {
    up = "up",
    down = "down"
}

local tabs = { activeDisplays.PO, activeDisplays.influence, activeDisplays.edictsAndTiers }

local currentActiveSorts = {
    influence = activeSort.down,
    level = activeSort.down,
    edict = activeSort.down
}

-- will hold influences information for each provinces
local data = {}

-- will hold initial height for provinces panel
local initialRegionsDropdownHeight = 0

local ui = {}

function ui.buildInfluenceText(row)
    -- get references for copy
    local copy = find_uicomponent(row, "income")

    -- build the influence text component
    local influenceText = UIComponent(copy:CopyComponent("mk_provinces_ui_influence_text"))
    destroyComponent(find_uicomponent(influenceText, "coin"))

    influenceText:SetCanResizeHeight(true)
    influenceText:SetCanResizeWidth(true)
    influenceText:ResizeTextResizingComponentToInitialSize(65, 20)

    influenceText:SetVisible(true)

    return influenceText
end

function ui.buildEdictIcon(row)
    -- get references for copy
    -- local copy = find_uicomponent(row, "mon")
    local copy = find_uicomponent(row, "icon_public_order")
    local iconPO = _("player_provinces > list_box > " .. row:Id() .. " > icon_public_order")
    local arrowPO = _("player_provinces > list_box > " .. row:Id() .. " > icon_public_order > arrow")

    -- build the influence text component
    local icon = UIComponent(copy:CopyComponent("mk_provinces_ui_edict_icon"))
    icon:SetVisible(true)

    -- local iconPO = find_uicomponent(row, "icon_public_order")
    local x, y = copy:Position()
    icon:MoveTo(x, y)
    icon:SetImagePath("UI/Campaign UI/edicts/troy_edict_icon_organize_games.png")

    icon:SetState(iconPO:CurrentState())

    local arrow = find_uicomponent(icon, "arrow")
    arrow:SetState(arrowPO:CurrentState())

    return icon
end

function ui.buildBuildingLevelText(row)
    -- get references for copy
    local copy = find_uicomponent(row, "income")

    local text = UIComponent(copy:CopyComponent("mk_provinces_ui_building_level"))
    destroyComponent(find_uicomponent(text, "coin"))

    text:SetVisible(true)
    text:SetStateText("")

    return text
end

function ui.buildProvincesPanelCopy()
    local list = _("dropdown_parent_2 > regions_dropdown > panel > panel_clip > listview > list_clip > list_box")
    local other = _("dropdown_parent_2 > regions_dropdown > panel > panel_clip > listview > list_clip > list_box > other_provinces")
    local provinces = _("dropdown_parent_2 > regions_dropdown > panel > panel_clip > listview > list_clip > list_box > player_provinces")
    local copy = UIComponent(provinces:CopyComponent("mk_provinces_player_provinces"))
    
    list:Divorce(other:Address())
    list:Adopt(other:Address())

    local arrowLeft = find_uicomponent(copy, "mk_provinces_ui_arrow_left")
    local arrowRight = find_uicomponent(copy, "mk_provinces_ui_arrow_right")

    local sortHappiness = find_uicomponent(copy, "headers", "sort_happiness")
    local sortResource = find_uicomponent(copy, "headers", "sort_pooled_resource")
    local cycleArrowLeft = find_uicomponent(copy, "headers", "cycle_button_arrow_left")
    local cycleArrowRight = find_uicomponent(copy, "headers", "cycle_button_arrow_right")

    local sortInfluence = UIComponent(cycleArrowRight:CopyComponent("mk_ui_provinces_sort_influence"))
    local x, y = sortResource:Position()
    sortInfluence:MoveTo(x + 10, y + 5)
    sortInfluence:SetVisible(true)
    sortInfluence:SetTooltipText("Sort by Influence", true)
    sortInfluence:SetImagePath("ui/skins/default/parchment_sort_btn_down.png")

    local sortLevel = UIComponent(cycleArrowRight:CopyComponent("mk_ui_provinces_sort_level"))
    x, y = sortResource:Position()
    sortLevel:MoveTo(x + 10, y + 5)
    sortLevel:SetVisible(true)
    sortLevel:SetTooltipText("Sort by Building Level", true)
    sortLevel:SetImagePath("ui/skins/default/parchment_sort_btn_down.png")

    local sortEdict = UIComponent(cycleArrowRight:CopyComponent("mk_ui_provinces_sort_edict"))
    x, y = sortHappiness:Position()
    sortEdict:MoveTo(x + 5, y)
    sortEdict:SetVisible(true)
    sortEdict:SetTooltipText("Sort by Edict", true)
    sortEdict:SetImagePath("ui/skins/default/parchment_sort_btn_down.png")

    sortHappiness:SetVisible(false)
    sortResource:SetVisible(false)
    cycleArrowLeft:SetVisible(false)
    cycleArrowRight:SetVisible(false)

    local listBox = find_uicomponent(copy, "list_box")
    ui.updateProvinceValues(listBox, function(child)
        local iconPO = find_uicomponent(child, "icon_public_order")
        local income = find_uicomponent(child, "income")
        local copyOf = find_uicomponent(provinces, "list_box", child:Id())
        local mon = find_uicomponent(copyOf, "mon")

        find_uicomponent(child, "mon"):SetState(mon:CurrentState())
        iconPO:SetVisible(false)
        income:SetVisible(false)

        local influenceText = find_uicomponent(child, "mk_provinces_ui_influence_text")
        if not influenceText then
            influenceText = ui.buildInfluenceText(child)
        end

        local edictIcon = find_uicomponent(child, "mk_provinces_ui_edict_icon")
        if not edictIcon then
            edictIcon = ui.buildEdictIcon(child)
        end

        local buildingLevelText = find_uicomponent(child, "mk_provinces_ui_building_level")
        if not buildingLevelText then
            buildingLevelText = ui.buildBuildingLevelText(child)
        end

        ui.registerRowClickListener(child)
    end)

    local listener = "mk_provinces_ui_arrow_left_copy_listener"
    core:remove_listener(listener)
    core:add_listener(
        listener,
        "ComponentLClickUp",
        function(context)
            return arrowLeft == UIComponent(context.component)
        end,
        function()
            ui.switchTab("left")
        end,
        true
    )

    listener = "mk_provinces_ui_arrow_right_copy_listener"
    core:remove_listener(listener)
    core:add_listener(
        listener,
        "ComponentLClickUp",
        function(context)
            return arrowRight == UIComponent(context.component) 
        end,
        function()
            ui.switchTab("right")
        end,
        true
    )

    listener = "mk_provinces_ui_sort_influence_listener"
    core:remove_listener(listener)
    core:add_listener(
        listener,
        "ComponentLClickUp",
        function(context) return sortInfluence == UIComponent(context.component) end,
        function()
           ui.sortBy("influence")
        end,
        true
    )

    listener = "mk_provinces_ui_sort_edict_listener"
    core:remove_listener(listener)
    core:add_listener(
        listener,
        "ComponentLClickUp",
        function(context) return sortEdict == UIComponent(context.component) end,
        function()
            ui.sortBy("edict")
        end,
        true
    )

    listener = "mk_provinces_ui_sort_level_listener"
    core:remove_listener(listener)
    core:add_listener(
        listener,
        "ComponentLClickUp",
        function(context) return sortLevel == UIComponent(context.component) end,
        function()
            ui.sortBy("level")
        end,
        true
    )


    return copy
end

function ui.updateProvinceValues(list, callback)
    for i = 0, list:ChildCount() - 1 do
        local child = UIComponent(list:Find(i))
        if is_function(callback) then
            callback(child)
        end

        local provinceName = string.gsub(child:Id(), "row_entry_", "")
        local provinceData = data[provinceName]
        if not provinceData then
            debug("ERROR: no province data for", provinceName)
            break
        end

        -- influence
        local influenceText = find_uicomponent(child, "mk_provinces_ui_influence_text")
        local influenceValue = provinceData.influence
        child:SetProperty("influence", influenceValue)

        local color = "dark_g"
        if influenceValue < 60 then
            color = "dark_r"
        end

        local text = string.format("[[col:%s]]%.1f%%[[/col]]", color, influenceValue)
        influenceText:SetStateText(text)

        color = "green"
        if influenceValue < 60 then
            color = "red"
        end

        local tooltipText = string.format("Influence [[col:%s]]%.1f%%[[/col]]", color, influenceValue)
        influenceText:SetTooltipText(tooltipText, true)

        local regionName = find_uicomponent(child, "region_name")
        local localisedZoomClick = effect.get_localised_string("uied_component_texts_localised_string_other_row_Tooltip_7d0008")
        regionName:SetTooltipText(tooltipText .. "\n" .. localisedZoomClick, true)

        -- edict
        local edictIcon = find_uicomponent(child, "mk_provinces_ui_edict_icon")
        local edictValue = provinceData.activeEdict

        if edictValue and edictValue ~= "" then
            local image = provincialRecords[edictValue].icon_path
            edictIcon:SetImagePath(image)
    
            local tooltip = getEdictTooltip(edictValue)
            edictIcon:SetTooltipText(tooltip, true)

            child:SetProperty("edict", edictValue)
        else
            child:SetProperty("edict", "")
        end

        -- building level
        local buildingLevel = find_uicomponent(child, "mk_provinces_ui_building_level")
        local buildingLevelValue = provinceData.level
        child:SetProperty("level", buildingLevelValue)

        color = "dark_g"
        if influenceValue < 60 then
            color = "dark_r"
        end

        buildingLevel:SetStateText(string.format("[[col:%s]]Tier %d[[/col]]", color, buildingLevelValue))
        buildingLevel:SetTooltipText("Highest building level in this province: " .. buildingLevelValue, true)
    end
end

function ui.displayTab(tab)
    debug("Display tab", tab)

    local playerProvincesCopy = _("mk_provinces_player_provinces")
    if not playerProvincesCopy then
        playerProvincesCopy = ui.buildProvincesPanelCopy()
    end

    local provinces = _("dropdown_parent_2 > regions_dropdown > panel > panel_clip > listview > list_clip > list_box > player_provinces")
    local listBox = find_uicomponent(playerProvincesCopy, "list_box")

    local sortInfluence = find_uicomponent(playerProvincesCopy, "mk_ui_provinces_sort_influence")
    local sortLevel = find_uicomponent(playerProvincesCopy, "mk_ui_provinces_sort_level")
    local sortEdict = find_uicomponent(playerProvincesCopy, "mk_ui_provinces_sort_edict")
    
    if tab == activeDisplays.influence then
        -- update influences value as they might have changed on turn start
        ui.updateProvinceValues(listBox)

        provinces:SetVisible(false)
        playerProvincesCopy:SetVisible(true)

        sortInfluence:SetVisible(true)
        sortLevel:SetVisible(false)
        sortEdict:SetVisible(false)

        for i = 0, listBox:ChildCount() - 1 do
            local child = UIComponent(listBox:Find(i))

            local influence = find_uicomponent(child, "mk_provinces_ui_influence_text")
            influence:SetVisible(true)
            
            local edictIcon = find_uicomponent(child, "mk_provinces_ui_edict_icon")
            edictIcon:SetVisible(false)

            local buildingLevel = find_uicomponent(child, "mk_provinces_ui_building_level")
            buildingLevel:SetVisible(false)
        end
    elseif tab == activeDisplays.PO then
        provinces:SetVisible(true)
        playerProvincesCopy:SetVisible(false)
    elseif tab == activeDisplays.edictsAndTiers then
        -- update influences value as they might have changed on turn start
        ui.updateProvinceValues(listBox)

        provinces:SetVisible(false)
        playerProvincesCopy:SetVisible(true)
        
        sortInfluence:SetVisible(false)
        sortLevel:SetVisible(true)
        sortEdict:SetVisible(true)

        for i = 0, listBox:ChildCount() - 1 do
            local child = UIComponent(listBox:Find(i))

            local influence = find_uicomponent(child, "mk_provinces_ui_influence_text")
            influence:SetVisible(false)
            
            local edictIcon = find_uicomponent(child, "mk_provinces_ui_edict_icon")
            local activeEdict = child:GetProperty("edict")
            local visible = false
            if activeEdict and activeEdict ~= "" then
                visible = true
            end
            edictIcon:SetVisible(visible)

            local iconPO = find_uicomponent(child, "icon_public_order")
            local x, y = iconPO:Position()
            edictIcon:MoveTo(x, y)

            local buildingLevel = find_uicomponent(child, "mk_provinces_ui_building_level")
            buildingLevel:SetVisible(true)
        end
    end
end

function ui.switchTab(direction)
    debug("Switch tab", direction)

    local tabIndex = cm:get_saved_value("mk_provinces_active_tabIndex")

    if direction == "left" then
        tabIndex = tabIndex - 1
        if tabIndex <= 0 then
            tabIndex = #tabs
        end
    elseif direction == "right" then
        tabIndex = tabIndex + 1
        if tabIndex > #tabs then
            tabIndex = 1
        end
    end

    local tab = tabs[tabIndex]
    cm:set_saved_value("mk_provinces_active_tab", tab)
    cm:set_saved_value("mk_provinces_active_tabIndex", tabIndex)

    ui.updateArrowTooltips()
    ui.displayTab(tab)
end

function ui.updateArrowTooltips()
    local left = _("mk_provinces_ui_arrow_left")
    local right = _("mk_provinces_ui_arrow_right")

    local tabIndex = cm:get_saved_value("mk_provinces_active_tabIndex")
    local tab = tabs[tabIndex]

    local previous = tabIndex ~= 1 and tabs[tabIndex - 1] or tabs[#tabs]
    local next = tabIndex ~= #tabs and tabs[tabIndex + 1] or tabs[1]

    debug("updateArrowTooltips", tab, tabIndex)
    debug("next", next)
    debug("previous", previous)

    left:SetTooltipText(string.format("Select Previous (%s)", previous), true)
    right:SetTooltipText(string.format("Select Next (%s)", next), true)
end

function ui.registerRowClickListener(row)
    local id = row:Id()
    local listener = "mk_ui_provinces_" .. id .. "_click_listener"

    core:remove_listener(listener)
    core:add_listener(
        listener,
        "ComponentLClickUp",
        function(context) return row == UIComponent(context.component) end,
        function(context)
            debug("Clicked on row entry", id)
            local uic = _("dropdown_parent_2 > regions_dropdown > player_provinces > " .. id)
            if not uic then
                debug("selectSettlement: Cannot find entry " .. id)
                return
            end

            local list = UIComponent(row:Parent())
            for i = 0, list:ChildCount() - 1 do
                local child = UIComponent(list:Find(i))
                child:SetState("unselected")
            end

            row:SetState("selected")
        
            debug("Simulate Click")
            uic:SimulateLClick()
        end,
        true
    )
end

function ui.sortBy(type)
    local direction = currentActiveSorts[type] == activeSort.down and activeSort.up or activeSort.down
    local image = direction == activeSort.up and "ui/skins/default/parchment_sort_btn_up.png" or "ui/skins/default/parchment_sort_btn_down.png"

    local btn = _("dropdown_parent_2 > mk_provinces_player_provinces > mk_ui_provinces_sort_" .. type)
    btn:SetImagePath(image)

    local rows = {}
    local list = _("dropdown_parent_2 > regions_dropdown > panel > panel_clip > listview > list_clip > list_box > mk_provinces_player_provinces > list_box")

    for i = 0, list:ChildCount() - 1 do
        local child = UIComponent(list:Find(i))
        table.insert(rows, child)
    end

    table.sort(rows, function(a, b)
        local valueA = a:GetProperty(type)
        local valueB = b:GetProperty(type)

        if type == "influence" or type == "level" then
            valueA = tonumber(valueA)
            valueB = tonumber(valueB)
        elseif type == "edict" then
            valueA = valueA and valueA or ""
            valueB = valueB and valueB or ""
        end

        if direction == activeSort.down then
            return valueA < valueB
        else
            return valueA > valueB
        end
    end)

    for k, v in pairs(rows) do
        list:Divorce(v:Address())
    end

    for k, v in pairs(rows) do
        list:Adopt(v:Address())
    end

    if type == "edict" or type == "level" then
        for i = 0, list:ChildCount() - 1 do
            local child = UIComponent(list:Find(i))

            -- reposition edict icon, it gets offset on sort for some reason
            local icon = find_uicomponent(child, "mk_provinces_ui_edict_icon")
            local iconPO = find_uicomponent(child, "icon_public_order")
            local x, y = iconPO:Position()
            local x2, y2 = icon:Position()
            icon:MoveTo(x, y)
        end
    end

    currentActiveSorts[type] = direction
end

function ui.buildButtons()
    debug("Build buttons")

    local header = _("dropdown_parent_2 > regions_dropdown > panel > panel_clip > title > header")
    local title = _("dropdown_parent_2 > regions_dropdown > panel > panel_clip > title > header > tx_title_text")

    local arrowLeftCopy = _("dropdown_parent_2 > regions_dropdown > panel > panel_clip > listview > list_clip > list_box > player_provinces > headers > cycle_button_arrow_left")
    local arrowRightCopy = _("dropdown_parent_2 > regions_dropdown > panel > panel_clip > listview > list_clip > list_box > player_provinces > headers > cycle_button_arrow_right")
    local sortButtonResources = _("dropdown_parent_2 > regions_dropdown > panel > panel_clip > listview > list_clip > list_box > player_provinces > headers > sort_pooled_resource")
    local sortName = _("dropdown_parent_2 > regions_dropdown > panel > panel_clip > listview > list_clip > list_box > player_provinces > headers > sort_name")

    local arrowLeft = UIComponent(arrowLeftCopy:CopyComponent("mk_provinces_ui_arrow_left"))
    local arrowRight = UIComponent(arrowRightCopy:CopyComponent("mk_provinces_ui_arrow_right"))

    arrowLeft:PropagatePriority(header:Priority())
    header:Adopt(arrowLeft:Address())

    arrowRight:PropagatePriority(header:Priority())
    header:Adopt(arrowRight:Address())

    ui.updateArrowTooltips()

    local x, y = title:Position()
    local w, h = title:Bounds()
    
    arrowLeft:MoveTo(x - 50, y + 5)
    arrowRight:MoveTo(x + w + 30, y + 5)

    x, y = sortName:Position()
    sortName:MoveTo(x - 10, y)

    local listener = "mk_provinces_ui_arrow_left_listener"
    core:remove_listener(listener)
    core:add_listener(
        listener,
        "ComponentLClickUp",
        function(context)
            return arrowLeft == UIComponent(context.component)
        end,
        function()
            ui.switchTab("left")
        end,
        true
    )

    listener = "mk_provinces_ui_arrow_right_listener"
    core:remove_listener(listener)
    core:add_listener(
        listener,
        "ComponentLClickUp",
        function(context)
            return arrowRight == UIComponent(context.component) 
        end,
        function()
            ui.switchTab("right")
        end,
        true
    )
end

function ui.registerUIListeners()
    local localFaction = cm:get_local_faction()

    local listeners = {
        PanelOpenedCampaign = "mk_ui_provinces_PanelOpenedCampaign_listener",
        PanelClosedCampaign = "mk_ui_provinces_PanelClosedCampaign_listener",
        RegionFactionChangeEvent = "mk_ui_provinces_RegionFactionChangeEvent_listener",
        FactionTurnStart = "mk_ui_provinces_FactionTurnStart_listener",
        TabRegionsClicked = "mk_ui_provinces_TabRegionsClicked_listener"
    }

    local tabRegionsBtn = _("faction_buttons_docker > bar_small_top > TabGroup > tab_regions")

    core:remove_listener(listeners.RegionFactionChangeEvent)
    core:remove_listener(listeners.PanelOpenedCampaign)
    core:remove_listener(listeners.PanelClosedCampaign)
    core:remove_listener(listeners.FactionTurnStart)
    core:remove_listener(listeners.TabRegionsClicked)

    core:add_listener(
        listeners.RegionFactionChangeEvent,
        "RegionFactionChangeEvent",
        function(context)
            local prevFaction = context:previous_faction():name()
            local newFaction = context:region():owning_faction():name()
            return prevFaction == localFaction or newFaction == localFaction
        end,
        function(context)
            debug("RegionFactionChangeEvent for %s faction", localFaction)
            debug("Region changed, rebuild UI")

            debug("Destroy mk_provinces_player_provinces")
            data = getProvincesData()
            destroyComponent(_("mk_provinces_player_provinces"))
        end,
        true
    )

    core:add_listener(
        listeners.FactionTurnStart,
        "FactionTurnStart",
        function(context)
            local faction = context:faction():name()
            return faction == localFaction
        end,
        function(context)
            debug("FactionTurnStart for %s faction", localFaction)
            debug("Turn Start, update data")

            data = getProvincesData()
        end,
        true
    )

    core:add_listener(
        listeners.TabRegionsClicked,
        "ComponentLClickUp",
        function(context)
            return tabRegionsBtn == UIComponent(context.component)
        end,
        function()
            debug("Regions button clicked")
            local regionsDropdown = _("dropdown_parent_2 > regions_dropdown")
            local w, h = regionsDropdown:Bounds()

            debug("Regions button clicked, height: ", h, initialRegionsDropdownHeight)

            if h == initialRegionsDropdownHeight then
                debug("Regions button clicked, opening")

                local savedTab = cm:get_saved_value("mk_provinces_active_tab")
                if savedTab then
                    debug("Display tab %s from saved value", savedTab)
                    cm:callback(function()
                        ui.displayTab(savedTab)
                    end, 0.1)
                end
            end
        end,
        true
    )

    core:add_listener(
        listeners.PanelOpenedCampaign,
        "PanelOpenedCampaign",
        function(context) return true end,
        function(context)
            debug("PanelOpenedCampaign", context.string)
        end,
        true
    )

    core:add_listener(
        listeners.PanelClosedCampaign,
        "PanelClosedCampaign",
        function(context) return true end,
        function(context)
            debug("PanelClosedCampaign", context.string)
        end,
        true
    )

end

function ui.build()
    debug("Build UI")

    local regionsDropdown = _("dropdown_parent_2 > regions_dropdown")
    local w, h = regionsDropdown:Bounds()
    initialRegionsDropdownHeight = h

    debug("initialRegionsDropdownHeight", initialRegionsDropdownHeight)

    local savedTab = cm:get_saved_value("mk_provinces_active_tab")
    local savedTabIndex = cm:get_saved_value("mk_provinces_active_tabIndex")

    if not savedTab then
        cm:set_saved_value("mk_provinces_active_tab", tabs[1])
    end

    if not savedTabIndex then
        cm:set_saved_value("mk_provinces_active_tabIndex", 1)
    end

    data = getProvincesData()
    debug("data", data)
    ui.buildButtons()
    ui.registerUIListeners()
end

function ui.init()
    local turn = cm:turn_number()
    local isNewGame = cm:is_new_game()

    debug("Init, turn number is %d", turn)
    debug("New game: ", isNewGame)

    if not isNewGame then
        ui.build()
        return
    end

    debug("New game, special care to build UI only when the first event panel is closed. Otherwise, UI becomes unresponsive")

    local listener = "mk_provinces_ui_PanelClosedCampaign_first_turn_listener"
    core:add_listener(
        listener,
        "PanelClosedCampaign",
        function(context) return context.string == "events" end,
        function(context)
            debug("Close events for first turn, delayed build")
            core:remove_listener(listener)
            ui.build()
        end,
        true
    )
end

return ui