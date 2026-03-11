-- =============================================================================
-- THUD Auto Summon Module
-- Integrated into THUD Raid Tools
-- Based on AutoHyjalInvite by Senzei
-- =============================================================================

THUD = THUD or {}

-- =============================================================================
-- 1. SETTINGS & STATE
-- =============================================================================

AutoSummon_Settings = {
    ["hyjal"]            = false,
    ["epl"]              = false,
    ["azshara"]          = false,
    ["ubrs"]             = false,
    ["winterspring"]     = false,
    ["silithus"]         = false,
    ["autoPostMsg"]      = "FREE summons active! PST for an invite!",
    ["autoPostInterval"] = 60,       -- seconds
    ["selectedChannel"]  = "world",  -- general / trade / world / raid
}

AutoSummon_State = {
    isRunning     = false,
    timeSinceLast = 0,
}

-- Indexed for consistent UI ordering
local locationOrder = { "hyjal", "epl", "azshara", "ubrs", "winterspring", "silithus" }
local locations = {
    ["hyjal"]        = "Hyjal",
    ["epl"]          = "EPL",
    ["azshara"]      = "Azshara",
    ["ubrs"]         = "UBRS",
    ["winterspring"] = "Winterspring",
    ["silithus"]     = "Silithus",
}

-- =============================================================================
-- 2. START / STOP LOGIC
-- =============================================================================

function THUD.StartAutoSummon()
    AutoSummon_State.isRunning     = true
    AutoSummon_State.timeSinceLast = 0  -- fire first post immediately
    THUD.ShowAutoSummonPanel()
    THUD.UpdateAutoSummonButton()
    local secs = tonumber(AutoSummon_Settings["autoPostInterval"]) or 60
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00THUD:|r Auto Summon |cff00ff00Started|r. Posting every " .. secs .. "s.")
end

function THUD.StopAutoSummon()
    AutoSummon_State.isRunning = false
    THUD.HideAutoSummonPanel()
    THUD.UpdateAutoSummonButton()
    DEFAULT_CHAT_FRAME:AddMessage("|cffff4444THUD:|r Auto Summon |cffff4444Stopped|r.")
end

function THUD.UpdateAutoSummonButton()
    local btn = getglobal("THUD_AutoSumBtn")
    if btn then
        if AutoSummon_State.isRunning then
            btn:SetText("|cffff4444Stop Auto Summon|r")
        else
            btn:SetText("|cff44ff44Start Auto Summon|r")
        end
    end
end

-- =============================================================================
-- 3. AUTO-POSTER TIMER
-- =============================================================================

local function SendAutoSummonPost()
    local ch  = AutoSummon_Settings["selectedChannel"] or "world"
    local msg = AutoSummon_Settings["autoPostMsg"] or ""
    if msg == "" then return end

    if ch == "general" then
        local num = GetChannelName("General")
        if num and num > 0 then SendChatMessage(msg, "CHANNEL", nil, num) end
    elseif ch == "trade" then
        local num = GetChannelName("Trade")
        if num and num > 0 then SendChatMessage(msg, "CHANNEL", nil, num) end
    elseif ch == "world" then
        local num = GetChannelName("World")
        if num and num > 0 then
            SendChatMessage(msg, "CHANNEL", nil, num)
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[AutoSummon]|r World channel not found. Stopping.")
            THUD.StopAutoSummon()
        end
    elseif ch == "raid" then
        SendChatMessage(msg, "RAID")
    end
end

local timerFrame = CreateFrame("Frame", "THUD_AutoSumTimerFrame", UIParent)
timerFrame:SetScript("OnUpdate", function()
    if not AutoSummon_State.isRunning then return end

    AutoSummon_State.timeSinceLast = AutoSummon_State.timeSinceLast + (arg1 or 0)

    local intervalSec = tonumber(AutoSummon_Settings["autoPostInterval"]) or 60
    if AutoSummon_State.timeSinceLast >= intervalSec then
        AutoSummon_State.timeSinceLast = 0
        SendAutoSummonPost()
    end
end)

-- =============================================================================
-- 4. COUNTDOWN PROGRESS PANEL (anchors below MainUI / Recruitment panel)
-- =============================================================================

local autoSummonPanel = nil

function THUD.ShowAutoSummonPanel()
    if not autoSummonPanel then
        THUD.CreateAutoSummonPanel()
    end
    if autoSummonPanel and not autoSummonPanel:IsVisible() then
        autoSummonPanel:Show()
    end
end

function THUD.HideAutoSummonPanel()
    if autoSummonPanel then autoSummonPanel:Hide() end
end

function THUD.CreateAutoSummonPanel()
    if autoSummonPanel then return end

    local anchorFrame = getglobal("THUD_RecruitPanel") or getglobal("THUD_MainBar")

    local f = CreateFrame("Frame", "THUD_AutoSumPanel", UIParent)
    f:SetWidth(280); f:SetHeight(45)
    f:SetPoint("TOP", anchorFrame, "BOTTOM", 0, -4)
    f:SetFrameStrata("HIGH")
    f:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12, insets = {left=4, right=4, top=4, bottom=4}
    })
    f:SetBackdropColor(0, 0.08, 0.18, 0.92)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOPLEFT", 10, -8)
    title:SetText("|cffcc88ffAuto Summon...|r")

    local stopBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    stopBtn:SetWidth(44); stopBtn:SetHeight(16)
    stopBtn:SetPoint("TOPRIGHT", -6, -6)
    stopBtn:SetText("|cffff4444Stop|r")
    stopBtn:SetScript("OnClick", function() THUD.StopAutoSummon() end)

    local bar = CreateFrame("StatusBar", nil, f)
    bar:SetPoint("TOPLEFT",  title, "BOTTOMLEFT", 0, -4)
    bar:SetPoint("TOPRIGHT", stopBtn, "BOTTOMRIGHT", 0, -4)
    bar:SetHeight(10)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetStatusBarColor(0.6, 0.3, 1.0, 1)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(1)
    f.bar = bar

    local barTxt = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    barTxt:SetPoint("CENTER", bar, "CENTER", 0, 0)
    barTxt:SetText("0:00")
    f.barTxt = barTxt

    f.lastTick = 0
    f:SetScript("OnUpdate", function()
        local now = GetTime()
        if now - this.lastTick < 1.0 then return end
        this.lastTick = now
        if not AutoSummon_State.isRunning then return end

        local intervalSec = tonumber(AutoSummon_Settings["autoPostInterval"]) or 60
        local elapsed     = AutoSummon_State.timeSinceLast
        local remaining   = math.max(0, intervalSec - elapsed)
        local progress    = remaining / intervalSec

        this.bar:SetValue(math.max(0, math.min(1, progress)))

        local mins   = math.floor(remaining / 60)
        local secs   = math.floor(math.mod(remaining, 60))
        local secStr = tostring(secs)
        if secs < 10 then secStr = "0" .. secStr end
        this.barTxt:SetText(tostring(mins) .. ":" .. secStr)
    end)

    autoSummonPanel = f
    f:Show()
end

-- =============================================================================
-- 5. CHAT SCANNER (invite + summon popup on matching messages)
-- =============================================================================

local chatFrame = CreateFrame("Frame")
chatFrame:RegisterEvent("CHAT_MSG_CHANNEL")
chatFrame:RegisterEvent("CHAT_MSG_SAY")
chatFrame:RegisterEvent("CHAT_MSG_YELL")
chatFrame:RegisterEvent("CHAT_MSG_WHISPER")

chatFrame:SetScript("OnEvent", function()
    if not AutoSummon_State.isRunning then return end
    if not arg1 or not arg2 then return end
    if arg2 == UnitName("player") then return end

    local text = string.lower(arg1)

    local hasIntent = string.find(text, "wtb") or string.find(text, "lf ") or string.find(text, "^lf")
    local hasSummon = string.find(text, " sum") or string.find(text, "^sum") or string.find(text, "summon") or string.find(text, "summons")

    local foundLocation = nil
    for key, name in pairs(locations) do
        if AutoSummon_Settings[key] and string.find(text, key) then
            foundLocation = name
            break
        end
    end

    if hasIntent and foundLocation and hasSummon then
        SendChatMessage("Free summon to " .. foundLocation .. "! No cost, tips appreciated!", "WHISPER", nil, arg2)

        if InviteUnit then InviteUnit(arg2) else InviteByName(arg2) end

        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[AutoSummon]|r Invited and whispered: " .. arg2)

        local popup = getglobal("THUD_AutoSummonPopup")
        if popup then
            local nameText = getglobal("THUD_AutoSummonPopupText")
            if nameText then nameText:SetText("Summon: " .. arg2) end
            local castBtn = getglobal("THUD_AutoSummonCastBtn")
            if castBtn then castBtn.summonTarget = arg2 end
            popup:Show()
        end

        PlaySound("ReadyCheck")
    end
end)

-- =============================================================================
-- 6. SUMMON ACTION POPUP
-- =============================================================================

local summonPopup = CreateFrame("Frame", "THUD_AutoSummonPopup", UIParent)
summonPopup:SetWidth(250); summonPopup:SetHeight(85)
summonPopup:SetPoint("TOP", UIParent, "TOP", 0, -150)
summonPopup:SetBackdrop({
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
summonPopup:Hide()
summonPopup:SetMovable(true); summonPopup:EnableMouse(true)
summonPopup:RegisterForDrag("LeftButton")
summonPopup:SetScript("OnDragStart", function() this:StartMoving() end)
summonPopup:SetScript("OnDragStop",  function() this:StopMovingOrSizing() end)

local popupText = summonPopup:CreateFontString("THUD_AutoSummonPopupText", "OVERLAY", "GameFontHighlight")
popupText:SetPoint("TOP", 0, -15)
popupText:SetText("Summon: Unknown")

local castSummonBtn = CreateFrame("Button", "THUD_AutoSummonCastBtn", summonPopup, "UIPanelButtonTemplate")
castSummonBtn:SetWidth(90); castSummonBtn:SetHeight(25)
castSummonBtn:SetPoint("BOTTOMLEFT", 20, 15)
castSummonBtn:SetText("Summon")
castSummonBtn:SetScript("OnClick", function()
    if this.summonTarget then
        TargetByName(this.summonTarget, true)
        CastSpellByName("Ritual of Summoning")
        summonPopup:Hide()
    end
end)

local dismissBtn = CreateFrame("Button", nil, summonPopup, "UIPanelButtonTemplate")
dismissBtn:SetWidth(90); dismissBtn:SetHeight(25)
dismissBtn:SetPoint("BOTTOMRIGHT", -20, 15)
dismissBtn:SetText("Dismiss")
dismissBtn:SetScript("OnClick", function() summonPopup:Hide() end)

-- =============================================================================
-- 7. MAIN GUI WINDOW
-- =============================================================================

function THUD.ShowAutoSummonWindow()
    local gui = getglobal("THUD_AutoSummonFrame")
        or CreateFrame("Frame", "THUD_AutoSummonFrame", UIParent)

    -- Only build contents once
    if gui.built then
        THUD.UpdateAutoSummonButton()
        gui:Show()
        return
    end
    gui.built = true

    gui:SetWidth(460); gui:SetHeight(400)
    gui:SetPoint("CENTER", UIParent, "CENTER")
    gui:SetFrameStrata("DIALOG"); gui:SetFrameLevel(150)
    gui:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 14, insets = {left=4, right=4, top=4, bottom=4}
    })
    gui:SetBackdropColor(0, 0, 0, 0.92)
    gui:EnableMouse(true); gui:SetMovable(true)
    gui:RegisterForDrag("LeftButton")
    gui:SetScript("OnDragStart", function() this:StartMoving() end)
    gui:SetScript("OnDragStop",  function() this:StopMovingOrSizing() end)
    table.insert(UISpecialFrames, "THUD_AutoSummonFrame")

    -- Title
    local title = gui:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -14)
    title:SetText("|cffcc88ffAuto Summon|r")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, gui, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function() gui:Hide() end)

    -- -------------------------------------------------------
    -- MESSAGE BOX
    -- -------------------------------------------------------
    local msgLabel = gui:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    msgLabel:SetPoint("TOPLEFT", 18, -46)
    msgLabel:SetText("Auto-Post Message (0/255):")
    gui.msgLabel = msgLabel

    local msgBg = CreateFrame("Frame", nil, gui)
    msgBg:SetPoint("TOPLEFT", 18, -64)
    msgBg:SetWidth(424); msgBg:SetHeight(60)
    msgBg:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 10, insets = {left=3, right=3, top=3, bottom=3}
    })
    msgBg:SetBackdropColor(0, 0, 0, 1)
    msgBg:SetBackdropBorderColor(0.35, 0.35, 0.5, 1)

    local msgSF = CreateFrame("ScrollFrame", nil, msgBg)
    msgSF:SetPoint("TOPLEFT", 5, -5); msgSF:SetPoint("BOTTOMRIGHT", -5, 5)
    local msgSC = CreateFrame("Frame", nil, msgSF)
    msgSF:SetScrollChild(msgSC); msgSC:SetWidth(410); msgSC:SetHeight(400)

    local msgBox = CreateFrame("EditBox", nil, msgSC)
    msgBox:SetPoint("TOPLEFT", 0, 0); msgBox:SetWidth(410); msgBox:SetHeight(400)
    msgBox:SetMultiLine(true); msgBox:SetAutoFocus(false); msgBox:SetMaxLetters(255)
    msgBox:SetFontObject(GameFontHighlightSmall); msgBox:SetTextInsets(4, 4, 3, 3)
    msgBox:SetText(AutoSummon_Settings["autoPostMsg"])
    msgBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    msgBox:SetScript("OnTextChanged", function()
        local txt = this:GetText()
        local len = string.len(txt)
        msgLabel:SetText("Auto-Post Message (" .. len .. "/255):")
        if len > 255 then msgLabel:SetTextColor(1, 0, 0) else msgLabel:SetTextColor(1, 1, 1) end
    end)
    msgBox:SetScript("OnEditFocusLost", function()
        AutoSummon_Settings["autoPostMsg"] = this:GetText()
    end)
    gui.msgBox = msgBox

    -- -------------------------------------------------------
    -- CHANNEL RADIO BUTTONS  (matches Recruitment exactly)
    -- -------------------------------------------------------
    local chLabel = gui:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    chLabel:SetPoint("TOPLEFT", 18, -138)
    chLabel:SetText("Advertise in:")

    local channels = {
        { key = "general", label = "General" },
        { key = "trade",   label = "Trade"   },
        { key = "world",   label = "World"   },
        { key = "raid",    label = "Raid"    },
    }
    local radioButtons = {}
    for i, ch in ipairs(channels) do
        local radio = CreateFrame("CheckButton", nil, gui, "UICheckButtonTemplate")
        radio:SetWidth(22); radio:SetHeight(22)
        radio:SetPoint("TOPLEFT", 18 + (i - 1) * 100, -158)
        radio:SetChecked(AutoSummon_Settings["selectedChannel"] == ch.key)

        local lbl = radio:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        lbl:SetPoint("LEFT", radio, "RIGHT", 2, 0)
        lbl:SetText(ch.label)

        local captureKey = ch.key
        radio:SetScript("OnClick", function()
            for _, rb in ipairs(radioButtons) do rb:SetChecked(false) end
            this:SetChecked(true)
            AutoSummon_Settings["selectedChannel"] = captureKey
        end)
        table.insert(radioButtons, radio)
    end
    gui.radioButtons = radioButtons

    -- -------------------------------------------------------
    -- INTERVAL BOX
    -- -------------------------------------------------------
    local intLabel = gui:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    intLabel:SetPoint("TOPLEFT", 18, -198)
    intLabel:SetText("Interval (seconds):")

    local intBox = CreateFrame("EditBox", nil, gui)
    intBox:SetPoint("LEFT", intLabel, "RIGHT", 8, 0)
    intBox:SetWidth(55); intBox:SetHeight(20)
    intBox:SetAutoFocus(false); intBox:SetNumeric(true)
    intBox:SetFontObject(GameFontHighlight)
    intBox:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/ChatFrame/ChatFrameBackground",
        tile = true, tileSize = 16, edgeSize = 1,
        insets = {left=3, right=3, top=3, bottom=3}
    })
    intBox:SetBackdropColor(0, 0, 0, 0.6)
    intBox:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    intBox:SetText(tostring(AutoSummon_Settings["autoPostInterval"]))
    intBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    intBox:SetScript("OnEditFocusLost", function() this:ClearFocus() end)
    intBox:SetScript("OnTextChanged", function()
        local v = tonumber(this:GetText())
        if v and v > 0 then AutoSummon_Settings["autoPostInterval"] = v end
    end)
    gui.intBox = intBox

    -- -------------------------------------------------------
    -- LOCATIONS LABEL
    -- -------------------------------------------------------
    local locLabel = gui:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    locLabel:SetPoint("TOPLEFT", 18, -234)
    locLabel:SetText("Locations to Scan For:")

    -- -------------------------------------------------------
    -- ZONE CHECKBOXES  (3-column grid)
    -- -------------------------------------------------------
    local columns = 3
    local xStart  = 18
    local yStart  = -256
    local xOffset = 145
    local yOffset = -28

    for i, key in ipairs(locationOrder) do
        local cbName = "THUD_AutoSumCB_" .. key
        local cb = getglobal(cbName)
            or CreateFrame("CheckButton", cbName, gui, "UICheckButtonTemplate")
        local row = math.floor((i - 1) / columns)
        local col = math.mod((i - 1), columns)
        cb:SetPoint("TOPLEFT", gui, "TOPLEFT", xStart + col * xOffset, yStart + row * yOffset)
        getglobal(cb:GetName() .. "Text"):SetText(locations[key])
        cb:SetChecked(AutoSummon_Settings[key] and 1 or nil)
        cb.zoneKey = key
        cb:SetScript("OnClick", function()
            AutoSummon_Settings[this.zoneKey] = (this:GetChecked() and true or false)
        end)
    end

    -- -------------------------------------------------------
    -- START / STOP BUTTON
    -- -------------------------------------------------------
    local sumBtn = CreateFrame("Button", "THUD_AutoSumBtn", gui, "UIPanelButtonTemplate")
    sumBtn:SetWidth(160); sumBtn:SetHeight(28)
    sumBtn:SetPoint("BOTTOM", 0, 16)
    sumBtn:SetScript("OnClick", function()
        if AutoSummon_State.isRunning then
            THUD.StopAutoSummon()
        else
            THUD.StartAutoSummon()
        end
    end)
    gui.sumBtn = sumBtn

    THUD.UpdateAutoSummonButton()
    gui:Show()
end

-- =============================================================================
-- 8. SLASH COMMANDS
-- =============================================================================

SLASH_THUDAS1 = "/thudas"
SLASH_THUDAS2 = "/autosummon"
SlashCmdList["THUDAS"] = function()
    if THUD_AutoSummonFrame and THUD_AutoSummonFrame:IsVisible() then
        THUD_AutoSummonFrame:Hide()
    else
        THUD.ShowAutoSummonWindow()
    end
end
