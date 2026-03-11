-- =============================================================================
-- THUD Auto Summon Module
-- Built from Recruitment.lua patterns
-- =============================================================================

THUD = THUD or {}

-- =============================================================================
-- 1. SETTINGS & STATE
-- =============================================================================

THUD_AutoSummonState = {
    isRunning  = false,
    lastAdTime = 0,
}

local function EnsureSettings()
    THUD_Settings = THUD_Settings or {}
    if not THUD_Settings.autoSummon then
        THUD_Settings.autoSummon = {
            msg             = "FREE summons! PST for an invite to Mount Hyjal!",
            selectedChannel = "world",
            interval        = 5,
            hyjal           = false,
            epl             = false,
            azshara         = false,
            ubrs            = false,
            winterspring    = false,
            silithus        = false,
        }
    end
    local s = THUD_Settings.autoSummon
    if s.msg             == nil then s.msg             = "FREE summons! PST for an invite to Mount Hyjal!" end
    if s.selectedChannel == nil then s.selectedChannel = "world"  end
    if s.interval        == nil then s.interval        = 5        end
    if s.hyjal           == nil then s.hyjal           = false    end
    if s.epl             == nil then s.epl             = false    end
    if s.azshara         == nil then s.azshara         = false    end
    if s.ubrs            == nil then s.ubrs            = false    end
    if s.winterspring    == nil then s.winterspring    = false    end
    if s.silithus        == nil then s.silithus        = false    end
end

-- =============================================================================
-- 2. LOCATION DEFINITIONS
-- =============================================================================

local locationOrder = { "hyjal", "epl", "azshara", "ubrs", "winterspring", "silithus" }

local locationDefs = {
    hyjal        = { label = "Hyjal",        keywords = { "hyjal", "mount hyjal", "hj" } },
    epl          = { label = "EPL",          keywords = { "epl", "eastern plaguelands", "eastern plague" } },
    azshara      = { label = "Azshara",      keywords = { "azshara", "azsh" } },
    ubrs         = { label = "UBRS",         keywords = { "ubrs", "upper blackrock", "upper br" } },
    winterspring = { label = "Winterspring", keywords = { "winterspring", "wspring" } },
    silithus     = { label = "Silithus",     keywords = { "silithus", "sili" } },
}

-- =============================================================================
-- 3. SEND & TIMER  (exact same pattern as Recruitment.lua)
-- =============================================================================

function THUD.SendAutoSummonPost()
    EnsureSettings()
    local s   = THUD_Settings.autoSummon
    local ch  = s.selectedChannel or "world"
    local msg = s.msg or ""

    if msg == "" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff9900THUD:|r No Auto Summon message set.")
        THUD.StopAutoSummon()
        return
    end

    local function SendToChannel(text)
        if ch == "general" then
            local num = GetChannelName("General")
            if num and num > 0 then SendChatMessage(text, "CHANNEL", nil, num) end
        elseif ch == "trade" then
            local num = GetChannelName("Trade")
            if num and num > 0 then SendChatMessage(text, "CHANNEL", nil, num) end
        elseif ch == "world" then
            local num = GetChannelName("World")
            if num and num > 0 then
                SendChatMessage(text, "CHANNEL", nil, num)
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cffff0000THUD:|r World channel not found.")
                THUD.StopAutoSummon()
                return
            end
        elseif ch == "raid" then
            if GetNumRaidMembers() > 0 then
                SendChatMessage(text, "RAID")
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cffff0000THUD:|r Not in a raid.")
                THUD.StopAutoSummon()
                return
            end
        end
    end

    SendToChannel(msg)
    THUD_AutoSummonState.lastAdTime = GetTime()
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00THUD:|r Auto Summon message sent.")
end

local timerFrame = CreateFrame("Frame", "THUD_AutoSumTimerFrame", UIParent)
timerFrame:SetScript("OnUpdate", function()
    if not THUD_AutoSummonState.isRunning then return end
    EnsureSettings()
    local intervalSec = (tonumber(THUD_Settings.autoSummon.interval) or 5) * 60
    local elapsed     = GetTime() - THUD_AutoSummonState.lastAdTime
    if elapsed >= intervalSec then
        THUD.SendAutoSummonPost()
    end
end)

-- =============================================================================
-- 4. START / STOP
-- =============================================================================

function THUD.StartAutoSummon()
    EnsureSettings()
    local s = THUD_Settings.autoSummon
    if not s.msg or s.msg == "" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff9900THUD:|r Please set an Auto Summon message first.")
        return
    end
    THUD_AutoSummonState.isRunning  = true
    THUD_AutoSummonState.lastAdTime = 0
    THUD.ShowAutoSummonPanel()
    THUD.UpdateAutoSummonButton()
    local mins = s.interval or 5
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00THUD:|r Auto Summon started. Posting every " .. mins .. " min.")
end

function THUD.StopAutoSummon()
    THUD_AutoSummonState.isRunning = false
    THUD.HideAutoSummonPanel()
    THUD.UpdateAutoSummonButton()
    DEFAULT_CHAT_FRAME:AddMessage("|cffff4444THUD:|r Auto Summon stopped.")
end

function THUD.UpdateAutoSummonButton()
    local btn = getglobal("THUD_AutoSumBtn")
    if btn then
        if THUD_AutoSummonState.isRunning then
            btn:SetText("|cffff4444Stop Auto Summon|r")
        else
            btn:SetText("|cff44ff44Start Auto Summon|r")
        end
    end
end

-- =============================================================================
-- 5. PROGRESS PANEL (same as Recruitment panel)
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

function THUD.UpdateAutoSummonPanelAnchor()
    if not autoSummonPanel then return end
    local recruitPanel = getglobal("THUD_RecruitPanel")
    autoSummonPanel:ClearAllPoints()
    if recruitPanel and recruitPanel:IsVisible() then
        autoSummonPanel:SetPoint("TOP", recruitPanel, "BOTTOM", 0, -4)
    else
        autoSummonPanel:SetPoint("TOP", THUD_MainBar, "BOTTOM", 0, -4)
    end
end

function THUD.CreateAutoSummonPanel()
    if autoSummonPanel then return end

    local f = CreateFrame("Frame", "THUD_AutoSumPanel", UIParent)
    f:SetWidth(280); f:SetHeight(45)
    f:SetPoint("TOP", THUD_MainBar, "BOTTOM", 0, -4)
    f:SetFrameStrata("HIGH")
    f:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12, insets = {left=4, right=4, top=4, bottom=4}
    })
    f:SetBackdropColor(0.08, 0, 0.18, 0.92)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOPLEFT", 10, -8)
    title:SetText("|cffcc88ffAuto Summon...|r")

    local stopBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    stopBtn:SetWidth(44); stopBtn:SetHeight(16)
    stopBtn:SetPoint("TOPRIGHT", -6, -6)
    stopBtn:SetText("|cffff4444Stop|r")
    stopBtn:SetScript("OnClick", function() THUD.StopAutoSummon() end)

    local bar = CreateFrame("StatusBar", nil, f)
    bar:SetPoint("TOPLEFT",  title,   "BOTTOMLEFT",  0, -4)
    bar:SetPoint("TOPRIGHT", stopBtn, "BOTTOMRIGHT", 0, -4)
    bar:SetHeight(10)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetStatusBarColor(0.6, 0.1, 0.8, 1)
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
        if not THUD_AutoSummonState.isRunning then return end
        EnsureSettings()
        local intervalSec = (tonumber(THUD_Settings.autoSummon.interval) or 5) * 60
        local elapsed     = now - THUD_AutoSummonState.lastAdTime
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
-- 6. CHAT SCANNER
-- =============================================================================

local chatScanner = CreateFrame("Frame")
chatScanner:RegisterEvent("CHAT_MSG_CHANNEL")
chatScanner:RegisterEvent("CHAT_MSG_SAY")
chatScanner:RegisterEvent("CHAT_MSG_YELL")
chatScanner:RegisterEvent("CHAT_MSG_WHISPER")

chatScanner:SetScript("OnEvent", function()
    if not THUD_AutoSummonState.isRunning then return end
    if not arg1 or not arg2 then return end
    if arg2 == UnitName("player") then return end

    EnsureSettings()
    local s    = THUD_Settings.autoSummon
    local text = string.lower(arg1)

    local wantsSummon = string.find(text, "summon") or string.find(text, "summons")
        or string.find(text, " summ") or string.find(text, "^summ")
        or string.find(text, " sum ") or string.find(text, "^sum ")

    if not wantsSummon then return end

    local matchedLabel = nil
    for _, key in ipairs(locationOrder) do
        if s[key] then
            for _, kw in ipairs(locationDefs[key].keywords) do
                if string.find(text, kw) then
                    matchedLabel = locationDefs[key].label
                    break
                end
            end
        end
        if matchedLabel then break end
    end

    if not matchedLabel then return end

    if InviteUnit then InviteUnit(arg2) else InviteByName(arg2) end
    SendChatMessage("Free summon to " .. matchedLabel .. "! No cost, tips appreciated!", "WHISPER", nil, arg2)
    DEFAULT_CHAT_FRAME:AddMessage("|cffcc88ffTHUD Auto Summon:|r Invited and whispered " .. arg2 .. " for " .. matchedLabel)
end)

-- =============================================================================
-- 7. CONFIG WINDOW
-- =============================================================================

local summonFrame = nil

function THUD.ShowAutoSummonWindow()
    EnsureSettings()

    if summonFrame then
        summonFrame:Show()
        THUD.RefreshAutoSummonWindow()
        return
    end

    local frame = CreateFrame("Frame", "THUD_AutoSummonFrame", UIParent)
    frame:SetWidth(460); frame:SetHeight(420)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true); frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() this:StartMoving() end)
    frame:SetScript("OnDragStop",  function() this:StopMovingOrSizing() end)
    frame:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 14, insets = {left=4, right=4, top=4, bottom=4}
    })
    frame:SetBackdropColor(0, 0, 0, 0.92)
    table.insert(UISpecialFrames, "THUD_AutoSummonFrame")

    local titleTxt = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleTxt:SetPoint("TOP", 0, -14)
    titleTxt:SetText("|cffcc88ffAuto Summon|r")

    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)

    -- Message box
    local msgLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    msgLabel:SetPoint("TOPLEFT", 18, -46)
    msgLabel:SetText("Auto-Post Message (0/255):")
    frame.msgLabel = msgLabel

    local msgBg = CreateFrame("Frame", nil, frame)
    msgBg:SetPoint("TOPLEFT", 18, -64)
    msgBg:SetWidth(424); msgBg:SetHeight(60)
    msgBg:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 10, insets = {left=3, right=3, top=3, bottom=3}
    })
    msgBg:SetBackdropColor(0,0,0,1)
    msgBg:SetBackdropBorderColor(0.35, 0.35, 0.5, 1)

    local msgSF = CreateFrame("ScrollFrame", nil, msgBg)
    msgSF:SetPoint("TOPLEFT", 5, -5); msgSF:SetPoint("BOTTOMRIGHT", -5, 5)
    local msgSC = CreateFrame("Frame", nil, msgSF)
    msgSF:SetScrollChild(msgSC); msgSC:SetWidth(410); msgSC:SetHeight(400)

    local msgBox = CreateFrame("EditBox", nil, msgSC)
    msgBox:SetPoint("TOPLEFT", 0, 0); msgBox:SetWidth(410); msgBox:SetHeight(400)
    msgBox:SetMultiLine(true); msgBox:SetAutoFocus(false); msgBox:SetMaxLetters(255)
    msgBox:SetFontObject(GameFontHighlightSmall); msgBox:SetTextInsets(4,4,3,3)
    msgBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    msgBox:SetScript("OnTextChanged", function()
        local txt = this:GetText()
        local len = string.len(txt)
        msgLabel:SetText("Auto-Post Message (" .. len .. "/255):")
        if len > 255 then msgLabel:SetTextColor(1,0,0) else msgLabel:SetTextColor(1,1,1) end
    end)
    msgBox:SetScript("OnEditFocusLost", function()
        THUD_Settings.autoSummon.msg = this:GetText()
    end)
    frame.msgBox = msgBox

    -- Channel radios
    local chLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    chLabel:SetPoint("TOPLEFT", 18, -138)
    chLabel:SetText("Advertise in:")

    local channels = {
        {key="general", label="General"},
        {key="trade",   label="Trade"},
        {key="world",   label="World"},
        {key="raid",    label="Raid"},
    }
    local radioButtons = {}
    for i, ch in ipairs(channels) do
        local radio = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        radio:SetWidth(22); radio:SetHeight(22)
        radio:SetPoint("TOPLEFT", 18 + (i-1)*90, -162)
        radio:SetChecked(THUD_Settings.autoSummon.selectedChannel == ch.key)

        local lbl = radio:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        lbl:SetPoint("LEFT", radio, "RIGHT", 2, 0)
        lbl:SetText(ch.label)

        local captureKey = ch.key
        radio:SetScript("OnClick", function()
            for _, rb in ipairs(radioButtons) do rb:SetChecked(false) end
            this:SetChecked(true)
            THUD_Settings.autoSummon.selectedChannel = captureKey
        end)
        table.insert(radioButtons, radio)
    end
    frame.radioButtons = radioButtons
    frame.channels     = channels

    -- Interval
    local intLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    intLabel:SetPoint("TOPLEFT", 18, -202)
    intLabel:SetText("Interval (minutes):")

    local intBox = CreateFrame("EditBox", nil, frame)
    intBox:SetPoint("LEFT", intLabel, "RIGHT", 8, 0)
    intBox:SetWidth(50); intBox:SetHeight(20)
    intBox:SetAutoFocus(false); intBox:SetNumeric(true)
    intBox:SetFontObject(GameFontHighlight)
    intBox:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/ChatFrame/ChatFrameBackground",
        tile=true, tileSize=16, edgeSize=1,
        insets={left=3,right=3,top=3,bottom=3}
    })
    intBox:SetBackdropColor(0,0,0,0.6); intBox:SetBackdropBorderColor(0.3,0.3,0.3,1)
    intBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    intBox:SetScript("OnTextChanged", function()
        local v = tonumber(this:GetText())
        if v and v > 0 then THUD_Settings.autoSummon.interval = v end
    end)
    intBox:SetScript("OnEditFocusLost", function() this:ClearFocus() end)
    frame.intBox = intBox

    -- Locations label
    local locLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    locLabel:SetPoint("TOPLEFT", 18, -236)
    locLabel:SetText("Locations to Scan For:")

    -- Location checkboxes 3-col grid
    local locationCBs = {}
    for i, key in ipairs(locationOrder) do
        local def = locationDefs[key]
        local row = math.floor((i-1) / 3)
        local col = math.mod((i-1), 3)
        local cb  = CreateFrame("CheckButton", "THUD_ASCB_"..key, frame, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", frame, "TOPLEFT", 18 + col*145, -258 + row*(-28))
        getglobal(cb:GetName().."Text"):SetText(def.label)
        cb:SetChecked(THUD_Settings.autoSummon[key] and 1 or nil)
        cb.zoneKey = key
        cb:SetScript("OnClick", function()
            THUD_Settings.autoSummon[this.zoneKey] = (this:GetChecked() and true or false)
        end)
        table.insert(locationCBs, cb)
    end
    frame.locationCBs = locationCBs

    -- Start/Stop button
    local sumBtn = CreateFrame("Button", "THUD_AutoSumBtn", frame, "UIPanelButtonTemplate")
    sumBtn:SetWidth(160); sumBtn:SetHeight(28)
    sumBtn:SetPoint("BOTTOM", 0, 16)
    sumBtn:SetScript("OnClick", function()
        if THUD_AutoSummonState.isRunning then
            THUD.StopAutoSummon()
        else
            THUD.StartAutoSummon()
        end
    end)

    summonFrame = frame
    THUD.RefreshAutoSummonWindow()
    frame:Show()
end

function THUD.RefreshAutoSummonWindow()
    if not summonFrame then return end
    EnsureSettings()
    local s = THUD_Settings.autoSummon

    summonFrame.msgBox:SetText(s.msg or "")
    summonFrame.intBox:SetText(tostring(s.interval or 5))

    for i, rb in ipairs(summonFrame.radioButtons) do
        rb:SetChecked(summonFrame.channels[i].key == s.selectedChannel)
    end
    for _, cb in ipairs(summonFrame.locationCBs) do
        cb:SetChecked(s[cb.zoneKey] and 1 or nil)
    end

    THUD.UpdateAutoSummonButton()
end

-- =============================================================================
-- 8. SLASH COMMANDS
-- =============================================================================

SLASH_THUDAS1 = "/thudas"
SLASH_THUDAS2 = "/autosummon"
SlashCmdList["THUDAS"] = function()
    if summonFrame and summonFrame:IsVisible() then
        summonFrame:Hide()
    else
        THUD.ShowAutoSummonWindow()
    end
end
