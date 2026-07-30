-- Configuration Defaults Profile with added Stat Scoring Module Data structures
local defaults = {
    enabled = true,
    timeThreshold = 5,
    autoGreedUnusable = true,
    buttonX = 0,
    buttonY = 150,
    bulkArmor = 0, bulkWeapons = 0, bulkQuality = 0,
    armor = { ["Cloth"] = 0, ["Leather"] = 0, ["Mail"] = 0, ["Plate"] = 0 },
    weapons = {
        ["Daggers"] = 0, ["One-Handed Swords"] = 0, ["Two-Handed Swords"] = 0, ["One-Handed Maces"] = 0,
        ["Two-Handed Maces"] = 0, ["One-Handed Axes"] = 0, ["Two-Handed Axes"] = 0, ["Staves"] = 0, ["Bows"] = 0, ["Guns"] = 0
    },
    quality = { ["Green"] = 0, ["Blue"] = 0, ["Purple"] = 0 },
    
    -- Smart Stat Module Configuration Tables
    statModuleEnabled = false,
    mainStatWeight = 10,
    secStatWeight = 5,
    selectedMainStat = "Intellect",
    selectedSecStat = "Agility",
}

-- Comprehensive raw text matching index dictionary for item scanning parsing loops
local STAT_PATTERNS = {
    ["Strength"]  = "%+(%d+) Strength",
    ["Agility"]   = "%+(%d+) Agility",
    ["Stamina"]   = "%+(%d+) Stamina",
    ["Intellect"] = "%+(%d+) Intellect",
    ["Spirit"]    = "%+(%d+) Spirit",
}

-- Hidden tooltip structure to scan item requirements and extract raw stats numbers
local scannerTooltip = CreateFrame("GameTooltip", "AutoRollScannerTooltip", nil, "GameTooltipTemplate")
scannerTooltip:SetOwner(WorldFrame, "SHOPPING_TOOLTIP_HAS_ITEM")

local function IsItemUnusable(itemLink)
    if not itemLink then return false end
    scannerTooltip:ClearLines()
    scannerTooltip:SetHyperlink(itemLink)
    for i = 1, scannerTooltip:NumLines() do
        local leftLine = _G["AutoRollScannerTooltipTextLeft" .. i]
        if leftLine then
            local r, g, b = leftLine:GetTextColor()
            if r and g and b and r > 0.9 and g < 0.2 and b < 0.2 then return true end
        end
    end
    return false
end

-- Deep tooltip string parsing calculator engine
local function CalculateItemScore(itemLink)
    if not itemLink then return 0 end
    scannerTooltip:ClearLines()
    scannerTooltip:SetHyperlink(itemLink)
    
    local mainStat = (AutoRollConfig and AutoRollConfig.selectedMainStat) or "Intellect"
    local secStat = (AutoRollConfig and AutoRollConfig.selectedSecStat) or "Agility"
    local patternMain = STAT_PATTERNS[mainStat]
    local patternSec = STAT_PATTERNS[secStat]
    
    local totalMainFound = 0
    local totalSecFound = 0
    
    for i = 1, scannerTooltip:NumLines() do
        local leftLine = _G["AutoRollScannerTooltipTextLeft" .. i]
        if leftLine then
            local text = leftLine:GetText()
            if text then
                if patternMain then
                    local match = string.match(text, patternMain)
                    if match then totalMainFound = totalMainFound + (tonumber(match) or 0) end
                end
                if patternSec then
                    local match = string.match(text, patternSec)
                    if match then totalSecFound = totalSecFound + (tonumber(match) or 0) end
                end
            end
        end
    end
    
    local wMain = (AutoRollConfig and AutoRollConfig.mainStatWeight) or 10
    local wSec = (AutoRollConfig and AutoRollConfig.secStatWeight) or 5
    return (totalMainFound * wMain) + (totalSecFound * wSec)
end

local handledRolls = {}
local mainFrame = CreateFrame("Frame")
mainFrame:RegisterEvent("ADDON_LOADED")
mainFrame:RegisterEvent("PLAYER_LOGIN")
mainFrame:RegisterEvent("START_LOOT_ROLL")
mainFrame:RegisterEvent("CANCEL_LOOT_ROLL")

local function ExecuteRollChoice(rollID, choiceCode, itemLink, reason)
    if choiceCode and choiceCode >= 1 and choiceCode <= 3 then
        handledRolls[rollID] = true
        RollOnLoot(rollID, choiceCode == 3 and 0 or choiceCode)
        local rollNames = { "Need", "Greed", "Pass" }
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[AutoRoll]|r Auto-" .. rollNames[choiceCode] .. ": " .. itemLink .. " (" .. reason .. ")")
        return true
    end
    return false
end
-- Maps global WoW item locations over to standard physical container gear slots
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
    if not AutoRollConfig or not AutoRollConfig.enabled or handledRolls[rollID] then return end
    local itemName, _, itemRarity, _, _, itemType, itemSubClass, _, itemEquipLoc = GetItemInfo(itemLink)
    if not itemName then return end
    
    if AutoRollConfig.autoGreedUnusable and IsItemUnusable(itemLink) then
        if ExecuteRollChoice(rollID, 2, itemLink, "Unusable") then return end
    end
    
    -- SMART STAT MODULE INTERCEPT PROCESSING ENGINE
    if AutoRollConfig.statModuleEnabled and itemEquipLoc and SLOT_MAP[itemEquipLoc] then
        local slotID = SLOT_MAP[itemEquipLoc]
        local equippedItemLink = GetInventoryItemLink("player", slotID)
        
        local droppedScore = CalculateItemScore(itemLink)
        local equippedScore = equippedItemLink and CalculateItemScore(equippedItemLink) or 0
        
        if droppedScore > equippedScore then
            if alertTextString then alertTextString:SetText("|cFF3399FFRoll NEED! Stat Upgrade!|r") end
            DEFAULT_CHAT_FRAME:AddMessage("|cFF3399FF[AutoRoll Alert]|r Drop " .. itemLink .. " (|cFF00FF00Score: " .. droppedScore .. "|r) beats Equipped (|cFFFF0000Score: " .. equippedScore .. "|r). Suggesting NEED!")
        end
    end
    
    -- Restructured safe checking architecture blocks
    local rarityMap = { [2] = "Green", [3] = "Blue", [4] = "Purple" }
    local rarityKey = rarityMap[itemRarity]
    
    if rarityKey and AutoRollConfig.quality then
        local qChoice = 0
        if AutoRollConfig.bulkQuality and AutoRollConfig.bulkQuality > 0 then
            qChoice = AutoRollConfig.bulkQuality
        else
            qChoice = AutoRollConfig.quality[rarityKey] or 0
        end
        if qChoice > 0 then
            if ExecuteRollChoice(rollID, qChoice, itemLink, "Quality Filter") then return end
        end
    end
    
    if itemType == "Armor" and AutoRollConfig.armor then
        local aChoice = 0
        if AutoRollConfig.bulkArmor and AutoRollConfig.bulkArmor > 0 then
            aChoice = AutoRollConfig.bulkArmor
        else
            aChoice = AutoRollConfig.armor[itemSubClass] or 0
        end
        if aChoice > 0 then
            if ExecuteRollChoice(rollID, aChoice, itemLink, itemSubClass) then return end
        end
    end
    
    if itemType == "Weapon" and AutoRollConfig.weapons then
        local wChoice = 0
        if AutoRollConfig.bulkWeapons and AutoRollConfig.bulkWeapons > 0 then
            wChoice = AutoRollConfig.bulkWeapons
        else
            wChoice = AutoRollConfig.weapons[itemSubClass] or 0
        end
        if wChoice > 0 then
            if ExecuteRollChoice(rollID, wChoice, itemLink, itemSubClass) then return end
        end
    end
end

-- GUI Layout Construction Engine pointers
local settingsFrame, statFrame, UpdateButtonVisuals
local dropdownCounter = 0
local activeDropdowns = {}

local function CreateDropdownMenu(parent, label, x, y, configTable, key, isBulk, bulkKey)
    dropdownCounter = dropdownCounter + 1
    local name = "AutoRollDropdown_" .. dropdownCounter
    
    local lbl = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    lbl:SetPoint("TOPLEFT", x, y)
    lbl:SetText(label)
    
    local f = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
    f:SetPoint("TOPLEFT", x + 105, y + 7)
    UIDropDownMenu_SetWidth(f, 75)
    
    local options = { "Manual", "Need", "Greed", "Pass" }
    if isBulk then options = { "Custom", "Need", "Greed", "Pass" } end
    
    if not isBulk then activeDropdowns[name] = { f = f, t = configTable, k = key, bk = bulkKey } end
    
    UIDropDownMenu_Initialize(f, function()
        local info = UIDropDownMenu_CreateInfo()
        for i, optName in ipairs(options) do
            info.text = optName
            info.value = i - 1
            info.checked = (configTable and configTable[key] == (i - 1))
            info.func = function(self)
                if configTable then configTable[key] = self.value end
                UIDropDownMenu_SetSelectedValue(f, self.value)
                UIDropDownMenu_SetText(f, options[self.value + 1])
                
                if isBulk then
                    for dName, data in activeDropdowns do
                        if data.bk == key then
                            if self.value > 0 and data.t then
                                data.t[data.k] = self.value
                                UIDropDownMenu_SetSelectedValue(data.f, self.value)
                                local subOpts = { "Manual", "Need", "Greed", "Pass" }
                                UIDropDownMenu_SetText(data.f, subOpts[self.value + 1])
                            end
                        end
                    end
                end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    local currentValue = (configTable and configTable[key]) or 0
    UIDropDownMenu_SetSelectedValue(f, currentValue)
    UIDropDownMenu_SetText(f, options[currentValue + 1])
    return f
end
local function CreateStatDropdown(parent, label, x, y, configTable, key, optionsList)
    dropdownCounter = dropdownCounter + 1
    local name = "AutoRollStatDropdown_" .. dropdownCounter
    
    local lbl = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    lbl:SetPoint("TOPLEFT", x, y)
    lbl:SetText(label)
    
    local f = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
    f:SetPoint("TOPLEFT", x + 105, y + 7)
    UIDropDownMenu_SetWidth(f, 85)
    
    UIDropDownMenu_Initialize(f, function()
        local info = UIDropDownMenu_CreateInfo()
        for _, optName in ipairs(optionsList) do
            info.text = optName
            info.value = optName
            info.checked = (configTable and configTable[key] == optName)
            info.func = function(self)
                if configTable then configTable[key] = self.value end
                UIDropDownMenu_SetSelectedValue(f, self.value)
                UIDropDownMenu_SetText(f, self.value)
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    local currentVal = (configTable and configTable[key]) or optionsList[1]
    UIDropDownMenu_SetSelectedValue(f, currentVal)
    UIDropDownMenu_SetText(f, currentVal)
    return f
end

local function CreateCheckbox(parent, label, x, y, configTable, key)
    local name = "AutoRollCheckButton_Master_" .. key
    local cb = CreateFrame("CheckButton", name, parent, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)
    local text = _G[name .. "Text"]
    if text then text:SetText(label) end
    cb:SetScript("OnShow", function(self) if configTable then self:SetChecked(configTable[key]) end end)
    cb:SetScript("OnClick", function(self) if configTable then configTable[key] = not not self:GetChecked() end end)
    return cb
end

local BuildUI

local function ToggleUI()
    if not settingsFrame then BuildUI() end
    if settingsFrame then
        if settingsFrame:IsShown() then 
            settingsFrame:Hide() 
            if statFrame then statFrame:Hide() end
        else 
            settingsFrame:Show() 
        end
    end
end

local function BuildStatUI()
    if statFrame or not AutoRollConfig then return end
    
    statFrame = CreateFrame("Frame", "AutoRollStatFrame", UIParent)
    statFrame:SetSize(255, 400)
    statFrame:SetPoint("LEFT", settingsFrame, "RIGHT", 12, 0)
    statFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    statFrame:Hide()
    
    local title = statFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetPoint("TOP", 0, -15)
    title:SetText("|cFF3399FFSmart Stats Config|r")
    
    local close = CreateFrame("Button", nil, statFrame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)
    
    local modCB = CreateCheckbox(statFrame, "Enable Auto-Inspect", 15, -45, AutoRollConfig, "statModuleEnabled")
    modCB:SetScript("OnClick", function(self) AutoRollConfig.statModuleEnabled = not not self:GetChecked() end)
    
    local statList = { "Strength", "Agility", "Stamina", "Intellect", "Spirit" }
    CreateStatDropdown(statFrame, "Main Stat", 15, -95, AutoRollConfig, "selectedMainStat", statList)
    CreateStatDropdown(statFrame, "Sec. Stat", 15, -145, AutoRollConfig, "selectedSecStat", statList)
    
    local mHelpBox = CreateFrame("Frame", nil, statFrame)
    mHelpBox:SetSize(225, 190)
    mHelpBox:SetPoint("BOTTOM", 0, 15)
    mHelpBox:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 12, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    mHelpBox:SetBackdropColor(0, 0, 0, 0.6)

    local mHelpText = mHelpBox:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    mHelpText:SetPoint("TOPLEFT", 10, -10)
    mHelpText:SetWidth(205)
    mHelpText:SetJustifyH("LEFT")
    mHelpText:SetJustifyV("TOP")
    mHelpText:SetSpacing(3)
    
    local mTextLines = {
        "|cFFFFD100Module Rules:|r",
        "• Automatically reads and analyzes the raw values of any item drops that match your equip slots.",
        "• Calculates complex score matrices based on active options.",
        "• If a drop out-values your currently equipped gear pieces, it highlights the launcher button to suggest NEED."
    }
    mHelpText:SetText(table.concat(mTextLines, "\n"))
end
function BuildUI()
    if settingsFrame or not AutoRollConfig then return end
    
    settingsFrame = CreateFrame("Frame", "AutoRollOptionsFrame", UIParent)
    settingsFrame:SetSize(490, 740)
    settingsFrame:SetPoint("CENTER")
    settingsFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    settingsFrame:SetMovable(true)
    settingsFrame:EnableMouse(true)
    settingsFrame:RegisterForDrag("LeftButton")
    settingsFrame:SetScript("OnDragStart", settingsFrame.StartMoving)
    settingsFrame:SetScript("OnDragStop", settingsFrame.StopMovingOrSizing)
    settingsFrame:Hide()

    local title = settingsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -18)
    title:SetText("AutoRoll Settings")

    local close = CreateFrame("Button", nil, settingsFrame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)
    
    local statToggleBtn = CreateFrame("Button", nil, settingsFrame, "UIPanelButtonTemplate")
    statToggleBtn:SetSize(110, 22)
    statToggleBtn:SetPoint("TOPRIGHT", -36, -16)
    statToggleBtn:SetText("Smart Stats >>")
    statToggleBtn:SetScript("OnClick", function()
        BuildStatUI()
        if statFrame then
            if statFrame:IsShown() then statFrame:Hide() else statFrame:Show() end
        end
    end)

    local masterCB = CreateCheckbox(settingsFrame, "|cFFFFD100Enable AutoRoll Addon Rules|r", 20, -50, AutoRollConfig, "enabled")
    masterCB:SetScript("OnClick", function(self) 
        if AutoRollConfig then AutoRollConfig.enabled = not not self:GetChecked() end
        UpdateButtonVisuals()
    end)
    
    CreateCheckbox(settingsFrame, "Auto-Greed Unusable Items (Red Text)", 20, -75, AutoRollConfig, "autoGreedUnusable")

    CreateDropdownMenu(settingsFrame, "|cFF00FF00All Armor|r", 25, -110, AutoRollConfig, "bulkArmor", true)
    CreateDropdownMenu(settingsFrame, "|cFF00FF00All Rarities|r", 250, -110, AutoRollConfig, "bulkQuality", true)

    local armors = {"Cloth", "Leather", "Mail", "Plate"}
    for i, name in ipairs(armors) do CreateDropdownMenu(settingsFrame, name, 25, -120 - (i * 28), AutoRollConfig.armor, name, false, "bulkArmor") end

    local qualities = { {label = "|cFF1EFF00Green|r", key = "Green"}, {label = "|cFF0070D8Blue|r", key = "Blue"}, {label = "|cFFA335EEPurple|r", key = "Purple"} }
    for i, qInfo in ipairs(qualities) do CreateDropdownMenu(settingsFrame, qInfo.label, 250, -120 - (i * 28), AutoRollConfig.quality, qInfo.key, false, "bulkQuality") end

    CreateDropdownMenu(settingsFrame, "|cFF00FF00All Weapons|r", 25, -280, AutoRollConfig, "bulkWeapons", true)
    
    local weaps = {
        "Daggers", "One-Handed Swords", "Two-Handed Swords", "One-Handed Maces",
        "Two-Handed Maces", "One-Handed Axes", "Two-Handed Axes", "Staves", "Bows", "Guns"
    }
    for i, name in ipairs(weaps) do
        local col = i <= 5 and 25 or 250
        local row = i <= 5 and i or i - 5
        local cleanLabel = name:gsub("One%-Handed ", "1H "):gsub("Two%-Handed ", "2H ")
        CreateDropdownMenu(settingsFrame, cleanLabel, col, -290 - (row * 28), AutoRollConfig.weapons, name, false, "bulkWeapons")
    end

    local helpBox = CreateFrame("Frame", nil, settingsFrame)
    helpBox:SetSize(440, 200)
    helpBox:SetPoint("TOP", settingsFrame, "TOP", 0, -475)
    helpBox:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    helpBox:SetBackdropColor(0, 0, 0, 0.6)

    local helpText = helpBox:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    helpText:SetPoint("TOPLEFT", 12, -12)
    helpText:SetWidth(415)
    helpText:SetJustifyH("LEFT")
    helpText:SetJustifyV("TOP")
    helpText:SetSpacing(4)
    
    local textLines = {
        "|cFFFFD100How AutoRoll Functions Internally:|r",
        "• Configured rule actions occur |cFFFFFFFFinstantly|r the exact millisecond a new item loot roll framework window prompt displays on your interface.",
        "• Setting an item type target rule value profile parameter to |cFFFF9900'Manual'|r completely prevents the script engine from interacting with it automatically, preserving regular item window selections.",
        "• |cFFFF2222CRITICAL SAFETY mechanism:|r If an item remains set to 'Manual' (or you decide to ignore a roll window while locked in heavy combat), the engine continuously tracks remaining frame timeout data.",
        "• When less than |cFFFFFFFF5 seconds|r remain on an ignored prompt, the fallback engine triggers an automatic |cFF00FF00Greed|r command selection so you never completely forfeit eligible group rewards."
    }
    helpText:SetText(table.concat(textLines, "\n"))
end
local function BuildLauncherButton()
    if AutoRollLauncherButton then return end

    local btn = CreateFrame("Button", "AutoRollLauncherButton", UIParent)
    btn:SetSize(32, 32)
    btn:SetPoint("CENTER", UIParent, "CENTER", (AutoRollConfig and AutoRollConfig.buttonX) or 0, (AutoRollConfig and AutoRollConfig.buttonY) or 150)
    btn:SetFrameStrata("HIGH")
    
    btn:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })

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
    
    btn:SetScript("OnDragStart", function(self)
        if not settingsFrame or not settingsFrame:IsShown() then self:StartMoving() end
    end)
    
    btn:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local _, _, _, x, y = self:GetPoint()
        if AutoRollConfig then
            AutoRollConfig.buttonX = x
            AutoRollConfig.buttonY = y
        end
    end)
    
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:SetScript("OnClick", function(self, button)
        if button == "LeftButton" and AutoRollConfig then
            AutoRollConfig.enabled = not AutoRollConfig.enabled
            UpdateButtonVisuals()
            if alertTextString then alertTextString:SetText("") end
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[AutoRoll]|r Status changed: " .. (AutoRollConfig.enabled and "|cFF00FF00Enabled|r" or "|cFFFF0000Disabled|r"))
            if settingsFrame and settingsFrame:IsShown() then
                settingsFrame:Hide()
                settingsFrame:Show()
            end
        elseif button == "RightButton" then
            if alertTextString then alertTextString:SetText("") end
            ToggleUI()
        end
    end)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("AutoRoll Core")
        GameTooltip:AddLine("Left-Click: |cFFFFFFFFToggle Entire Addon On/Off|r", 1, 1, 1)
        GameTooltip:AddLine("Right-Click: |cFFFFFFFFOpen Dropdown Settings Panel|r", 1, 1, 1)
        GameTooltip:AddLine("Drag: |cFFFFFFFFMove Square Anywhere on Screen|r", 1, 1, 1)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    UpdateButtonVisuals()
end
local isLoaded = false
local function InitializeAddon()
    if isLoaded then return end
    isLoaded = true
    
    if not AutoRollConfig then 
        AutoRollConfig = defaults 
    else
        for k, v in pairs(defaults) do 
            if AutoRollConfig[k] == nil then AutoRollConfig[k] = v end 
        end
    end
    BuildLauncherButton()
end

mainFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "AutoRoll" then
        pcall(InitializeAddon)
    elseif event == "PLAYER_LOGIN" then
        pcall(InitializeAddon)
    elseif event == "START_LOOT_ROLL" then
        local rollID = arg1
        local itemLink = GetLootRollItemLink(rollID)
        handledRolls[rollID] = false
        if itemLink then pcall(ProcessLootRoll, rollID, itemLink) end
    elseif event == "CANCEL_LOOT_ROLL" then
        handledRolls[arg1] = nil
    end
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
                    local _, maxTime = statusBar:GetMinMaxValues()
                    local secondsLeft = statusBar:GetValue() / 1000
                    if secondsLeft > 0 and secondsLeft <= AutoRollConfig.timeThreshold then
                        handledRolls[rollID] = true RollOnLoot(rollID, 2)
                        if alertTextString then alertTextString:SetText("") end
                        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[AutoRoll]|r Fallback Greed: Timer expiring.")
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
