-- =============================================================================
-- THUD Auto Invite Module (Final Reconstruction)
-- =============================================================================

-- 1. STRICT INITIALIZATION
-- Ensure the global settings table exists immediately upon file load.
if not THUD_AutoInvite then
    THUD_AutoInvite = {
        enabled = false,
        keyword = ""
    }
end

-- 2. WHISPER LISTENER
local aiFrame = CreateFrame("Frame")
aiFrame:RegisterEvent("CHAT_MSG_WHISPER")
aiFrame:SetScript("OnEvent", function()
    if event == "CHAT_MSG_WHISPER" then
        if not THUD_AutoInvite or not THUD_AutoInvite.enabled or THUD_AutoInvite.keyword == "" then return end
        
        local msg = string.lower(arg1 or "")
        for word in string.gfind(THUD_AutoInvite.keyword, '([^,]+)') do
            local cleanWord = string.gsub(word, "^%s*(.-)%s*$", "%1")
            if msg == string.lower(cleanWord) then
                InviteByName(arg2)
                DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00THUD:|r Auto-invited " .. arg2)
                return 
            end
        end
    end
end)

-- 3. GLOBAL CONFIG WINDOW
function THUD_OpenAutoInviteConfig()
    -- Safety check for global variable
    if not THUD_AutoInvite then THUD_AutoInvite = { enabled = false, keyword = "" } end

    local frame = getglobal("THUD_AutoInvFrame") or CreateFrame("Frame", "THUD_AutoInvFrame", UIParent)
    
    -- Window Setup
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetWidth(350); frame:SetHeight(200)
    frame:SetFrameStrata("DIALOG") 
    frame:SetFrameLevel(150)
    
    frame:SetBackdrop({
        bgFile="Interface/Tooltips/UI-Tooltip-Background", 
        edgeFile="Interface/Tooltips/UI-Tooltip-Border", 
        edgeSize=12, insets={left=4,right=4,top=4,bottom=4}
    })
    frame:SetBackdropColor(0,0,0,0.95); frame:EnableMouse(true); frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() this:StartMoving() end)
    frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    
    -- Close Button
    local close = frame.close or CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)
    close:SetScript("OnClick", function() frame:Hide() end)
    frame.close = close

    -- Instruction Label
    local label = frame.label or frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", 25, -40)
    label:SetText("Enter keywords (separated by commas):")
    frame.label = label

    -- Keyword Input Box
    local eb = frame.eb or CreateFrame("EditBox", nil, frame)
    eb:SetPoint("TOPLEFT", 25, -60); eb:SetWidth(300); eb:SetHeight(30)
    eb:SetAutoFocus(false); eb:SetFontObject(GameFontHighlightSmall)
    eb:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background", edgeFile="Interface/Tooltips/UI-Tooltip-Border", edgeSize=8})
    eb:SetBackdropColor(0,0,0,1); eb:SetTextInsets(8,8,0,0)
    eb:SetText(THUD_AutoInvite.keyword or "")
    eb:SetScript("OnTextChanged", function() 
        THUD_AutoInvite.keyword = this:GetText() 
    end)
    frame.eb = eb

    -- START / STOP BUTTON (Force Recreation)
    local toggle = frame.toggle or CreateFrame("Button", "THUD_AutoInvToggle", frame, "UIPanelButtonTemplate")
    toggle:SetWidth(120); toggle:SetHeight(30); toggle:SetPoint("BOTTOM", 0, 30)
    
    -- Style the button
    toggle:SetBackdrop({bgFile = "Interface\\Buttons\\UI-Panel-Button-Up", edgeFile = "Interface\\Buttons\\UI-SliderBar-Border", edgeSize = 8})
    toggle:SetBackdropColor(0, 0, 0, 1)

    -- Shared update function
    local function UpdateBtnState()
        if THUD_AutoInvite.enabled then
            toggle:SetText("|cffff0000STOP|r")
        else
            toggle:SetText("|cff00ff00START|r")
        end
    end
    
    toggle:SetScript("OnClick", function()
        THUD_AutoInvite.enabled = not THUD_AutoInvite.enabled
        UpdateBtnState()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00THUD:|r Auto-Invite " .. (THUD_AutoInvite.enabled and "|cff00ff00Started|r" or "|cffff0000Stopped|r"))
    end)
    
    frame.toggle = toggle
    UpdateBtnState()
    
    frame:Show() 
end

-- 4. SLASH COMMANDS
SLASH_THUDAI1 = "/trtai"
SlashCmdList["THUDAI"] = function()
    THUD_OpenAutoInviteConfig()
end
