
-- Forward declarations to prevent top-to-bottom variable loading sequence crashes
local GetPlayerClassProfile
local CalculateItemScore
local scannerTooltip



-- Global array table holding current edits during typing sessions
local tempWeights = {}

-- A clean, pre-compiled stat profile template used to safely spawn new classes
local function GetBlankStatTable()
    return {
        ["Strength"] = 0, ["Agility"] = 0, ["Stamina"] = 0, ["Intellect"] = 0, ["Spirit"] = 0,
        ["Crit"] = 0, ["Hit"] = 0, ["Haste"] = 0, ["Resilience"] = 0, ["Mana per 5"] = 0,
        ["Weapon DPS"] = 0, ["Ranged DPS"] = 0, ["Attack Power"] = 0, ["Ranged Attack Power"] = 0, ["Spell Power"] = 0, 
        ["Spell Damage"] = 0, ["Armor Pen"] = 0, ["Spell Pen"] = 0, ["Expertise"] = 0
    }
end

-- A clean blueprint template used to safely spawn isolated character loot filters
local function GetBlankCharSettings()
    return {
        enabled = true,
        timeThreshold = 5,
        autoGreedUnusable = true,
        bulkArmor = 0,
        bulkWeapons = 0,
        bulkQuality = 0,
        armor = { ["Cloth"] = 0, ["Leather"] = 0, ["Mail"] = 0, ["Plate"] = 0, ["Shields"] = 0 },
        weapons = {
            ["Daggers"] = 0, ["One-Handed Swords"] = 0, ["Two-Handed Swords"] = 0, ["One-Handed Maces"] = 0,
            ["Two-Handed Maces"] = 0, ["One-Handed Axes"] = 0, ["Two-Handed Axes"] = 0, ["Staves"] = 0, ["Bows"] = 0, ["Guns"] = 0,
            ["Crossbows"] = 0
        },
        quality = { ["Green"] = 0, ["Blue"] = 0, ["Purple"] = 0 },
        statModuleEnabled = false
    }
end

-- Configuration Defaults Profile with integrated global and local storage dictionary maps
local defaults = {
    buttonX = 0,
    buttonY = 150,
    classProfiles = {},
    charSettings = {} -- Brand New: Holds completely separate loot rules mapped per character name
}

-- Mapping database translating tooltip string text matching rules to database indices
-- Fortified pattern table corrected with single-escape matching rules for literal plus sign lines
local STAT_PATTERNS = {
    { key = "Strength",     pats = { "%+(%d+)%s*Strength", "%+(%d+)%s*strength" } },
    { key = "Agility",      pats = { "%+(%d+)%s*Agility", "%+(%d+)%s*agility" } },
    { key = "Stamina",      pats = { "%+(%d+)%s*Stamina", "%+(%d+)%s*stamina" } },
    { key = "Intellect",    pats = { "%+(%d+)%s*Intellect", "%+(%d+)%s*intellect" } },
    { key = "Spirit",       pats = { "%+(%d+)%s*Spirit", "%+(%d+)%s*spirit" } },
    
    { key = "Crit",         pats = { "critical strike rating by (%d+)", "critical strike rating", "Critical Strike", "crit rating", "Crit Rating", "Improves critical strike rating by (%d+)" } },
    { key = "Hit",          pats = { "hit rating by (%d+)", "hit rating", "Hit Rating", "Improves hit rating by (%d+)" } },
    { key = "Haste",        pats = { "haste rating by (%d+)", "haste rating", "Haste Rating", "Improves haste rating by (%d+)" } },
    
    { key = "Ranged Attack Power", pats = { "ranged attack power by (%d+)", "Ranged Attack Power", "ranged attack power" } },
    { key = "Attack Power", pats = { "attack power by (%d+)", "%+(%d+)%s*Attack Power", "Attack Power" } },
    { key = "Spell Power",  pats = { "spell power by (%d+)", "spell power", "Spell Power", "Increases spell power by (%d+)" } },
    { key = "Spell Damage", pats = { "spell damage by (%d+)", "Increases spell damage by (%d+)" } },
    
    { key = "Armor Pen",    pats = { "armor penetration rating by (%d+)", "armor penetration", "Armor Pen", "Improves armor penetration rating by (%d+)" } },
    { key = "Spell Pen",    pats = { "spell penetration by (%d+)", "spell penetration", "Spell Pen", "Increases spell penetration by (%d+)" } },
    { key = "Expertise",    pats = { "expertise rating by (%d+)", "expertise rating", "Expertise", "Improves expertise rating by (%d+)" } },
    { key = "Weapon DPS",   pats = { "((%d+%.?%d*)) damage per second", "((%d+%.?%d*)) DPS" } },
    { key = "Ranged DPS",   pats = { "Ranged.*((%d+%.?%d*)) damage per second" } },
    { key = "Resilience",   pats = { "resilience rating by (%d+)", "resilience rating", "Resilience" } },
    { key = "Mana per 5",   pats = { "mana per 5 sec", "Restores (%d+) mana per 5", "mana per 5 seconds" } }
}




function CalculateItemScore(itemLink)
    local playerClass = GetPlayerClassProfile()
    if not itemLink or not AutoRollConfig or not AutoRollConfig.classProfiles or not AutoRollConfig.classProfiles[playerClass] then 
        return 0 
    end
    scannerTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    scannerTooltip:ClearLines()
    scannerTooltip:SetHyperlink(itemLink)
    local totalScore = 0
    for i = 1, scannerTooltip:NumLines() do
        local leftLine = _G["AutoRollScannerTooltipTextLeft" .. i]
        if leftLine then
            local text = leftLine:GetText()
            if text then
                -- Set Bonus Shield: Skips line immediately if it contains set piece bonus markers
                if string.find(text, "Set:") or string.find(text, "%(%d+%)%s*Set") then
                    -- Skips straight to the next line without running text pattern matches
                else
                    for _, item in ipairs(STAT_PATTERNS) do
                        local weight = AutoRollConfig.classProfiles[playerClass][item.key] or 0
                        if weight > 0 then
                            for _, pattern in ipairs(item.pats) do
                                local match = string.match(text, pattern)
                                if match then 
                                    totalScore = totalScore + (tonumber(match) * weight) 
                                    break 
                                end
                            end
                        end
                    end
                end -- End of Set Shield check
            end
        end
    end

    scannerTooltip:Hide()
    return totalScore
end


scannerTooltip = CreateFrame("GameTooltip", "AutoRollScannerTooltip", nil, "GameTooltipTemplate")

local function IsItemUnusable(itemLink)
    if not itemLink then return false end
    scannerTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    scannerTooltip:ClearLines()
    scannerTooltip:SetHyperlink(itemLink)
    local unusable = false
    for i = 1, scannerTooltip:NumLines() do
        local leftLine = _G["AutoRollScannerTooltipTextLeft" .. i]
        if leftLine then
            local r, g, b = leftLine:GetTextColor()
            if r and g and b and r > 0.9 and g < 0.2 and b < 0.2 then unusable = true break end
        end
    end
    scannerTooltip:Hide()
    return unusable
end

function GetPlayerClassProfile()
    local localClassName, _ = UnitClass("player")
    if not localClassName or localClassName == "" then return "Unknown" end
    if localClassName == "Knight Of Xoroth" then localClassName = "Knight of Xoroth" end
    return localClassName
end

-- Helper macro to pull the absolute distinct identifier for the logged-in character
local function GetCharacterUniqueKey()
    local name = UnitName("player")
    local realm = GetRealmName()
    if name and realm then
        return name .. " - " .. realm
    end
    return "UnknownCharacter"
end

-- Anchors universally mapped cross-references to secure error-free page loads
local settingsFrame, statFrame, weightFrame
local BuildUI

local function ToggleUI()
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

local handledRolls = {}
local mainFrame = CreateFrame("Frame")
mainFrame:RegisterEvent("ADDON_LOADED")
mainFrame:RegisterEvent("PLAYER_LOGIN")
mainFrame:RegisterEvent("START_LOOT_ROLL")
mainFrame:RegisterEvent("CANCEL_LOOT_ROLL")




local function CloseActiveLootFrame(rollID)
    for i = 1, 4 do
        local rollFrame = _G["GroupLootFrame" .. i]
        if rollFrame and rollFrame:IsShown() and rollFrame.rollID == rollID then
            rollFrame:Hide()
            break
        end
    end
end

local function ExecuteRollChoice(rollID, choiceCode, itemLink, reason)
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

-- Cross-referenced inventory tracking map updated with custom server text label overrides
local SLOT_MAP = {
    ["INVTYPE_HEAD"] = 1,      ["Head"] = 1,
    ["INVTYPE_NECK"] = 2,      ["Neck"] = 2,
    ["INVTYPE_SHOULDER"] = 3,  ["Shoulder"] = 3, ["Shoulders"] = 3,
    ["INVTYPE_BODY"] = 4,      ["Shirt"] = 4,
    ["INVTYPE_CHEST"] = 5,     ["Chest"] = 5,    ["Robe"] = 5, ["INVTYPE_ROBE"] = 5,
    ["INVTYPE_WAIST"] = 6,     ["Waist"] = 6,    ["Belt"] = 6,
    ["INVTYPE_LEGS"] = 7,      ["Legs"] = 7,
    ["INVTYPE_FEET"] = 8,      ["Feet"] = 8,     ["Boots"] = 8,
    ["INVTYPE_WRIST"] = 9,     ["Wrist"] = 9,    ["Bracers"] = 9,
    ["INVTYPE_HANDS"] = 10,    ["Hands"] = 10,   ["Gloves"] = 10, ["Gauntlets"] = 10,
    ["INVTYPE_FINGER"] = 11,   ["Finger"] = 11,  ["Ring"] = 11,
    ["INVTYPE_TRINKET"] = 12,  ["Trinket"] = 12,
    ["INVTYPE_CLOAK"] = 15,    ["Back"] = 15,    ["Cloak"] = 15,
    
    ["INVTYPE_WEAPON"] = 16,   ["One-Hand"] = 16, ["One-Handed"] = 16,
    ["INVTYPE_2HWEAPON"] = 16, ["Two-Hand"] = 16, ["Two-Handed"] = 16,
    ["INVTYPE_WEAPONMAINHAND"] = 16, ["Main-Hand"] = 16, ["Main Hand"] = 16,
    
    ["INVTYPE_SHIELD"] = 17,   ["Shield"] = 17,
    ["INVTYPE_WEAPONOFFHAND"] = 17,  ["Off-Hand"] = 17, ["Off Hand"] = 17,
    ["INVTYPE_HOLDABLE"] = 17, ["Held In Off-Hand"] = 17, ["Held in Off-Hand"] = 17,
    
    ["INVTYPE_RANGED"] = 18,   ["Ranged"] = 18,  ["INVTYPE_RANGEDRIGHT"] = 18
}


local alertTextString
local function ProcessLootRoll(rollID, itemLink)
    if not AutoRollConfig or not AutoRollConfig.charSettings then return end
    local charKey = GetCharacterUniqueKey()
    local cCfg = AutoRollConfig.charSettings[charKey]
    if not cCfg or not cCfg.enabled or handledRolls[rollID] then return end
    
    local playerClass = GetPlayerClassProfile()
    local itemName, _, itemRarity, _, _, itemType, itemSubClass, _, itemEquipLoc = GetItemInfo(itemLink)
    if not itemName then return end
    
    local rarityKey = nil
    if itemRarity == 2 then rarityKey = "Green"
    elseif itemRarity == 3 then rarityKey = "Blue"
    elseif itemRarity == 4 then rarityKey = "Purple"
    end
    
    if cCfg.bulkQuality == 0 or (rarityKey and cCfg.quality and cCfg.quality[rarityKey] == 0) then return end
    if (itemType == "Armor" or itemSubClass == "Shields") and (cCfg.bulkArmor == 0 or (cCfg.armor and cCfg.armor[itemSubClass] == 0)) then return end
    if itemType == "Weapon" and (cCfg.bulkWeapons == 0 or (cCfg.weapons and cCfg.weapons[itemSubClass] == 0)) then return end
    if cCfg.autoGreedUnusable and IsItemUnusable(itemLink) then if ExecuteRollChoice(rollID, 2, itemLink, "Unusable") then return end end
    
        -- Weapon Exception Override: Prevents automatic stat passes on alternative weapon combos
    if itemType == "Weapon" or itemSubClass == "Shields" or itemEquipLoc == "INVTYPE_HOLDABLE" then
        local droppedScore = CalculateItemScore(itemLink)
        if alertTextString then 
            alertTextString:SetText("|cFFFFD100Weapon Dropped! Manual Choice Required|r") 
        end
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFD100[AutoRoll Override]|r Weapon combo piece dropped: %s (|cFF00FF00Score: %.2f|r). Auto-rolling paused so you can choose manually!", itemLink, droppedScore))
        return -- Safely exits the function right here, leaving the roll window open for you!
    end

    if cCfg.statModuleEnabled and itemEquipLoc and SLOT_MAP[itemEquipLoc] and AutoRollConfig.classProfiles and AutoRollConfig.classProfiles[playerClass] then
        local slotID = SLOT_MAP[itemEquipLoc] local equippedItemLink = GetInventoryItemLink("player", slotID)
        local droppedScore = CalculateItemScore(itemLink) local equippedScore = equippedItemLink and CalculateItemScore(equippedItemLink) or 0
        if droppedScore > equippedScore then if alertTextString then alertTextString:SetText("|cFF3399FFRoll NEED! Stat Upgrade!|r") end
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF3399FF[AutoRoll Alert]|r %s (|cFF00FF00Weight Score: %.2f|r) beats Equipped (|cFFFF0000Score: %.2f|r). Suggesting NEED!", itemLink, droppedScore, equippedScore))
        end
    end
    if rarityKey and cCfg.quality then
        local qChoice = 0 if cCfg.bulkQuality and cCfg.bulkQuality > 0 then qChoice = cCfg.bulkQuality else qChoice = cCfg.quality[rarityKey] or 0 end
        if qChoice > 0 then if ExecuteRollChoice(rollID, qChoice, itemLink, "Quality Filter") then return end end
    end
    if (itemType == "Armor" or itemSubClass == "Shields") and cCfg.armor then
        local aChoice = 0 if cCfg.bulkArmor and cCfg.bulkArmor > 0 then aChoice = cCfg.bulkArmor else aChoice = cCfg.armor[itemSubClass] or 0 end
        if aChoice > 0 then if ExecuteRollChoice(rollID, aChoice, itemLink, itemSubClass) then return end end
    end
    if itemType == "Weapon" and cCfg.weapons then
        local wChoice = 0 if cCfg.bulkWeapons and cCfg.bulkWeapons > 0 then wChoice = cCfg.bulkWeapons else wChoice = cCfg.weapons[itemSubClass] or 0 end
        if wChoice > 0 then if ExecuteRollChoice(rollID, wChoice, itemLink, itemSubClass) then return end end
    end
end


local dropdownCounter = 0

local function ForcePanelVisualSync()
    if settingsFrame and settingsFrame:IsShown() then settingsFrame:Hide() settingsFrame:Show() end
end

local function SyncBulkArmorOptions(val)
    local charKey = GetCharacterUniqueKey()
    local cCfg = AutoRollConfig.charSettings[charKey]
    if val and val > 0 and cCfg then
        cCfg.armor["Cloth"] = val cCfg.armor["Leather"] = val cCfg.armor["Mail"] = val cCfg.armor["Plate"] = val cCfg.armor["Shields"] = val
        ForcePanelVisualSync()
    end
end

local function SyncBulkWeaponOptions(val)
    local charKey = GetCharacterUniqueKey()
    local cCfg = AutoRollConfig.charSettings[charKey]
    if val and val > 0 and cCfg then
        cCfg.weapons["Daggers"] = val cCfg.weapons["One-Handed Swords"] = val cCfg.weapons["Two-Handed Swords"] = val cCfg.weapons["One-Handed Maces"] = val cCfg.weapons["Two-Handed Maces"] = val
        cCfg.weapons["One-Handed Axes"] = val cCfg.weapons["Two-Handed Axes"] = val cCfg.weapons["Staves"] = val cCfg.weapons["Bows"] = val cCfg.weapons["Guns"] = val cCfg.weapons["Crossbows"] = val
        ForcePanelVisualSync()
    end
end

local function SyncBulkQualityOptions(val)
    local charKey = GetCharacterUniqueKey()
    local cCfg = AutoRollConfig.charSettings[charKey]
    if val and val > 0 and cCfg then cCfg.quality["Green"] = val cCfg.quality["Blue"] = val cCfg.quality["Purple"] = val ForcePanelVisualSync() end
end

local function CreateDropdownMenu(parent, label, x, y, configTable, key, bulkCategory)
    dropdownCounter = dropdownCounter + 1 local name = "AutoRollDropdown_" .. dropdownCounter
    local lbl = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall") lbl:SetPoint("TOPLEFT", x, y) lbl:SetText(label)
    local f = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate") f:SetPoint("TOPLEFT", x + 105, y + 7) UIDropDownMenu_SetWidth(f, 75)
    local options = { "Manual", "Need", "Greed", "Pass" } if bulkCategory then options = { "Custom", "Need", "Greed", "Pass" } end
    UIDropDownMenu_Initialize(f, function()
        local info = UIDropDownMenu_CreateInfo()
        for i, optName in ipairs(options) do
            info.text = optName info.value = i - 1 info.checked = (configTable and configTable[key] == (i - 1))
            info.func = function(self)
                if configTable then configTable[key] = self.value end UIDropDownMenu_SetSelectedValue(f, self.value) UIDropDownMenu_SetText(f, options[self.value + 1])
                if bulkCategory == "armor" then SyncBulkArmorOptions(self.value) elseif bulkCategory == "weapons" then SyncBulkWeaponOptions(self.value) elseif bulkCategory == "quality" then SyncBulkQualityOptions(self.value) end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    local currentValue = (configTable and configTable[key]) or 0
    UIDropDownMenu_SetSelectedValue(f, currentValue) UIDropDownMenu_SetText(f, options[currentValue + 1])
    return f
end

local function CreateCheckbox(parent, label, x, y, configTable, key)
    local name = "AutoRollCheckButton_Master_" .. key local cb = CreateFrame("CheckButton", name, parent, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y) local text = _G[name .. "Text"] if text then text:SetText(label) end
    if configTable and configTable[key] ~= nil then cb:SetChecked(configTable[key]) end
    cb:SetScript("OnShow", function(self) if configTable and configTable[key] ~= nil then self:SetChecked(configTable[key]) end end)
    cb:SetScript("OnClick", function(self) if configTable then configTable[key] = not not self:GetChecked() end end)
    return cb
end




local function BuildWeightEditUI()
    if weightFrame or not AutoRollConfig then 
        return 
    end
    
    local editBoxesTable = {}
    local playerClass = GetPlayerClassProfile()
    -- Safety Lock: Prevents OnTextChanged from firing while the UI is drawing numbers
    local isUpdating = false
    
    if not AutoRollConfig.classProfiles then
        AutoRollConfig.classProfiles = {}
    end
    
    if not AutoRollConfig.classProfiles[playerClass] then
        AutoRollConfig.classProfiles[playerClass] = GetBlankStatTable()
    end
    
    local isProfileBlank = true
    for k, v in pairs(AutoRollConfig.classProfiles[playerClass]) do
        if v and tonumber(v) ~= 0 then
            isProfileBlank = false
            break
        end
    end
    
    if isProfileBlank and AutoRoll_ClassTemplates then
        local foundTemplate = nil
        for templateName, templateData in pairs(AutoRoll_ClassTemplates) do
            if string.lower(templateName) == string.lower(playerClass) then
                foundTemplate = templateData
                break
            end
        end
        if foundTemplate then
            for k, v in pairs(foundTemplate) do
                AutoRollConfig.classProfiles[playerClass][k] = v
            end
        end
    end
    
    for k, v in pairs(AutoRollConfig.classProfiles[playerClass]) do 
        tempWeights[k] = tonumber(v) or 0 
    end
    
    weightFrame = CreateFrame("Frame", "AutoRollWeightFrame", UIParent) 
    weightFrame:SetSize(280, 480) 
    weightFrame:SetPoint("TOPLEFT", statFrame, "BOTTOMLEFT", 0, -5)
    weightFrame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 5, right = 5, top = 5, bottom = 5 } })
    
    local title = weightFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal") 
    title:SetPoint("TOP", 0, -15) 
    title:SetText("|cFF3399FFModify weights: " .. playerClass .. "|r")
    
    local close = CreateFrame("Button", nil, weightFrame, "UIPanelCloseButton") 
    close:SetPoint("TOPRIGHT", -2, -2)
    
    local scrollFrame = CreateFrame("ScrollFrame", "AutoRollWeightScrollFrame", weightFrame, "UIPanelScrollFrameTemplate") 
    scrollFrame:SetPoint("TOPLEFT", 15, -45) 
    scrollFrame:SetPoint("BOTTOMRIGHT", -35, 50) 
    
    local content = CreateFrame("Frame", nil, scrollFrame) 
    content:SetWidth(210) 
    content:SetHeight(520) 
    scrollFrame:SetScrollChild(content)
    
    local dummy = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
    dummy:SetSize(1, 1) 
    dummy:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0) 
    dummy:Hide()
    
    local categorizedKeys = {
        { isHeader = true,  text = "|cFFFFD100[ Primary Stats ]|r" },
        { isStat = true,    key = "Strength" },
        { isStat = true,    key = "Agility" },
        { isStat = true,    key = "Stamina" },
        { isStat = true,    key = "Intellect" },
        { isStat = true,    key = "Spirit" },
        { isHeader = true,  text = "|cFFFFD100[ Secondary Stats ]|r" },
        { isStat = true,    key = "Crit" },
        { isStat = true,    key = "Hit" },
        { isStat = true,    key = "Haste" },
        { isStat = true,    key = "Resilience" },
        { isStat = true,    key = "Mana per 5" },
        { isHeader = true,  text = "|cFFFFD100[ Offensive Stats ]|r" },
        { isStat = true,    key = "Weapon DPS" },
        { isStat = true,    key = "Ranged DPS" },
        { isStat = true,    key = "Attack Power" },
        { isStat = true,    key = "Ranged Attack Power" }, 
        { isStat = true,    key = "Spell Power" },
        { isStat = true,    key = "Spell Damage" },
        { isStat = true,    key = "Armor Pen" },
        { isStat = true,    key = "Spell Pen" },
        { isStat = true,    key = "Expertise" }
    }
    
    local totalYOffset = 0
    for _, item in ipairs(categorizedKeys) do
        if item.isHeader then
            totalYOffset = totalYOffset - 12
            local headerTxt = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            headerTxt:SetPoint("TOPLEFT", content, "TOPLEFT", 5, totalYOffset) 
            headerTxt:SetText(item.text)
            totalYOffset = totalYOffset - 18
        elseif item.isStat then
            local key = item.key
            local lbl = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall") 
            lbl:SetPoint("TOPLEFT", content, "TOPLEFT", 12, totalYOffset - 3) 
            lbl:SetText(key) 
            lbl:SetWidth(110) 
            lbl:SetJustifyH("LEFT")
            
            local boxWrapper = CreateFrame("Frame", nil, content)
            boxWrapper:SetSize(60, 20) 
            boxWrapper:SetPoint("LEFT", lbl, "RIGHT", 10, 0)
            
            local eb = CreateFrame("EditBox", nil, boxWrapper, "InputBoxTemplate") 
            eb:SetSize(55, 18)
            eb:SetPoint("LEFT", boxWrapper, "LEFT", 0, 0)
            eb:SetAutoFocus(false) 
            eb:SetMaxLetters(6) 
            eb:SetTextInsets(4, 0, 0, 0)
            
            editBoxesTable[key] = eb
            
            eb:SetScript("OnShow", function(self) 
                -- Safeguarded localized show check
                if not isUpdating then
                    local currentVal = tempWeights[key] or 0
                    self:SetText(tostring(currentVal)) 
                    self:SetCursorPosition(0)
                end
            end)
            
            eb:SetScript("OnTextChanged", function(self) 
                -- Strictly ignore typing actions while the system is programmatically loading text strings
                if isUpdating then return end
                local txt = self:GetText() 
                if txt and txt ~= "" then 
                    tempWeights[key] = tonumber(txt) or 0 
                else 
                    tempWeights[key] = 0 
                end 
            end)
            totalYOffset = totalYOffset - 24
        end
    end
    content:SetHeight(math.abs(totalYOffset) + 20)
    
    -- Absolute UI Refresh Synchronization Hook
    weightFrame:SetScript("OnShow", function()
        isUpdating = true
        for key, ebBox in pairs(editBoxesTable) do
            local currentVal = tempWeights[key] or 0
            ebBox:SetText(tostring(currentVal))
            ebBox:SetCursorPosition(0)
        end
        isUpdating = false
    end)
    
    local saveBtn = CreateFrame("Button", nil, weightFrame, "UIPanelButtonTemplate")
    saveBtn:SetSize(140, 24) 
    saveBtn:SetPoint("BOTTOM", weightFrame, "BOTTOM", 0, 15) 
    saveBtn:SetText("[ Save Weights ]")
    
    saveBtn:SetScript("OnClick", function()
        if not AutoRollConfig or not AutoRollConfig.classProfiles or not AutoRollConfig.classProfiles[playerClass] then 
            return 
        end
        for k, v in pairs(tempWeights) do
            local cleanNum = tonumber(v)
            if not cleanNum or type(cleanNum) ~= "number" then cleanNum = 0 end
            AutoRollConfig.classProfiles[playerClass][k] = cleanNum
        end
        
        -- Safe programmatic panel refresh toggle string
        isUpdating = true
        if weightFrame and weightFrame:IsShown() then 
            weightFrame:Hide() 
            weightFrame:Show() 
        end
        isUpdating = false
        
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF00FF00[AutoRoll]|r Saved successfully to the shared account-wide |cFFFFFFFF%s|r profile library slot!", playerClass))
    end)
end




local function BuildStatUI()
    if statFrame or not AutoRollConfig then return end
    local charKey = GetCharacterUniqueKey()
    local cCfg = AutoRollConfig.charSettings[charKey]
    if not cCfg then return end
    
    statFrame = CreateFrame("Frame", "AutoRollStatFrame", UIParent) 
    statFrame:SetSize(260, 220) statFrame:SetPoint("TOPLEFT", settingsFrame, "TOPRIGHT", 12, 0)
    statFrame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 5, right = 5, top = 5, bottom = 5 } })
    
    local title = statFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal") 
    title:SetPoint("TOP", 0, -15) title:SetText("|cFF3399FFSmart Stats Config|r")
    
    local close = CreateFrame("Button", nil, statFrame, "UIPanelCloseButton") close:SetPoint("TOPRIGHT", -2, -2)
    local modCB = CreateCheckbox(statFrame, "Enable Scale Inspector", 15, -45, cCfg, "statModuleEnabled")
    local editWeightsBtn = CreateFrame("Button", nil, statFrame, "UIPanelButtonTemplate") 
    editWeightsBtn:SetSize(140, 24) editWeightsBtn:SetPoint("TOP", 0, -85) editWeightsBtn:SetText("[ Edit Scale Weights ]")
    
    editWeightsBtn:SetScript("OnClick", function() 
        if not weightFrame then BuildWeightEditUI() weightFrame:Show() if weightFrame:GetScript("OnShow") then weightFrame:GetScript("OnShow")() end
        else if weightFrame:IsShown() then weightFrame:Hide() else weightFrame:Show() if weightFrame:GetScript("OnShow") then weightFrame:GetScript("OnShow")() end end end 
    end)
    
    local desc = statFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall") 
    desc:SetPoint("TOPLEFT", 15, -125) desc:SetWidth(230) desc:SetJustifyH("LEFT")
    desc:SetText("|cFFFFD100Weight Scoring Mode:|r\nAddon calculates items over custom decimal matrix values. Items scoring higher than your equipped gear trigger NEED recommendations.")
    statFrame:Show()
end



function BuildUI()
    if settingsFrame or not AutoRollConfig then return end
    local charKey = GetCharacterUniqueKey()
    local cCfg = AutoRollConfig.charSettings[charKey]
    if not cCfg then return end
    
    -- Restored: Main frame height locked exactly back to 695 pixels as requested
    settingsFrame = CreateFrame("Frame", "AutoRollOptionsFrame", UIParent) 
    settingsFrame:SetSize(490, 695) 
    settingsFrame:SetPoint("CENTER")
    settingsFrame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 11, right = 12, top = 12, bottom = 11 } })
    settingsFrame:SetMovable(true) settingsFrame:EnableMouse(true) settingsFrame:RegisterForDrag("LeftButton")
    settingsFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    settingsFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    settingsFrame:Show()
    
    -- Realignment: Title shifted leftward (24px padding) and justified left to stay clear of buttons
    local title = settingsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge") 
    title:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 24, -18) 
    title:SetText("AutoRoll Settings: " .. UnitName("player"))
    title:SetJustifyH("LEFT")
    
    local close = CreateFrame("Button", nil, settingsFrame, "UIPanelCloseButton") close:SetPoint("TOPRIGHT", -6, -6)
    close:SetScript("OnClick", function() settingsFrame:Hide() if statFrame then statFrame:Hide() end if weightFrame then weightFrame:Hide() end end)
    
    -- Realignment: Lowered button down slightly (-18) so it aligns perfectly with the top title string row
    local statToggleBtn = CreateFrame("Button", nil, settingsFrame, "UIPanelButtonTemplate") 
    statToggleBtn:SetSize(110, 22) 
    statToggleBtn:SetPoint("TOPRIGHT", settingsFrame, "TOPRIGHT", -36, -18) 
    statToggleBtn:SetText("Smart Stats >>")
    statToggleBtn:SetScript("OnClick", function() if not statFrame then BuildStatUI() else if statFrame:IsShown() then statFrame:Hide() if weightFrame then weightFrame:Hide() end else statFrame:Show() end end end)
    
    local masterCB = CreateCheckbox(settingsFrame, "|cFFFFD100Enable AutoRoll Addon Rules|r", 20, -50, cCfg, "enabled")
    masterCB:SetScript("OnClick", function(self) cCfg.enabled = not not self:GetChecked() UpdateButtonVisuals() end)
    
    CreateCheckbox(settingsFrame, "Auto-Greed Unusable Items (Red Text)", 20, -75, cCfg, "autoGreedUnusable")
    CreateDropdownMenu(settingsFrame, "|cFF00FF00All Armor|r", 25, -110, cCfg, "bulkArmor", "armor")
    CreateDropdownMenu(settingsFrame, "|cFF00FF00All Rarities|r", 250, -110, cCfg, "bulkQuality", "quality")
    
    local armors = {"Cloth", "Leather", "Mail", "Plate", "Shields"}
    for i, name in ipairs(armors) do CreateDropdownMenu(settingsFrame, name, 25, -120 - (i * 28), cCfg.armor, name) end
    local qualities = { {label = "|cFF1EFF00Green|r", key = "Green"}, {label = "|cFF0070D8Blue|r", key = "Blue"}, {label = "|cFFA335EEPurple|r", key = "Purple"} }
    for i, qInfo in ipairs(qualities) do CreateDropdownMenu(settingsFrame, qInfo.label, 250, -120 - (i * 28), cCfg.quality, qInfo.key) end
    
    CreateDropdownMenu(settingsFrame, "|cFF00FF00All Weapons|r", 25, -285, cCfg, "bulkWeapons", "weapons")
    local weaps = { "Daggers", "One-Handed Swords", "Two-Handed Swords", "One-Handed Maces", "Two-Handed Maces", "One-Handed Axes", "Two-Handed Axes", "Staves", "Bows", "Guns", "Crossbows" }
    for i, name in ipairs(weaps) do
        local col = i <= 6 and 25 or 250 local row = i <= 6 and i or i - 6 local cleanLabel = name:gsub("One%-Handed ", "1H "):gsub("Two%-Handed ", "2H ")
        CreateDropdownMenu(settingsFrame, cleanLabel, col, -295 - (row * 28), cCfg.weapons, name) 
    end
    
    -- Realignment: Moved explanation box lower by half the remaining bottom gap distance (14px)
    local helpBox = CreateFrame("Frame", nil, settingsFrame) 
    helpBox:SetSize(440, 195) 
    helpBox:SetPoint("BOTTOM", settingsFrame, "BOTTOM", 0, 14)
    helpBox:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    helpBox:SetBackdropColor(0, 0, 0, 0.6)
    
    local helpText = helpBox:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall") helpText:SetPoint("TOPLEFT", 12, -12) helpText:SetWidth(415) helpText:SetJustifyH("LEFT") helpText:SetJustifyV("TOP") helpText:SetSpacing(4)
    local textLines = { "|cFFFFD100How AutoRoll Functions Internally:|r", "• Configured rule actions occur |cFFFFFFFFinstantly|r the exact millisecond a new item loot roll framework window prompt displays on your interface.", "• Setting an item type target rule value profile parameter to |cFFFF9900'Manual'|r completely prevents the script engine from interacting with it automatically, preserving regular item window selections.", "• |cFFFF2222CRITICAL SAFETY mechanism:|r If an item remains set to 'Manual' (or you decide to ignore a roll window while locked in heavy combat), the engine continuously tracks remaining frame timeout data.", "• When less than |cFFFFFFFF5 seconds|r remain on an ignored prompt, the fallback engine triggers an automatic |cFF00FF00Greed|r command selection so you never completely forfeit eligible group rewards." }
    helpText:SetText(table.concat(textLines, "\n"))
end



local function BuildLauncherButton()
    if AutoRollLauncherButton then 
        return 
    end
    local btn = CreateFrame("Button", "AutoRollLauncherButton", UIParent) 
    btn:SetSize(32, 32) 
    btn:SetPoint("CENTER", UIParent, "CENTER", (AutoRollConfig and AutoRollConfig.buttonX) or 0, (AutoRollConfig and AutoRollConfig.buttonY) or 150) 
    btn:SetFrameStrata("HIGH")
    btn:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    
    local icon = btn:CreateTexture(nil, "ARTWORK") 
    icon:SetSize(22, 22) 
    icon:SetPoint("CENTER", 0, 0) 
    icon:SetTexture("Interface\\Icons\\INV_Misc_Dice_01")
    
    alertTextString = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") 
    alertTextString:SetPoint("BOTTOM", btn, "TOP", 0, 4) 
    alertTextString:SetText("")
    
        function UpdateButtonVisuals() 
        local charKey = GetCharacterUniqueKey()
        local cCfg = AutoRollConfig and AutoRollConfig.charSettings and AutoRollConfig.charSettings[charKey]
        if cCfg and cCfg.enabled then 
            btn:SetBackdropColor(0, 0.6, 0, 0.8) btn:SetBackdropBorderColor(0.2, 1, 0.2, 1) icon:SetVertexColor(1, 1, 1, 1) 
        else 
            btn:SetBackdropColor(0.6, 0, 0, 0.8) btn:SetBackdropBorderColor(1, 0.2, 0.2, 1) icon:SetVertexColor(0.5, 0.5, 0.5, 0.8) 
        end 
    end
    
    btn:SetMovable(true) btn:EnableMouse(true) btn:RegisterForDrag("LeftButton")
    btn:SetScript("OnDragStart", function(self) if not settingsFrame or not settingsFrame:IsShown() then self:StartMoving() end end)
    btn:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() local _, _, _, x, y = self:GetPoint() if AutoRollConfig then AutoRollConfig.buttonX = x AutoRollConfig.buttonY = y end end)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    
    btn:SetScript("OnClick", function(self, button) 
        local charKey = GetCharacterUniqueKey()
        local cCfg = AutoRollConfig and AutoRollConfig.charSettings and AutoRollConfig.charSettings[charKey]
        if button == "LeftButton" and cCfg then
            cCfg.enabled = not cCfg.enabled UpdateButtonVisuals() if alertTextString then alertTextString:SetText("") end
            if settingsFrame and settingsFrame:IsShown() then settingsFrame:Hide() if statFrame then statFrame:Hide() end if weightFrame then weightFrame:Hide() end end
        elseif button == "RightButton" then
            if alertTextString then alertTextString:SetText("") end if not settingsFrame then BuildUI() else ToggleUI() end
        end
    end)
    btn:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_LEFT") GameTooltip:SetText("AutoRoll Core") GameTooltip:AddLine("Left-Click: |cFFFFFFFFToggle Entire Addon On/Off|r", 1, 1, 1) GameTooltip:AddLine("Right-Click: |cFFFFFFFFOpen Dropdown Settings Panel|r", 1, 1, 1) GameTooltip:Show() end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end) 
    UpdateButtonVisuals()
end

local isLoaded = false
local function InitializeAddon() 
    if isLoaded then return end isLoaded = true 
    
    if type(AutoRollConfig) ~= "table" or not AutoRollConfig.classProfiles then AutoRollConfig = nil end
    if not AutoRollConfig then 
        AutoRollConfig = defaults 
    else 
        if not AutoRollConfig.charSettings then AutoRollConfig.charSettings = {} end
        for k, v in pairs(defaults) do if AutoRollConfig[k] == nil then AutoRollConfig[k] = v end end 
    end 
    
    -- Spawn standalone character profile slots inside the shared database index framework
    local charKey = GetCharacterUniqueKey()
    if not AutoRollConfig.charSettings[charKey] then
        AutoRollConfig.charSettings[charKey] = GetBlankCharSettings()
    end
    
    local playerClass = GetPlayerClassProfile()
    local isProfileBlank = true
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
            else
                AutoRollConfig.classProfiles[playerClass] = GetBlankStatTable()
            end
        else
            AutoRollConfig.classProfiles[playerClass] = GetBlankStatTable()
        end
    end
    
    if AutoRollConfig.classProfiles[playerClass]["Ranged Attack Power"] == nil then AutoRollConfig.classProfiles[playerClass]["Ranged Attack Power"] = 0 end
    if AutoRollConfig.classProfiles and AutoRollConfig.classProfiles[playerClass] then
        for k, v in pairs(AutoRollConfig.classProfiles[playerClass]) do tempWeights[k] = tonumber(v) or 0 end
    end
    
    BuildLauncherButton() 
end

mainFrame:SetScript("OnEvent", function(self, event, arg1) 
    if event == "ADDON_LOADED" and arg1 == "AutoRoll" then pcall(InitializeAddon) elseif event == "PLAYER_LOGIN" then pcall(InitializeAddon) elseif event == "START_LOOT_ROLL" then local rollID = arg1 local itemLink = GetLootRollItemLink(rollID) handledRolls[rollID] = false if itemLink then pcall(ProcessLootRoll, rollID, itemLink) end elseif event == "CANCEL_LOOT_ROLL" then handledRolls[arg1] = nil end 
end)

mainFrame:SetScript("OnUpdate", function(self, elapsed) 
    local charKey = GetCharacterUniqueKey()
    local cCfg = AutoRollConfig and AutoRollConfig.charSettings and AutoRollConfig.charSettings[charKey]
    if not cCfg or not cCfg.enabled then return end 
    for i = 1, 4 do 
        local rollFrame = _G["GroupLootFrame"..i] 
        if rollFrame and rollFrame:IsShown() then 
            local rollID = rollFrame.rollID 
            if rollID and handledRolls[rollID] == false then 
                local statusBar = _G["GroupLootFrame"..i.."Timer"] 
                if statusBar then 
                    local secondsLeft = statusBar:GetValue() / 1000 
                    if secondsLeft > 0 and secondsLeft <= cCfg.timeThreshold then 
                        local itemLink = GetLootRollItemLink(rollID) local shouldFallback = true 
                        if itemLink then 
                            local _, _, _, _, _, itemType, itemSubClass = GetItemInfo(itemLink) 
                            if (itemType == "Weapon" and cCfg.weapons and cCfg.weapons[itemSubClass] == 0) or ((itemType == "Armor" or itemSubClass == "Shields") and cCfg.armor and cCfg.armor[itemSubClass] == 0) then shouldFallback = false end 
                        end 
                        if shouldFallback then handledRolls[rollID] = true RollOnLoot(rollID, 2) CloseActiveLootFrame(rollID) if alertTextString then alertTextString:SetText("") end end 
                    end 
                end 
            end 
        end 
    end 
end)

SLASH_AUTOROLL1 = "/autoroll" SlashCmdList["AUTOROLL"] = function() ToggleUI() end


--Test code below
-- Global Tooltip Hook for Ondemand Diagnostic Scans
-- Fortified Global Tooltip Hook for On-Demand Slot Comparison Upgrades
GameTooltip:HookScript("OnTooltipSetItem", function(self)
    if IsControlKeyDown() then
        local _, itemLink = self:GetItem()
        if not itemLink then return end
        
        local itemName, _, _, _, _, _, _, _, itemEquipLoc = GetItemInfo(itemLink)
        if not itemName then return end
        
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00--- AutoRoll Diagnostic Scan: " .. itemLink .. " ---|r")
        
        local playerClass = GetPlayerClassProfile()
        
                -- 1. Calculate the flat total score of the targeted inventory item
        local totalDroppedScore = 0
        for i = 1, self:NumLines() do
            local leftLine = _G[self:GetName() .. "TextLeft" .. i]
            if leftLine then
                local text = leftLine:GetText()
                if text then
                    -- Set Bonus Shield: Bypasses line logging completely for set benchmarks
                    if string.find(text, "Set:") or string.find(text, "%(%d+%)%s*Set") then
                        -- Ignores text row
                    else
                        local lineMatched = false
                        for _, item in ipairs(STAT_PATTERNS) do
                            local weight = 0
                            if AutoRollConfig and AutoRollConfig.classProfiles and AutoRollConfig.classProfiles[playerClass] then
                                weight = AutoRollConfig.classProfiles[playerClass][item.key] or 0
                            end
                            
                            for _, pattern in ipairs(item.pats) do
                                local match = string.match(text, pattern)
                                if match then
                                    local value = tonumber(match) or 0
                                    local lineScore = value * weight
                                    totalDroppedScore = totalDroppedScore + lineScore
                                    lineMatched = true
                                    DEFAULT_CHAT_FRAME:AddMessage(string.format("  |cFFFFD100Matched Line:|r \"%s\" -> |cFF3399FFKey:|r %s, |cFF00FF00Val:|r %s, |cFFFF9900Weight:|r %s (|cFF00FF00Score:+%.2f|r)", text, item.key, value, weight, lineScore))
                                    break
                                end
                            end
                            if lineMatched then break end
                        end
                    end -- End of Set Shield check
                end
            end
        end

        
                -- 2. Fortified Character Slot Detector adapted for Conquest of Azeroth
        local equippedScore = 0
        local equippedItemLink = nil
        local foundSlotID = nil

                -- A. Handle explicit weapon/shield/off-hand slots with priority pairing logic
        -- Smart Filter: If the item subclass is a core armor type (Cloth, Leather, Mail, Plate), it is FORCED to skip weapon logic!
        local isCoreArmor = (itemSubClass == "Cloth" or itemSubClass == "Leather" or itemSubClass == "Mail" or itemSubClass == "Plate")
        
        if not isCoreArmor and (itemEquipLoc == "INVTYPE_WEAPON" or itemEquipLoc == "INVTYPE_WEAPONMAINHAND" or itemEquipLoc == "INVTYPE_WEAPONOFFHAND" or itemEquipLoc == "INVTYPE_SHIELD" or itemEquipLoc == "INVTYPE_HOLDABLE" or itemType == "Weapon") then
            local mhLink = GetInventoryItemLink("player", 16)
            local ohLink = GetInventoryItemLink("player", 17)
            
            local mhScore = mhLink and CalculateItemScore(mhLink) or 0
            local ohScore = ohLink and CalculateItemScore(ohLink) or 0
            
            equippedScore = mhScore + ohScore
            equippedItemLink = string.format("MH: %s + OH: %s", mhLink or "[Empty]", ohLink or "[Empty]")
            
            if itemEquipLoc == "INVTYPE_WEAPON" or itemEquipLoc == "INVTYPE_WEAPONMAINHAND" or string.find(string.lower(itemEquipLoc or ""), "main") then
                totalDroppedScore = totalDroppedScore + ohScore
            elseif itemEquipLoc == "INVTYPE_SHIELD" or itemEquipLoc == "INVTYPE_HOLDABLE" or itemEquipLoc == "INVTYPE_WEAPONOFFHAND" or string.find(string.lower(itemEquipLoc or ""), "shield") or string.find(string.lower(itemEquipLoc or ""), "off") then
                totalDroppedScore = mhScore + totalDroppedScore
            end
            foundSlotID = 16 -- Flag to skip standard armor check
        end


        -- B. Fallback Armor Check: If slot isn't found yet, read the tooltip text directly to identify armor slots!
        if not foundSlotID then
            local lowerLinkStr = string.lower(itemLink or "")
            -- Primary text boundary loop scanning for explicit server gear strings
            for i = 1, self:NumLines() do
                local leftLine = _G[self:GetName() .. "TextLeft" .. i]
                local lineText = leftLine and leftLine:GetText() or ""
                if lineText ~= "" then
                    if string.find(lineText, "Head") or string.find(lineText, "Helm") then foundSlotID = 1 break
                    elseif string.find(lineText, "Neck") or string.find(lineText, "Amulet") then foundSlotID = 2 break
                    elseif string.find(lineText, "Shoulder") then foundSlotID = 3 break
                    elseif string.find(lineText, "Chest") or string.find(lineText, "Robe") or string.find(lineText, "Vest") then foundSlotID = 5 break
                    elseif string.find(lineText, "Waist") or string.find(lineText, "Belt") or string.find(lineText, "Girdle") then foundSlotID = 6 break
                    elseif string.find(lineText, "Legs") or string.find(lineText, "Pants") or string.find(lineText, "Greaves") then foundSlotID = 7 break
                    elseif string.find(lineText, "Feet") or string.find(lineText, "Boots") then foundSlotID = 8 break
                    elseif string.find(lineText, "Wrist") or string.find(lineText, "Bracers") then foundSlotID = 9 break
                    elseif string.find(lineText, "Hands") or string.find(lineText, "Gloves") or string.find(lineText, "Handwraps") or string.find(lineText, "Gauntlets") then foundSlotID = 10 break
                    elseif string.find(lineText, "Finger") or string.find(lineText, "Ring") then foundSlotID = 11 break
                    elseif string.find(lineText, "Trinket") then foundSlotID = 12 break
                    elseif string.find(lineText, "Back") or string.find(lineText, "Cloak") or string.find(lineText, "Cape") then foundSlotID = 15 break
                    end
                end
            end
            
            -- If text scanning fails, fall back to our SLOT_MAP configuration dictionary
            if not foundSlotID and itemEquipLoc and SLOT_MAP and SLOT_MAP[itemEquipLoc] then
                foundSlotID = SLOT_MAP[itemEquipLoc]
            end

            -- Execute the gear sheet query using the successfully isolated slot integer number
            if foundSlotID then
                local standardLink = GetInventoryItemLink("player", foundSlotID)
                if standardLink then
                    equippedScore = CalculateItemScore(standardLink)
                    equippedItemLink = standardLink
                end
            end
        end

        
        -- 3. Print the comprehensive dual-score mathematical evaluation to chat
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF3399FF[Target Item Score]:|r %.2f", totalDroppedScore))
        if equippedItemLink then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFF0000[Equipped Item Baseline]:|r %.2f (%s)", equippedScore, equippedItemLink))
            local scoreDelta = totalDroppedScore - equippedScore
            if scoreDelta > 0 then
                DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF00FF00[STAT UPGRADE!]:|r This item is a +%.2f upgrade over equipped!", scoreDelta))
            else
                DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFF2222[NO UPGRADE]:|r This item scores %.2f lower than equipped.", math.abs(scoreDelta)))
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFF999999[Slot Baseline]:|r Empty slot. This item is an absolute upgrade!")
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00------------------------------------------------|r")
    end
end)
