-- =============================================================================
-- THUD Main UI (Final Optimized Toggle Logic)
-- =============================================================================

local Main = CreateFrame("Frame", "THUD_MainBar", UIParent)
Main:SetWidth(280); Main:SetHeight(40) 
Main:SetPoint("CENTER", 0, 150); Main:SetFrameStrata("HIGH")
Main:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background", edgeFile="Interface/Tooltips/UI-Tooltip-Border", edgeSize=12, insets={left=4,right=4,top=4,bottom=4}})
Main:SetBackdropColor(0,0.1,0.3,0.9); Main:EnableMouse(true); Main:SetMovable(true)
Main:RegisterForDrag("LeftButton")
Main:SetScript("OnDragStart", function() this:StartMoving() end)
Main:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

local function THUD_Style(btn, label)
    -- 1. Setup the Background and Border
    btn:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", 
        edgeFile = "Interface\\Buttons\\UI-SliderBar-Border", 
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    
    -- 2. Apply Navy/Steel Blue fill
    btn:SetBackdropColor(0, 0.2, 0.4, 1) 
    btn:SetBackdropBorderColor(0.7, 0.7, 0.7, 1) -- Silver Border
    
    -- 3. Manually create the Silver Text
    local t = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    t:SetPoint("CENTER", btn, "CENTER", 0, 0)
    t:SetTextColor(0.8, 0.8, 0.8) -- Silver
    t:SetText(label)
    btn.text = t
end

-- 1. GR Button
local gr = CreateFrame("Button", "THUD_GRBtn", Main) -- No template
gr:SetWidth(40); gr:SetHeight(22); gr:SetPoint("LEFT", 10, 0)
THUD_Style(gr, "GR")

-- 2. Rdy Button
local rdy = CreateFrame("Button", "THUD_RdyBtn", Main)
rdy:SetWidth(40); rdy:SetHeight(22); rdy:SetPoint("LEFT", gr, "RIGHT", 5, 0)
THUD_Style(rdy, "Rdy")
rdy:SetScript("OnClick", function() DoReadyCheck() end)

-- 3. Consume Button
local con = CreateFrame("Button", "THUD_ConBtn", Main)
con:SetWidth(75); con:SetHeight(22); con:SetPoint("LEFT", rdy, "RIGHT", 5, 0)
THUD_Style(con, "Consume")

-- 4. Auto Inv Button
local ai = CreateFrame("Button", "THUD_AIBtn", Main)
ai:SetWidth(80); ai:SetHeight(22); ai:SetPoint("LEFT", con, "RIGHT", 5, 0)
THUD_Style(ai, "Auto Inv")

-- EVENT HANDLER: Safely link all logic with Toggle Support
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function()
    if arg1 == "THUD_Raid_Tools" then
        
        -- Link GR Button (Toggle Logic)
        gr:SetScript("OnClick", function() 
            if THUD_RecruitmentFrame then
                if THUD_RecruitmentFrame:IsVisible() then 
                    THUD_RecruitmentFrame:Hide() 
                else 
                    THUD.ShowRecruitmentWindow() 
                end
            else
                THUD.ShowRecruitmentWindow()
            end
        end)
        
        -- Link Consume Button (Toggle Logic)
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
        
        -- Link Auto Inv Button (Toggle Logic)
        ai:SetScript("OnClick", function() 
            if THUD_AutoInvFrame then
                if THUD_AutoInvFrame:IsVisible() then 
                    THUD_AutoInvFrame:Hide() 
                else 
                    THUD_OpenAutoInviteConfig() 
                end
            else
                THUD_OpenAutoInviteConfig()
            end
        end)
        
        this:UnregisterEvent("ADDON_LOADED")
    end
end)
