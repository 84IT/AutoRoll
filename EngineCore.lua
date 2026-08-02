-- =========================================================================
-- AUTOROLL MODULAR CORE - ENGINECORE.LUA (CALCULATIONS & LOOT LOGIC)
-- =========================================================================
handledRolls = {}
alertTextString = nil
settingsFrame, statFrame, weightFrame = nil, nil, nil
tempWeights = {}

SLOT_MAP = {
    ["INVTYPE_HEAD"] = 1, ["Head"] = 1, ["INVTYPE_NECK"] = 2, ["Neck"] = 2,
    ["INVTYPE_SHOULDER"] = 3, ["Shoulder"] = 3, ["Shoulders"] = 3,
    ["INVTYPE_CHEST"] = 5, ["Chest"] = 5, ["Robe"] = 5, ["INVTYPE_ROBE"] = 5,
    ["INVTYPE_WAIST"] = 6, ["Waist"] = 6, ["Belt"] = 6, ["INVTYPE_LEGS"] = 7,
    ["Legs"] = 7, ["INVTYPE_FEET"] = 8, ["Feet"] = 8, ["Boots"] = 8,
    ["INVTYPE_WRIST"] = 9, ["Wrist"] = 9, ["Bracers"] = 9, ["INVTYPE_HANDS"] = 10,
    ["Hands"] = 10, ["Gloves"] = 10, ["Gauntlets"] = 10, ["INVTYPE_FINGER"] = 11,
    ["Finger"] = 11, ["Ring"] = 11, ["INVTYPE_TRINKET"] = 12, ["Trinket"] = 12,
    ["INVTYPE_CLOAK"] = 15, ["Back"] = 15, ["Cloak"] = 15, ["INVTYPE_WEAPON"] = 16,
    ["One-Hand"] = 16, ["One-Handed"] = 16, ["INVTYPE_2HWEAPON"] = 16,
    ["Two-Hand"] = 16, ["Two-Handed"] = 16, ["INVTYPE_WEAPONMAINHAND"] = 16,
    ["Main-Hand"] = 16, ["Main Hand"] = 16, ["INVTYPE_SHIELD"] = 17,
    ["Shield"] = 17, ["INVTYPE_WEAPONOFFHAND"] = 17, ["Off-Hand"] = 17,
    ["Off Hand"] = 17, ["INVTYPE_HOLDABLE"] = 17, ["Held In Off-Hand"] = 17,
    ["INVTYPE_RANGED"] = 18, ["Ranged"] = 18, ["INVTYPE_RANGEDRIGHT"] = 18
}

STAT_PATTERNS = {
    { key = "Strength", pats = { "%+(%d+)%s*Strength", "%+(%d+)%s*strength" } },
    { key = "Agility", pats = { "%+(%d+)%s*Agility", "%+(%d+)%s*agility" } },
    { key = "Stamina", pats = { "%+(%d+)%s*Stamina", "%+(%d+)%s*stamina" } },
    { key = "Intellect", pats = { "%+(%d+)%s*Intellect", "%+(%d+)%s*intellect" } },
    { key = "Spirit", pats = { "%+(%d+)%s*Spirit", "%+(%d+)%s*spirit" } },
    { key = "Crit", pats = { "critical strike rating by (%d+)", "critical strike rating", "Critical Strike", "crit rating", "Crit Rating", "Improves critical strike rating by (%d+)" } },
    { key = "Hit", pats = { "hit rating by (%d+)", "hit rating", "Hit Rating", "Improves hit rating by (%d+)" } },
    { key = "Haste", pats = { "haste rating by (%d+)", "haste rating", "Haste Rating", "Improves haste rating by (%d+)" } },
    { key = "Ranged Attack Power", pats = { "ranged attack power by (%d+)", "Ranged Attack Power", "ranged attack power" } },
    { key = "Attack Power", pats = { "attack power by (%d+)", "%+(%d+)%s*Attack Power", "Attack Power" } },
    { key = "Spell Power", pats = { "spell power by (%d+)", "spell power", "Spell Power", "Increases spell power by (%d+)" } },
    { key = "Spell Damage", pats = { "spell damage by (%d+)", "Increases spell damage by (%d+)" } },
    { key = "Armor Pen", pats = { "armor penetration rating by (%d+)", "armor penetration", "Armor Pen", "Improves armor penetration rating by (%d+)" } },
    { key = "Spell Pen", pats = { "spell penetration by (%d+)", "spell penetration", "Spell Pen", "Increases spell penetration by (%d+)" } },
    { key = "Expertise", pats = { "expertise rating by (%d+)", "expertise rating", "Expertise", "Improves expertise rating by (%d+)" } },
    { key = "Weapon DPS", pats = { "((%d+%.?%d*)) damage per second", "((%d+%.?%d*)) DPS" } },
    { key = "Ranged DPS", pats = { "Ranged.*((%d+%.?%d*)) damage per second" } },
    { key = "Resilience", pats = { "resilience rating by (%d+)", "resilience rating", "Resilience" } },
    { key = "Mana per 5", pats = { "mana per 5 sec", "Restores (%d+) mana per 5", "mana per 5 seconds" } }
}
function GetBlankStatTable()
    return {
        ["Strength"] = 0, ["Agility"] = 0, ["Stamina"] = 0, ["Intellect"] = 0, ["Spirit"] = 0,
        ["Crit"] = 0, ["Hit"] = 0, ["Haste"] = 0, ["Resilience"] = 0, ["Mana per 5"] = 0,
        ["Weapon DPS"] = 0, ["Ranged DPS"] = 0, ["Attack Power"] = 0, ["Ranged Attack Power"] = 0, ["Spell Power"] = 0, 
        ["Spell Damage"] = 0, ["Armor Pen"] = 0, ["Spell Pen"] = 0, ["Expertise"] = 0
    }
end

function GetBlankCharSettings()
    return {
        enabled = true, timeThreshold = 5, autoGreedUnusable = true, bulkArmor = 0, bulkWeapons = 0, bulkQuality = 0,
        armor = { ["Cloth"] = 0, ["Leather"] = 0, ["Mail"] = 0, ["Plate"] = 0, ["Shields"] = 0 },
        weapons = { ["Daggers"] = 0, ["One-Handed Swords"] = 0, ["Two-Handed Swords"] = 0, ["One-Handed Maces"] = 0, ["Two-Handed Maces"] = 0, ["One-Handed Axes"] = 0, ["Two-Handed Axes"] = 0, ["Staves"] = 0, ["Fist Weapons"] = 0, ["Polearms"] = 0, ["Wands"] = 0, ["Bows"] = 0, ["Guns"] = 0, ["Crossbows"] = 0, ["Thrown"] = 0 },
        quality = { ["Green"] = 0, ["Blue"] = 0, ["Purple"] = 0 }, statModuleEnabled = false
    }
end

defaults = { buttonX = 0, buttonY = 150, classProfiles = {}, charSettings = {} }
scannerTooltip = CreateFrame("GameTooltip", "AutoRollScannerTooltip", nil, "GameTooltipTemplate")

function GetPlayerClassProfile()
    local localClassName, _ = UnitClass("player")
    if not localClassName or localClassName == "" then return "Unknown" end
    if localClassName == "Knight Of Xoroth" then localClassName = "Knight of Xoroth" end
    return localClassName
end

function GetCharacterUniqueKey()
    local name = UnitName("player") local realm = GetRealmName()
    return (name and realm) and (name .. " - " .. realm) or "UnknownCharacter"
end

function CalculateItemScore(itemLink)
    local playerClass = GetPlayerClassProfile()
    if not itemLink or not AutoRollConfig or not AutoRollConfig.classProfiles or not AutoRollConfig.classProfiles[playerClass] then return 0 end
    scannerTooltip:SetOwner(WorldFrame, "ANCHOR_NONE") scannerTooltip:ClearLines() scannerTooltip:SetHyperlink(itemLink)
    local totalScore = 0
    for i = 1, scannerTooltip:NumLines() do
        local leftLine = _G["AutoRollScannerTooltipTextLeft" .. i] local rightLine = _G["AutoRollScannerTooltipTextRight" .. i]
        local rawTextLeft = leftLine and leftLine:GetText() or "" local rawTextRight = rightLine and rightLine:GetText() or ""
        if (rawTextLeft ~= "" and not string.find(rawTextLeft, "Set:") and not string.find(rawTextLeft, "%(%d+%)%s*Set")) or (rawTextRight ~= "" and not string.find(rawTextRight, "Set:")) then
            local combinedText = rawTextLeft .. "\n" .. rawTextRight
            for text in string.gmatch(combinedText, "[^\r\n]+") do
                for _, item in ipairs(STAT_PATTERNS) do
                    local weight = AutoRollConfig.classProfiles[playerClass][item.key] or 0
                    if weight > 0 then
                        local cleanPat = nil
                        if item.key == "Strength" then cleanPat = "(%d+)%s*[Ss]trength"
                        elseif item.key == "Agility" then cleanPat = "(%d+)%s*[Aa]gility"
                        elseif item.key == "Stamina" then cleanPat = "(%d+)%s*[Ss]tamina"
                        elseif item.key == "Intellect" then cleanPat = "(%d+)%s*[Ii]ntellect"
                        elseif item.key == "Spirit" then cleanPat = "(%d+)%s*[Ss]pirit"
                        elseif item.key == "Haste" then cleanPat = "(%d+)%s*[Hh]aste" end
                        if cleanPat then
                            local match = string.match(text, cleanPat)
                            if match and tonumber(match) then totalScore = totalScore + (tonumber(match) * weight) end
                        else
                            for _, pattern in ipairs(item.pats) do
                                local cleanPattern = pattern:gsub("%%%+", ""):gsub("%^", "")
                                local match = string.match(text, cleanPattern)
                                if match and tonumber(match) then totalScore = totalScore + (tonumber(match) * weight) break end
                            end
                        end
                    end
                end
            end
        end
    end
    scannerTooltip:Hide() return totalScore
end

function IsItemUnusable(itemLink)
    if not itemLink then return false end
    local _, _, _, _, _, itemType, itemSubClass = GetItemInfo(itemLink)
    if itemType == "Weapon" then
        local lowerSub = string.lower(itemSubClass or "")
        if lowerSub == "crossbow" or lowerSub == "crossbows" or lowerSub == "bows" or lowerSub == "bow" then
            return true
        end
    end
    scannerTooltip:SetOwner(WorldFrame, "ANCHOR_NONE") scannerTooltip:ClearLines() scannerTooltip:SetHyperlink(itemLink)
    local unusable = false
    for i = 1, scannerTooltip:NumLines() do
        local leftLine = _G["AutoRollScannerTooltipTextLeft" .. i]
        if leftLine then
            local text = leftLine:GetText() or "" local r, g, b = leftLine:GetTextColor()
            if r and g and b and r > 0.9 and g < 0.2 and b < 0.2 and text ~= "" then
                if not string.find(string.lower(text), "level") and not string.find(string.lower(text), "requires") then
                    unusable = true break
                end
            end
            if text ~= "" then
                local lowerText = string.lower(text)
                if string.find(lowerText, "|cffff0000") and not string.find(lowerText, "level") and not string.find(lowerText, "requires") then
                    unusable = true break
                elseif string.find(lowerText, "can't equip") or string.find(lowerText, "cannot equip") then
                    unusable = true break
                end
            end
        end
    end
    scannerTooltip:Hide() return unusable
end

function CloseActiveLootFrame(rollID)
    for i = 1, 4 do
        local rollFrame = _G["GroupLootFrame" .. i]
        if rollFrame and rollFrame:IsShown() and rollFrame.rollID == rollID then
            rollFrame:Hide() break
        end
    end
end

function ExecuteRollChoice(rollID, choiceCode, itemLink, reason)
    if choiceCode and choiceCode >= 1 and choiceCode <= 3 then
        handledRolls[rollID] = true
        RollOnLoot(rollID, choiceCode == 3 and 0 or choiceCode)
        CloseActiveLootFrame(rollID)
        local rollNames = { "Need", "Greed", "Pass" }
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[AutoRoll]|r Auto-" .. rollNames[choiceCode] .. ": " .. itemLink .. " (" .. reason .. ")")
        return true
    end
    return false
end
