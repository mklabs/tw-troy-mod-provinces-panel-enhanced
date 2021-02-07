local debug = require("tw-debug")("mk:provinces:ui")

local getProvincesData = require("provinces/data").getProvincesData
local _ = require("provinces/utils")._

local activeDisplays = {
    PO = "public_order",
    influence = "influence"
}

local activeSort = {
    up = "up",
    down = "down"
}

local currentActiveDisplay = activeDisplays.PO
local currentActiveSort = activeSort.down

-- will hold influences information for each provinces
local data = {}

local ui = {}

function ui.destroyComponent(component)
    if not component then
        return
    end

    local root = core:get_ui_root()
    local dummy = find_uicomponent(root, 'DummyComponent')
    if not dummy then
        root:CreateComponent("DummyComponent", "UI/campaign ui/script_dummy")        
    end
    
    local gc = UIComponent(root:Find("DummyComponent"))
    gc:Adopt(component:Address())
    gc:DestroyChildren()
end

function ui.buildInfluenceText(row)
    debug("Build Influences Text for row", row:Id())

    -- get references for copy
    local copy = find_uicomponent(row, "income")

    -- build the influence text component
    local influenceText = UIComponent(copy:CopyComponent("mk_provinces_ui_influence_text"))
    ui.destroyComponent(find_uicomponent(influenceText, "coin"))

    influenceText:SetCanResizeHeight(true)
    influenceText:SetCanResizeWidth(true)
    influenceText:ResizeTextResizingComponentToInitialSize(65, 20)

    influenceText:SetVisible(false)

    -- resize region name to not overlap
    local name = find_uicomponent(row, "region_name")
    local w, h = name:Bounds()
    name:Resize(w - 19, h)

    debug("Build Influences Text done for", row:Id())
    return influenceText
end

function ui.switchDisplay(direction)
    debug("Switch display", direction)
    if currentActiveDisplay == activeDisplays.PO then
        currentActiveDisplay = activeDisplays.influence
    elseif currentActiveDisplay == activeDisplays.influence then
        currentActiveDisplay = activeDisplays.PO
    end

    local sortButtonHapyness = _("dropdown_parent_2 > regions_dropdown > panel > panel_clip > listview > list_clip > list_box > player_provinces > headers > sort_happiness")
    local sortButtonInfluence = _("dropdown_parent_2 > regions_dropdown > panel > panel_clip > listview > list_clip > list_box > player_provinces > headers > mk_provinces_ui_sort_influence")

    local isInfluenceVisible = currentActiveDisplay == activeDisplays.influence
    sortButtonHapyness:SetVisible(not isInfluenceVisible)
    sortButtonInfluence:SetVisible(isInfluenceVisible)

    local listBox = _("dropdown_parent_2 > regions_dropdown > panel > panel_clip > listview > list_clip > list_box > player_provinces > list_box")
    for i = 0, listBox:ChildCount() - 1 do
        local child = UIComponent(listBox:Find(i))
        local iconPO = find_uicomponent(child, "icon_public_order")
        local influenceText = find_uicomponent(child, "mk_provinces_ui_influence_text")

        if not influenceText then
            influenceText = ui.buildInfluenceText(child)
        end
        
        local provinceName = string.gsub(child:Id(), "row_entry_", "")
        local value = data[provinceName]
        child:SetProperty("influence", value)

        if not value then
            debug("ERROR: no influence data for", provinceName)
            break
        end

        local color = "dark_g"
        if value < 60 then
            color = "dark_r"
        end

        local text = string.format("[[col:%s]]%.1f%%[[/col]]", color, value)
        influenceText:SetStateText(text)

        local tooltipText = "Influence: " .. text
        influenceText:SetTooltipText(tooltipText, true)
        
        local x, y = iconPO:Position()
        influenceText:MoveTo(x - 35, y)

        iconPO:SetVisible(not isInfluenceVisible)
        influenceText:SetVisible(isInfluenceVisible)
    end
end

function ui.registerRowClickListener(row)
    local province = row:GetProperty("province")
    local listener = "mk_ui_" .. province .. "_click_listener"

    core:remove_listener(listener)
    core:add_listener(
        listener,
        "ComponentLClickUp",
        function(context) return row == UIComponent(context.component) end,
        function(context)
            ui.selectSettlement(province)
        end,
        true
    )
end

function ui.sort()
    local direction = currentActiveSort == activeSort.down and activeSort.up or activeSort.down
    debug("Sort something", direction)

    local image = direction == activeSort.up and "ui/skins/default/parchment_sort_btn_up.png" or "ui/skins/default/parchment_sort_btn_down.png"
    local btn = _("dropdown_parent_2 > mk_provinces_ui_sort_influence")

    btn:SetImagePath(image)

    local rows = {}
    local list = _("dropdown_parent_2 > regions_dropdown > panel > panel_clip > listview > list_clip > list_box > player_provinces > list_box")
    for i = 0, list:ChildCount() - 1 do
        local child = UIComponent(list:Find(i))
        table.insert(rows, child)
    end

    table.sort(rows, function(a, b)
        local influenceA = tonumber(a:GetProperty("influence"))
        local influenceB = tonumber(b:GetProperty("influence"))

        if direction == activeSort.down then
            return influenceA < influenceB
        else
            return influenceA > influenceB
        end
    end)

    for k, v in pairs(rows) do
        list:Divorce(v:Address())
    end

    for k, v in pairs(rows) do
        list:Adopt(v:Address())
    end

    ui.repositionInfluenceTexts()
    currentActiveSort = direction
end

function ui.repositionInfluenceTexts()
    local list = _("dropdown_parent_2 > regions_dropdown > panel > panel_clip > listview > list_clip > list_box > player_provinces > list_box")

    for i = 0, list:ChildCount() - 1 do
        local child = UIComponent(list:Find(i))

        local iconPO = find_uicomponent(child, "icon_public_order")
        local influenceText = find_uicomponent(child, "mk_provinces_ui_influence_text")

        local x, y = iconPO:Position()
        influenceText:MoveTo(x - 35, y)
    end
end

function ui.buildButtons()
    debug("Build buttons")
    local arrowLeftCopy = _("dropdown_parent_2 > regions_dropdown > panel > panel_clip > listview > list_clip > list_box > player_provinces > headers > cycle_button_arrow_left")
    local arrowRightCopy = _("dropdown_parent_2 > regions_dropdown > panel > panel_clip > listview > list_clip > list_box > player_provinces > headers > cycle_button_arrow_right")
    local sortButtonResources = _("dropdown_parent_2 > regions_dropdown > panel > panel_clip > listview > list_clip > list_box > player_provinces > headers > sort_pooled_resource")
    local sortButtonCopy = _("dropdown_parent_2 > regions_dropdown > panel > panel_clip > listview > list_clip > list_box > player_provinces > headers > sort_happiness")

    local arrowLeft = UIComponent(arrowLeftCopy:CopyComponent("mk_provinces_ui_arrow_left"))
    local arrowRight = UIComponent(arrowRightCopy:CopyComponent("mk_provinces_ui_arrow_right"))
    local sortButton = UIComponent(arrowRightCopy:CopyComponent("mk_provinces_ui_sort_influence"))
    sortButton:SetImagePath("ui/skins/default/parchment_sort_btn_down.png")

    local x, y = sortButtonCopy:Position()
    sortButtonCopy:MoveTo(x - 8, y)

    x, y = sortButtonCopy:Position()
    arrowLeft:MoveTo(x - 20, y)
    arrowRight:MoveTo(x + 20, y)

    sortButton:MoveTo(x, y)
    sortButton:SetVisible(false)
    sortButton:SetTooltipText("Sort by Influence", true)

    local listener = "mk_provinces_ui_arrow_left_listener"
    core:remove_listener(listener)
    core:add_listener(
        listener,
        "ComponentLClickUp",
        function(context) return arrowLeft == UIComponent(context.component) end,
        function()
            ui.switchDisplay("left")
        end,
        true
    )

    listener = "mk_provinces_ui_arrow_right_listener"
    core:remove_listener(listener)
    core:add_listener(
        listener,
        "ComponentLClickUp",
        function(context) return arrowRight == UIComponent(context.component) end,
        function()
            ui.switchDisplay("right")
        end,
        true
    )

    listener = "mk_provinces_ui_sort_listener"
    core:remove_listener(listener)
    core:add_listener(
        listener,
        "ComponentLClickUp",
        function(context) return sortButton == UIComponent(context.component) end,
        function()
            ui.sort()
        end,
        true
    )

    local listBox = _("dropdown_parent_2 > regions_dropdown > panel > panel_clip > listview > list_clip > list_box > player_provinces > list_box")
    listener = "mk_provinces_ui_sort_cycle_button_arrow_left_listener"
    core:remove_listener(listener)
    core:add_listener(
        listener,
        "ComponentLClickUp",
        function(context) 
            local uic = UIComponent(context.component)
            local parent = UIComponent(uic:Parent())
            local id = uic:Id()

            local rowEntryStart, rowEntryEnd = string.find(id, "row_entry")
            local isRowEntry = rowEntryStart == 1 and parent == listBox

            debug("row entry", rowEntryStart, isRowEntry, id)

            return arrowLeftCopy == uic or arrowRightCopy == uic or sortButtonResources == uic or isRowEntry
        end,
        function()
            debug("repositionInfluenceTexts on old button click")
            cm:callback(function()
                ui.repositionInfluenceTexts()            
            end, 0.1)
        end,
        true
    )
end

function ui.build()
    debug("Build UI")

    data = getProvincesData()
    ui.buildButtons()
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