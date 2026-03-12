-- =============================================================================
-- THUD Recruitment Module (Enhanced - Ported from OG-RaidHelper)
-- Features: 5 message slots, rotation, second message, channel radio buttons,
--           [TTP] target time tag, interval in minutes, progress bar panel
-- =============================================================================

THUD = THUD or {}

-- =============================================================================
-- 1. SETTINGS INITIALIZATION
-- =============================================================================

-- In-memory state (never persisted across sessions)
THUD_RecruitmentState = {
    isRecruiting   = false,
    lastAdTime     = 0,
    lastRotIndex   = 0,
}

-- Saved settings (persisted via THUD_Settings global)
local function EnsureSettings()
    THUD_Settings = THUD_Settings or {}
    local s = THUD_Settings

    if not s.recruit then
        s.recruit = {
            messages         = {"", "", "", "", ""},
            messages2        = {"", "", "", "", ""},
            selectedIndex    = 1,
            rotateMessages   = {false, false, false, false, false},
            selectedChannel  = "world",
            interval         = 10,       -- minutes
            targetTime       = "",        -- "HHMM" format e.g. "2030"
        }
    end

    -- Migration / field guards
    local r = s.recruit
    if not r.messages        then r.messages        = {"","","","",""}              end
    if not r.messages2       then r.messages2       = {"","","","",""}              end
    if not r.selectedIndex   then r.selectedIndex   = 1                             end
    if not r.rotateMessages  then r.rotateMessages  = {false,false,false,false,false} end
    if not r.selectedChannel then r.selectedChannel = "world"                       end
    if not r.interval        then r.interval        = 10                            end
    if not r.targetTime      then r.targetTime      = ""                            end

    -- Migrate from old flat THUD_Settings fields
    if s.message and s.message ~= "" and r.messages[1] == "" then
        r.messages[1] = s.message
        s.message = nil
    end
    if s.channel and r.selectedChannel == "world" then
        local ch = string.lower(s.channel or "")
        if ch == "general" or ch == "trade" or ch == "world" or ch == "raid" then
            r.selectedChannel = ch
        end
        s.channel = nil
    end
    if s.interval and r.interval == 10 then
        -- old setting was in seconds, convert
        local sec = tonumber(s.interval)
        if sec and sec > 60 then
            r.interval = math.floor(sec / 60)
        end
        s.interval = nil
    end
end

-- =============================================================================
-- 2. ADVERTISING LOGIC
-- =============================================================================

-- Replace [TTP] with minutes until target time (e.g. targetTime = "2030")
local function ApplyTTPTag(msg)
    if not msg or msg == "" then return msg end
    local tt = THUD_Settings.recruit.targetTime
    if not tt or tt == "" then return msg end

    local tNum = tonumber(tt)
    if not tNum then return msg end

    local tH = math.floor(tNum / 100)
    local tM = math.mod(tNum, 100)
    local cH = tonumber(date("%H"))
    local cM = tonumber(date("%M"))
    local diffMin = (tH * 60 + tM) - (cH * 60 + cM)
    if diffMin < 0 then diffMin = diffMin + 1440 end -- wrap past midnight

    return string.gsub(msg, "%[TTP%]", tostring(diffMin))
end

function THUD.SendRecruitmentAd()
    EnsureSettings()
    local r = THUD_Settings.recruit

    -- Determine which message slot to use
    local checkedSlots = {}
    for i = 1, 5 do
        if r.rotateMessages[i] then
            table.insert(checkedSlots, i)
        end
    end

    local slotIdx
    if table.getn(checkedSlots) > 1 then
        -- Rotation mode: find next checked slot after lastRotIndex
        local next = nil
        for _, idx in ipairs(checkedSlots) do
            if idx > THUD_RecruitmentState.lastRotIndex then
                next = idx
                break
            end
        end
        if not next then next = checkedSlots[1] end
        slotIdx = next
        THUD_RecruitmentState.lastRotIndex = next
    else
        slotIdx = r.selectedIndex or 1
    end

    local msg  = ApplyTTPTag(r.messages[slotIdx]  or "")
    local msg2 = ApplyTTPTag(r.messages2[slotIdx] or "")

    if not msg or msg == "" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff9900THUD:|r No recruitment message set for slot " .. slotIdx .. ".")
        THUD.StopRecruiting()
        return
    end

    local ch = r.selectedChannel or "world"

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
                THUD.StopRecruiting()
                return
            end
        elseif ch == "raid" then
            if GetNumRaidMembers() > 0 then
                SendChatMessage(text, "RAID")
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cffff0000THUD:|r You are not in a raid.")
                THUD.StopRecruiting()
                return
            end
        end
    end

    SendToChannel(msg)
    if msg2 ~= "" then SendToChannel(msg2) end

    THUD_RecruitmentState.lastAdTime = GetTime()
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00THUD:|r Recruitment message sent (slot " .. slotIdx .. ").")
end

function THUD.StartRecruiting()
    EnsureSettings()
    local r = THUD_Settings.recruit
    if not r.messages[r.selectedIndex] or r.messages[r.selectedIndex] == "" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff9900THUD:|r Please set a recruitment message first.")
        return
    end
    THUD_RecruitmentState.isRecruiting = true
    THUD_RecruitmentState.lastAdTime   = 0  -- fire immediately
    THUD.ShowRecruitingPanel()
    THUD.UpdateRecruitmentButton()
    local mins = r.interval or 10
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00THUD:|r Recruiting started. Posting every " .. mins .. " min.")
end

function THUD.StopRecruiting()
    THUD_RecruitmentState.isRecruiting = false
    THUD.HideRecruitingPanel()
    THUD.UpdateRecruitmentButton()
    DEFAULT_CHAT_FRAME:AddMessage("|cffff0000THUD:|r Recruiting stopped.")
end

-- =============================================================================
-- 3. TIMER / POSTING FRAME
-- =============================================================================

local timerFrame = CreateFrame("Frame", "THUD_RecruitTimer", UIParent)
timerFrame:SetScript("OnUpdate", function()
    if not THUD_RecruitmentState.isRecruiting then return end
    EnsureSettings()
    local intervalSec = (tonumber(THUD_Settings.recruit.interval) or 10) * 60
    local elapsed = GetTime() - THUD_RecruitmentState.lastAdTime
    if elapsed >= intervalSec then
        THUD.SendRecruitmentAd()
    end
end)

-- =============================================================================
-- 4. RECRUITING PROGRESS PANEL (anchors below MainUI bar)
-- =============================================================================

local recruitingPanel = nil

function THUD.ShowRecruitingPanel()
    if not recruitingPanel then
        THUD.CreateRecruitingPanel()
    end
    if recruitingPanel and not recruitingPanel:IsVisible() then
        recruitingPanel:Show()
    end
end

function THUD.HideRecruitingPanel()
    if recruitingPanel then recruitingPanel:Hide() end
end

function THUD.CreateRecruitingPanel()
    if recruitingPanel then return end

    local f = CreateFrame("Frame", "THUD_RecruitPanel", UIParent)
    f:SetWidth(210); f:SetHeight(34)
    f:SetPoint("TOP", THUD_MainBar, "BOTTOM", 0, -3)
    f:SetFrameStrata("HIGH")
    f:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 8, insets = {left=3, right=3, top=3, bottom=3}
    })
    f:SetBackdropColor(0, 0.05, 0.15, 0.92)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOPLEFT", 6, -6)
    title:SetText("|cff00ccffRecruiting...|r")

    local stopBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    stopBtn:SetWidth(36); stopBtn:SetHeight(14)
    stopBtn:SetPoint("TOPRIGHT", -4, -4)
    stopBtn:SetText("|cffff4444Stop|r")
    stopBtn:SetScript("OnClick", function() THUD.StopRecruiting() end)

    local bar = CreateFrame("StatusBar", nil, f)
    bar:SetPoint("TOPLEFT",  title, "BOTTOMLEFT", 0, -3)
    bar:SetPoint("TOPRIGHT", stopBtn, "BOTTOMRIGHT", 0, -3)
    bar:SetHeight(8)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetStatusBarColor(0.1, 0.7, 0.1, 1)
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

        if not THUD_RecruitmentState.isRecruiting then return end
        EnsureSettings()
        local intervalSec = (tonumber(THUD_Settings.recruit.interval) or 10) * 60
        local elapsed     = now - THUD_RecruitmentState.lastAdTime
        local remaining   = math.max(0, intervalSec - elapsed)
        local progress    = remaining / intervalSec

        this.bar:SetValue(math.max(0, math.min(1, progress)))

        local mins = math.floor(remaining / 60)
        local secs = math.floor(math.mod(remaining, 60))
        local secStr = tostring(secs)
        if secs < 10 then secStr = "0" .. secStr end
        this.barTxt:SetText(tostring(mins) .. ":" .. secStr)
    end)

    recruitingPanel = f
    f:Show()
end

-- =============================================================================
-- 5. RECRUITMENT WINDOW
-- =============================================================================

local recruitFrame = nil

function THUD.ShowRecruitmentWindow()
    EnsureSettings()

    if recruitFrame then
        recruitFrame:Show()
        if recruitFrame.RefreshAdvertiseView then
            recruitFrame.RefreshAdvertiseView()
        end
        return
    end

    -- Main window
    local frame = CreateFrame("Frame", "THUD_RecruitmentFrame", UIParent)
    frame:SetWidth(460); frame:SetHeight(480)
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
    table.insert(UISpecialFrames, "THUD_RecruitmentFrame")

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -14)
    title:SetText("|cff00ccffGuild Recruitment|r")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)

    -- ---- SLOT SELECTOR ----
    local slotLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    slotLabel:SetPoint("TOPLEFT", 18, -46)
    slotLabel:SetText("Message Slot:")

    -- Slot dropdown button (simple custom menu)
    local slotBtn = CreateFrame("Button", "THUD_SlotBtn", frame, "UIPanelButtonTemplate")
    slotBtn:SetWidth(100); slotBtn:SetHeight(22)
    slotBtn:SetPoint("LEFT", slotLabel, "RIGHT", 8, 0)

    local function UpdateSlotBtnText()
        slotBtn:SetText("Message " .. (THUD_Settings.recruit.selectedIndex or 1))
    end
    UpdateSlotBtnText()

    slotBtn:SetScript("OnClick", function()
        -- Build a tiny dropdown menu
        local menuF = CreateFrame("Frame", nil, UIParent)
        menuF:SetWidth(110); menuF:SetHeight(5 * 22 + 8)
        menuF:SetPoint("TOPLEFT", slotBtn, "BOTTOMLEFT", 0, -2)
        menuF:SetFrameStrata("TOOLTIP"); menuF:SetFrameLevel(110)
        menuF:SetBackdrop({
            bgFile="Interface/Tooltips/UI-Tooltip-Background",
            edgeFile="Interface/Tooltips/UI-Tooltip-Border",
            edgeSize=10, insets={left=3,right=3,top=3,bottom=3}
        })
        menuF:SetBackdropColor(0.05, 0.05, 0.1, 0.98)
        menuF:EnableMouse(true)
        menuF:SetScript("OnHide", function() this:SetParent(nil) end)

        for i = 1, 5 do
            local btn = CreateFrame("Button", nil, menuF)
            btn:SetWidth(104); btn:SetHeight(20)
            btn:SetPoint("TOPLEFT", menuF, "TOPLEFT", 3, -3 - ((i-1)*22))

            local bg = btn:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints(); bg:SetTexture("Interface\\Buttons\\WHITE8X8")
            bg:SetVertexColor(0.2, 0.4, 0.8, 0.4); bg:Hide()

            local t = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            t:SetPoint("LEFT", 6, 0); t:SetText("Message " .. i)
            if i == THUD_Settings.recruit.selectedIndex then
                t:SetTextColor(1, 0.82, 0)
            end

            local captureI = i
            btn:SetScript("OnEnter", function() bg:Show() end)
            btn:SetScript("OnLeave", function() bg:Hide() end)
            btn:SetScript("OnClick", function()
                THUD_Settings.recruit.selectedIndex = captureI
                UpdateSlotBtnText()
                menuF:Hide()
                if frame.RefreshAdvertiseView then frame.RefreshAdvertiseView() end
            end)
        end
        menuF:Show()
    end)

    -- ---- MESSAGE BOX 1 ----
    local msgLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    msgLabel:SetPoint("TOPLEFT", 18, -78)
    msgLabel:SetText("Recruitment Message (0/255):")
    frame.msgLabel = msgLabel

    local msgBg = CreateFrame("Frame", nil, frame)
    msgBg:SetPoint("TOPLEFT", 18, -96)
    msgBg:SetWidth(424); msgBg:SetHeight(60)
    msgBg:SetBackdrop({
        bgFile="Interface/Tooltips/UI-Tooltip-Background",
        edgeFile="Interface/Tooltips/UI-Tooltip-Border",
        edgeSize=10, insets={left=3,right=3,top=3,bottom=3}
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
        msgLabel:SetText("Recruitment Message (" .. len .. "/255):")
        if len > 255 then msgLabel:SetTextColor(1,0,0) else msgLabel:SetTextColor(1,1,1) end
    end)
    msgBox:SetScript("OnEditFocusLost", function()
        local idx = THUD_Settings.recruit.selectedIndex
        THUD_Settings.recruit.messages[idx] = this:GetText()
    end)
    frame.msgBox = msgBox

    -- ---- MESSAGE BOX 2 ----
    local msg2Label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    msg2Label:SetPoint("TOPLEFT", 18, -166)
    msg2Label:SetText("Second Message (0/255):")
    frame.msg2Label = msg2Label

    local msg2Bg = CreateFrame("Frame", nil, frame)
    msg2Bg:SetPoint("TOPLEFT", 18, -184)
    msg2Bg:SetWidth(424); msg2Bg:SetHeight(60)
    msg2Bg:SetBackdrop({
        bgFile="Interface/Tooltips/UI-Tooltip-Background",
        edgeFile="Interface/Tooltips/UI-Tooltip-Border",
        edgeSize=10, insets={left=3,right=3,top=3,bottom=3}
    })
    msg2Bg:SetBackdropColor(0,0,0,1)
    msg2Bg:SetBackdropBorderColor(0.35, 0.35, 0.5, 1)

    local msg2SF = CreateFrame("ScrollFrame", nil, msg2Bg)
    msg2SF:SetPoint("TOPLEFT", 5, -5); msg2SF:SetPoint("BOTTOMRIGHT", -5, 5)
    local msg2SC = CreateFrame("Frame", nil, msg2SF)
    msg2SF:SetScrollChild(msg2SC); msg2SC:SetWidth(410); msg2SC:SetHeight(400)

    local msg2Box = CreateFrame("EditBox", nil, msg2SC)
    msg2Box:SetPoint("TOPLEFT", 0, 0); msg2Box:SetWidth(410); msg2Box:SetHeight(400)
    msg2Box:SetMultiLine(true); msg2Box:SetAutoFocus(false); msg2Box:SetMaxLetters(255)
    msg2Box:SetFontObject(GameFontHighlightSmall); msg2Box:SetTextInsets(4,4,3,3)
    msg2Box:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    msg2Box:SetScript("OnTextChanged", function()
        local txt = this:GetText()
        local len = string.len(txt)
        msg2Label:SetText("Second Message (" .. len .. "/255):")
        if len > 255 then msg2Label:SetTextColor(1,0,0) else msg2Label:SetTextColor(1,1,1) end
    end)
    msg2Box:SetScript("OnEditFocusLost", function()
        local idx = THUD_Settings.recruit.selectedIndex
        THUD_Settings.recruit.messages2[idx] = this:GetText()
    end)
    frame.msg2Box = msg2Box

    -- ---- CHANNEL RADIO BUTTONS ----
    local chLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    chLabel:SetPoint("TOPLEFT", 18, -256)
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
        radio:SetPoint("TOPLEFT", 18 + (i-1)*90, -280)
        radio:SetChecked(THUD_Settings.recruit.selectedChannel == ch.key)

        local lbl = radio:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        lbl:SetPoint("LEFT", radio, "RIGHT", 2, 0)
        lbl:SetText(ch.label)

        local captureKey = ch.key
        radio:SetScript("OnClick", function()
            for _, rb in ipairs(radioButtons) do rb:SetChecked(false) end
            this:SetChecked(true)
            THUD_Settings.recruit.selectedChannel = captureKey
        end)
        table.insert(radioButtons, radio)
    end
    frame.radioButtons = radioButtons
    frame.channels     = channels

    -- ---- INTERVAL + TARGET TIME ----
    local intLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    intLabel:SetPoint("TOPLEFT", 18, -316)
    intLabel:SetText("Interval (minutes):")

    local intBox = CreateFrame("EditBox", nil, frame)
    intBox:SetPoint("LEFT", intLabel, "RIGHT", 8, 0)
    intBox:SetWidth(50); intBox:SetHeight(20)
    intBox:SetAutoFocus(false); intBox:SetNumeric(true)
    intBox:SetFontObject(GameFontHighlight)
    intBox:SetBackdrop({
        bgFile="Interface/Tooltips/UI-Tooltip-Background",
        edgeFile="Interface/ChatFrame/ChatFrameBackground",
        tile=true, tileSize=16, edgeSize=1,
        insets={left=3,right=3,top=3,bottom=3}
    })
    intBox:SetBackdropColor(0,0,0,0.6); intBox:SetBackdropBorderColor(0.3,0.3,0.3,1)
    intBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    intBox:SetScript("OnTextChanged", function()
        local v = tonumber(this:GetText())
        if v and v > 0 then THUD_Settings.recruit.interval = v end
    end)
    intBox:SetScript("OnEditFocusLost", function() this:ClearFocus() end)
    frame.intBox = intBox

    local ttpLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ttpLabel:SetPoint("LEFT", intBox, "RIGHT", 20, 0)
    ttpLabel:SetText("Target Time (HHMM):")

    local ttpBox = CreateFrame("EditBox", nil, frame)
    ttpBox:SetPoint("LEFT", ttpLabel, "RIGHT", 8, 0)
    ttpBox:SetWidth(55); ttpBox:SetHeight(20)
    ttpBox:SetAutoFocus(false); ttpBox:SetMaxLetters(4)
    ttpBox:SetFontObject(GameFontHighlight)
    ttpBox:SetBackdrop({
        bgFile="Interface/Tooltips/UI-Tooltip-Background",
        edgeFile="Interface/ChatFrame/ChatFrameBackground",
        tile=true, tileSize=16, edgeSize=1,
        insets={left=3,right=3,top=3,bottom=3}
    })
    ttpBox:SetBackdropColor(0,0,0,0.6); ttpBox:SetBackdropBorderColor(0.3,0.3,0.3,1)
    ttpBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    ttpBox:SetScript("OnTextChanged", function()
        THUD_Settings.recruit.targetTime = this:GetText()
    end)
    ttpBox:SetScript("OnEditFocusLost", function() this:ClearFocus() end)
    frame.ttpBox = ttpBox

    -- ttp hint
    local ttpHint = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ttpHint:SetPoint("TOPLEFT", 18, -344)
    ttpHint:SetText("|cff888888Use [TTP] in message to show minutes until Target Time|r")

    -- ---- ROTATE CHECKBOXES ----
    local rotLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rotLabel:SetPoint("TOPLEFT", 18, -364)
    rotLabel:SetText("Rotate Message #:")

    for i = 1, 5 do
        local cb = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        cb:SetWidth(22); cb:SetHeight(22)
        cb:SetPoint("TOPLEFT", 18 + (i-1)*52, -386)
        cb:SetChecked(THUD_Settings.recruit.rotateMessages[i])

        local lbl = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        lbl:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        lbl:SetText(tostring(i))

        local captureI = i
        cb:SetScript("OnClick", function()
            THUD_Settings.recruit.rotateMessages[captureI] = this:GetChecked()
        end)
    end

    -- ---- START / STOP BUTTON ----
    local recruitBtn = CreateFrame("Button", "THUD_RecBtn", frame, "UIPanelButtonTemplate")
    recruitBtn:SetWidth(140); recruitBtn:SetHeight(28)
    recruitBtn:SetPoint("BOTTOM", 0, 16)
    recruitBtn:SetScript("OnClick", function()
        if THUD_RecruitmentState.isRecruiting then
            THUD.StopRecruiting()
        else
            THUD.StartRecruiting()
        end
    end)
    frame.recruitBtn = recruitBtn

    -- ---- REFRESH FUNCTION (called when slot changes or window opens) ----
    frame.RefreshAdvertiseView = function()
        EnsureSettings()
        local r = THUD_Settings.recruit
        local idx = r.selectedIndex or 1

        UpdateSlotBtnText()

        -- Load message texts for selected slot
        frame.msgBox:SetText(r.messages[idx] or "")
        frame.msg2Box:SetText(r.messages2[idx] or "")

        -- Sync char counts
        local len1 = string.len(r.messages[idx] or "")
        local len2 = string.len(r.messages2[idx] or "")
        msgLabel:SetText("Recruitment Message (" .. len1 .. "/255):")
        msg2Label:SetText("Second Message (" .. len2 .. "/255):")

        -- Sync radio buttons
        for i, rb in ipairs(frame.radioButtons) do
            rb:SetChecked(frame.channels[i].key == r.selectedChannel)
        end

        -- Sync interval / ttp
        frame.intBox:SetText(tostring(r.interval or 10))
        frame.ttpBox:SetText(r.targetTime or "")

        -- Sync rotate checkboxes (we can't store refs easily; OnClick handles saves,
        -- but we need to re-read on open. Iterate children approach via global state)
        -- (checkboxes read directly from THUD_Settings.recruit.rotateMessages on creation,
        -- and are kept in sync via OnClick — no re-read needed here unless reloading UI)

        -- Update button text
        THUD.UpdateRecruitmentButton()
    end

    recruitFrame = frame
    frame.RefreshAdvertiseView()
    frame:Show()
end

-- =============================================================================
-- 6. BUTTON STATE HELPER
-- =============================================================================

function THUD.UpdateRecruitmentButton()
    local btn = getglobal("THUD_RecBtn")
    if btn then
        if THUD_RecruitmentState.isRecruiting then
            btn:SetText("|cffff4444Stop Recruiting|r")
        else
            btn:SetText("|cff44ff44Start Recruiting|r")
        end
    end
end

-- =============================================================================
-- 7. SLASH COMMAND
-- =============================================================================

SLASH_THUDGR1 = "/thudgr"
SlashCmdList["THUDGR"] = function()
    THUD.ShowRecruitmentWindow()
end
