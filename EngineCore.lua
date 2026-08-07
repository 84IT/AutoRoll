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
    { key = "Crit", pats = { "critical strike rating by (%d+)", "critical strike rating", "Critical Strike", "crit rating", "Crit Rating", "Improves critical strike rating by (%d+)", "%+(%d+)%s*[Cc]rit%s*[Rr]ating?", "%+(%d+)%s*[Cc]ritical%s*[Ss]trike%s*[Rr]ating?" } },
    { key = "Hit", pats = { "hit rating by (%d+)", "hit rating", "Hit Rating", "Improves hit rating by (%d+)", "%+(%d+)%s*[Hh]it%s*[Rr]ating?", "%+(%d+)%s*[Hh]it" } },
    { key = "Haste", pats = { "haste rating by (%d+)", "haste rating", "Haste Rating", "Improves haste rating by (%d+)", "%+(%d+)%s*[Hh]aste%s*[Rr]ating?", "%+(%d+)%s*[Hh]aste" } },
    { key = "Ranged Attack Power", pats = { "ranged attack power by (%d+)", "Ranged Attack Power", "ranged attack power", "%+(%d+)%s*[Rr]anged%s*[Aa]ttack%s*[Pp]ower" } },
    { key = "Attack Power", pats = { "attack power by (%d+)", "%+(%d+)%s*Attack Power", "Attack Power", "%+(%d+)%s*[Aa]ttack%s*[Pp]ower" } },
    { key = "Spell Power", pats = { "spell power by (%d+)", "spell power", "Spell Power", "Increases spell power by (%d+)", "%+(%d+)%s*[Ss]pell%s*[Pp]ower" } },
    { key = "Spell Damage", pats = { "spell damage by (%d+)", "Increases spell damage by (%d+)", "%+(%d+)%s*[Ss]pell%s*[Dd]amage" } },
    { key = "Armor Pen", pats = { "armor penetration rating by (%d+)", "armor penetration", "Armor Pen", "Improves armor penetration rating by (%d+)", "%+(%d+)%s*[Aa]rmor%s*[Pp]en%s*[Rr]ating?", "%+(%d+)%s*[Aa]rmor%s*[Pp]en" } },
    { key = "Spell Pen", pats = { "spell penetration by (%d+)", "spell penetration", "Spell Pen", "Increases spell penetration by (%d+)", "%+(%d+)%s*[Ss]pell%s*[Pp]en%s*[Rr]ating?", "%+(%d+)%s*[Ss]pell%s*[Pp]en" } },
    { key = "Expertise", pats = { "expertise rating by (%d+)", "expertise rating", "Expertise", "Improves expertise rating by (%d+)", "%+(%d+)%s*[Ee]xpertise%s*[Rr]ating?", "%+(%d+)%s*[Ee]xpertise" } },
    { key = "Weapon DPS", pats = { "((%d+%.?%d*)) damage per second", "((%d+%.?%d*)) DPS" } },
    { key = "Ranged DPS", pats = { "((%d+%.?%d*)) damage per second", "((%d+%.?%d*)) DPS" } },
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
        quality = { ["Green"] = 0, ["Blue"] = 0, ["Purple"] = 0 }, statModuleEnabled = false, smartStatsDelay = 1.0
    }
end

defaults = { buttonX = 0, buttonY = 150, classProfiles = {}, statProfiles = {}, charSettings = {} }
scannerTooltip = CreateFrame("GameTooltip", "AutoRollScannerTooltip", nil, "GameTooltipTemplate")
local SMART_STATS_DELAY_SECONDS = 1.0

local function QueueRollProcessing(rollID, itemLink, delaySeconds, reason)
    local delayFrame = CreateFrame("Frame")
    local elapsed = 0
    delayFrame:SetScript("OnUpdate", function(f, delta)
        elapsed = elapsed + delta
        if elapsed >= delaySeconds then
            f:SetScript("OnUpdate", nil)
            pcall(ProcessLootRoll, rollID, itemLink)
        end
    end)
    if reason then
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFD100[AutoRoll Delay]|r %s: waiting %.2f seconds before evaluating roll.", reason, delaySeconds))
    end
end

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

-- =========================================================================
-- MULTI-PROFILE LIBRARY: Profiles are stored flat in AutoRollConfig.statProfiles,
-- keyed by name (not by class), so a class can have any number of named specs
-- ("Reaper - Tank", "Reaper - DPS", etc). Each character just remembers which
-- named profile it's currently pointed at via charSettings[charKey].activeStatProfile.
-- The 21 built-in class-name-matching profiles (seeded from AutoRoll_ClassTemplates
-- in Profiles.lua) are treated as protected defaults: editable, but not renameable
-- or deletable, so there's always a safe fallback for every class.
-- =========================================================================
local function EscapePattern(s)
    return (s:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1"))
end

function IsProtectedProfileName(name)
    if not name or not AutoRoll_ClassTemplates then return false end
    for templateName, _ in pairs(AutoRoll_ClassTemplates) do
        if string.lower(templateName) == string.lower(name) then return true end
    end
    return false
end

-- Makes sure AutoRollConfig.statProfiles[profileName] exists, seeding it from a
-- matching AutoRoll_ClassTemplates entry if this is the first time it's used,
-- or from a blank all-zero table otherwise.
function EnsureProfileExists(profileName)
    if not profileName or profileName == "" or not AutoRollConfig then return end
    if not AutoRollConfig.statProfiles then AutoRollConfig.statProfiles = {} end
    if AutoRollConfig.statProfiles[profileName] then return end
    local foundTemplate = nil
    if AutoRoll_ClassTemplates then
        for templateName, templateData in pairs(AutoRoll_ClassTemplates) do
            if string.lower(templateName) == string.lower(profileName) then foundTemplate = templateData break end
        end
    end
    if foundTemplate then
        AutoRollConfig.statProfiles[profileName] = {}
        for k, v in pairs(foundTemplate) do AutoRollConfig.statProfiles[profileName][k] = v end
    else
        AutoRollConfig.statProfiles[profileName] = GetBlankStatTable()
    end
end

-- Returns the profile name this character currently has active, defaulting to
-- (and auto-selecting) their own class's default profile the first time they're seen.
function GetActiveProfileName()
    if not AutoRollConfig or not AutoRollConfig.charSettings then return GetPlayerClassProfile() end
    local charKey = GetCharacterUniqueKey()
    local cCfg = AutoRollConfig.charSettings[charKey]
    local profileName = cCfg and cCfg.activeStatProfile
    if not profileName or profileName == "" then
        profileName = GetPlayerClassProfile()
        if cCfg then cCfg.activeStatProfile = profileName end
    end
    EnsureProfileExists(profileName)
    return profileName
end

-- Points this character at a different (existing or new) named profile.
function SetActiveProfileName(profileName)
    if not AutoRollConfig or not AutoRollConfig.charSettings or not profileName or profileName == "" then return end
    local charKey = GetCharacterUniqueKey()
    if not AutoRollConfig.charSettings[charKey] then AutoRollConfig.charSettings[charKey] = GetBlankCharSettings() end
    EnsureProfileExists(profileName)
    AutoRollConfig.charSettings[charKey].activeStatProfile = profileName
end

-- Profiles relevant to a given class: the exact-name default, plus any custom
-- profile named "ClassName - Something" (e.g. "Reaper - Tank").
function GetProfilesForClass(className)
    local list = {}
    if AutoRollConfig and AutoRollConfig.statProfiles and className then
        local escapedClass = EscapePattern(string.lower(className))
        for name, _ in pairs(AutoRollConfig.statProfiles) do
            local lname = string.lower(name)
            if lname == string.lower(className) or string.find(lname, "^" .. escapedClass .. "%s*%-") then
                table.insert(list, name)
            end
        end
    end
    table.sort(list, function(a, b) return string.lower(a) < string.lower(b) end)
    return list
end

-- Every profile in the library, across all classes.
function GetAllProfileNames()
    local list = {}
    if AutoRollConfig and AutoRollConfig.statProfiles then
        for name, _ in pairs(AutoRollConfig.statProfiles) do table.insert(list, name) end
    end
    table.sort(list, function(a, b) return string.lower(a) < string.lower(b) end)
    return list
end

-- Creates a new named profile, optionally cloning an existing profile's weights
-- (falls back to an all-zero table if baseName is nil or not found).
function CreateNewStatProfile(newName, baseName)
    if not AutoRollConfig then return false, "Addon not ready yet." end
    if not AutoRollConfig.statProfiles then AutoRollConfig.statProfiles = {} end
    if not newName or newName == "" then return false, "Name cannot be empty." end
    if AutoRollConfig.statProfiles[newName] then return false, "A profile with that name already exists." end
    local baseWeights = (baseName and AutoRollConfig.statProfiles[baseName]) or GetBlankStatTable()
    AutoRollConfig.statProfiles[newName] = {}
    for k, v in pairs(baseWeights) do AutoRollConfig.statProfiles[newName][k] = v end
    return true
end

-- Renames a profile in place, repointing every character currently using it.
function RenameStatProfile(oldName, newName)
    if not AutoRollConfig or not AutoRollConfig.statProfiles then return false, "Addon not ready yet." end
    if not newName or newName == "" then return false, "Name cannot be empty." end
    if IsProtectedProfileName(oldName) then return false, "Default class profiles can't be renamed." end
    if not AutoRollConfig.statProfiles[oldName] then return false, "Profile not found." end
    if AutoRollConfig.statProfiles[newName] then return false, "A profile with that name already exists." end
    AutoRollConfig.statProfiles[newName] = AutoRollConfig.statProfiles[oldName]
    AutoRollConfig.statProfiles[oldName] = nil
    if AutoRollConfig.charSettings then
        for _, cCfg in pairs(AutoRollConfig.charSettings) do
            if cCfg.activeStatProfile == oldName then cCfg.activeStatProfile = newName end
        end
    end
    return true
end

-- Deletes a custom profile. Any character pointed at it falls back to their own
-- class's default profile (re-seeded automatically via GetActiveProfileName).
function DeleteStatProfile(name)
    if not AutoRollConfig or not AutoRollConfig.statProfiles then return false, "Addon not ready yet." end
    if IsProtectedProfileName(name) then return false, "Default class profiles can't be deleted." end
    if not AutoRollConfig.statProfiles[name] then return false, "Profile not found." end
    AutoRollConfig.statProfiles[name] = nil
    if AutoRollConfig.charSettings then
        for _, cCfg in pairs(AutoRollConfig.charSettings) do
            if cCfg.activeStatProfile == name then cCfg.activeStatProfile = nil end
        end
    end
    return true
end

-- =========================================================================
-- SHARED SCORING ENGINE: Single source of truth for reading a populated
-- tooltip's lines and turning them into a class-weighted score. Used by
-- CalculateItemScore below, and by the Ctrl+Hover diagnostic and equipped
-- weapon breakdown in InterfaceGUI.lua, so all three always agree.
--   tooltipFrame  - a GameTooltip-type frame that already has SetHyperlink
--                    (or SetItem) called on it
--   profileName   - the profile-library key into AutoRollConfig.statProfiles
--                    (an active profile name, not necessarily a class name)
--   isRangedItem  - true if the item is a bow/gun/crossbow/thrown/ranged slot
--   verbose       - if true, prints each matched stat line to chat
--   linePrefix    - optional chat-log tag, e.g. "(MH)" or "(OH)"
-- =========================================================================
function ScoreTooltipLines(tooltipFrame, profileName, isRangedItem, verbose, linePrefix)
    local totalScore = 0
    local profile = AutoRollConfig and AutoRollConfig.statProfiles and AutoRollConfig.statProfiles[profileName]
    local tipName = tooltipFrame:GetName()
    for i = 1, tooltipFrame:NumLines() do
        local leftLine = _G[tipName .. "TextLeft" .. i] local rightLine = _G[tipName .. "TextRight" .. i]
        local rawTextLeft = leftLine and leftLine:GetText() or "" local rawTextRight = rightLine and rightLine:GetText() or ""
        if (rawTextLeft ~= "" and not string.find(rawTextLeft, "Set:") and not string.find(rawTextLeft, "%(%d+%)%s*Set")) or (rawTextRight ~= "" and not string.find(rawTextRight, "Set:")) then
            local combinedText = rawTextLeft .. "\n" .. rawTextRight
            for text in string.gmatch(combinedText, "[^\r\n]+") do
                for _, item in ipairs(STAT_PATTERNS) do
                    local weight = (profile and profile[item.key]) or 0
                    local skipDpsMismatch = (item.key == "Weapon DPS" and isRangedItem) or (item.key == "Ranged DPS" and not isRangedItem)
                    if weight > 0 and not skipDpsMismatch then
                        local cleanPat = nil
                        if item.key == "Strength" then cleanPat = "%+(%d+)%s*[Ss]trength"
                        elseif item.key == "Agility" then cleanPat = "%+(%d+)%s*[Aa]gility"
                        elseif item.key == "Stamina" then cleanPat = "%+(%d+)%s*[Ss]tamina"
                        elseif item.key == "Intellect" then cleanPat = "%+(%d+)%s*[Ii]ntellect"
                        elseif item.key == "Spirit" then cleanPat = "%+(%d+)%s*[Ss]pirit"
                        elseif item.key == "Haste" then cleanPat = "%+(%d+)%s*[Hh]aste" end

                        local matchVal = nil
                        if cleanPat then
                            local match = string.match(text, cleanPat)
                            if match and tonumber(match) then matchVal = tonumber(match) end
                        else
                            for _, pattern in ipairs(item.pats) do
                                local cleanPattern = pattern:gsub("%%%+", ""):gsub("%^", "")
                                local match = string.match(text, cleanPattern)
                                if match and tonumber(match) then matchVal = tonumber(match) break end
                            end
                        end

                        if matchVal then
                            local lineScore = matchVal * weight
                            totalScore = totalScore + lineScore
                            if verbose then
                                DEFAULT_CHAT_FRAME:AddMessage(string.format("  %s|cFF3399FFKey:|r %s, |cFF00FF00Val:|r %s, |cFFFF9900Weight:|r %s (|cFF00FF00Score:+%.2f|r)", linePrefix or "", item.key, matchVal, weight, lineScore))
                            end
                        end
                    end
                end
            end
        end
    end
    return totalScore
end

function CalculateItemScore(itemLink)
    local profileName = GetActiveProfileName()
    if not itemLink or not AutoRollConfig or not AutoRollConfig.statProfiles or not AutoRollConfig.statProfiles[profileName] then return 0 end
    local _, _, _, _, _, _, itemSubClass, _, itemEquipLoc = GetItemInfo(itemLink)
    local isRangedItem = (itemEquipLoc == "INVTYPE_RANGED" or itemEquipLoc == "INVTYPE_RANGEDRIGHT" or
        itemSubClass == "Bows" or itemSubClass == "Guns" or itemSubClass == "Crossbows" or itemSubClass == "Thrown")
    scannerTooltip:SetOwner(WorldFrame, "ANCHOR_NONE") scannerTooltip:ClearLines() scannerTooltip:SetHyperlink(itemLink)
    local totalScore = ScoreTooltipLines(scannerTooltip, profileName, isRangedItem, false)
    scannerTooltip:Hide() return totalScore
end

function GetStatModuleComparisonScores(itemLink, itemType, itemSubClass, itemEquipLoc)
    local profileName = GetActiveProfileName()
    if not itemLink or not AutoRollConfig or not AutoRollConfig.statProfiles or not AutoRollConfig.statProfiles[profileName] then
        return 0, 0
    end

    local candidateScore = CalculateItemScore(itemLink)
    local equippedScore = 0
    local isRangedItem = (itemEquipLoc == "INVTYPE_RANGED" or itemEquipLoc == "INVTYPE_RANGEDRIGHT" or
        itemSubClass == "Bows" or itemSubClass == "Guns" or itemSubClass == "Crossbows" or itemSubClass == "Thrown")
    local isWeaponItem = itemType == "Weapon" or itemSubClass == "Shields" or itemEquipLoc == "INVTYPE_HOLDABLE" or
        itemEquipLoc == "INVTYPE_RANGED" or itemEquipLoc == "INVTYPE_RANGEDRIGHT" or itemSubClass == "Guns" or
        itemSubClass == "Bows" or itemSubClass == "Crossbows" or itemSubClass == "Thrown"
    local isArmorPiece = itemSubClass == "Cloth" or itemSubClass == "Leather" or itemSubClass == "Mail" or itemSubClass == "Plate"

    if isRangedItem then
        local rangedLink = GetInventoryItemLink("player", 18)
        equippedScore = rangedLink and CalculateItemScore(rangedLink) or 0
    elseif isWeaponItem and not isArmorPiece then
        local mhLink = GetInventoryItemLink("player", 16)
        local ohLink = GetInventoryItemLink("player", 17)
        local mhScore = mhLink and CalculateItemScore(mhLink) or 0
        local ohScore = ohLink and CalculateItemScore(ohLink) or 0
        equippedScore = mhScore + ohScore
        if itemEquipLoc == "INVTYPE_WEAPON" or itemEquipLoc == "INVTYPE_WEAPONMAINHAND" then
            candidateScore = candidateScore + ohScore
        elseif itemEquipLoc == "INVTYPE_SHIELD" or itemEquipLoc == "INVTYPE_HOLDABLE" or itemEquipLoc == "INVTYPE_WEAPONOFFHAND" or itemSubClass == "Shields" then
            candidateScore = mhScore + candidateScore
        end
    elseif itemEquipLoc == "INVTYPE_FINGER" then
        local r1Link = GetInventoryItemLink("player", 11)
        local r2Link = GetInventoryItemLink("player", 12)
        local s1 = r1Link and CalculateItemScore(r1Link) or 0
        local s2 = r2Link and CalculateItemScore(r2Link) or 0
        equippedScore = math.min(s1, s2)
    elseif itemEquipLoc == "INVTYPE_TRINKET" then
        local t1Link = GetInventoryItemLink("player", 13)
        local t2Link = GetInventoryItemLink("player", 14)
        local s1 = t1Link and CalculateItemScore(t1Link) or 0
        local s2 = t2Link and CalculateItemScore(t2Link) or 0
        equippedScore = math.min(s1, s2)
    elseif itemEquipLoc and SLOT_MAP[itemEquipLoc] then
        local slotID = SLOT_MAP[itemEquipLoc]
        local equippedItemLink = GetInventoryItemLink("player", slotID)
        equippedScore = equippedItemLink and CalculateItemScore(equippedItemLink) or 0
    end

    return candidateScore, equippedScore
end

function ProcessLootRoll(rollID, itemLink)
    if not AutoRollConfig or not AutoRollConfig.charSettings then return end
    local charKey = GetCharacterUniqueKey() local cCfg = AutoRollConfig.charSettings[charKey]
    if not cCfg or not cCfg.enabled or handledRolls[rollID] then return end
    local profileName = GetActiveProfileName()
    local itemName, _, itemRarity, _, _, itemType, itemSubClass, _, itemEquipLoc = GetItemInfo(itemLink)
    if not itemName then return end
    local rollNames = { [1] = "Need", [2] = "Greed", [3] = "Pass" }
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF00FF00[AutoRoll Trace]|r Evaluating %s: type=%s subclass=%s equip=%s", itemLink, itemType or "nil", itemSubClass or "nil", itemEquipLoc or "nil"))

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
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFD100[AutoRoll Trace]|r Recipe auto-roll -> %s", itemLink))
        if ExecuteRollChoice(rollID, 1, itemLink, "Unknown Usable Recipe") then return end
    end

    -- =========================================================================
    -- PRIORITY 1: HARD BLOCK USABILITY SHIELD (Instantly drops unwearable gear)
    -- =========================================================================
    if not isRecipeItem then isUnusable = IsItemUnusable(itemLink) end

    -- =========================================================================
    -- PRIORITY 2: SMART STATS UPGRADE TRACKER (Prioritizes item slot upgrades)
    -- =========================================================================
    if cCfg.statModuleEnabled and itemEquipLoc and SLOT_MAP[itemEquipLoc] and AutoRollConfig.statProfiles and AutoRollConfig.statProfiles[profileName] then
        local droppedScore, equippedScore = GetStatModuleComparisonScores(itemLink, itemType, itemSubClass, itemEquipLoc)
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFD100[AutoRoll Trace]|r Stat compare (profile: %s) -> candidate=%.2f equipped=%.2f", profileName, droppedScore, equippedScore))
        if droppedScore > equippedScore then 
            if alertTextString then alertTextString:SetText("|cFF3399FFRoll NEED! Stat Upgrade!|r") end
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFD100[AutoRoll Trace]|r Stat auto-roll -> %s [Need], delta=%.2f", itemLink, droppedScore - equippedScore))
            if ExecuteRollChoice(rollID, 1, itemLink, string.format("Upgrade Over Equipped: +%.2f Pts", droppedScore - equippedScore)) then return end
        end
    end

    -- =========================================================================
    -- PRIORITY 3: SPECIFIC TYPE OVERRIDES (Evaluates custom checkbox configurations)
    -- =========================================================================
    if (itemType == "Armor" or itemSubClass == "Shields") and cCfg.armor then
        local aChoice = 0 if cCfg.bulkArmor and cCfg.bulkArmor > 0 then aChoice = cCfg.bulkArmor else aChoice = cCfg.armor[itemSubClass] or 0 end
        if aChoice > 0 then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFD100[AutoRoll Trace]|r Armor filter auto-roll -> %s, action=%s", itemSubClass or "Unknown", rollNames[aChoice] or tostring(aChoice)))
            if ExecuteRollChoice(rollID, aChoice, itemLink, "Armor Filter: " .. itemSubClass) then return end
        end
    end
    if itemType == "Weapon" or itemSubClass == "Shields" or itemEquipLoc == "INVTYPE_HOLDABLE" or itemEquipLoc == "INVTYPE_RANGED" or itemEquipLoc == "INVTYPE_RANGEDRIGHT" or itemSubClass == "Guns" or itemSubClass == "Bows" or itemSubClass == "Crossbows" or itemSubClass == "Thrown" then
        if cCfg.weapons and cCfg.weapons[itemSubClass] and cCfg.weapons[itemSubClass] > 0 then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFD100[AutoRoll Trace]|r Weapon filter auto-roll -> %s, action=%s", itemSubClass or "Unknown", rollNames[cCfg.weapons[itemSubClass]] or tostring(cCfg.weapons[itemSubClass])))
            if ExecuteRollChoice(rollID, cCfg.weapons[itemSubClass], itemLink, "Weapon Auto Filter: " .. itemSubClass) then return end
        end
        local hasQualityRule = rarityKey and cCfg.quality and ((cCfg.bulkQuality and cCfg.bulkQuality > 0) or (cCfg.quality[rarityKey] or 0) > 0)
        if not hasQualityRule then
            if isUnusable and cCfg.autoGreedUnusable then
                local finalRollType = "Greed"
                if not cCfg.autoGreedUnusable then finalRollType = "Pass" end
                if alertTextString then alertTextString:SetText("|cFFFF0000Auto-Greed unusable weapon override active.|r") end
                DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFD100[AutoRoll Override]|r Weapon piece dropped: %s is unusable and Auto-Greed Unusable is enabled. Final unusable fallback will handle the roll as %s.", itemLink, finalRollType))
            else
                local droppedScore = CalculateItemScore(itemLink)
                if alertTextString then alertTextString:SetText("|cFFFFD100Weapon dropped! Manual pause.|r") end
                DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFD100[AutoRoll Override]|r Weapon piece dropped: %s (|cFF00FF00Score: %.2f|r). Auto-rolling paused so you can choose manually!", itemLink, droppedScore)) return 
            end
        end
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
        if qChoice > 0 then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFD100[AutoRoll Trace]|r Quality filter auto-roll -> %s rarity, action=%s", rarityKey, rollNames[qChoice] or tostring(qChoice)))
            if ExecuteRollChoice(rollID, qChoice, itemLink, "Quality Filter: " .. rarityKey) then return end
        end
    end

    -- =========================================================================
    -- FINAL FALLBACK: Unusable gear only triggers after explicit item rules fail
    -- =========================================================================
    if isUnusable then
        local fallbackAction = cCfg.autoGreedUnusable and 2 or 3
        local fallbackReason = cCfg.autoGreedUnusable and "Unusable Greed Catch" or "Unusable Pass Exclusion"
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFD100[AutoRoll Trace]|r Unusable fallback auto-roll -> action=%s", rollNames[fallbackAction] or tostring(fallbackAction)))
        if ExecuteRollChoice(rollID, fallbackAction, itemLink, fallbackReason) then return end
    end
end


local function IsWeaponSkillRecognized(weaponSubClass, skillTable)
    if not weaponSubClass or not skillTable then return false end
    local lowSub = string.lower(weaponSubClass)
    if skillTable[lowSub] then return true end

    local normalized = lowSub:gsub("[%s%-]+", " ")
    if string.find(normalized, "sword") and skillTable["swords"] then return true end
    if string.find(normalized, "mace") and skillTable["maces"] then return true end
    if string.find(normalized, "axe") and skillTable["axes"] then return true end
    if string.find(normalized, "dagger") and skillTable["daggers"] then return true end
    if (string.find(normalized, "staff") or string.find(normalized, "staves")) and skillTable["staves"] then return true end
    if string.find(normalized, "bow") and skillTable["bows"] then return true end
    if string.find(normalized, "crossbow") and skillTable["crossbows"] then return true end
    if string.find(normalized, "gun") and skillTable["guns"] then return true end
    if string.find(normalized, "fist") and skillTable["fist weapons"] then return true end
    return false
end

function IsItemUnusable(itemLink)
    if not itemLink then return false, "StandardGear" end
    local _, _, _, _, _, itemType, itemSubClass, _, itemEquipLoc = GetItemInfo(itemLink)
    local isRecipeItem = (itemType == "Recipe")
    
    -- Safety Check: If background data isn't loaded yet, run a fast fallback sync scan
    local armorSkillsReady = playerArmorSkills ~= nil and next(playerArmorSkills) ~= nil
    local weaponSkillsReady = playerWeaponSkills ~= nil and next(playerWeaponSkills) ~= nil
    if not armorSkillsReady or not weaponSkillsReady then ScanCharacterSkillsEngine() end
    
    local unusable = false
    local isAlreadyKnown = false
    local hasUnusableProfession = false
    
    -- 1. HARD IMPLEMENTED LIVE EQUIPMENT SKILLS SHIELD
    local lowSub = string.lower(itemSubClass or "")
    local isAccessorySlot = itemEquipLoc == "INVTYPE_NECK" or itemEquipLoc == "INVTYPE_FINGER" or itemEquipLoc == "INVTYPE_TRINKET" or itemEquipLoc == "INVTYPE_CLOAK" or itemEquipLoc == "INVTYPE_HOLDABLE" or itemEquipLoc == "INVTYPE_BODY" or itemEquipLoc == "INVTYPE_TABARD"
    if itemType == "Armor" and not isAccessorySlot and lowSub ~= "cloth" and lowSub ~= "leather" and lowSub ~= "mail" and lowSub ~= "plate" and lowSub ~= "misc" and lowSub ~= "miscellaneous" and lowSub ~= "shields" and lowSub ~= "" then
        -- Direct Database Validation: If your character skills tab lacks this proficiency, flag it instantly
        if playerArmorSkills and not playerArmorSkills[lowSub] then unusable = true end
    elseif itemType == "Weapon" and lowSub ~= "" then
        -- Normalizes specific name variances cleanly into raw weapon class terms
        local matchedWpSkill = false
        if playerWeaponSkills then
            matchedWpSkill = IsWeaponSkillRecognized(itemSubClass, playerWeaponSkills)
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
    if type(AutoRollConfig) ~= "table" or not AutoRollConfig.classProfiles then AutoRollConfig = nil end
    if not AutoRollConfig then
        AutoRollConfig = defaults
    else
        if not AutoRollConfig.charSettings then AutoRollConfig.charSettings = {} end
        for k, v in pairs(defaults) do if AutoRollConfig[k] == nil then AutoRollConfig[k] = v end end
    end
    local charKey = GetCharacterUniqueKey()
    if not AutoRollConfig.charSettings[charKey] then AutoRollConfig.charSettings[charKey] = GetBlankCharSettings() end
    local cCfg = AutoRollConfig.charSettings[charKey]
    local playerClass = GetPlayerClassProfile()
    if not AutoRollConfig.statProfiles then AutoRollConfig.statProfiles = {} end

    -- One-time migration: pre-v3.4 saves kept a single profile per class in
    -- classProfiles[className]. Fold that into the new named-profile library
    -- (if a statProfiles entry with that name doesn't already exist) so nobody
    -- loses their tuned weights on upgrade.
    if AutoRollConfig.classProfiles and AutoRollConfig.classProfiles[playerClass] and not AutoRollConfig.statProfiles[playerClass] then
        AutoRollConfig.statProfiles[playerClass] = {}
        for k, v in pairs(AutoRollConfig.classProfiles[playerClass]) do AutoRollConfig.statProfiles[playerClass][k] = v end
    end

    -- This character's active profile defaults to their own class's profile the
    -- first time they're seen, exactly matching pre-v3.4 behavior until they
    -- deliberately pick something else from the Smart Stats dropdown.
    if not cCfg.activeStatProfile or cCfg.activeStatProfile == "" then cCfg.activeStatProfile = playerClass end
    EnsureProfileExists(cCfg.activeStatProfile)
    local activeProfile = AutoRollConfig.statProfiles[cCfg.activeStatProfile]

    if activeProfile["Ranged Attack Power"] == nil then activeProfile["Ranged Attack Power"] = 0 end
    for k, v in pairs(activeProfile) do tempWeights[k] = tonumber(v) or 0 end
    -- Skills Cache Ingestion: Replaces old manual overrides with live server metrics
    ScanCharacterSkillsEngine()

    if not isLoaded then
        isLoaded = true
        if not AutoRollLauncherButton then BuildLauncherButton() end
    end
end

mainFrame = CreateFrame("Frame")
mainFrame:RegisterEvent("ADDON_LOADED") mainFrame:RegisterEvent("PLAYER_LOGIN")
mainFrame:RegisterEvent("START_LOOT_ROLL") mainFrame:RegisterEvent("CANCEL_LOOT_ROLL")
mainFrame:RegisterEvent("SKILL_LINES_CHANGED")
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
            local itemName, _, _, _, _, itemType, itemSubClass, _, itemEquipLoc = GetItemInfo(itemLink)
            if not itemName then
                local retryFrame = CreateFrame("Frame") local elapsed = 0
                retryFrame:SetScript("OnUpdate", function(f, delta)
                    elapsed = elapsed + delta
                    if GetItemInfo(itemLink) then pcall(ProcessLootRoll, rollID, itemLink) retryFrame:SetScript("OnUpdate", nil)
                    elseif elapsed > 2.0 then retryFrame:SetScript("OnUpdate", nil) end
                end)
            else
                local charKey = GetCharacterUniqueKey()
                local cCfg = AutoRollConfig and AutoRollConfig.charSettings and AutoRollConfig.charSettings[charKey]
                local isGearLikeItem = itemEquipLoc and SLOT_MAP[itemEquipLoc]
                if cCfg and cCfg.statModuleEnabled and isGearLikeItem then
                    local delaySeconds = tonumber(cCfg.smartStatsDelay) or SMART_STATS_DELAY_SECONDS
                    QueueRollProcessing(rollID, itemLink, delaySeconds, "Smart stats evaluation")
                else
                    pcall(ProcessLootRoll, rollID, itemLink)
                end
            end
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
