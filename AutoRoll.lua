-- Global array table holding current edits during typing sessions
local tempWeights = {}

-- Configuration Defaults Profile with added Stat Weight Matrices
local defaults = {
    enabled = true,
    timeThreshold = 5,
    autoGreedUnusable = true,
    buttonX = 0,
    buttonY = 150,
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
    
    -- Smart Stat Module Global Switch
    statModuleEnabled = false,
    
        -- Full Decimal Stat Weight Dictionary Table (Cleaned & Duplicate-Free)
    weights = {
        ["Strength"] = 0, ["Agility"] = 0, ["Stamina"] = 0, ["Intellect"] = 0, ["Spirit"] = 0,
        ["Crit"] = 0, ["Hit"] = 0, ["Haste"] = 0, ["Resilience"] = 0, ["Mana per 5"] = 0,
        ["Weapon DPS"] = 0, ["Ranged DPS"] = 0, ["Attack Power"] = 0, ["Spell Power"] = 0, 
        ["Spell Damage"] = 0, ["Armor Pen"] = 0, ["Spell Pen"] = 0, ["Expertise"] = 0
        } 
    }

-- Mapping database translating tooltip string text matching rules to database indices
local STAT_PATTERNS = {
    { key = "Strength",     pats = { "%+(%d+) Strength", "%+(%d+) strength" } },
    { key = "Agility",      pats = { "%+(%d+) Agility", "%+(%d+) agility" } },
    { key = "Stamina",      pats = { "%+(%d+) Stamina", "%+(%d+) stamina" } },
    { key = "Intellect",    pats = { "%+(%d+) Intellect", "%+(%d+) intellect" } },
    { key = "Spirit",       pats = { "%+(%d+) Spirit", "%+(%d+) spirit" } },
    { key = "Crit",         pats = { "critical strike rating", "Critical Strike", "crit rating", "Crit Rating", "Improves critical strike rating by (%d+)" } },
    { key = "Hit",          pats = { "hit rating", "Hit Rating", "Improves hit rating by (%d+)" } },
    { key = "Haste",        pats = { "haste rating", "Haste Rating", "Improves haste rating by (%d+)" } },
    { key = "Spell Power",  pats = { "spell power", "Spell Power", "Increases spell power by (%d+)" } },
    { key = "Attack Power", pats = { "attack power", "Attack Power", "Increases attack power by (%d+)" } },
    { key = "PvE Power",    pats = { "pve power", "PvE Power", "Increases PvE Power by (%d+)" } },
    { key = "Armor Pen",    pats = { "armor penetration", "Armor Pen", "Improves armor penetration rating by (%d+)" } },
    { key = "Weapon DPS",   pats = { "((%d+%.?%d*)) damage per second", "((%d+%.?%d*)) DPS" } },
    { key = "Ranged DPS",   pats = { "Ranged.*((%d+%.?%d*)) damage per second" } },
    { key = "Spell Damage", pats = { "Increases spell damage by (%d+)" } },
    { key = "Healing Power",pats = { "Increases healing power by (%d+)" } },
    { key = "Resilience",   pats = { "resilience rating", "Resilience" } },
    { key = "Mana per 5",   pats = { "mana per 5 sec", "Restores (%d+) mana per 5" } }
}

-- Hidden tooltip structure to scan item requirements and extract raw stats numbers
local scannerTooltip = CreateFrame("GameTooltip", "AutoRollScannerTooltip", nil, "GameTooltipTemplate")

local function IsItemUnusable(itemLink)
    if not itemLink then 
        return false 
    end
    scannerTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    scannerTooltip:ClearLines()
    scannerTooltip:SetHyperlink(itemLink)
    local unusable = false
    for i = 1, scannerTooltip:NumLines() do
        local leftLine = _G["AutoRollScannerTooltipTextLeft" .. i]
        if leftLine then
            local r, g, b = leftLine:GetTextColor()
            if r and g and b and r > 0.9 and g < 0.2 and b < 0.2 then 
                unusable = true 
                break 
            end
        end
    end
    scannerTooltip:Hide()
    return unusable
end

local function CalculateItemScore(itemLink)
    if not itemLink or not AutoRollConfig or not AutoRollConfig.weights then 
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
                for _, item in ipairs(STAT_PATTERNS) do
                    local weight = AutoRollConfig.weights[item.key] or 0
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
            end
        end
    end
    scannerTooltip:Hide()
    return totalScore
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

local SLOT_MAP = {
    ["INVTYPE_HEAD"] = 1, ["INVTYPE_NECK"] = 2, ["INVTYPE_SHOULDER"] = 3, ["INVTYPE_BODY"] = 4,
    ["INVTYPE_CHEST"] = 5, ["INVTYPE_ROBE"] = 5, ["INVTYPE_WAIST"] = 6, ["INVTYPE_LEGS"] = 7,
    ["INVTYPE_FEET"] = 8, ["INVTYPE_WRIST"] = 9, ["INVTYPE_HANDS"] = 10, ["INVTYPE_FINGER"] = 11,
    ["INVTYPE_TRINKET"] = 12, ["INVTYPE_CLOAK"] = 15, ["INVTYPE_WEAPON"] = 16, ["INVTYPE_SHIELD"] = 17,
    ["INVTYPE_RANGED"] = 18, ["INVTYPE_2HWEAPON"] = 16, ["INVTYPE_WEAPONMAINHAND"] = 16,
    ["INVTYPE_WEAPONOFFHAND"] = 17, ["INVTYPE_HOLDABLE"] = 17, ["INVTYPE_RANGEDRIGHT"] = 18
}

local alertTextString
local function ProcessLootRoll(rollID, itemLink)
    if not AutoRollConfig or not AutoRollConfig.enabled or handledRolls[rollID] then 
        return 
    end
    local itemName, _, itemRarity, _, _, itemType, itemSubClass, _, itemEquipLoc = GetItemInfo(itemLink)
    if not itemName then 
        return 
    end
    local rarityKey = nil
    if itemRarity == 2 then rarityKey = "Green"
    elseif itemRarity == 3 then rarityKey = "Blue"
    elseif itemRarity == 4 then rarityKey = "Purple"
    end
    if AutoRollConfig.bulkQuality == 0 or (rarityKey and AutoRollConfig.quality and AutoRollConfig.quality[rarityKey] == 0) then return end
    if (itemType == "Armor" or itemSubClass == "Shields") and (AutoRollConfig.bulkArmor == 0 or (AutoRollConfig.armor and AutoRollConfig.armor[itemSubClass] == 0)) then return end
    if itemType == "Weapon" and (AutoRollConfig.bulkWeapons == 0 or (AutoRollConfig.weapons and AutoRollConfig.weapons[itemSubClass] == 0)) then return end
    if AutoRollConfig.autoGreedUnusable and IsItemUnusable(itemLink) then if ExecuteRollChoice(rollID, 2, itemLink, "Unusable") then return end end
    if AutoRollConfig.statModuleEnabled and itemEquipLoc and SLOT_MAP[itemEquipLoc] then
        local slotID = SLOT_MAP[itemEquipLoc] local equippedItemLink = GetInventoryItemLink("player", slotID)
        local droppedScore = CalculateItemScore(itemLink) local equippedScore = equippedItemLink and CalculateItemScore(equippedItemLink) or 0
        if droppedScore > equippedScore then if alertTextString then alertTextString:SetText("|cFF3399FFRoll NEED! Stat Upgrade!|r") end
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF3399FF[AutoRoll Alert]|r %s (|cFF00FF00Weight Score: %.2f|r) beats Equipped (|cFFFF0000Score: %.2f|r). Suggesting NEED!", itemLink, droppedScore, equippedScore))
        end
    end
    if rarityKey and AutoRollConfig.quality then
        local qChoice = 0 if AutoRollConfig.bulkQuality and AutoRollConfig.bulkQuality > 0 then qChoice = AutoRollConfig.bulkQuality else qChoice = AutoRollConfig.quality[rarityKey] or 0 end
        if qChoice > 0 then if ExecuteRollChoice(rollID, qChoice, itemLink, "Quality Filter") then return end end
    end
    if (itemType == "Armor" or itemSubClass == "Shields") and AutoRollConfig.armor then
        local aChoice = 0 if AutoRollConfig.bulkArmor and AutoRollConfig.bulkArmor > 0 then aChoice = AutoRollConfig.bulkArmor else aChoice = AutoRollConfig.armor[itemSubClass] or 0 end
        if aChoice > 0 then if ExecuteRollChoice(rollID, aChoice, itemLink, itemSubClass) then return end end
    end
    if itemType == "Weapon" and AutoRollConfig.weapons then
        local wChoice = 0 if AutoRollConfig.bulkWeapons and AutoRollConfig.bulkWeapons > 0 then wChoice = AutoRollConfig.bulkWeapons else wChoice = AutoRollConfig.weapons[itemSubClass] or 0 end
        if wChoice > 0 then if ExecuteRollChoice(rollID, wChoice, itemLink, itemSubClass) then return end end
    end
end

local UpdateButtonVisuals
local dropdownCounter = 0

local function ForcePanelVisualSync()
    if settingsFrame and settingsFrame:IsShown() then settingsFrame:Hide() settingsFrame:Show() end
end

local function SyncBulkArmorOptions(val)
    if val and val > 0 then
        AutoRollConfig.armor["Cloth"] = val AutoRollConfig.armor["Leather"] = val AutoRollConfig.armor["Mail"] = val AutoRollConfig.armor["Plate"] = val AutoRollConfig.armor["Shields"] = val
        ForcePanelVisualSync()
    end
end

local function SyncBulkWeaponOptions(val)
    if val and val > 0 then
        AutoRollConfig.weapons["Daggers"] = val AutoRollConfig.weapons["One-Handed Swords"] = val AutoRollConfig.weapons["Two-Handed Swords"] = val AutoRollConfig.weapons["One-Handed Maces"] = val AutoRollConfig.weapons["Two-Handed Maces"] = val
        AutoRollConfig.weapons["One-Handed Axes"] = val AutoRollConfig.weapons["Two-Handed Axes"] = val AutoRollConfig.weapons["Staves"] = val AutoRollConfig.weapons["Bows"] = val AutoRollConfig.weapons["Guns"] = val AutoRollConfig.weapons["Crossbows"] = val
        ForcePanelVisualSync()
    end
end

local function SyncBulkQualityOptions(val)
    if val and val > 0 then AutoRollConfig.quality["Green"] = val AutoRollConfig.quality["Blue"] = val AutoRollConfig.quality["Purple"] = val ForcePanelVisualSync() end
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
    cb:SetScript("OnShow", function(self) if configTable then self:SetChecked(configTable[key]) end end)
    cb:SetScript("OnClick", function(self) if configTable then configTable[key] = not not self:GetChecked() end end)
    return cb
end

-- Create a completely custom font profile that bypasses the client's hardcoded gray theme
local AutoRollWhiteFont = CreateFont("AutoRollWhiteFont")
AutoRollWhiteFont:SetFont([[Fonts\FRIZQT__.TTF]], 10, "")
AutoRollWhiteFont:SetTextColor(1, 1, 1, 1)

local function BuildWeightEditUI()
    if weightFrame or not AutoRollConfig then 
        return 
    end
    
    local editBoxesTable = {}
    
    if AutoRollConfig.weights then
        for k, v in pairs(AutoRollConfig.weights) do 
            tempWeights[k] = tonumber(v) or 0 
        end
    end
    
    weightFrame = CreateFrame("Frame", "AutoRollWeightFrame", UIParent) 
    weightFrame:SetSize(280, 480) 
    weightFrame:SetPoint("TOPLEFT", statFrame, "BOTTOMLEFT", 0, -5)
    weightFrame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 5, right = 5, top = 5, bottom = 5 } })
    
    local title = weightFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal") 
    title:SetPoint("TOP", 0, -15) 
    title:SetText("|cFF3399FFModify Scale Weights|r")
    
    local close = CreateFrame("Button", nil, weightFrame, "UIPanelCloseButton") 
    close:SetPoint("TOPRIGHT", -2, -2)
    
    local scrollFrame = CreateFrame("ScrollFrame", "AutoRollWeightScrollFrame", weightFrame, "UIPanelScrollFrameTemplate") 
    scrollFrame:SetPoint("TOPLEFT", 15, -45) 
    scrollFrame:SetPoint("BOTTOMRIGHT", -35, 50) 
    
    local content = CreateFrame("Frame", nil, scrollFrame) 
    content:SetWidth(210) 
    content:SetHeight(520) 
    scrollFrame:SetScrollChild(content)
    
    -- Smart Fix: Spawns an invisible 1x1 dummy box at the exact ceiling edge to absorb the template texture crash
    local dummy = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
    dummy:SetSize(1, 1)
    dummy:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    dummy:Hide()
    
    -- Re-ordered category matrix array matching your website layout blocks exactly
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
            boxWrapper:SetSize(65, 18)
            boxWrapper:SetPoint("LEFT", lbl, "RIGHT", 5, 0)
            
            local eb = CreateFrame("EditBox", nil, boxWrapper, "InputBoxTemplate") 
            eb:SetAllPoints(boxWrapper)
            eb:SetAutoFocus(false) 
            eb:SetMaxLetters(6)
            eb:SetTextInsets(4, 0, 0, 0)
            
            editBoxesTable[key] = eb
            
            eb:SetScript("OnShow", function(self) 
                local currentVal = tempWeights[key] or 0
                self:SetText(tostring(currentVal)) 
            end)
            
            eb:SetScript("OnTextChanged", function(self) 
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
    
    local saveBtn = CreateFrame("Button", nil, weightFrame, "UIPanelButtonTemplate")
    saveBtn:SetSize(140, 24) 
    saveBtn:SetPoint("BOTTOM", weightFrame, "BOTTOM", 0, 15) 
    saveBtn:SetText("[ Save Weights ]")
    
    saveBtn:SetScript("OnClick", function()
        if not AutoRollConfig or not AutoRollConfig.weights then return end
        for k, v in pairs(tempWeights) do
            local cleanNum = tonumber(v)
            if not cleanNum or type(cleanNum) ~= "number" then cleanNum = 0 end
            AutoRollConfig.weights[k] = cleanNum
        end
        if weightFrame and weightFrame:IsShown() then weightFrame:Hide() weightFrame:Show() end
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[AutoRoll]|r Scale weights saved successfully to character profile!")
    end)
end


local function BuildStatUI()
    if statFrame or not AutoRollConfig then return end
    statFrame = CreateFrame("Frame", "AutoRollStatFrame", UIParent) 
    statFrame:SetSize(260, 220) 
    statFrame:SetPoint("TOPLEFT", settingsFrame, "TOPRIGHT", 12, 0)
    statFrame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 5, right = 5, top = 5, bottom = 5 } })
    
    local title = statFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal") 
    title:SetPoint("TOP", 0, -15) title:SetText("|cFF3399FFSmart Stats Config|r")
    
    local close = CreateFrame("Button", nil, statFrame, "UIPanelCloseButton") close:SetPoint("TOPRIGHT", -2, -2)
    local modCB = CreateCheckbox(statFrame, "Enable Scale Inspector", 15, -45, AutoRollConfig, "statModuleEnabled")
    local editWeightsBtn = CreateFrame("Button", nil, statFrame, "UIPanelButtonTemplate") 
    editWeightsBtn:SetSize(140, 24) editWeightsBtn:SetPoint("TOP", 0, -85) editWeightsBtn:SetText("[ Edit Scale Weights ]")
    
    editWeightsBtn:SetScript("OnClick", function() 
        if not weightFrame then
            BuildWeightEditUI()
            weightFrame:Show()
        else
            if weightFrame:IsShown() then 
                weightFrame:Hide() 
            else 
                weightFrame:Show() 
            end 
        end
    end)
    
    local desc = statFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall") 
    desc:SetPoint("TOPLEFT", 15, -125) desc:SetWidth(230) desc:SetJustifyH("LEFT")
    desc:SetText("|cFFFFD100Weight Scoring Mode:|r\nAddon calculates items over custom decimal matrix values. Items scoring higher than your equipped gear trigger NEED recommendations.")
    statFrame:Show()
end

function BuildUI()
    if settingsFrame or not AutoRollConfig then return end
    settingsFrame = CreateFrame("Frame", "AutoRollOptionsFrame", UIParent) 
    settingsFrame:SetSize(490, 695) settingsFrame:SetPoint("CENTER")
    settingsFrame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 11, right = 12, top = 12, bottom = 11 } })
    
    settingsFrame:SetMovable(true) settingsFrame:EnableMouse(true) settingsFrame:RegisterForDrag("LeftButton")
    settingsFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    settingsFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    -- Removed settingsFrame:Hide() from here so the initial generation right-click opens the window instantly!
    
    local title = settingsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge") title:SetPoint("TOP", 0, -18) title:SetText("AutoRoll Settings")

    
    local close = CreateFrame("Button", nil, settingsFrame, "UIPanelCloseButton") 
    close:SetPoint("TOPRIGHT", -6, -6)
    close:SetScript("OnClick", function()
        settingsFrame:Hide()
        if statFrame then statFrame:Hide() end
        if weightFrame then weightFrame:Hide() end
    end)
    
    local statToggleBtn = CreateFrame("Button", nil, settingsFrame, "UIPanelButtonTemplate") 
    statToggleBtn:SetSize(110, 22) 
    statToggleBtn:SetPoint("TOPRIGHT", -36, -16) 
    statToggleBtn:SetText("Smart Stats >>")
    
    statToggleBtn:SetScript("OnClick", function() 
        if not statFrame then
            BuildStatUI()
        else
            if statFrame:IsShown() then 
                statFrame:Hide() 
                if weightFrame then weightFrame:Hide() end 
            else 
                statFrame:Show() 
            end 
        end
    end)
    
    local masterCB = CreateCheckbox(settingsFrame, "|cFFFFD100Enable AutoRoll Addon Rules|r", 20, -50, AutoRollConfig, "enabled")
    masterCB:SetScript("OnClick", function(self) 
        if AutoRollConfig then 
            AutoRollConfig.enabled = not not self:GetChecked() 
        end 
        UpdateButtonVisuals() 
    end)
    
    CreateCheckbox(settingsFrame, "Auto-Greed Unusable Items (Red Text)", 20, -75, AutoRollConfig, "autoGreedUnusable")
    CreateDropdownMenu(settingsFrame, "|cFF00FF00All Armor|r", 25, -110, AutoRollConfig, "bulkArmor", "armor")
    CreateDropdownMenu(settingsFrame, "|cFF00FF00All Rarities|r", 250, -110, AutoRollConfig, "bulkQuality", "quality")
    
    local armors = {"Cloth", "Leather", "Mail", "Plate", "Shields"}
    for i, name in ipairs(armors) do 
        CreateDropdownMenu(settingsFrame, name, 25, -120 - (i * 28), AutoRollConfig.armor, name) 
    end
    
    local qualities = { {label = "|cFF1EFF00Green|r", key = "Green"}, {label = "|cFF0070D8Blue|r", key = "Blue"}, {label = "|cFFA335EEPurple|r", key = "Purple"} }
    for i, qInfo in ipairs(qualities) do 
        CreateDropdownMenu(settingsFrame, qInfo.label, 250, -120 - (i * 28), AutoRollConfig.quality, qInfo.key) 
    end
    
    CreateDropdownMenu(settingsFrame, "|cFF00FF00All Weapons|r", 25, -285, AutoRollConfig, "bulkWeapons", "weapons")
    
    local weaps = { "Daggers", "One-Handed Swords", "Two-Handed Swords", "One-Handed Maces", "Two-Handed Maces", "One-Handed Axes", "Two-Handed Axes", "Staves", "Bows", "Guns", "Crossbows" }
    for i, name in ipairs(weaps) do 
        local col = i <= 6 and 25 or 250 
        local row = i <= 6 and i or i - 6 
        local cleanLabel = name:gsub("One%-Handed ", "1H "):gsub("Two%-Handed ", "2H ") 
        CreateDropdownMenu(settingsFrame, cleanLabel, col, -295 - (row * 28), AutoRollConfig.weapons, name) 
    end
    
    local helpBox = CreateFrame("Frame", nil, settingsFrame) 
    helpBox:SetSize(440, 195) 
    helpBox:SetPoint("BOTTOM", settingsFrame, "BOTTOM", 0, 22)
    helpBox:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    helpBox:SetBackdropColor(0, 0, 0, 0.6)
    
    local helpText = helpBox:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall") 
    helpText:SetPoint("TOPLEFT", 12, -12) 
    helpText:SetWidth(415) 
    helpText:SetJustifyH("LEFT") 
    helpText:SetJustifyV("TOP") 
    helpText:SetSpacing(4)
    
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
        if AutoRollConfig and AutoRollConfig.enabled then 
            btn:SetBackdropColor(0, 0.6, 0, 0.8) 
            btn:SetBackdropBorderColor(0.2, 1, 0.2, 1) 
            icon:SetVertexColor(1, 1, 1, 1) 
        else 
            btn:SetBackdropColor(0.6, 0, 0, 0.8) 
            btn:SetBackdropBorderColor(1, 0.2, 0.2, 1) 
            icon:SetVertexColor(0.5, 0.5, 0.5, 0.8) 
        end 
    end
    
    btn:SetMovable(true) 
    btn:EnableMouse(true) 
    btn:RegisterForDrag("LeftButton")
    btn:SetScript("OnDragStart", function(self) if not settingsFrame or not settingsFrame:IsShown() then self:StartMoving() end end)
    btn:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() local _, _, _, x, y = self:GetPoint() if AutoRollConfig then AutoRollConfig.buttonX = x AutoRollConfig.buttonY = y end end)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    
    btn:SetScript("OnClick", function(self, button) 
        if button == "LeftButton" and AutoRollConfig then
            AutoRollConfig.enabled = not AutoRollConfig.enabled 
            UpdateButtonVisuals() 
            if alertTextString then alertTextString:SetText("") end
            if settingsFrame and settingsFrame:IsShown() then 
                settingsFrame:Hide() 
                if statFrame then statFrame:Hide() end 
                if weightFrame then weightFrame:Hide() end 
            end
        elseif button == "RightButton" then
            if alertTextString then alertTextString:SetText("") end 
            -- Fixed execution path bypasses the double right-click engine loop glitch
            if not settingsFrame then
                BuildUI()
            else
                ToggleUI()
            end
        end
    end)
    btn:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_LEFT") GameTooltip:SetText("AutoRoll Core") GameTooltip:AddLine("Left-Click: |cFFFFFFFFToggle Entire Addon On/Off|r", 1, 1, 1) GameTooltip:AddLine("Right-Click: |cFFFFFFFFOpen Dropdown Settings Panel|r", 1, 1, 1) GameTooltip:Show() end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end) 
    UpdateButtonVisuals()
end

local isLoaded = false
local function InitializeAddon() 
    if isLoaded then return end 
    isLoaded = true 
    if type(AutoRollConfig) ~= "table" or not AutoRollConfig.weights or type(AutoRollConfig.armor) ~= "table" then 
        AutoRollConfig = nil 
    end
    if not AutoRollConfig then 
        AutoRollConfig = defaults 
    else 
        for k, v in pairs(defaults) do 
            if AutoRollConfig[k] == nil then 
                AutoRollConfig[k] = v 
            end 
        end 
    end 
    BuildLauncherButton() 
end

mainFrame:SetScript("OnEvent", function(self, event, arg1) 
    if event == "ADDON_LOADED" and arg1 == "AutoRoll" then pcall(InitializeAddon) elseif event == "PLAYER_LOGIN" then pcall(InitializeAddon) elseif event == "START_LOOT_ROLL" then local rollID = arg1 local itemLink = GetLootRollItemLink(rollID) handledRolls[rollID] = false if itemLink then pcall(ProcessLootRoll, rollID, itemLink) end elseif event == "CANCEL_LOOT_ROLL" then handledRolls[arg1] = nil end 
end)

mainFrame:SetScript("OnUpdate", function(self, elapsed) 
    if not AutoRollConfig or not AutoRollConfig.enabled then return end 
    for i = 1, 4 do 
        local rollFrame = _G["GroupLootFrame"..i] 
        if rollFrame and rollFrame:IsShown() then 
            local rollID = rollFrame.rollID 
            if rollID and handledRolls[rollID] == false then 
                local statusBar = _G["GroupLootFrame"..i.."Timer"] 
                if statusBar then 
                    local secondsLeft = statusBar:GetValue() / 1000 
                    if secondsLeft > 0 and secondsLeft <= AutoRollConfig.timeThreshold then 
                        local itemLink = GetLootRollItemLink(rollID) local shouldFallback = true 
                        if itemLink then 
                            local _, _, _, _, _, itemType, itemSubClass = GetItemInfo(itemLink) 
                            if (itemType == "Weapon" and AutoRollConfig.weapons and AutoRollConfig.weapons[itemSubClass] == 0) or ((itemType == "Armor" or itemSubClass == "Shields") and AutoRollConfig.armor and AutoRollConfig.armor[itemSubClass] == 0) then shouldFallback = false end 
                        end 
                        if shouldFallback then handledRolls[rollID] = true RollOnLoot(rollID, 2) CloseActiveLootFrame(rollID) if alertTextString then alertTextString:SetText("") end end 
                    end 
                end 
            end 
        end 
    end 
end)

SLASH_AUTOROLL1 = "/autoroll" 
SlashCmdList["AUTOROLL"] = function() 
    ToggleUI() 
end
