-- =============================================================================
-- THUD Main UI
-- Layout: Header + 2 rows of buttons
--   Row 1: GR | Rdy | Consume
--   Row 2: Auto Inv | Chronicle | Auto Sum
-- =============================================================================

local BTN_H    = 22
local ROW_PAD  = 5    -- padding above row1 and below row2
local ROW_GAP  = 5    -- gap between rows
local SIDE_PAD = 10   -- left/right inner padding
local HEADER_H = 22   -- height reserved for the title text + divider

-- Total frame height: header + top-pad + row1 + gap + row2 + bottom-pad
local FRAME_H = HEADER_H + ROW_PAD + BTN_H + ROW_GAP + BTN_H + ROW_PAD + 4
local FRAME_W = 260

local Main = CreateFrame("Frame", "THUD_MainBar", UIParent)
Main:SetWidth(FRAME_W)
Main:SetHeight(FRAME_H)
Main:SetPoint("CENTER", 0, 150)
Main:SetFrameStrata("HIGH")
Main:SetBackdrop({
    bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 12, insets = {left=4, right=4, top=4, bottom=4}
})
Main:SetBackdropColor(0, 0.1, 0.3, 0.9)
Main:EnableMouse(true); Main:SetMovable(true)
Main:RegisterForDrag("LeftButton")
Main:SetScript("OnDragStart", function() this:StartMoving() end)
Main:SetScript("OnDragStop",  function() this:StopMovingOrSizing() end)

-- Header title
local header = Main:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
header:SetPoint("TOP", Main, "TOP", 0, -6)
header:SetText("|cffaaddffTHUD Raid Tools|r")

-- Thin divider line under the header
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
        edgeSize = 8,
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
-- Row Y offsets: distance from top of frame to TOP edge of each button row
-- -------------------------------------------------------
local row1TopY = -(HEADER_H + ROW_PAD)           -- top of row 1
local row2TopY = row1TopY - BTN_H - ROW_GAP      -- top of row 2

-- Row 1: Guild Recruit | Rdy | Consume
local ROW1_BTN_W = 75

local gr = CreateFrame("Button", "THUD_GRBtn", Main)
gr:SetWidth(ROW1_BTN_W); gr:SetHeight(BTN_H)
gr:SetPoint("TOPLEFT", Main, "TOPLEFT", SIDE_PAD, row1TopY)
THUD_Style(gr, "Guild Recruit")

local rdy = CreateFrame("Button", "THUD_RdyBtn", Main)
rdy:SetWidth(ROW1_BTN_W); rdy:SetHeight(BTN_H)
rdy:SetPoint("LEFT", gr, "RIGHT", 5, 0)
THUD_Style(rdy, "Rdy")
rdy:SetScript("OnClick", function() DoReadyCheck() end)

local con = CreateFrame("Button", "THUD_ConBtn", Main)
con:SetWidth(ROW1_BTN_W); con:SetHeight(BTN_H)
con:SetPoint("LEFT", rdy, "RIGHT", 5, 0)
THUD_Style(con, "Consume")

-- Row 2: Auto Inv | Chronicle | Auto Sum
local ROW2_BTN_W = 73

local ai = CreateFrame("Button", "THUD_AIBtn", Main)
ai:SetWidth(ROW2_BTN_W); ai:SetHeight(BTN_H)
ai:SetPoint("TOPLEFT", Main, "TOPLEFT", SIDE_PAD, row2TopY)
THUD_Style(ai, "Auto Inv")

local ch = CreateFrame("Button", "THUD_CHBtn", Main)
ch:SetWidth(ROW2_BTN_W); ch:SetHeight(BTN_H)
ch:SetPoint("LEFT", ai, "RIGHT", 5, 0)
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
as:SetPoint("LEFT", ch, "RIGHT", 5, 0)
THUD_Style(as, "Auto Sum")

-- -------------------------------------------------------
-- EVENT HANDLER: link button clicks after addon loads
-- -------------------------------------------------------
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function()
    if arg1 == "THUD_Raid_Tools" then

        -- GR: toggle Recruitment window
        gr:SetScript("OnClick", function()
            if THUD_RecruitmentFrame and THUD_RecruitmentFrame:IsVisible() then
                THUD_RecruitmentFrame:Hide()
            else
                THUD.ShowRecruitmentWindow()
            end
        end)

        -- Consume: toggle Raid Inspect frame
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

        -- Auto Inv: toggle AutoInvite config
        ai:SetScript("OnClick", function()
            if THUD_AutoInvFrame and THUD_AutoInvFrame:IsVisible() then
                THUD_AutoInvFrame:Hide()
            else
                THUD_OpenAutoInviteConfig()
            end
        end)

        -- Auto Sum: toggle AutoSummon window
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

        this:UnregisterEvent("ADDON_LOADED")
    end
end)
