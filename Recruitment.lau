-- =============================================================================
-- THUD Recruitment Module (Posting Logic Fix)
-- =============================================================================

THUD = THUD or {}
THUD_Settings = THUD_Settings or { message = "", interval = 30, lastAdTime = 0, isRecruiting = false, channel = "World" }

-- --- 1. THE BRAIN: Posting Logic ---
local timerFrame = CreateFrame("Frame", "THUD_RecruitmentTimer", UIParent)
timerFrame:SetScript("OnUpdate", function()
    -- Only run if recruiting is enabled and we have a message
    if THUD_Settings.isRecruiting and THUD_Settings.message ~= "" then
        local currentTime = GetTime()
        local interval = tonumber(THUD_Settings.interval) or 30
        
        -- Check if enough time has passed since the last post
        if not THUD_Settings.lastAdTime or (currentTime - THUD_Settings.lastAdTime) >= interval then
            -- Find the World channel index
            local channelNum = GetChannelName(THUD_Settings.channel or "World")
            
            if channelNum > 0 then
                SendChatMessage(THUD_Settings.message, "CHANNEL", nil, channelNum)
                THUD_Settings.lastAdTime = currentTime
            else
                -- If World isn't found, try to join or notify the user
                DEFAULT_CHAT_FRAME:AddMessage("|cffff0000THUD Error:|r " .. (THUD_Settings.channel or "World") .. " channel not found.")
                THUD_Settings.isRecruiting = false
                if THUD_RecruitmentFrame then THUD_RecruitmentFrame.UpdateBtn() end
            end
        end
    end
end)

-- --- 2. THE UI: Window Setup ---
function THUD.ShowRecruitmentWindow()
  local frame = getglobal("THUD_RecruitmentFrame") or CreateFrame("Frame", "THUD_RecruitmentFrame", UIParent)
  frame:SetWidth(400); frame:SetHeight(320); frame:SetPoint("CENTER", 0, 0)
  frame:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background", edgeFile="Interface/Tooltips/UI-Tooltip-Border", edgeSize=12, insets={left=4,right=4,top=4,bottom=4}})
  frame:SetBackdropColor(0,0,0,0.9); frame:EnableMouse(true); frame:SetMovable(true)
  frame:SetFrameStrata("DIALOG") -- Always on top
  
  -- Safety Reset Position
  frame:ClearAllPoints()
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function() this:StartMoving() end)
  frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

  -- Close Button
  local close = frame.close or CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -5, -5); frame.close = close

  -- Instructional Blurb
  local blurb = frame.blurb or frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  blurb:SetPoint("TOPLEFT", 25, -40); blurb:SetText("Please put your recruitment message here:")

  -- Multi-line Message Box
  local sf = frame.sf or CreateFrame("ScrollFrame", "THUD_RecScroll", frame, "UIPanelScrollFrameTemplate")
  sf:SetWidth(330); sf:SetHeight(100); sf:SetPoint("TOPLEFT", 25, -60)
  sf:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background", edgeFile="Interface/Tooltips/UI-Tooltip-Border", edgeSize=8})
  sf:SetBackdropColor(0,0,0,1)

  local eb = frame.eb or CreateFrame("EditBox", nil, sf)
  eb:SetWidth(320); eb:SetMultiLine(true); eb:SetAutoFocus(false); eb:SetFontObject(GameFontHighlightSmall)
  eb:SetTextInsets(5,5,5,5); eb:SetText(THUD_Settings.message or "")
  
  local countTxt = frame.countTxt or frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  countTxt:SetPoint("TOPRIGHT", sf, "BOTTOMRIGHT", 0, -5)
  
  local function UpdateCount()
    local len = string.len(eb:GetText())
    countTxt:SetText(len.."/254")
    if len > 254 then countTxt:SetTextColor(1,0,0) else countTxt:SetTextColor(1,1,1) end
  end

  eb:SetScript("OnTextChanged", function() 
    THUD_Settings.message = this:GetText() 
    UpdateCount()
  end)
  sf:SetScrollChild(eb); UpdateCount()

  -- Interval in Seconds
  local intL = frame.intL or frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  intL:SetPoint("BOTTOMLEFT", 30, 85); intL:SetText("Interval in seconds:")
  
  local intB = frame.intB or CreateFrame("EditBox", nil, frame)
  intB:SetPoint("LEFT", intL, "RIGHT", 10, 0); intB:SetWidth(50); intB:SetHeight(20)
  intB:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background", edgeFile="Interface/Tooltips/UI-Tooltip-Border", edgeSize=8})
  intB:SetBackdropColor(0,0,0,1); intB:SetFontObject(GameFontHighlight); intB:SetText(tostring(THUD_Settings.interval))
  intB:SetScript("OnTextChanged", function() 
      local val = tonumber(this:GetText())
      if val then THUD_Settings.interval = val end
  end)

  -- Start / Stop Button
  local toggle = frame.toggle or CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  toggle:SetWidth(120); toggle:SetHeight(30); toggle:SetPoint("BOTTOM", 0, 25)
  
  function frame.UpdateBtn()
    toggle:SetText(THUD_Settings.isRecruiting and "|cffff0000STOP|r" or "|cff00ff00START|r")
  end
  
  toggle:SetScript("OnClick", function()
    THUD_Settings.isRecruiting = not THUD_Settings.isRecruiting
    -- Reset timer so it posts immediately upon starting
    if THUD_Settings.isRecruiting then THUD_Settings.lastAdTime = 0 end
    frame.UpdateBtn()
  end)
  
  frame.UpdateBtn(); frame:Show()
end
