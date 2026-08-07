-- =========================================================================
-- AUTOROLL SYSTEM HUD - INTERFACEGUI.LUA (PANELS, HOVER HOOKS & CMDS)
-- =========================================================================
-- Links your variables to the global engine core registry
scannerTooltip = _G.scannerTooltip or scannerTooltip

local dropdownCounter = 0

function ForcePanelVisualSync()
    if settingsFrame and settingsFrame:IsShown() then settingsFrame:Hide() settingsFrame:Show() end
end

function SyncBulkArmorOptions(val)
    local charKey = GetCharacterUniqueKey() local cCfg = AutoRollConfig.charSettings[charKey]
    if cCfg then
        cCfg.armor["Cloth"] = val or 0 cCfg.armor["Leather"] = val or 0 cCfg.armor["Mail"] = val or 0 cCfg.armor["Plate"] = val or 0 cCfg.armor["Shields"] = val or 0
        ForcePanelVisualSync()
    end
end

function SyncBulkWeaponOptions(val)
    local charKey = GetCharacterUniqueKey() local cCfg = AutoRollConfig.charSettings[charKey]
    if cCfg then
        cCfg.weapons["Daggers"] = val or 0 cCfg.weapons["One-Handed Swords"] = val or 0 cCfg.weapons["Two-Handed Swords"] = val or 0 cCfg.weapons["One-Handed Maces"] = val or 0 cCfg.weapons["Two-Handed Maces"] = val or 0
        cCfg.weapons["One-Handed Axes"] = val or 0 cCfg.weapons["Two-Handed Axes"] = val or 0 cCfg.weapons["Staves"] = val or 0 cCfg.weapons["Bows"] = val or 0 cCfg.weapons["Guns"] = val or 0 cCfg.weapons["Crossbows"] = val or 0
        ForcePanelVisualSync()
    end
end

function SyncBulkQualityOptions(val)
    local charKey = GetCharacterUniqueKey() local cCfg = AutoRollConfig.charSettings[charKey]
    if cCfg then cCfg.quality["Green"] = val or 0 cCfg.quality["Blue"] = val or 0 cCfg.quality["Purple"] = val or 0 ForcePanelVisualSync() end
end

function CreateDropdownMenu(parent, label, x, y, configTable, key, bulkCategory)
    dropdownCounter = dropdownCounter + 1 
    local name = "AutoRollDropdown_" .. dropdownCounter
    
    local textXOffset = x
    local menuXOffset = x + 105
    
    if x == 210 then
        textXOffset = x + 24
        menuXOffset = x + 100
    end
    
    local lbl = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall") 
    lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", textXOffset, y) 
    lbl:SetText(label)
    
    local f = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate") 
    f:SetPoint("TOPLEFT", parent, "TOPLEFT", menuXOffset, y + 7) 
    UIDropDownMenu_SetWidth(f, 75)
    
    local options = { "Manual", "Need", "Greed", "Pass" } 
    if bulkCategory then options = { "Custom", "Need", "Greed", "Pass" } end
    
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
                
                if bulkCategory == "armor" then SyncBulkArmorOptions(self.value) 
                elseif bulkCategory == "weapons" then SyncBulkWeaponOptions(self.value) 
                elseif bulkCategory == "quality" then SyncBulkQualityOptions(self.value) end
                
                local charKey = GetCharacterUniqueKey()
                if AutoRollConfig and AutoRollConfig.charSettings and AutoRollConfig.charSettings[charKey] then
                    for rID, status in pairs(handledRolls) do
                        if status == false then
                            local itemLink = GetLootRollItemLink(rID)
                            if itemLink then pcall(ProcessLootRoll, rID, itemLink) end
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

function CreateCheckbox(parent, label, x, y, configTable, key)
    local name = "AutoRollCheckButton_Master_" .. tostring(key or dropdownCounter)
    local cb = CreateFrame("CheckButton", name, parent, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    
    local text = _G[name .. "Text"]
    if text then text:SetText(label) end
    
    if configTable and key and configTable[key] ~= nil then cb:SetChecked(configTable[key]) end
    cb:SetScript("OnShow", function(self) if configTable and key and configTable[key] ~= nil then self:SetChecked(configTable[key]) end end)
    cb:SetScript("OnClick", function(self) if configTable and key then configTable[key] = not not self:GetChecked() end end)
    return cb
end

function BuildWeightEditUI()
    if weightFrame or not AutoRollConfig then return end
    
    local editBoxesTable = {}
    local charClass = GetPlayerClassProfile()
    local activeProfile = GetActiveProfileName()
    local showAllClasses = false
    local isUpdating = false
    local profileDropdown, renameBtn, deleteBtn
    
    local function LoadTempWeightsFromActiveProfile()
        EnsureProfileExists(activeProfile)
        for k, v in pairs(AutoRollConfig.statProfiles[activeProfile]) do tempWeights[k] = tonumber(v) or 0 end
    end
    LoadTempWeightsFromActiveProfile()
    
    weightFrame = CreateFrame("Frame", "AutoRollWeightFrame", UIParent) 
    weightFrame:SetSize(300, 540) 
    weightFrame:SetPoint("TOPLEFT", statFrame, "BOTTOMLEFT", 0, -5)
    weightFrame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 5, right = 5, top = 5, bottom = 5 } })
    
    local title = weightFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal") 
    title:SetPoint("TOP", 0, -15) title:SetText("|cFF3399FFModify weights: " .. activeProfile .. "|r")
    
    local close = CreateFrame("Button", nil, weightFrame, "UIPanelCloseButton") close:SetPoint("TOPRIGHT", -2, -2)
    
    -- =====================================================================
    -- PROFILE SELECTOR: Lets a character use any named profile from the
    -- shared account-wide library, not just the one matching its own class.
    -- Defaults to showing only profiles relevant to this character's class.
    -- =====================================================================
    local profileLbl = weightFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    profileLbl:SetPoint("TOPLEFT", weightFrame, "TOPLEFT", 15, -38) profileLbl:SetText("Profile:")
    
    profileDropdown = CreateFrame("Frame", "AutoRollProfileDropdown", weightFrame, "UIDropDownMenuTemplate")
    profileDropdown:SetPoint("TOPLEFT", weightFrame, "TOPLEFT", 45, -31)
    UIDropDownMenu_SetWidth(profileDropdown, 165)
    
    local allClassesCB = CreateFrame("CheckButton", "AutoRollShowAllClassesCB", weightFrame, "InterfaceOptionsCheckButtonTemplate")
    allClassesCB:SetPoint("TOPLEFT", weightFrame, "TOPLEFT", 12, -62)
    _G["AutoRollShowAllClassesCBText"]:SetText("Show profiles from all classes")
    allClassesCB:SetChecked(false)
    
    local newBtn = CreateFrame("Button", nil, weightFrame, "UIPanelButtonTemplate")
    newBtn:SetSize(66, 22) newBtn:SetPoint("TOPLEFT", weightFrame, "TOPLEFT", 15, -90) newBtn:SetText("New")
    
    local dupBtn = CreateFrame("Button", nil, weightFrame, "UIPanelButtonTemplate")
    dupBtn:SetSize(66, 22) dupBtn:SetPoint("LEFT", newBtn, "RIGHT", 4, 0) dupBtn:SetText("Duplicate")
    
    renameBtn = CreateFrame("Button", nil, weightFrame, "UIPanelButtonTemplate")
    renameBtn:SetSize(66, 22) renameBtn:SetPoint("LEFT", dupBtn, "RIGHT", 4, 0) renameBtn:SetText("Rename")
    
    deleteBtn = CreateFrame("Button", nil, weightFrame, "UIPanelButtonTemplate")
    deleteBtn:SetSize(66, 22) deleteBtn:SetPoint("LEFT", renameBtn, "RIGHT", 4, 0) deleteBtn:SetText("Delete")
    
    local scrollFrame = CreateFrame("ScrollFrame", "AutoRollWeightScrollFrame", weightFrame, "UIPanelScrollFrameTemplate") 
    scrollFrame:SetPoint("TOPLEFT", 15, -118) scrollFrame:SetPoint("BOTTOMRIGHT", -35, 50) 
    
    local content = CreateFrame("Frame", nil, scrollFrame) content:SetWidth(210) content:SetHeight(520) scrollFrame:SetScrollChild(content)
    local dummy = CreateFrame("EditBox", nil, content, "InputBoxTemplate") dummy:SetSize(1, 1) dummy:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0) dummy:Hide()
    
    local categorizedKeys = {
        { isHeader = true,  text = "|cFFFFD100[ Primary Stats ]|r" },
        { isStat = true,    key = "Strength" }, { isStat = true,    key = "Agility" },
        { isStat = true,    key = "Stamina" }, { isStat = true,    key = "Intellect" }, { isStat = true,    key = "Spirit" },
        { isHeader = true,  text = "|cFFFFD100[ Secondary Stats ]|r" },
        { isStat = true,    key = "Crit" }, { isStat = true,    key = "Hit" }, { isStat = true,    key = "Haste" },
        { isStat = true,    key = "Resilience" }, { isStat = true,    key = "Mana per 5" },
        { isHeader = true,  text = "|cFFFFD100[ Offensive Stats ]|r" },
        { isStat = true,    key = "Weapon DPS" }, { isStat = true,    key = "Ranged DPS" },
        { isStat = true,    key = "Attack Power" }, { isStat = true,    key = "Ranged Attack Power" }, 
        { isStat = true,    key = "Spell Power" }, { isStat = true,    key = "Spell Damage" },
        { isStat = true,    key = "Armor Pen" }, { isStat = true,    key = "Spell Pen" }, { isStat = true,    key = "Expertise" }
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
            lbl:SetText(key) lbl:SetWidth(110) lbl:SetJustifyH("LEFT")
            
            local boxWrapper = CreateFrame("Frame", nil, content)
            boxWrapper:SetSize(60, 20) boxWrapper:SetPoint("LEFT", lbl, "RIGHT", 10, 0)
            
            local eb = CreateFrame("EditBox", nil, boxWrapper, "InputBoxTemplate") 
            eb:SetSize(55, 18) eb:SetPoint("LEFT", boxWrapper, "LEFT", 0, 0)
            eb:SetAutoFocus(false) eb:SetMaxLetters(6) eb:SetTextInsets(4, 0, 0, 0)
            
            editBoxesTable[key] = eb
            
            eb:SetScript("OnShow", function(self) 
                if not isUpdating then
                    local currentVal = tempWeights[key] or 0
                    self:SetText(tostring(currentVal)) self:SetCursorPosition(0)
                end
            end)
            
            eb:SetScript("OnTextChanged", function(self) 
                if isUpdating then return end
                local txt = self:GetText() 
                if txt and txt ~= "" then tempWeights[key] = tonumber(txt) or 0 else tempWeights[key] = 0 end 
            end)
            totalYOffset = totalYOffset - 24
        end
    end
    content:SetHeight(math.abs(totalYOffset) + 20)
    
    local function RefreshEditBoxes()
        isUpdating = true
        for key, ebBox in pairs(editBoxesTable) do
            local currentVal = tempWeights[key] or 0
            ebBox:SetText(tostring(currentVal)) ebBox:SetCursorPosition(0)
        end
        isUpdating = false
    end
    
    local function RefreshButtonStates()
        local protected = IsProtectedProfileName(activeProfile)
        if protected then renameBtn:Disable() deleteBtn:Disable() else renameBtn:Enable() deleteBtn:Enable() end
    end
    
    local function RefreshProfileDropdownText()
        UIDropDownMenu_SetText(profileDropdown, activeProfile)
    end
    
    local function SwitchToProfile(newProfileName)
        activeProfile = newProfileName
        SetActiveProfileName(activeProfile)
        LoadTempWeightsFromActiveProfile()
        title:SetText("|cFF3399FFModify weights: " .. activeProfile .. "|r")
        RefreshProfileDropdownText()
        RefreshButtonStates()
        RefreshEditBoxes()
    end
    
    UIDropDownMenu_Initialize(profileDropdown, function()
        local list = showAllClasses and GetAllProfileNames() or GetProfilesForClass(charClass)
        for _, name in ipairs(list) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = name
            info.value = name
            info.checked = (name == activeProfile)
            info.func = function(self)
                SwitchToProfile(self.value)
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    RefreshProfileDropdownText()
    RefreshButtonStates()
    
    allClassesCB:SetScript("OnClick", function(self) showAllClasses = not not self:GetChecked() end)
    
    -- =====================================================================
    -- PROFILE MANAGEMENT: New / Duplicate / Rename / Delete, via StaticPopup
    -- text-entry dialogs (the standard WoW pattern for a naming prompt).
    -- =====================================================================
    StaticPopupDialogs["AUTOROLL_NEW_PROFILE"] = {
        text = "Name for the new blank profile:",
        button1 = "Create", button2 = "Cancel", hasEditBox = true, maxLetters = 40,
        OnShow = function(self) self.editBox:SetText("") self.editBox:SetFocus() end,
        OnAccept = function(self)
            local newName = self.editBox:GetText()
            local ok, err = CreateNewStatProfile(newName, nil)
            if ok then SwitchToProfile(newName)
            elseif err then DEFAULT_CHAT_FRAME:AddMessage("|cFFFF4444[AutoRoll]|r " .. err) end
        end,
        EditBoxOnEnterPressed = function(self) self:GetParent().button1:Click() end,
        timeout = 0, whileDead = true, hideOnEscape = true,
    }
    StaticPopupDialogs["AUTOROLL_DUPLICATE_PROFILE"] = {
        text = "Name for the copy of \"%s\":",
        button1 = "Create", button2 = "Cancel", hasEditBox = true, maxLetters = 40,
        OnShow = function(self) self.editBox:SetText("") self.editBox:SetFocus() end,
        OnAccept = function(self)
            local newName = self.editBox:GetText()
            local ok, err = CreateNewStatProfile(newName, activeProfile)
            if ok then SwitchToProfile(newName)
            elseif err then DEFAULT_CHAT_FRAME:AddMessage("|cFFFF4444[AutoRoll]|r " .. err) end
        end,
        EditBoxOnEnterPressed = function(self) self:GetParent().button1:Click() end,
        timeout = 0, whileDead = true, hideOnEscape = true,
    }
    StaticPopupDialogs["AUTOROLL_RENAME_PROFILE"] = {
        text = "New name for \"%s\":",
        button1 = "Rename", button2 = "Cancel", hasEditBox = true, maxLetters = 40,
        OnShow = function(self) self.editBox:SetText("") self.editBox:SetFocus() end,
        OnAccept = function(self)
            local newName = self.editBox:GetText()
            local oldName = activeProfile
            local ok, err = RenameStatProfile(oldName, newName)
            if ok then SwitchToProfile(newName)
            elseif err then DEFAULT_CHAT_FRAME:AddMessage("|cFFFF4444[AutoRoll]|r " .. err) end
        end,
        EditBoxOnEnterPressed = function(self) self:GetParent().button1:Click() end,
        timeout = 0, whileDead = true, hideOnEscape = true,
    }
    StaticPopupDialogs["AUTOROLL_DELETE_PROFILE"] = {
        text = "Delete profile \"%s\"? This cannot be undone.",
        button1 = "Delete", button2 = "Cancel",
        OnAccept = function(self)
            local nameToDelete = activeProfile
            local ok, err = DeleteStatProfile(nameToDelete)
            if ok then SwitchToProfile(GetActiveProfileName())
            elseif err then DEFAULT_CHAT_FRAME:AddMessage("|cFFFF4444[AutoRoll]|r " .. err) end
        end,
        timeout = 0, whileDead = true, hideOnEscape = true,
    }
    
    newBtn:SetScript("OnClick", function() StaticPopup_Show("AUTOROLL_NEW_PROFILE") end)
    dupBtn:SetScript("OnClick", function() StaticPopup_Show("AUTOROLL_DUPLICATE_PROFILE", activeProfile) end)
    renameBtn:SetScript("OnClick", function() if not IsProtectedProfileName(activeProfile) then StaticPopup_Show("AUTOROLL_RENAME_PROFILE", activeProfile) end end)
    deleteBtn:SetScript("OnClick", function() if not IsProtectedProfileName(activeProfile) then StaticPopup_Show("AUTOROLL_DELETE_PROFILE", activeProfile) end end)
    
    weightFrame:SetScript("OnShow", function()
        RefreshProfileDropdownText()
        RefreshButtonStates()
        RefreshEditBoxes()
    end)
    
    local saveBtn = CreateFrame("Button", nil, weightFrame, "UIPanelButtonTemplate")
    saveBtn:SetSize(140, 24) saveBtn:SetPoint("BOTTOM", weightFrame, "BOTTOM", 0, 15) saveBtn:SetText("[ Save Weights ]")
    
    saveBtn:SetScript("OnClick", function()
        if not AutoRollConfig or not AutoRollConfig.statProfiles or not AutoRollConfig.statProfiles[activeProfile] then return end
        for k, v in pairs(tempWeights) do
            local cleanNum = tonumber(v)
            if not cleanNum or type(cleanNum) ~= "number" then cleanNum = 0 end
            AutoRollConfig.statProfiles[activeProfile][k] = cleanNum
        end
        
        isUpdating = true
        if weightFrame and weightFrame:IsShown() then weightFrame:Hide() weightFrame:Show() end
        isUpdating = false
        
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF00FF00[AutoRoll]|r Saved successfully to the shared account-wide |cFFFFFFFF%s|r profile library slot!", activeProfile))
    end)
end

function BuildStatUI()
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
    
    settingsFrame = CreateFrame("Frame", "AutoRollOptionsFrame", UIParent) 
    settingsFrame:SetSize(490, 480) 
    settingsFrame:SetPoint("CENTER")
    settingsFrame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 11, right = 12, top = 12, bottom = 11 } })
    settingsFrame:SetMovable(true) settingsFrame:EnableMouse(true) settingsFrame:RegisterForDrag("LeftButton")
    settingsFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    settingsFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    settingsFrame:Show()
    
    tinsert(UISpecialFrames, "AutoRollOptionsFrame")
    settingsFrame:SetScript("OnHide", function()
        if statFrame and statFrame:IsShown() then statFrame:Hide() end
        if weightFrame and weightFrame:IsShown() then weightFrame:Hide() end
        if helpBox and helpBox:IsShown() then helpBox:Hide() end
    end)
    
    local title = settingsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge") 
    title:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 24, -18) 
    title:SetText("AutoRoll Settings: " .. UnitName("player"))
    title:SetJustifyH("LEFT")
    
    -- Visual Identity Header: Positioned cleanly right underneath the main title string label
    local versionText = settingsFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    versionText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4) -- Snaps to the bottom left edge of title
    versionText:SetText("|cFF999999v3.5 Stable Build|r")


    
    local close = CreateFrame("Button", nil, settingsFrame, "UIPanelCloseButton") 
    close:SetPoint("TOPRIGHT", -6, -6)
    close:SetScript("OnClick", function() settingsFrame:Hide() if statFrame then statFrame:Hide() end if weightFrame then weightFrame:Hide() end end)
    local statToggleBtn = CreateFrame("Button", nil, settingsFrame, "UIPanelButtonTemplate") 
    statToggleBtn:SetSize(110, 22) 
    statToggleBtn:SetPoint("TOPRIGHT", settingsFrame, "TOPRIGHT", -36, -18) 
    statToggleBtn:SetText("Smart Stats >>")
    statToggleBtn:SetScript("OnClick", function() if not statFrame then BuildStatUI() else if statFrame:IsShown() then statFrame:Hide() if weightFrame then weightFrame:Hide() end else statFrame:Show() end end end)
    
    local helpBox = CreateFrame("Frame", nil, settingsFrame) 
    helpBox:SetSize(440, 195) 
    helpBox:SetPoint("TOP", settingsFrame, "BOTTOM", 0, 5)
    helpBox:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    helpBox:SetBackdropColor(0, 0, 0, 0.85)
    helpBox:Hide()
    
    local helpText = helpBox:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall") helpText:SetPoint("TOPLEFT", 12, -12) helpText:SetWidth(415) helpText:SetJustifyH("LEFT") helpText:SetJustifyV("TOP") helpText:SetSpacing(4)
    local textLines = { "|cFFFFD100How AutoRoll Functions Internally:|r", "• Configured rule actions occur |cFFFFFFFFinstantly|r the exact millisecond a new item loot roll framework window prompt displays on your interface.", "• Setting an item type target rule value profile parameter to |cFFFF9900'Manual'|r completely prevents the script engine from interacting with it automatically, preserving regular item window selections.", "• |cFFFF2222CRITICAL SAFETY mechanism:|r If an item remains set to 'Manual' (or you decide to ignore a roll window while locked in heavy combat), the engine continuously tracks remaining frame timeout data.", "• When less than |cFFFFFFFF5 seconds|r remain on an ignored prompt, the fallback engine triggers an automatic |cFF00FF00Greed|r command selection so you never completely forfeit eligible group rewards." }
    helpText:SetText(table.concat(textLines, "\n"))
    
        -- Engineering Cog Button: Spits out a complete account/character configuration dump straight to chat logs
    local diagnosticBtn = CreateFrame("Button", nil, settingsFrame) 
    diagnosticBtn:SetSize(22, 22) 
    diagnosticBtn:SetPoint("RIGHT", statToggleBtn, "LEFT", -34, 0) -- Positioned cleanly next to help button
    diagnosticBtn:SetNormalTexture("Interface\\Icons\\Trade_Engineering")
    
    local btnHighlight = diagnosticBtn:CreateTexture(nil, "HIGHLIGHT") 
    btnHighlight:SetTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight") 
    btnHighlight:SetAllPoints(diagnosticBtn) 
    diagnosticBtn:SetHighlightTexture(btnHighlight)
    
    diagnosticBtn:SetScript("OnClick", function()
        local choices = { [0] = "|cFF999999Manual|r", [1] = "|cFF3399FFNeed|r", [2] = "|cFF00FF00Greed|r", [3] = "|cFFFF2222Pass|r" }
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD100=== AutoRoll Current Configuration Audit ===|r")
        DEFAULT_CHAT_FRAME:AddMessage(string.format("Addon Active Status: %s", cCfg.enabled and "|cFF00FF00ENABLED|r" or "|cFFFF2222DISABLED|r"))
        DEFAULT_CHAT_FRAME:AddMessage(string.format("Smart Stats Module: %s", cCfg.statModuleEnabled and "|cFF00FF00RUNNING|r" or "|cFF999999INACTIVE|r"))
        DEFAULT_CHAT_FRAME:AddMessage(string.format("Auto-Greed Unusable (Red Text): %s", cCfg.autoGreedUnusable and "|cFF00FF00ON|r" or "|cFFFF2222OFF|r"))
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00-- Quality Selection Priorities --|r")
        for k, v in pairs(cCfg.quality or {}) do DEFAULT_CHAT_FRAME:AddMessage(string.format("  %s Rarity: %s", k, choices[v] or "|cFFFF0000Error|r")) end
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00-- Armor Selection Matrices --|r")
        for k, v in pairs(cCfg.armor or {}) do DEFAULT_CHAT_FRAME:AddMessage(string.format("  %s Class: %s", k, choices[v] or "|cFFFF0000Error|r")) end
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00-- Weapon Selection Matrices --|r")
        for k, v in pairs(cCfg.weapons or {}) do DEFAULT_CHAT_FRAME:AddMessage(string.format("  %s Type: %s", k, choices[v] or "|cFFFF0000Error|r")) end
        
        -- =========================================================================
        -- LIVE SERVER SKILLS DATABASE DUMP: Audits your exact proficiency names
        -- =========================================================================
        if ScanCharacterSkillsEngine then ScanCharacterSkillsEngine() end
        DEFAULT_CHAT_FRAME:AddMessage("|cFF3399FF=== Live Server Skills Tab Inventory Audit ===|r")
        
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Tradeskills / Secondary Profiles]:|r")
        if _G.playerProfessions then
            for prof, rank in pairs(_G.playerProfessions) do DEFAULT_CHAT_FRAME:AddMessage(string.format("  Prof: %s (Level Skill Rank: %d/300)", prof, rank)) end
        end
        
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Armor Mastery Proficiencies]:|r")
        if _G.playerArmorSkills then
            for armorClass in pairs(_G.playerArmorSkills) do DEFAULT_CHAT_FRAME:AddMessage(string.format("  Armor Token Key: \"%s\"", armorClass)) end
        end
        
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Weapon Competency Skill Sets]:|r")
        if _G.playerWeaponSkills then
            for weaponType in pairs(_G.playerWeaponSkills) do DEFAULT_CHAT_FRAME:AddMessage(string.format("  Weapon Token Key: \"%s\"", weaponType)) end
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD100==============================================|r")
    end)



    local helpToggleBtn = CreateFrame("Button", nil, settingsFrame, "UIPanelButtonTemplate")
    helpToggleBtn:SetSize(24, 22)
    helpToggleBtn:SetPoint("RIGHT", statToggleBtn, "LEFT", -5, 0)
    helpToggleBtn:SetText("?")
    helpToggleBtn:SetScript("OnClick", function() if helpBox:IsShown() then helpBox:Hide() else helpBox:Show() end end)
    
    local scrollFrame = CreateFrame("ScrollFrame", "AutoRollOptionsScrollFrame", settingsFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 12, -45)
    scrollFrame:SetPoint("BOTTOMRIGHT", settingsFrame, "BOTTOMRIGHT", -36, 15)
    
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(415) content:SetHeight(520) 
    scrollFrame:SetScrollChild(content)
    
    local dummy = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
    dummy:SetSize(1, 1) dummy:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0) dummy:Hide()
    local masterCB = CreateCheckbox(content, "|cFFFFD100Enable AutoRoll Addon Rules|r", 10, -5)
    masterCB:SetScript("OnClick", function(self) cCfg.enabled = not not self:GetChecked() UpdateButtonVisuals() end)
    if cCfg.enabled ~= nil then masterCB:SetChecked(cCfg.enabled) end
    
    CreateCheckbox(content, "Auto-Greed Unusable Items (Red Text)", 10, -30, cCfg, "autoGreedUnusable")
    
    CreateDropdownMenu(content, "|cFF00FF00All Armor|r", 15, -65, cCfg, "bulkArmor", "armor")
    CreateDropdownMenu(content, "|cFF00FF00All Rarities|r", 210, -65, cCfg, "bulkQuality", "quality")
    
    local armors = {"Cloth", "Leather", "Mail", "Plate", "Shields"}
    for i, name in ipairs(armors) do 
        CreateDropdownMenu(content, name, 15, -75 - (i * 28), cCfg.armor, name) 
    end
    
    local qualities = { {label = "|cFF1EFF00Green|r", key = "Green"}, {label = "|cFF0070D8Blue|r", key = "Blue"}, {label = "|cFFA335EEPurple|r", key = "Purple"} }
    for i, qInfo in ipairs(qualities) do 
        CreateDropdownMenu(content, qInfo.label, 210, -75 - (i * 28), cCfg.quality, qInfo.key) 
    end
    
    CreateDropdownMenu(content, "|cFF00FF00All Weapons|r", 15, -240, cCfg, "bulkWeapons", "weapons")
    local weaps = { "Daggers", "One-Handed Swords", "Two-Handed Swords", "One-Handed Maces", "Two-Handed Maces", "One-Handed Axes", "Two-Handed Axes", "Staves", "Fist Weapons", "Polearms", "Wands", "Bows", "Guns", "Crossbows", "Thrown" }
    for i, name in ipairs(weaps) do
        local col = i <= 8 and 15 or 210 
        local row = i <= 8 and i or i - 8 
        local cleanLabel = name:gsub("One%-Handed ", "1H "):gsub("Two%-Handed ", "2H ")
        CreateDropdownMenu(content, cleanLabel, col, -250 - (row * 28), cCfg.weapons, name) 
    end
end

function BuildLauncherButton()
    if AutoRollLauncherButton then return end
    local btn = CreateFrame("Button", "AutoRollLauncherButton", UIParent) 
    btn:SetSize(32, 32) 
    btn:SetPoint("CENTER", UIParent, "CENTER", (AutoRollConfig and AutoRollConfig.buttonX) or 0, (AutoRollConfig and AutoRollConfig.buttonY) or 150) 
    btn:SetFrameStrata("HIGH")
    btn:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    
    local icon = btn:CreateTexture(nil, "ARTWORK") 
    icon:SetSize(22, 22) icon:SetPoint("CENTER", 0, 0) icon:SetTexture("Interface\\Icons\\INV_Misc_Dice_01")
    
    alertTextString = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") 
    alertTextString:SetPoint("BOTTOM", btn, "TOP", 0, 4) alertTextString:SetText("")
    
    function UpdateButtonVisuals() 
        local charKey = GetCharacterUniqueKey()
        local cCfg = AutoRollConfig and AutoRollConfig.charSettings and AutoRollConfig.charSettings[charKey]
        if cCfg and cCfg.enabled then btn:SetBackdropColor(0, 0.6, 0, 0.8) btn:SetBackdropBorderColor(0.2, 1, 0.2, 1) icon:SetVertexColor(1, 1, 1, 1) 
        else btn:SetBackdropColor(0.6, 0, 0, 0.8) btn:SetBackdropBorderColor(1, 0.2, 0.2, 1) icon:SetVertexColor(0.5, 0.5, 0.5, 0.8) end 
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

GameTooltip:HookScript("OnTooltipSetItem", function(self)
    if IsControlKeyDown() then
        local _, itemLink = self:GetItem() if not itemLink then return end
        local itemName, _, _, _, _, itemType, itemSubClass, _, itemEquipLoc = GetItemInfo(itemLink) if not itemName then return end
        
                -- =========================================================================
        -- HOVER HOOK SHIELD: Queries your modular cross-file dual column color engine live
        -- =========================================================================
        local isUnusableClassGear = false
        if _G.IsItemUnusable then
            local checkState, token = _G.IsItemUnusable(itemLink)
            if checkState == true then
                isUnusableClassGear = true
            end
        end
        
        if isUnusableClassGear then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00--- AutoRoll Diagnostic Scan: " .. itemLink .. " ---|r")
            DEFAULT_CHAT_FRAME:AddMessage("  |cFFFF2222[UNEQUIPPABLE]: You cannot wear this item class! Skipping score tracking.|r")
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00------------------------------------------------|r")
            return
        end

        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00--- AutoRoll Diagnostic Scan: " .. itemLink .. " ---|r")
        local playerClass = GetActiveProfileName()
        DEFAULT_CHAT_FRAME:AddMessage("|cFF999999  [Active Profile: " .. playerClass .. "]|r")
        local function PrintEquippedItemScore(equipLink, label, isRanged)
            if not equipLink then return 0 end
            DEFAULT_CHAT_FRAME:AddMessage("|cFF999999  [Scanning Equipped " .. label .. " Stats...]|r")
            scannerTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
            scannerTooltip:ClearLines()
            scannerTooltip:SetHyperlink(equipLink)
            local score = ScoreTooltipLines(scannerTooltip, playerClass, isRanged, true, "(Equipped)")
            scannerTooltip:Hide()
            return score
        end

        local isRangedItemHover = (itemEquipLoc == "INVTYPE_RANGED" or itemEquipLoc == "INVTYPE_RANGEDRIGHT" or
            itemSubClass == "Bows" or itemSubClass == "Guns" or itemSubClass == "Crossbows" or itemSubClass == "Thrown")
        local totalDroppedScore = ScoreTooltipLines(self, playerClass, isRangedItemHover, true)
        local equippedScore = 0 
        local equippedItemLink = "Slot Combo" 
        local foundSlotID = nil
        
        local isRangedWeapon = (itemEquipLoc == "INVTYPE_RANGED" or
            itemEquipLoc == "INVTYPE_RANGEDRIGHT" or
            itemSubClass == "Bows" or
            itemSubClass == "Guns" or
            itemSubClass == "Crossbows" or
            itemSubClass == "Thrown")

        local isWp = (itemEquipLoc == "INVTYPE_WEAPON" or 
            itemEquipLoc == "INVTYPE_2HWEAPON" or 
            itemEquipLoc == "INVTYPE_WEAPONMAINHAND" or 
            itemEquipLoc == "INVTYPE_WEAPONOFFHAND" or 
            itemEquipLoc == "INVTYPE_SHIELD" or 
            itemEquipLoc == "INVTYPE_HOLDABLE" or 
            itemType == "Weapon" or itemSubClass == "Shields")
            
        local isArm = (itemSubClass == "Cloth" or 
            itemSubClass == "Leather" or 
            itemSubClass == "Mail" or itemSubClass == "Plate")
        
        if isRangedWeapon then
            local rangedLink = GetInventoryItemLink("player", 18)
            equippedScore = PrintEquippedItemScore(rangedLink, "Ranged Slot", true)
            equippedItemLink = rangedLink or "[Empty]"
            foundSlotID = 18
        elseif not isArm and isWp then
            local mhLink = GetInventoryItemLink("player", 16) 
            local ohLink = GetInventoryItemLink("player", 17)
            local mhScore, ohScore = 0, 0

            if mhLink then
                mhScore = PrintEquippedItemScore(mhLink, "Main-Hand", false)
            end
            if ohLink then
                ohScore = PrintEquippedItemScore(ohLink, "Off-Hand/Shield", false)
            end

            equippedScore = mhScore + ohScore 
            equippedItemLink = string.format("MH: %s + OH: %s", 
                mhLink or "[Empty]", ohLink or "[Empty]")

            if itemEquipLoc == "INVTYPE_WEAPON" or itemEquipLoc == "INVTYPE_WEAPONMAINHAND" then totalDroppedScore = totalDroppedScore + ohScore
            elseif itemEquipLoc == "INVTYPE_SHIELD" or itemEquipLoc == "INVTYPE_HOLDABLE" or itemEquipLoc == "INVTYPE_WEAPONOFFHAND" or itemSubClass == "Shields" then totalDroppedScore = mhScore + totalDroppedScore end
            foundSlotID = 16
        end
        if not foundSlotID then
            for i = 2, self:NumLines() do
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
                    elseif lineText == "Finger" or string.find(lineText, "%sRing%s") or lineText == "Ring" then foundSlotID = 11 break
                    elseif string.find(lineText, "Trinket") then foundSlotID = 12 break
                    elseif string.find(lineText, "Back") or string.find(lineText, "Cloak") or string.find(lineText, "Cape") then foundSlotID = 15 break end
                end
            end
            if not foundSlotID and itemEquipLoc and SLOT_MAP and SLOT_MAP[itemEquipLoc] then foundSlotID = SLOT_MAP[itemEquipLoc] end
            if foundSlotID then
                if foundSlotID == 11 or itemEquipLoc == "INVTYPE_FINGER" then
                    local r1Link = GetInventoryItemLink("player", 11) local r2Link = GetInventoryItemLink("player", 12)
                    local s1 = r1Link and PrintEquippedItemScore(r1Link, "Finger Slot 1", false) or 0 local s2 = r2Link and PrintEquippedItemScore(r2Link, "Finger Slot 2", false) or 0
                    equippedScore = math.min(s1, s2)
                    equippedItemLink = string.format("\n    Slot 1: %s (Score: %.2f)\n    Slot 2: %s (Score: %.2f)\n    [Challenging Lowest]", r1Link or "[Empty]", s1, r2Link or "[Empty]", s2)
                elseif foundSlotID == 12 or itemEquipLoc == "INVTYPE_TRINKET" then
                    local t1Link = GetInventoryItemLink("player", 13) local t2Link = GetInventoryItemLink("player", 14)
                    local s1 = t1Link and PrintEquippedItemScore(t1Link, "Trinket Slot 1", false) or 0 local s2 = t2Link and PrintEquippedItemScore(t2Link, "Trinket Slot 2", false) or 0
                    equippedScore = math.min(s1, s2)
                    equippedItemLink = string.format("\n    Slot 1: %s (Score: %.2f)\n    Slot 2: %s (Score: %.2f)\n    [Challenging Lowest]", t1Link or "[Empty]", s1, t2Link or "[Empty]", s2)
                else
                    local standardLink = GetInventoryItemLink("player", foundSlotID)
                    if standardLink then
                        equippedItemLink = standardLink
                        if standardLink == itemLink then
                            equippedScore = totalDroppedScore
                        else
                            equippedScore = PrintEquippedItemScore(standardLink, "Equipped Slot", isRangedItemHover)
                        end
                    end
                end
            end
        end
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF3399FF[%s Score]:|r %.2f", itemName, totalDroppedScore))
        if equippedItemLink then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFF0000[Equipped Item Baseline]:|r %.2f (%s)", equippedScore, equippedItemLink))
            local scoreDelta = totalDroppedScore - equippedScore
            if scoreDelta > 0 then DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF00FF00[STAT UPGRADE!]:|r This item is a +%.2f upgrade over equipped!", scoreDelta))
            else DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFF2222[NO UPGRADE]:|r This item scores %.2f lower than equipped.", math.abs(scoreDelta))) end
        else DEFAULT_CHAT_FRAME:AddMessage("|cFF999999[Slot Baseline]:|r Empty slot. This item is an absolute upgrade!") end
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00------------------------------------------------|r") scannerTooltip:Hide()
    end
end)


local debugLogFrame, debugEditBox = nil, nil

function ShowInGameDebugLog(itemLink)
    if not itemLink then return end
    local playerClass = GetPlayerClassProfile()
    local activeProfile = GetActiveProfileName()
    
    if not debugLogFrame then
        debugLogFrame = CreateFrame("Frame", "AutoRollDebugLogFrame", UIParent)
        debugLogFrame:SetSize(460, 420)
        debugLogFrame:SetPoint("CENTER")
        debugLogFrame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 5, right = 5, top = 5, bottom = 5 } })
        debugLogFrame:SetMovable(true) debugLogFrame:EnableMouse(true) debugLogFrame:RegisterForDrag("LeftButton")
        debugLogFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
        debugLogFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        
        local t = debugLogFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        t:SetPoint("TOP", 0, -15) t:SetText("|cFFFF9900AutoRoll Copyable Diagnostic Inspector|r")
        
        local close = CreateFrame("Button", nil, debugLogFrame, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -2, -2)
        
        local sf = CreateFrame("ScrollFrame", "AutoRollDebugScroll", debugLogFrame, "UIPanelScrollFrameTemplate")
        sf:SetPoint("TOPLEFT", 15, -45) sf:SetPoint("BOTTOMRIGHT", -35, 45)
        
        local c = CreateFrame("Frame", nil, sf)
        c:SetWidth(380) c:SetHeight(1200)
        sf:SetScrollChild(c)
        
        debugEditBox = CreateFrame("EditBox", nil, c)
        debugEditBox:SetWidth(370) debugEditBox:SetHeight(1200) debugEditBox:SetMultiLine(true) debugEditBox:SetMaxLetters(99999) debugEditBox:SetFontObject("GameFontHighlightSmall")
        debugEditBox:SetPoint("TOPLEFT", c, "TOPLEFT", 5, -5) debugEditBox:SetAutoFocus(false)
        debugEditBox:SetScript("OnEscapePressed", function(self) debugLogFrame:Hide() end)
        
        local footer = debugLogFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        footer:SetPoint("BOTTOM", debugLogFrame, "BOTTOM", 0, 18)
        footer:SetText("|cFF999999Click inside -> Press Ctrl+A -> Press Ctrl+C to Copy|r")
    end
    
    debugLogFrame:Show()
    scannerTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    scannerTooltip:ClearLines()
    scannerTooltip:SetHyperlink(itemLink)
    
    local linesOutput = {}
    table.insert(linesOutput, "Item Link: " .. tostring(itemLink))
    table.insert(linesOutput, "Class: " .. tostring(playerClass))
    table.insert(linesOutput, "Active Profile: " .. tostring(activeProfile))
    table.insert(linesOutput, "---------------------------------------------")
    
    for i = 1, scannerTooltip:NumLines() do
        local leftLine = _G["AutoRollScannerTooltipTextLeft" .. i]
        local rightLine = _G["AutoRollScannerTooltipTextRight" .. i]
        
        local leftText = leftLine and leftLine:GetText() or ""
        local rightText = rightLine and rightLine:GetText() or ""
        
        if leftText ~= "" then
            local cleanLeft = leftText:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
            if rightText ~= "" then
                local cleanRight = rightText:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
                table.insert(linesOutput, string.format("Line %d: \"%s\"   [Right Column: \"%s\"]", i, cleanLeft, cleanRight))
            else
                table.insert(linesOutput, string.format("Line %d: \"%s\"", i, cleanLeft))
            end
        elseif rightText ~= "" then
            local cleanRight = rightText:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
            table.insert(linesOutput, string.format("Line %d: (Empty Left)   [Right Column: \"%s\"]", i, cleanRight))
        end
    end
    
    debugEditBox:SetText(table.concat(linesOutput, "\r\n"))
    debugEditBox:SetFocus()
    debugEditBox:HighlightText()
    scannerTooltip:Hide()
end

SLASH_ARCHECK1 = "/archeck"
SlashCmdList["ARCHECK"] = function(msg)
    if msg and msg ~= "" then ShowInGameDebugLog(msg)
    else DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[AutoRoll]|r Please type /archeck followed by an item link to copy its data!") end
end

-- Global Client Command Registry: Overrides local scopes to let you open panels hands-free via chat windows
SLASH_AUTOROLL1 = "/autoroll"
SlashCmdList["AUTOROLL"] = function() 
    ToggleUI() 
end
