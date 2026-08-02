-- =========================================================================
-- AUTOROLL MODULAR CORE - ENGINECORE.LUA (CALCULATIONS & LOOT LOGIC)
-- =========================================================================
handledRolls = handledRolls or {}
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

function ProcessLootRoll(rollID, itemLink)
    if not AutoRollConfig or not AutoRollConfig.charSettings then return end
    local charKey = GetCharacterUniqueKey() local cCfg = AutoRollConfig.charSettings[charKey]
    if not cCfg or not cCfg.enabled or handledRolls[rollID] then return end
    local playerClass = GetPlayerClassProfile()
    local itemName, _, itemRarity, _, _, itemType, itemSubClass, _, itemEquipLoc = GetItemInfo(itemLink)
    if not itemName then return end
    local rarityKey = nil
    if itemRarity == 2 then rarityKey = "Green" elseif itemRarity == 3 then rarityKey = "Blue" elseif itemRarity == 4 then rarityKey = "Purple" end
    if not rarityKey and itemLink then
        if string.find(itemLink, "|cff1eff00") then rarityKey = "Green"
        elseif string.find(itemLink, "|cff0070dd") or string.find(itemLink, "|cff0070d8") then rarityKey = "Blue"
        elseif string.find(itemLink, "|ffa335ee") then rarityKey = "Purple" end
    end
    if itemType == "Weapon" then
        local lowerSub = string.lower(itemSubClass or "") local lowerEquip = string.lower(itemEquipLoc or "") local lowerName = string.lower(itemName or "") local isolatedSubClass = nil
        for i = 1, scannerTooltip:NumLines() do
            local leftLine = _G["AutoRollScannerTooltipTextLeft" .. i] local rightLine = _G["AutoRollScannerTooltipTextRight" .. i]
            local leftText = leftLine and leftLine:GetText() or "" local rightText = rightLine and rightLine:GetText() or "" local combined = string.lower(leftText .. " " .. rightText)
            if string.find(combined, "dagger") then isolatedSubClass = "Daggers" break
            elseif string.find(combined, "staff") or string.find(combined, "staves") then isolatedSubClass = "Staves" break
            elseif string.find(combined, "polearm") then isolatedSubClass = "Polearms" break
            elseif string.find(combined, "wand") then isolatedSubClass = "Wands" break
            elseif string.find(combined, "fist") or string.find(combined, "claw") or string.find(combined, "knuckles") then isolatedSubClass = "Fist Weapons" break
            elseif string.find(combined, "gun") or string.find(combined, "rifle") or string.find(combined, "musket") or string.find(combined, "shotgun") then isolatedSubClass = "Guns" break
            elseif string.find(combined, "crossbow") then isolatedSubClass = "Crossbows" break
            elseif string.find(combined, "bow") then isolatedSubClass = "Bows" break
            elseif string.find(combined, "thrown") or string.find(combined, "throwing") then isolatedSubClass = "Thrown" break
            elseif string.find(combined, "mace") then isolatedSubClass = (string.find(lowerSub, "two") or string.find(combined, "2h")) and "Two-Handed Maces" or "One-Handed Maces" break
            elseif string.find(combined, "sword") then isolatedSubClass = (string.find(lowerSub, "two") or string.find(combined, "2h")) and "Two-Handed Swords" or "One-Handed Swords" break
            elseif string.find(combined, "axe") then isolatedSubClass = (string.find(lowerSub, "two") or string.find(combined, "2h")) and "Two-Handed Axes" or "One-Handed Axes" break end
        end
        if not isolatedSubClass then
            if string.find(lowerName, "gun") or string.find(lowerName, "rifle") or string.find(lowerName, "blunderbuss") or string.find(lowerName, "musket") then isolatedSubClass = "Guns"
            elseif string.find(lowerName, "crossbow") then isolatedSubClass = "Crossbows"
            elseif string.find(lowerName, "bow") or string.find(lowerName, "longbow") then isolatedSubClass = "Bows"
            elseif string.find(lowerName, "thrown") or string.find(lowerName, "throwing") or string.find(lowerName, "hatchet") then isolatedSubClass = "Thrown" end
        end
        if isolatedSubClass then itemSubClass = isolatedSubClass end
    end
    if rarityKey and cCfg.quality then
        local qChoice = 0 if cCfg.bulkQuality and cCfg.bulkQuality > 0 then qChoice = cCfg.bulkQuality else qChoice = cCfg.quality[rarityKey] or 0 end
        if qChoice > 0 then if ExecuteRollChoice(rollID, qChoice, itemLink, "Quality Filter: " .. rarityKey) then return end end
    end
    if cCfg.autoGreedUnusable and IsItemUnusable(itemLink) then if ExecuteRollChoice(rollID, 2, itemLink, "Unusable Red Text") then return end end
    if (itemType == "Armor" or itemSubClass == "Shields") and cCfg.armor then
        local aChoice = 0 if cCfg.bulkArmor and cCfg.bulkArmor > 0 then aChoice = cCfg.bulkArmor else aChoice = cCfg.armor[itemSubClass] or 0 end
        if aChoice > 0 then if ExecuteRollChoice(rollID, aChoice, itemLink, "Armor Filter: " .. itemSubClass) then return end end
    end
    if itemType == "Weapon" or itemSubClass == "Shields" or itemEquipLoc == "INVTYPE_HOLDABLE" or itemEquipLoc == "INVTYPE_RANGED" or itemEquipLoc == "INVTYPE_RANGEDRIGHT" or itemSubClass == "Guns" or itemSubClass == "Bows" or itemSubClass == "Crossbows" or itemSubClass == "Thrown" then
        if cCfg.weapons and cCfg.weapons[itemSubClass] and cCfg.weapons[itemSubClass] > 0 then if ExecuteRollChoice(rollID, cCfg.weapons[itemSubClass], itemLink, "Weapon Auto Filter: " .. itemSubClass) then return end end
        local droppedScore = CalculateItemScore(itemLink)
        if alertTextString then alertTextString:SetText("|cFFFFD100Weapon Dropped! Manual Choice Required|r") end
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFD100[AutoRoll Override]|r Weapon piece dropped: %s (|cFF00FF00Score: %.2f|r). Auto-rolling paused so you can choose manually!", itemLink, droppedScore)) return 
    end
    if itemType == "Weapon" and cCfg.weapons then
        local wChoice = 0 if cCfg.bulkWeapons and cCfg.bulkWeapons > 0 then wChoice = cCfg.bulkWeapons else wChoice = cCfg.weapons[itemSubClass] or 0 end
        if wChoice > 0 then if ExecuteRollChoice(rollID, wChoice, itemLink, "Weapon Filter: " .. itemSubClass) then return end end
    end
    if cCfg.statModuleEnabled and itemEquipLoc and SLOT_MAP[itemEquipLoc] and AutoRollConfig.classProfiles and AutoRollConfig.classProfiles[playerClass] then
        local slotID = SLOT_MAP[itemEquipLoc] local equippedItemLink = GetInventoryItemLink("player", slotID)
        local droppedScore = CalculateItemScore(itemLink) local equippedScore = equippedItemLink and CalculateItemScore(equippedItemLink) or 0
        if droppedScore > equippedScore then 
            if alertTextString then alertTextString:SetText("|cFF3399FFRoll NEED! Stat Upgrade!|r") end
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF3399FF[AutoRoll Alert]|r %s (|cFF00FF00Weight Score: %.2f|r) beats Equipped (|cFFFF0000Score: %.2f|r). Suggesting NEED!", itemLink, droppedScore, equippedScore))
        end
    end
end

function IsItemUnusable(itemLink)
    if not itemLink then return false, "StandardGear" end
    local _, _, _, _, _, itemType, itemSubClass = GetItemInfo(itemLink)
    if itemType == "Weapon" then
        local lowerSub = string.lower(itemSubClass or "")
        if lowerSub == "crossbow" or lowerSub == "crossbows" or lowerSub == "bows" or lowerSub == "bow" then return true, "StandardGear" end
    end
    scannerTooltip:SetOwner(WorldFrame, "ANCHOR_NONE") scannerTooltip:ClearLines() scannerTooltip:SetHyperlink(itemLink)
    local unusable, isRecipeItem, isAlreadyKnown, hasUnusableProfession = false, (itemType == "Recipe"), false, false
    local myProfessions = {}
    for i = 1, 100 do
        local name = GetSpellName(i, "spell") if not name then break end
        local lowerName = string.lower(name)
        if string.find(lowerName, "alchemy") then myProfessions["alchemy"] = true
        elseif string.find(lowerName, "blacksmithing") then myProfessions["blacksmithing"] = true
        elseif string.find(lowerName, "leatherworking") then myProfessions["leatherworking"] = true
        elseif string.find(lowerName, "tailoring") then myProfessions["tailoring"] = true
        elseif string.find(lowerName, "engineering") then myProfessions["engineering"] = true
        elseif string.find(lowerName, "enchanting") then myProfessions["enchanting"] = true
        elseif string.find(lowerName, "jewelcrafting") then myProfessions["jewelcrafting"] = true
        elseif string.find(lowerName, "cooking") then myProfessions["cooking"] = true
        elseif string.find(lowerName, "first aid") then myProfessions["first aid"] = true end
    end
    for i = 1, scannerTooltip:NumLines() do
        local leftLine = _G["AutoRollScannerTooltipTextLeft" .. i]
        if leftLine then
            local text = leftLine:GetText() or "" local r, g, b = leftLine:GetTextColor() local lowerText = string.lower(text)
            if isRecipeItem and (string.find(lowerText, "already known") or string.find(lowerText, "already learnt")) then isAlreadyKnown = true end
            if r and g and b and r > 0.9 and g < 0.2 and b < 0.2 and text ~= "" then
                if isRecipeItem then
                    local foundMatchingOwnedProf = false
                    for profName in pairs(myProfessions) do if string.find(lowerText, profName) then foundMatchingOwnedProf = true break end end
                    if not foundMatchingOwnedProf and string.find(lowerText, "requires") then hasUnusableProfession = true end
                elseif not string.find(lowerText, "level") and not string.find(lowerText, "requires") then unusable = true end
            end
            if text ~= "" and not isRecipeItem then
                if string.find(lowerText, "|cffff0000") and not string.find(lowerText, "level") and not string.find(lowerText, "requires") then unusable = true
                elseif string.find(lowerText, "can't equip") or string.find(lowerText, "cannot equip") then unusable = true end
            end
        end
    end
    scannerTooltip:Hide()
    if isRecipeItem then
        if isAlreadyKnown or hasUnusableProfession then return true, "KnownOrUnusableRecipe"
        else return false, "UnknownUsableRecipe" end
    end
    return unusable, "StandardGear"
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
-- Cross-File Interface Trigger: Allows InterfaceGUI.lua to toggle frames smoothly across file borders
function ToggleUI()
    if not settingsFrame then 
        BuildUI() 
    end
    if settingsFrame then 
        if settingsFrame:IsShown() then 
            settingsFrame:Hide() 
            if statFrame then statFrame:Hide() end 
            if weightFrame then weightFrame:Hide() end 
        else 
            settingsFrame:Show() 
        end 
    end
end

local isLoaded = false
function InitializeAddon() 
    if isLoaded then return end isLoaded = true 
    if type(AutoRollConfig) ~= "table" or not AutoRollConfig.classProfiles then AutoRollConfig = nil end
    if not AutoRollConfig then AutoRollConfig = defaults 
    else 
        if not AutoRollConfig.charSettings then AutoRollConfig.charSettings = {} end
        for k, v in pairs(defaults) do if AutoRollConfig[k] == nil then AutoRollConfig[k] = v end end 
    end 
    local charKey = GetCharacterUniqueKey()
    if not AutoRollConfig.charSettings[charKey] then AutoRollConfig.charSettings[charKey] = GetBlankCharSettings() end
    local playerClass = GetPlayerClassProfile() local isProfileBlank = true
    if AutoRollConfig.classProfiles[playerClass] then
        for k, val in pairs(AutoRollConfig.classProfiles[playerClass]) do if val and val ~= 0 then isProfileBlank = false break end end
    end
    if not AutoRollConfig.classProfiles[playerClass] or isProfileBlank then
        if AutoRoll_ClassTemplates then
            local foundTemplate = nil
            for templateName, templateData in pairs(AutoRoll_ClassTemplates) do
                if string.lower(templateName) == string.lower(playerClass) then foundTemplate = templateData break end
            end
            if foundTemplate then
                AutoRollConfig.classProfiles[playerClass] = {}
                for k, v in pairs(foundTemplate) do AutoRollConfig.classProfiles[playerClass][k] = v end
            else AutoRollConfig.classProfiles[playerClass] = GetBlankStatTable() end
        else AutoRollConfig.classProfiles[playerClass] = GetBlankStatTable() end
    end
    if AutoRollConfig.classProfiles[playerClass]["Ranged Attack Power"] == nil then AutoRollConfig.classProfiles[playerClass]["Ranged Attack Power"] = 0 end
    if AutoRollConfig.classProfiles and AutoRollConfig.classProfiles[playerClass] then
        for k, v in pairs(AutoRollConfig.classProfiles[playerClass]) do tempWeights[k] = tonumber(v) or 0 end
    end
    BuildLauncherButton() 
end

mainFrame = CreateFrame("Frame")
mainFrame:RegisterEvent("ADDON_LOADED") mainFrame:RegisterEvent("PLAYER_LOGIN")
mainFrame:RegisterEvent("START_LOOT_ROLL") mainFrame:RegisterEvent("CANCEL_LOOT_ROLL")
mainFrame:SetScript("OnEvent", function(self, event, arg1) 
    if event == "ADDON_LOADED" and arg1 == "AutoRoll" then pcall(InitializeAddon) 
    elseif event == "PLAYER_LOGIN" then pcall(InitializeAddon) 
    elseif event == "START_LOOT_ROLL" then 
        local rollID = arg1 local itemLink = GetLootRollItemLink(rollID) handledRolls[rollID] = false 
        if itemLink then 
            local itemName = GetItemInfo(itemLink)
            if not itemName then
                local retryFrame = CreateFrame("Frame") local elapsed = 0
                retryFrame:SetScript("OnUpdate", function(f, delta)
                    elapsed = elapsed + delta
                    if GetItemInfo(itemLink) then pcall(ProcessLootRoll, rollID, itemLink) retryFrame:SetScript("OnUpdate", nil)
                    elseif elapsed > 2.0 then retryFrame:SetScript("OnUpdate", nil) end
                end)
            else pcall(ProcessLootRoll, rollID, itemLink) end
        end 
    elseif event == "CANCEL_LOOT_ROLL" then handledRolls[arg1] = nil end 
end)
