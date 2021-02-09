local debug = require("tw-debug")("mk:provinces:ui")

local effectsRecords = require("provinces/db/effects")
local effectBundlesToEffectsRecords = require("provinces/db/effect_bundles_to_effects_junctions")
local provincialsRecords = require("provinces/db/provincial_initiative_records")

local function getEffectsForBundle(key)
    local result = {}
    local effects = {}
    
    for i = 1, #effectBundlesToEffectsRecords do
        local row = effectBundlesToEffectsRecords[i]
        if key == row.effect_bundle_key then
            table.insert(effects, row)
        end
    end

    for i = 1, #effects do
        local row = effects[i]

        for j = 1, #effectsRecords do
            local effect = effectsRecords[j]
 
            if row.effect_key == effect.effect then
                table.insert(result, {
                    key = effect.effect,
                    value = row.value,
                    scope = row.effect_scope,
                    category = effect.category,
                    icon = effect.icon,
                    icon_negative = effect.icon_negative,
                    is_positive_value_good = effect.is_positive_value_good,
                })
            end
        end

    end

    return result
end

local function getLocalisedString(key)
    local text = effect.get_localised_string(key)
    if text == "" then
        return text
    end

    local tr = string.match(text, "{{tr:(.+)}}")
    if not tr then
        return text
    end

    local trText = effect.get_localised_string("ui_text_replacements_localised_text_" .. tr)

    trText = string.gsub(trText, "%%", "%%%%")
    local result = string.gsub(text, "{{tr:" .. tr .. "}}", trText)
    return result
end

local function getTooltipTextsForEffects(effects, edict)
    local texts = {}

    for i = 1, #effects do
        local effect = effects[i]
        local desc = getLocalisedString("effects_description_" .. effect.key)
        local value = effect.value
        local isPositiveValueGood = effect.is_positive_value_good
        local icon = isPositiveValueGood and effect.icon or effect.icon_negative
        local scope = getLocalisedString("campaign_effect_scopes_localised_text_" .. effect.scope)
        local color = "green"

        if isPositiveValueGood then
            color = value >= 0 and "green" or "red"
        else
            color = value <= 0 and "green" or "red"
        end

        if edict == "troy_edict_organize_games" then
            local faction = cm:get_faction(cm:get_local_faction())
            local aphroditeCultLevel = faction:pooled_resource("troy_god_attitude_aphrodite"):value()

            if aphroditeCultLevel >= 50 then
                value = value * 3
            end
        end

        local descPattern = string.gsub(desc, "%+n", "%s")
        descPattern = string.gsub(descPattern, "%%s%%", "%%s%%%%")  

        -- scope = string.gsub(scope, "\n ", "\n [[img:ui/skins/default/1x1_transparent_white.png]][[/img]]")
        local escapedDesc = string.format(descPattern, value > 0 and "+" .. value or value)
        local text = string.format("[[img:%s]][[/img]] [[col:%s]]%s%s[[/col]]", "ui/campaign ui/effect_bundles/large/" .. icon, color, escapedDesc, scope)

        table.insert(texts, text)
    end


    return texts
end

local function getEdictTooltip(edict)
    if not edict then
        return ""
    end
    
    local row = provincialsRecords[edict]
    if not row then
        return ""
    end

    local effectBundleKey = row.effect_bundle

    local effects = getEffectsForBundle(effectBundleKey)
    local texts = getTooltipTextsForEffects(effects, edict)
    local result = effect.get_localised_string("provincial_initiative_records_localised_name_" .. edict) .. "\n\n"
    result = result .. table.concat(texts, "\n")

    return result
end

return {
    getEdictTooltip = getEdictTooltip,
    getTooltipTextsForEffects = getTooltipTextsForEffects,
    getLocalisedString = getLocalisedString,
    getEffectsForBundle = getEffectsForBundle
}