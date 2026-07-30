-- Configuration Defaults Profile
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
    quality = { ["Green"] = 0, ["Blue"] = 0, ["Purple"] = 0 }
}

-- Hidden tooltip structure to scan item requirements
local scannerTooltip = CreateFrame("GameTooltip", "AutoRollScannerTooltip", nil, "GameTooltipTemplate")
scannerTooltip:SetOwner(WorldFrame, "SHOPPING_TOOLTIP_HAS_ITEM")

local function IsItemUnusable(itemLink)
    scannerTooltip:ClearLines()
    scannerTooltip:SetHyperlink(itemLink)
    for i = 1, scannerTooltip:NumLines() do
        local leftLine = _G["AutoRollScannerTooltipTextLeft" .. i]
        if leftLine then
            local r, g, b = leftLine:GetTextColor()
            if r > 0.9 and g < 0.2 and b < 0.2 then return true end
        end
    end
    return false
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
local function ProcessLootRoll(rollID, itemLink)
    if not AutoRollConfig or not AutoRollConfig.enabled or handledRolls[rollID] then return end
    local itemName, _, itemRarity, _, _, itemType, itemSubClass = GetItemInfo(itemLink)
    if not itemName then return end
    
    if AutoRollConfig.autoGreedUnusable and IsItemUnusable(itemLink) then
        if ExecuteRollChoice(rollID, 2, itemLink, "Unusable") then return end
    end
    
    local rarityMap = { [2] = "Green", [3] = "Blue", [4] = "Purple" }
    local rarityKey = rarityMap[itemRarity]
    
    if rarityKey then
        local qChoice = AutoRollConfig.bulkQuality > 0 and AutoRollConfig.bulkQuality or AutoRollConfig.quality[rarityKey]
        if qChoice and qChoice > 0 then
            if ExecuteRollChoice(rollID, qChoice, itemLink, "Quality Filter") then return end
        end
    end
    
    if itemType == "Armor" then
        local aChoice = AutoRollConfig.bulkArmor > 0 and AutoRollConfig.bulkArmor or AutoRollConfig.armor[itemSubClass]
        if aChoice and aChoice > 0 then
            if ExecuteRollChoice(rollID, aChoice, itemLink, itemSubClass) then return end
        end
    end
    
    if itemType == "Weapon" then
        local wChoice = AutoRollConfig.bulkWeapons > 0 and AutoRollConfig.bulkWeapons or AutoRollConfig.weapons[itemSubClass]
        if wChoice and wChoice > 0 then
            if ExecuteRollChoice(rollID, wChoice, itemLink, itemSubClass) then return end
        end
    end
end

-- GUI Layout Construction Engine
local settingsFrame, UpdateButtonVisuals
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
            info.checked = (configTable[key] == (i - 1))
            info.func = function(self)
                configTable[key] = self.value
                UIDropDownMenu_SetSelectedValue(f, self.value)
                UIDropDownMenu_SetText(f, options[self.value + 1])
                
                if isBulk then
                    for dName, data in pairs(activeDropdowns) do
                        if data.bk == key then
                            if self.value > 0 then
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
    
    local currentValue = configTable[key] or 0
    UIDropDownMenu_SetSelectedValue(f, currentValue)
    UIDropDownMenu_SetText(f, options[currentValue + 1])
    return f
end
local function CreateCheckbox(parent, label, x, y, configTable, key)
    local name = "AutoRollCheckButton_Master_" .. key
    local cb = CreateFrame("CheckButton", name, parent, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)
    local text = _G[name .. "Text"]
    if text then text:SetText(label) end
    cb:SetScript("OnShow", function(self) self:SetChecked(configTable[key]) end)
    cb:SetScript("OnClick", function(self) configTable[key] = not not self:GetChecked() end)
    return cb
end

local function BuildUI()
    if settingsFrame then return end
    
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

    local masterCB = CreateCheckbox(settingsFrame, "|cFFFFD100Enable AutoRoll Addon Rules|r", 20, -50, AutoRollConfig, "enabled")
    masterCB:SetScript("OnClick", function(self) 
        AutoRollConfig.enabled = not not self:GetChecked()
        UpdateButtonVisuals()
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[AutoRoll]|r Status changed: " .. (AutoRollConfig.enabled and "|cFF00FF00Enabled|r" or "|cFFFF0000Disabled|r"))
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
    helpBox:SetSize(440, 185)
    helpBox:SetPoint("TOP", settingsFrame, "TOP", 0, -485)
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

local function ToggleUI()
    if not settingsFrame then BuildUI() end
    if settingsFrame:IsShown() then settingsFrame:Hide() else settingsFrame:Show() end
end
local function BuildLauncherButton()
    if AutoRollLauncherButton then return end

    local btn = CreateFrame("Button", "AutoRollLauncherButton", UIParent)
    btn:SetSize(32, 32)
    btn:SetPoint("CENTER", UIParent, "CENTER", AutoRollConfig.buttonX or 0, AutoRollConfig.buttonY or 150)
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
    
    function UpdateButtonVisuals()
        if AutoRollConfig.enabled then 
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
        if not settingsFrame or not settingsFrame:IsShown() then
            self:StartMoving()
        end
    end)
    
    btn:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local _, _, _, x, y = self:GetPoint()
        AutoRollConfig.buttonX = x
        AutoRollConfig.buttonY = y
    end)
    
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            AutoRollConfig.enabled = not AutoRollConfig.enabled
            UpdateButtonVisuals()
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[AutoRoll]|r Status changed: " .. (AutoRollConfig.enabled and "|cFF00FF00Enabled|r" or "|cFFFF0000Disabled|r"))
            if settingsFrame and settingsFrame:IsShown() then
                settingsFrame:Hide()
                settingsFrame:Show()
            end
        elseif button == "RightButton" then
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
        InitializeAddon()
    elseif event == "PLAYER_LOGIN" then
        InitializeAddon()
    elseif event == "START_LOOT_ROLL" then
        local rollID = arg1
        local itemLink = GetLootRollItemLink(rollID)
        handledRolls[rollID] = false
        if itemLink then ProcessLootRoll(rollID, itemLink) end
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
