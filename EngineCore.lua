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
                        if item.key == "Strength" then cleanPat = "%+(%d+)%s*[Ss]trength"
                        elseif item.key == "Agility" then cleanPat = "%+(%d+)%s*[Aa]gility"
                        elseif item.key == "Stamina" then cleanPat = "%+(%d+)%s*[Ss]tamina"
                        elseif item.key == "Intellect" then cleanPat = "%+(%d+)%s*[Ii]ntellect"
                        elseif item.key == "Spirit" then cleanPat = "%+(%d+)%s*[Ss]pirit"
                        elseif item.key == "Haste" then cleanPat = "%+(%d+)%s*[Hh]aste" end

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
    -- =========================================================================
    -- PREFIX ANCHOR SHIELD: Prevents multiline set-text from triggering false values
    -- =========================================================================
    if not rarityKey and itemLink then
        -- The '^' anchor restricts the pattern matching engine strictly to the start of strings
        if string.match(itemLink, "^|cff1eff00") then rarityKey = "Green"
        elseif string.match(itemLink, "^|cff0070dd") or string.match(itemLink, "^|cff0070d8") then rarityKey = "Blue"
        elseif string.match(itemLink, "^|cffa335ee") then rarityKey = "Purple" end
    end

    -- =========================================================================
    -- PRIORITY 0: RECIPE INTERCEPTOR (Always fires first on unknown formulas)
    -- =========================================================================
    local isRecipeItem = (itemType == "Recipe")
    local isUnusable, recipeState = false, "StandardGear"
    if isRecipeItem then isUnusable, recipeState = IsItemUnusable(itemLink) end
    if isRecipeItem and recipeState == "UnknownUsableRecipe" then
        if alertTextString then alertTextString:SetText("|cFF3399FFRecipe Sniper: NEED|r") end
        if ExecuteRollChoice(rollID, 1, itemLink, "Unknown Usable Recipe") then return end
    end

    -- =========================================================================
    -- PRIORITY 1: HARD BLOCK USABILITY SHIELD (Instantly drops unwearable gear)
    -- =========================================================================
    if not isRecipeItem then isUnusable = IsItemUnusable(itemLink) end
    if isUnusable then
        -- Auto-greeds or passes unwearable gear immediately before analyzing any configuration stats
        local fallbackAction = cCfg.autoGreedUnusable and 2 or 3
        local fallbackReason = cCfg.autoGreedUnusable and "Unusable Greed Catch" or "Unusable Pass Exclusion"
        if ExecuteRollChoice(rollID, fallbackAction, itemLink, fallbackReason) then return end
    end

        -- =========================================================================
    -- PRIORITY 2: SMART STATS UPGRADE TRACKER (Prioritizes item slot upgrades)
    -- =========================================================================
    if cCfg.statModuleEnabled and itemEquipLoc and SLOT_MAP[itemEquipLoc] and AutoRollConfig.classProfiles and AutoRollConfig.classProfiles[playerClass] then
        local slotID = SLOT_MAP[itemEquipLoc] local equippedItemLink = GetInventoryItemLink("player", slotID)
        local droppedScore = CalculateItemScore(itemLink) local equippedScore = equippedItemLink and CalculateItemScore(equippedItemLink) or 0
        if droppedScore > equippedScore then 
            if alertTextString then alertTextString:SetText("|cFF3399FFRoll NEED! Stat Upgrade!|r") end
            if ExecuteRollChoice(rollID, 1, itemLink, string.format("Upgrade Over Equipped: +%.2f Pts", droppedScore - equippedScore)) then return end
        end
    end

    -- =========================================================================
    -- PRIORITY 3: SPECIFIC TYPE OVERRIDES (Evaluates custom checkbox configurations)
    -- =========================================================================
    if (itemType == "Armor" or itemSubClass == "Shields") and cCfg.armor then
        local aChoice = 0 if cCfg.bulkArmor and cCfg.bulkArmor > 0 then aChoice = cCfg.bulkArmor else aChoice = cCfg.armor[itemSubClass] or 0 end
        if aChoice > 0 then if ExecuteRollChoice(rollID, aChoice, itemLink, "Armor Filter: " .. itemSubClass) then return end end
    end
    if itemType == "Weapon" or itemSubClass == "Shields" or itemEquipLoc == "INVTYPE_HOLDABLE" or itemEquipLoc == "INVTYPE_RANGED" or itemEquipLoc == "INVTYPE_RANGEDRIGHT" or itemSubClass == "Guns" or itemSubClass == "Bows" or itemSubClass == "Crossbows" or itemSubClass == "Thrown" then
        if cCfg.weapons and cCfg.weapons[itemSubClass] and cCfg.weapons[itemSubClass] > 0 then if ExecuteRollChoice(rollID, cCfg.weapons[itemSubClass], itemLink, "Weapon Auto Filter: " .. itemSubClass) then return end end
        local droppedScore = CalculateItemScore(itemLink)
        if alertTextString then alertTextString:SetText("|cFFFFD100Weapon dropped! Manual pause.|r") end
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFD100[AutoRoll Override]|r Weapon piece dropped: %s (|cFF00FF00Score: %.2f|r). Auto-rolling paused so you can choose manually!", itemLink, droppedScore)) return 
    end
    if itemType == "Weapon" and cCfg.weapons then
        local wChoice = 0 if cCfg.bulkWeapons and cCfg.bulkWeapons > 0 then wChoice = cCfg.bulkWeapons else wChoice = cCfg.weapons[itemSubClass] or 0 end
        if wChoice > 0 then if ExecuteRollChoice(rollID, wChoice, itemLink, "Weapon Filter: " .. itemSubClass) then return end end
    end

    -- =========================================================================
    -- PRIORITY 4: UNIVERSAL QUALITY CLEANUP FALLBACK (Broad background cushion)
    -- =========================================================================
    if rarityKey and cCfg.quality then
        local qChoice = 0 if cCfg.bulkQuality and cCfg.bulkQuality > 0 then qChoice = cCfg.bulkQuality else qChoice = cCfg.quality[rarityKey] or 0 end
        if qChoice > 0 then if ExecuteRollChoice(rollID, qChoice, itemLink, "Quality Filter: " .. rarityKey) then return end end
    end
end


function IsItemUnusable(itemLink)
    if not itemLink then return false, "StandardGear" end
    local _, _, _, _, _, itemType, itemSubClass, _, itemEquipLoc = GetItemInfo(itemLink)
    local isRecipeItem = (itemType == "Recipe")
    
    -- Safety Check: If background data isn't loaded yet, run a fast fallback sync scan
    if not playerArmorSkills or not playerWeaponSkills then ScanCharacterSkillsEngine() end
    
    local unusable = false
    local isAlreadyKnown = false
    local hasUnusableProfession = false
    
    -- 1. HARD IMPLEMENTED LIVE EQUIPMENT SKILLS SHIELD
    local lowSub = string.lower(itemSubClass or "")
    if itemType == "Armor" and lowSub ~= "cloth" and lowSub ~= "misc" and lowSub ~= "" then
        -- Direct Database Validation: If your character skills tab lacks this proficiency, flag it instantly
        if playerArmorSkills and not playerArmorSkills[lowSub] then unusable = true end
    elseif itemType == "Weapon" and lowSub ~= "" then
        -- Normalizes specific name variances cleanly into raw weapon class terms
        local matchedWpSkill = false
        if playerWeaponSkills then
            if playerWeaponSkills[lowSub] then matchedWpSkill = true
            elseif string.find(lowSub, "sword") and playerWeaponSkills["swords"] then matchedWpSkill = true
            elseif string.find(lowSub, "mace") and playerWeaponSkills["maces"] then matchedWpSkill = true
            elseif string.find(lowSub, "axe") and playerWeaponSkills["axes"] then matchedWpSkill = true
            elseif string.find(lowSub, "dagger") and playerWeaponSkills["daggers"] then matchedWpSkill = true
            elseif (string.find(lowSub, "staff") or string.find(lowSub, "staves")) and playerWeaponSkills["staves"] then matchedWpSkill = true
            elseif string.find(lowSub, "bow") and playerWeaponSkills["bows"] then matchedWpSkill = true
            elseif string.find(lowSub, "crossbow") and playerWeaponSkills["crossbows"] then matchedWpSkill = true
            elseif string.find(lowSub, "gun") and playerWeaponSkills["guns"] then matchedWpSkill = true
            elseif string.find(lowSub, "fist") and playerWeaponSkills["fist weapons"] then matchedWpSkill = true end
        end
        if not matchedWpSkill then unusable = true end
    end
    
    -- 2. DYNAMIC TEXT ANALYSIS LAYER (Validates Recipe Requirements and Already Known Flags)
    scannerTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    scannerTooltip:ClearLines()
    scannerTooltip:SetHyperlink(itemLink)
    
    for i = 1, scannerTooltip:NumLines() do
        local leftLine = _G["AutoRollScannerTooltipTextLeft" .. i]
        local rightLine = _G["AutoRollScannerTooltipTextRight" .. i]
        local textL = leftLine and leftLine:GetText() or ""
        local textR = rightLine and rightLine:GetText() or ""
        local lowerL = string.lower(textL)
        local lowerR = string.lower(textR)
        
        if isRecipeItem then
            if string.find(lowerL, "already known") or string.find(lowerL, "already learnt") then isAlreadyKnown = true end
            if string.find(lowerL, "requires") then
                local foundMatchingOwnedProf = false
                if playerProfessions then
                    for profName in pairs(playerProfessions) do
                        if string.find(lowerL, profName) then foundMatchingOwnedProf = true break end
                    end
                end
                if not foundMatchingOwnedProf then hasUnusableProfession = true end
            end
        else
            -- Non-Recipe Text Verification (Fallback text catches extra red alerts or explicit cannot equip notices)
            if leftLine and textL ~= "" then
                local r, g, b = leftLine:GetTextColor()
                if r and g and b and r > 0.9 and g < 0.2 and b < 0.2 then
                    if not string.find(lowerL, "level") and not string.find(lowerL, "requires") then unusable = true end
                end
                if string.find(lowerL, "|cffff0000") or string.find(lowerL, "can't equip") or string.find(lowerL, "cannot equip") then
                    if not string.find(lowerL, "level") and not string.find(lowerL, "requires") then unusable = true end
                end
            end
            if rightLine and textR ~= "" then
                local r, g, b = rightLine:GetTextColor()
                if r and g and b and r > 0.9 and g < 0.2 and b < 0.2 then
                    if not string.find(lowerR, "level") and not string.find(lowerR, "requires") then unusable = true end
                end
                if string.find(lowerR, "|cffff0000") or string.find(lowerR, "can't equip") or string.find(lowerR, "cannot equip") then
                    if not string.find(lowerR, "level") and not string.find(lowerR, "requires") then unusable = true end
                end
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
    -- Skills Cache Ingestion: Replaces old manual overrides with live server metrics
    ScanCharacterSkillsEngine()

    BuildLauncherButton() 
end

mainFrame = CreateFrame("Frame")
mainFrame:RegisterEvent("ADDON_LOADED") mainFrame:RegisterEvent("PLAYER_LOGIN")
mainFrame:RegisterEvent("START_LOOT_ROLL") mainFrame:RegisterEvent("CANCEL_LOOT_ROLL")
mainFrame:SetScript("OnEvent", function(self, event, arg1) 
    if event == "ADDON_LOADED" and arg1 == "AutoRoll" then pcall(InitializeAddon) 
    elseif event == "PLAYER_LOGIN" or event == "SKILL_LINES_CHANGED" then
        if event == "PLAYER_LOGIN" then
            -- Delayed Ignition Engine: Creates a clean 2-second buffer timer before booting core systems
            local delayFrame = CreateFrame("Frame")
            local totalElapsed = 0
            delayFrame:SetScript("OnUpdate", function(f, delta)
                totalElapsed = totalElapsed + delta
                if totalElapsed >= 2.0 then
                    pcall(InitializeAddon)
                    delayFrame:SetScript("OnUpdate", nil) -- Disposes timer frame safely from memory
                end
            end)
        else
            pcall(InitializeAddon)
        end
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


-- =========================================================================
-- SYSTEM SCANNER MODULE: Dynamically queries your native Skills Tab live
-- =========================================================================
playerProfessions = {}
playerArmorSkills = {}
playerWeaponSkills = {}

function ScanCharacterSkillsEngine()
    playerProfessions = {} playerArmorSkills = {} playerWeaponSkills = {}
    local currentHeader = ""
    for i = 1, 200 do
        local skillName, isHeader, _, skillRank, _, _, _, _, _, _, _, _, _ = GetSkillLineInfo(i)
        if not skillName then break end
        
        if isHeader then
            currentHeader = skillName
        else
            local lowName = string.lower(skillName)
            if currentHeader == "Professions" or currentHeader == "Secondary Skills" then
                playerProfessions[lowName] = skillRank
            elseif currentHeader == "Armor Proficiencies" then
                playerArmorSkills[lowName] = true
            elseif currentHeader == "Weapon Skills" then
                -- Cleans server variations like "One-Handed Swords" down to "swords" or matches exact families
                playerWeaponSkills[lowName] = true
                if string.find(lowName, "sword") then playerWeaponSkills["swords"] = true end
                if string.find(lowName, "mace") then playerWeaponSkills["maces"] = true end
                if string.find(lowName, "axe") then playerWeaponSkills["axes"] = true end
                if string.find(lowName, "dagger") then 
                    playerWeaponSkills["dagger"] = true 
                    playerWeaponSkills["daggers"] = true 
                end
                if string.find(lowName, "staff") or string.find(lowName, "staves") then playerWeaponSkills["staves"] = true end
                if string.find(lowName, "bow") then playerWeaponSkills["bows"] = true end
                if string.find(lowName, "crossbow") then playerWeaponSkills["crossbows"] = true end
                if string.find(lowName, "gun") then playerWeaponSkills["guns"] = true end
                if string.find(lowName, "fist") then playerWeaponSkills["fist weapons"] = true end

            end
        end
    end
end
