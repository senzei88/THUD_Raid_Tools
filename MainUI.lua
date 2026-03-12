-- =============================================================================
-- THUD Main UI + Minimap Button
-- Layout: Header + 2 rows of buttons
--   Row 1: GR | Rdy | Consume
--   Row 2: Auto Inv | Chronicle | Auto Sum
-- =============================================================================

local BTN_H    = 16
local ROW_PAD  = 2
local ROW_GAP  = 2
local SIDE_PAD = 5
local HEADER_H = 14

local FRAME_H = HEADER_H + ROW_PAD + BTN_H + ROW_GAP + BTN_H + ROW_GAP + BTN_H + ROW_PAD + 4
local FRAME_W = 210

-- =============================================================================
-- MAIN BAR
-- =============================================================================

local Main = CreateFrame("Frame", "THUD_MainBar", UIParent)
Main:SetWidth(FRAME_W)
Main:SetHeight(FRAME_H)
Main:SetPoint("CENTER", 0, 150)
Main:SetFrameStrata("HIGH")
Main:SetBackdrop({
    bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 8, insets = {left=3, right=3, top=3, bottom=3}
})
Main:SetBackdropColor(0, 0.1, 0.3, 0.9)
Main:EnableMouse(true)
Main:SetMovable(true)
Main:RegisterForDrag("LeftButton")
Main:SetScript("OnDragStart", function() this:StartMoving() end)
Main:SetScript("OnDragStop",  function() this:StopMovingOrSizing() end)

-- Header title
local header = Main:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
header:SetPoint("TOP", Main, "TOP", 0, -4)
header:SetText("|cffaaddffTHUD Raid Tools|r")

-- Divider line
local divider = Main:CreateTexture(nil, "ARTWORK")
divider:SetHeight(1)
divider:SetPoint("TOPLEFT",  Main, "TOPLEFT",  6, -(HEADER_H + 2))
divider:SetPoint("TOPRIGHT", Main, "TOPRIGHT", -6, -(HEADER_H + 2))
divider:SetTexture("Interface\\Buttons\\WHITE8X8")
divider:SetVertexColor(0.4, 0.6, 0.9, 0.5)

-- -------------------------------------------------------
-- Button style helper
-- -------------------------------------------------------
local function THUD_Style(btn, label)
    btn:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
        edgeSize = 6,
        insets   = {left=2, right=2, top=2, bottom=2}
    })
    btn:SetBackdropColor(0, 0.2, 0.4, 1)
    btn:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)

    local t = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    t:SetPoint("CENTER", btn, "CENTER", 0, 0)
    t:SetTextColor(0.8, 0.8, 0.8)
    t:SetText(label)
    btn.text = t
end

-- -------------------------------------------------------
-- Rows
-- -------------------------------------------------------
local row1TopY = -(HEADER_H + ROW_PAD)
local row2TopY = row1TopY - BTN_H - ROW_GAP

-- Row 1: 3 buttons, 2 gaps of 2px, SIDE_PAD on each side
-- Available width = FRAME_W - SIDE_PAD*2 - 2*BTN_GAP = 210 - 10 - 4 = 196 → 65 per button
local ROW1_BTN_W = 65
local BTN_GAP = 2

local gr = CreateFrame("Button", "THUD_GRBtn", Main)
gr:SetWidth(ROW1_BTN_W); gr:SetHeight(BTN_H)
gr:SetPoint("TOPLEFT", Main, "TOPLEFT", SIDE_PAD, row1TopY)
THUD_Style(gr, "Guild Recruit")

local rdy = CreateFrame("Button", "THUD_RdyBtn", Main)
rdy:SetWidth(ROW1_BTN_W); rdy:SetHeight(BTN_H)
rdy:SetPoint("LEFT", gr, "RIGHT", BTN_GAP, 0)
THUD_Style(rdy, "Rdy")
rdy:SetScript("OnClick", function() DoReadyCheck() end)

local con = CreateFrame("Button", "THUD_ConBtn", Main)
con:SetWidth(ROW1_BTN_W); con:SetHeight(BTN_H)
con:SetPoint("LEFT", rdy, "RIGHT", BTN_GAP, 0)
THUD_Style(con, "Consume")

-- Row 2 — same width/gaps as Row 1
local ROW2_BTN_W = ROW1_BTN_W
local row3TopY = row2TopY - BTN_H - ROW_GAP

local ai = CreateFrame("Button", "THUD_AIBtn", Main)
ai:SetWidth(ROW2_BTN_W); ai:SetHeight(BTN_H)
ai:SetPoint("TOPLEFT", Main, "TOPLEFT", SIDE_PAD, row2TopY)
THUD_Style(ai, "Auto Inv")

local ch = CreateFrame("Button", "THUD_CHBtn", Main)
ch:SetWidth(ROW2_BTN_W); ch:SetHeight(BTN_H)
ch:SetPoint("LEFT", ai, "RIGHT", BTN_GAP, 0)
THUD_Style(ch, "Chronicle")
ch:SetScript("OnClick", function()
    if SlashCmdList["CHRONICLE"] then
        SlashCmdList["CHRONICLE"]("config")
    elseif SlashCmdList["Chronicle"] then
        SlashCmdList["Chronicle"]("config")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffcc88ffTHUD:|r Chronicle addon not loaded.")
    end
end)

local as = CreateFrame("Button", "THUD_ASBtn", Main)
as:SetWidth(ROW2_BTN_W); as:SetHeight(BTN_H)
as:SetPoint("LEFT", ch, "RIGHT", BTN_GAP, 0)
THUD_Style(as, "Auto Sum")

-- =============================================================================
-- ROW 3: Cooldown readiness icons + raid health/mana bars
-- Self-contained — no OGRH dependency
-- Icons: Rebirth | AOE Taunt | Innervate   then   [H bar] / [M bar]
-- Left-click: announce to raid   Right-click: start + poll
-- =============================================================================

local STATUS_TINTS = {
    green  = {0.0, 1.0, 0.0},
    yellow = {1.0, 1.0, 0.0},
    red    = {1.0, 0.0, 0.0},
    gray   = {0.5, 0.5, 0.5},
}

local function THUD_FormatTime(seconds)
    if not seconds or seconds <= 0 then return "0s" end
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds - mins * 60)
    if mins > 0 then return string.format("%dm %ds", mins, secs) end
    return string.format("%ds", secs)
end

-- -------------------------------------------------------
-- Self-contained cooldown tracker
-- -------------------------------------------------------
-- Spell definitions: which classes have it, cooldown duration, spell name for /rw
local THUD_COOLDOWNS = {
    rebirth = {
        label    = "Rebirth",
        classes  = { DRUID = true },
        duration = 1800,  -- 30 min
        rwMsg    = "Druids: type + in raid if your Rebirth is ready",
        icon     = "Interface\\Icons\\Spell_Nature_Reincarnation",
    },
    taunt = {
        label    = "AOE Taunt",
        classes  = { WARRIOR = true, DRUID = true },
        duration = 600,   -- 10 min
        rwMsg    = "Warriors/Druids: type + in raid if your AOE Taunt is ready",
        icon     = "Interface\\Icons\\Ability_BullRush",
    },
    innervate = {
        label    = "Innervate",
        classes  = { DRUID = true },
        duration = 360,   -- 6 min
        rwMsg    = "Druids: type + in raid if your Innervate is ready",
        icon     = "Interface\\Icons\\Spell_Nature_Lightning",
    },
}

-- State per ability: { casts={[name]=timestamp}, ready={[name]=true}, total=N }
local THUD_CDState = {}
for key, _ in pairs(THUD_COOLDOWNS) do
    THUD_CDState[key] = { casts = {}, ready = {}, total = 0 }
end

-- Active poll: only one at a time
local THUD_ActivePoll = nil  -- { key, respondents={}, total, timer }
local THUD_POLL_TIMEOUT = 15

-- Count relevant raid members for an ability
local function THUD_CountRelevant(key)
    local def = THUD_COOLDOWNS[key]
    if not def then return 0 end
    local count = 0
    for i = 1, GetNumRaidMembers() do
        local name, _, _, _, class = GetRaidRosterInfo(i)
        if name and class and def.classes[string.upper(class)] then
            count = count + 1
        end
    end
    return count
end

-- Rebuild availability from cast timestamps + reported ready
local function THUD_RebuildStatus(key)
    local def = THUD_COOLDOWNS[key]
    local state = THUD_CDState[key]
    local now = GetTime()
    local available, onCooldown = {}, {}
    local total = 0

    for i = 1, GetNumRaidMembers() do
        local name, _, _, _, class = GetRaidRosterInfo(i)
        if name and class and def.classes[string.upper(class)] then
            total = total + 1
            local cast = state.casts[name]
            if cast then
                local remaining = def.duration - (now - cast)
                if remaining > 0 then
                    table.insert(onCooldown, { name = name, remaining = remaining })
                else
                    table.insert(available, name)
                end
            elseif state.ready[name] then
                table.insert(available, name)
            else
                table.insert(available, name)  -- assume ready if no data
            end
        end
    end

    state.total     = total
    state.available = available
    state.onCooldown = onCooldown

    local readyCount = table.getn(available)
    if total == 0 then
        state.status = "gray"
    elseif readyCount == total then
        state.status = "green"
    elseif readyCount > 0 then
        state.status = "yellow"
    else
        state.status = "red"
    end
end

-- Announce current state to raid chat
local function THUD_AnnounceCooldown(key)
    local def   = THUD_COOLDOWNS[key]
    local state = THUD_CDState[key]
    if not state.available then return end
    local readyCount = table.getn(state.available)
    local total = state.total or 0
    local names = table.concat(state.available, ", ")
    local msg = string.format("[THUD] %s ready: %d/%d", def.label, readyCount, total)
    if readyCount > 0 then msg = msg .. " — " .. names end
    if IsRaidLeader() or IsRaidOfficer() then
        SendChatMessage(msg, "RAID_WARNING")
    elseif GetNumRaidMembers() > 0 then
        SendChatMessage(msg, "RAID")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffaaddff" .. msg .. "|r")
    end
end

-- Start a + poll for an ability
local function THUD_StartPoll(key)
    if THUD_ActivePoll then
        DEFAULT_CHAT_FRAME:AddMessage("|cffcc88ffTHUD:|r A poll is already running.")
        return
    end
    local def = THUD_COOLDOWNS[key]
    local total = THUD_CountRelevant(key)
    if total == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cffcc88ffTHUD:|r No " .. def.label .. " classes in raid.")
        return
    end
    -- Clear old ready state for this ability
    THUD_CDState[key].ready = {}
    THUD_ActivePoll = { key = key, respondents = {}, total = total, startTime = GetTime() }
    local rwMsg = "[THUD] " .. def.rwMsg
    if IsRaidLeader() or IsRaidOfficer() then
        SendChatMessage(rwMsg, "RAID_WARNING")
    elseif GetNumRaidMembers() > 0 then
        SendChatMessage(rwMsg, "RAID")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffaaddff" .. rwMsg .. "|r")
    end
end

-- Poll listener: CHAT_MSG_RAID / CHAT_MSG_RAID_LEADER
local pollEventFrame = CreateFrame("Frame")
pollEventFrame:RegisterEvent("CHAT_MSG_RAID")
pollEventFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
pollEventFrame:SetScript("OnEvent", function()
    if not THUD_ActivePoll then return end
    local text, sender = arg1, arg2
    if not text or not sender then return end
    if not string.find(text, "%+") then return end

    local poll = THUD_ActivePoll
    local def  = THUD_COOLDOWNS[poll.key]
    local playerName = string.match(sender, "^([^-]+)") or sender

    -- Only accept from relevant class
    for i = 1, GetNumRaidMembers() do
        local name, _, _, _, class = GetRaidRosterInfo(i)
        if name == playerName and def.classes[string.upper(class or "")] then
            if not poll.respondents[playerName] then
                poll.respondents[playerName] = true
                THUD_CDState[poll.key].ready[playerName] = true
                THUD_CDState[poll.key].casts[playerName] = nil  -- clear any cooldown
            end
            break
        end
    end
end)

-- Combat log: track actual casts to put people on cooldown
local castEventFrame = CreateFrame("Frame")
castEventFrame:RegisterEvent("CHAT_MSG_SPELL_SELF_BUFF")
castEventFrame:RegisterEvent("CHAT_MSG_SPELL_PARTY_BUFF")
castEventFrame:RegisterEvent("CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF")
castEventFrame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS")
local SPELL_TO_KEY = {
    ["Rebirth"]          = "rebirth",
    ["Challenging Shout"]= "taunt",
    ["Challenging Roar"] = "taunt",
    ["Innervate"]        = "innervate",
}
castEventFrame:SetScript("OnEvent", function()
    local msg = arg1
    if not msg then return end
    for spellName, key in pairs(SPELL_TO_KEY) do
        -- "PlayerName casts SpellName" or "You cast SpellName"
        local caster
        if string.find(msg, "You cast " .. spellName) then
            caster = UnitName("player")
        else
            caster = string.match(msg, "^(.+) casts " .. spellName)
        end
        if caster then
            THUD_CDState[key].casts[caster] = GetTime()
            THUD_CDState[key].ready[caster] = nil
            break
        end
    end
end)

-- -------------------------------------------------------
-- Tooltip helper
-- -------------------------------------------------------
local function THUD_ShowCooldownTooltip(frame, key)
    local def   = THUD_COOLDOWNS[key]
    local state = THUD_CDState[key]
    GameTooltip:SetOwner(frame, "ANCHOR_TOP")
    GameTooltip:ClearLines()
    GameTooltip:SetText(def.label .. " Readiness", 1, 1, 1)
    local readyCount = state.available and table.getn(state.available) or 0
    GameTooltip:AddLine(string.format("Available: %d / %d", readyCount, state.total or 0), 1, 1, 1)
    if state.available and table.getn(state.available) > 0 then
        GameTooltip:AddLine("Ready:", 0.0, 1.0, 0.0)
        for _, name in ipairs(state.available) do
            GameTooltip:AddLine("  " .. name, 0.5, 1.0, 0.5)
        end
    end
    if state.onCooldown and table.getn(state.onCooldown) > 0 then
        GameTooltip:AddLine("On Cooldown:", 1.0, 0.5, 0.0)
        for _, entry in ipairs(state.onCooldown) do
            GameTooltip:AddLine(string.format("  %s: %s", entry.name, THUD_FormatTime(entry.remaining)), 1.0, 0.7, 0.3)
        end
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Left-click: Announce to raid", 0.5, 0.5, 0.5)
    GameTooltip:AddLine("Right-click: Start readiness poll", 0.5, 0.5, 0.5)
    GameTooltip:Show()
end

-- -------------------------------------------------------
-- Icon button factory
-- -------------------------------------------------------
local ICON_SIZE = BTN_H
local function THUD_CreateCooldownIcon(parent, name, key)
    local def = THUD_COOLDOWNS[key]
    local btn = CreateFrame("Button", name, parent)
    btn:SetWidth(ICON_SIZE)
    btn:SetHeight(ICON_SIZE)
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
        edgeSize = 4, insets = {left=1, right=1, top=1, bottom=1}
    })
    btn:SetBackdropColor(0, 0, 0, 0.6)
    btn:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(ICON_SIZE - 4); icon:SetHeight(ICON_SIZE - 4)
    icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
    icon:SetTexture(def.icon)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:SetVertexColor(0.5, 0.5, 0.5, 1)
    btn.icon = icon
    btn:SetScript("OnClick", function()
        if arg1 == "LeftButton" then
            THUD_AnnounceCooldown(key)
        else
            THUD_StartPoll(key)
        end
    end)
    btn:SetScript("OnEnter", function() THUD_ShowCooldownTooltip(this, key) end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return btn
end

-- Place the three icons
local rbtn = THUD_CreateCooldownIcon(Main, "THUD_RebirthBtn",  "rebirth")
rbtn:SetPoint("TOPLEFT", Main, "TOPLEFT", SIDE_PAD, row3TopY)

local tbtn = THUD_CreateCooldownIcon(Main, "THUD_TauntBtn",    "taunt")
tbtn:SetPoint("LEFT", rbtn, "RIGHT", BTN_GAP, 0)

local ibtn = THUD_CreateCooldownIcon(Main, "THUD_InnervateBtn", "innervate")
ibtn:SetPoint("LEFT", tbtn, "RIGHT", BTN_GAP, 0)

-- -------------------------------------------------------
-- Raid health + mana bars (fill remaining width)
-- 3 icons + 4 gaps (left pad, 2 between icons, right pad) = 3*16 + 2*2 + 5 + 5 = 62
-- Remaining = 210 - 62 - 2(gap after last icon) = 146
-- -------------------------------------------------------
local RAID_BAR_W = FRAME_W - SIDE_PAD - (ICON_SIZE * 3) - (BTN_GAP * 2) - BTN_GAP - SIDE_PAD
local RAID_BAR_H = math.floor((ICON_SIZE - 2) / 2)

local raidBarsFrame = CreateFrame("Frame", "THUD_RaidBarsFrame", Main)
raidBarsFrame:SetWidth(RAID_BAR_W)
raidBarsFrame:SetHeight(ICON_SIZE)
raidBarsFrame:SetPoint("LEFT", ibtn, "RIGHT", BTN_GAP, 0)

local hBar = CreateFrame("StatusBar", nil, raidBarsFrame)
hBar:SetWidth(RAID_BAR_W); hBar:SetHeight(RAID_BAR_H)
hBar:SetPoint("TOPLEFT", raidBarsFrame, "TOPLEFT", 0, 0)
hBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
hBar:SetStatusBarColor(0.0, 0.75, 0.1, 1)
hBar:SetMinMaxValues(0, 100); hBar:SetValue(100)
local hBg = hBar:CreateTexture(nil, "BACKGROUND")
hBg:SetAllPoints(hBar); hBg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
hBg:SetVertexColor(0.08, 0.08, 0.08, 0.9)
local hTxt = hBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
hTxt:SetPoint("CENTER", hBar, "CENTER", 0, 0)
hTxt:SetTextColor(1, 1, 1, 0.85); hTxt:SetText("H: --")

local mBar = CreateFrame("StatusBar", nil, raidBarsFrame)
mBar:SetWidth(RAID_BAR_W); mBar:SetHeight(RAID_BAR_H)
mBar:SetPoint("BOTTOMLEFT", raidBarsFrame, "BOTTOMLEFT", 0, 0)
mBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
mBar:SetStatusBarColor(0.0, 0.4, 1.0, 1)
mBar:SetMinMaxValues(0, 100); mBar:SetValue(100)
local mBg = mBar:CreateTexture(nil, "BACKGROUND")
mBg:SetAllPoints(mBar); mBg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
mBg:SetVertexColor(0.08, 0.08, 0.08, 0.9)
local mTxt = mBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
mTxt:SetPoint("CENTER", mBar, "CENTER", 0, 0)
mTxt:SetTextColor(1, 1, 1, 0.85); mTxt:SetText("M: --")

raidBarsFrame:EnableMouse(true)
raidBarsFrame:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_TOP")
    GameTooltip:ClearLines()
    GameTooltip:SetText("Raid Resources", 1, 1, 1)
    GameTooltip:AddLine(string.format("Health: %d%%", math.floor(hBar:GetValue())), 0.0, 0.9, 0.1)
    GameTooltip:AddLine(string.format("Mana:   %d%%", math.floor(mBar:GetValue())), 0.2, 0.5, 1.0)
    GameTooltip:Show()
end)
raidBarsFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- -------------------------------------------------------
-- Scan functions
-- -------------------------------------------------------
local function THUD_ScanRaidResources()
    local numMembers = GetNumRaidMembers()
    local hCur, hMax, mCur, mMax = 0, 0, 0, 0
    local function scanUnit(unit)
        if not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit) then return end
        local hp = UnitHealthMax(unit)
        if hp > 0 then hCur = hCur + UnitHealth(unit); hMax = hMax + hp end
        if UnitPowerType(unit) == 0 then
            local mp = UnitManaMax(unit)
            if mp > 0 then mCur = mCur + UnitMana(unit); mMax = mMax + mp end
        end
    end
    if numMembers == 0 then
        scanUnit("player")
    else
        for i = 1, numMembers do scanUnit("raid" .. i) end
    end
    local hPct = hMax > 0 and math.floor(hCur / hMax * 100) or 100
    local mPct = mMax > 0 and math.floor(mCur / mMax * 100) or 100
    hBar:SetValue(hPct); hTxt:SetText("H: " .. hPct .. "%")
    mBar:SetValue(mPct); mTxt:SetText("M: " .. mPct .. "%")
end

-- -------------------------------------------------------
-- OnUpdate: refresh everything every 0.5s
-- -------------------------------------------------------
local rdRefreshElapsed = 0
local rdRefreshFrame = CreateFrame("Frame")
rdRefreshFrame:SetScript("OnUpdate", function()
    rdRefreshElapsed = rdRefreshElapsed + arg1
    if rdRefreshElapsed < 0.5 then return end
    rdRefreshElapsed = 0
    if not THUD_MainBar or not THUD_MainBar:IsVisible() then return end

    -- Expire poll timeout
    if THUD_ActivePoll then
        if (GetTime() - THUD_ActivePoll.startTime) >= THUD_POLL_TIMEOUT then
            THUD_ActivePoll = nil
        end
    end

    -- Rebuild cooldown status and tint icons
    for key, def in pairs(THUD_COOLDOWNS) do
        THUD_RebuildStatus(key)
    end
    local tintBtn = {
        { THUD_RebirthBtn,   "rebirth"   },
        { THUD_TauntBtn,     "taunt"     },
        { THUD_InnervateBtn, "innervate" },
    }
    for _, pair in ipairs(tintBtn) do
        local btn, key = pair[1], pair[2]
        local tint = STATUS_TINTS[THUD_CDState[key].status or "gray"]
        btn.icon:SetVertexColor(tint[1], tint[2], tint[3], 1)
    end

    THUD_ScanRaidResources()
end)

-- =============================================================================
-- MINIMAP BUTTON
-- =============================================================================

local MINIMAP_RADIUS  = 80
local MINIMAP_DEFAULT = 225

local function THUD_CreateMinimapButton()
    local btn = CreateFrame("Button", "THUD_MinimapButton", Minimap)
    btn:SetWidth(33)
    btn:SetHeight(33)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    btn.icon = btn:CreateTexture(nil, "BACKGROUND")
    btn.icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
    btn.icon:SetWidth(20)
    btn.icon:SetHeight(20)
    btn.icon:SetTexture("Interface\\Icons\\Ability_Hunter_AspectOfTheMonkey")
    btn.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    btn.border = btn:CreateTexture(nil, "OVERLAY")
    btn.border:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    btn.border:SetWidth(53)
    btn.border:SetHeight(53)
    btn.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    local function UpdatePosition()
        local angle = MINIMAP_DEFAULT
        if THUD_MinimapDB and THUD_MinimapDB.angle then
            angle = THUD_MinimapDB.angle
        end
        btn:ClearAllPoints()
        btn:SetPoint("CENTER", Minimap, "CENTER", MINIMAP_RADIUS * cos(angle), MINIMAP_RADIUS * sin(angle))
    end

    btn:RegisterForDrag("LeftButton")
    btn:SetScript("OnDragStart", function()
        this:SetScript("OnUpdate", function()
            local mx, my = GetCursorPosition()
            local px, py = Minimap:GetCenter()
            local scale  = Minimap:GetEffectiveScale()
            mx, my = mx / scale, my / scale
            local angle = math.deg(math.atan2(my - py, mx - px))
            if angle < 0 then angle = angle + 360 end
            if not THUD_MinimapDB then THUD_MinimapDB = {} end
            THUD_MinimapDB.angle = angle
            UpdatePosition()
        end)
    end)
    btn:SetScript("OnDragStop", function()
        this:SetScript("OnUpdate", nil)
    end)

    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:SetScript("OnClick", function()
        if THUD_MainBar:IsVisible() then
            THUD_MainBar:Hide()
        else
            THUD_MainBar:Show()
        end
    end)

    btn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cffaaddffTHUD Raid Tools|r")
        GameTooltip:AddLine("|cffaaaaaaClick|r to show/hide", 1, 1, 1)
        GameTooltip:AddLine("|cffaaaaaa/thudbar|r to toggle", 1, 1, 1)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    UpdatePosition()
end

-- -------------------------------------------------------
-- Slash command
-- -------------------------------------------------------
SLASH_THUDBAR1 = "/thudbar"
SlashCmdList["THUDBAR"] = function(msg)
    local cmd = string.lower(msg or "")
    if cmd == "show" then
        THUD_MainBar:Show()
    elseif cmd == "hide" then
        THUD_MainBar:Hide()
    else
        if THUD_MainBar:IsVisible() then
            THUD_MainBar:Hide()
        else
            THUD_MainBar:Show()
        end
    end
end

-- =============================================================================
-- INIT — one event frame handles both button wiring and minimap creation
-- =============================================================================

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("VARIABLES_LOADED")
loader:SetScript("OnEvent", function()

    if event == "VARIABLES_LOADED" then
        if not THUD_MinimapDB then
            THUD_MinimapDB = { angle = MINIMAP_DEFAULT }
        end
        THUD_CreateMinimapButton()
    end

    if event == "ADDON_LOADED" and arg1 == "THUD_Raid_Tools" then

        gr:SetScript("OnClick", function()
            if THUD_RecruitmentFrame and THUD_RecruitmentFrame:IsVisible() then
                THUD_RecruitmentFrame:Hide()
            else
                THUD.ShowRecruitmentWindow()
            end
        end)

        con:SetScript("OnClick", function()
            if RaidInspectFrame then
                if RaidInspectFrame:IsVisible() then
                    RaidInspectFrame:Hide()
                else
                    RaidInspectFrame:Show()
                    if THUD and THUD.ScanRaid then THUD.ScanRaid() end
                end
            end
        end)

        ai:SetScript("OnClick", function()
            if THUD_AutoInvFrame and THUD_AutoInvFrame:IsVisible() then
                THUD_AutoInvFrame:Hide()
            else
                THUD_OpenAutoInviteConfig()
            end
        end)

        as:SetScript("OnClick", function()
            if not THUD or type(THUD.ShowAutoSummonWindow) ~= "function" then
                DEFAULT_CHAT_FRAME:AddMessage("|cffcc88ffTHUD:|r Auto Summon module not loaded.")
                return
            end
            if THUD_AutoSummonFrame and THUD_AutoSummonFrame:IsVisible() then
                THUD_AutoSummonFrame:Hide()
            else
                THUD.ShowAutoSummonWindow()
            end
        end)

        loader:UnregisterEvent("ADDON_LOADED")
    end
end)
