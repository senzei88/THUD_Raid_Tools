-- Configuration
local ADDON_NAME = "THUD_Raid_Tools"
local ROW_HEIGHT = 18
local MAX_ROWS = 40
local ICON_SIZE = 16
local COL_WIDTH = 20
local NAME_WIDTH = 120 -- Widened slightly for Ready Icon

-- Main Frame Setup
local mainFrame = CreateFrame("Frame", "RaidInspectFrame", UIParent)
mainFrame:SetWidth(NAME_WIDTH + (9 * COL_WIDTH) + 200) 
mainFrame:SetHeight(90 + (MAX_ROWS * ROW_HEIGHT)) 
mainFrame:SetPoint("CENTER", UIParent, "CENTER")
mainFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
mainFrame:SetBackdropColor(0,0,0,0.8)
mainFrame:EnableMouse(true)
mainFrame:SetMovable(true)
mainFrame:RegisterForDrag("LeftButton")
mainFrame:SetScript("OnMouseDown", function() this:StartMoving() end)
mainFrame:SetScript("OnMouseUp", function() this:StopMovingOrSizing() end)
mainFrame:Hide()

-- Title
local title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOP", mainFrame, "TOP", 0, -15)
title:SetText("THUD Raid Tools")

-- Close Button
local closeBtn = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -8, -8)

-- --- DATA DEFINITIONS ---

-- 1. Class Buff Columns
local classBuffCols = {
    [1] = { name="Fortitude", icon="Interface\\Icons\\Spell_Holy_WordFortitude" },
    [2] = { name="Mark",      icon="Interface\\Icons\\Spell_Nature_Regeneration" },
    [3] = { name="Intellect", icon="Interface\\Icons\\Spell_Holy_MagicalSentry" },
    [4] = { name="Spirit",    icon="Interface\\Icons\\Spell_Holy_DivineSpirit" },
    [5] = { name="Shadow",    icon="Interface\\Icons\\Spell_Shadow_AntiShadow" },
    [6] = { name="Might",     icon="Interface\\Icons\\Spell_Holy_FistOfJustice" },
    [7] = { name="Kings",     icon="Interface\\Icons\\Spell_Magic_MageArmor" },
    [8] = { name="Wisdom",    icon="Interface\\Icons\\Spell_Holy_SealOfWisdom" },
    [9] = { name="Salv",      icon="Interface\\Icons\\Spell_Holy_SealOfSalvation" },
}

-- Map specific textures
local classBuffTextures = {
    ["Interface\\Icons\\Spell_Holy_WordFortitude"] = 1,
    ["Interface\\Icons\\Spell_Holy_PrayerOfFortitude"] = 1,
    ["Interface\\Icons\\Spell_Nature_Regeneration"] = 2,
    ["Interface\\Icons\\Spell_Nature_GiftOfTheWild"] = 2,
    ["Interface\\Icons\\Spell_Holy_MagicalSentry"] = 3,
    ["Interface\\Icons\\Spell_Holy_ArcaneIntellect"] = 3,
    ["Interface\\Icons\\Spell_Holy_DivineSpirit"] = 4,
    ["Interface\\Icons\\Spell_Holy_PrayerofSpirit"] = 4,
    ["Interface\\Icons\\Spell_Shadow_AntiShadow"] = 5,
    ["Interface\\Icons\\Spell_Holy_PrayerofShadowProtection"] = 5,
    ["Interface\\Icons\\Spell_Holy_FistOfJustice"] = 6,
    ["Interface\\Icons\\Spell_Holy_GreaterBlessingofKings"] = 6, 
    ["Interface\\Icons\\Spell_Magic_MageArmor"] = 7, 
    ["Interface\\Icons\\Spell_Magic_GreaterBlessingofKings"] = 7,
    ["Interface\\Icons\\Spell_Holy_SealOfWisdom"] = 8,
    ["Interface\\Icons\\Spell_Holy_GreaterBlessingofWisdom"] = 8,
    ["Interface\\Icons\\Spell_Holy_SealOfSalvation"] = 9,
    ["Interface\\Icons\\Spell_Holy_GreaterBlessingofSalvation"] = 9,
}

-- 2. Consumables
local importantBuffs = {
    -- FLASKS (Priority 1)
    ["Interface\\Icons\\INV_Potion_41"] = {name="Flask of Supreme Power", priority=1},
    ["Interface\\Icons\\INV_Potion_97"] = {name="Flask of Distilled Wisdom", priority=1},
    ["Interface\\Icons\\INV_Potion_62"] = {name="Flask of the Titans", priority=1},
    
    -- PROTECTION POTIONS (Priority 2)
    ["Interface\\Icons\\Spell_Fire_FireArmor"] = {name="GFPP", priority=2},
    ["Interface\\Icons\\Spell_Shadow_RagingScream"] = {name="GSPP", priority=2},
    ["Interface\\Icons\\Spell_Nature_SpiritArmor"] = {name="GNPP", priority=2},
    ["Interface\\Icons\\Spell_Holy_PrayerOfHealing02"] = {name="GAPP", priority=2},
    ["Interface\\Icons\\Spell_Frost_FrostArmor02"] = {name="GFRPP", priority=2},

    -- ELIXIRS & ALCOHOL (Priority 3)
    ["Interface\\Icons\\INV_Potion_32"] = {name="Mongoose", priority=3},
    ["Interface\\Icons\\INV_Potion_45"] = {name="Mageblood", priority=3},
    ["Interface\\Icons\\INV_Potion_61"] = {name="Giants", priority=3},
    ["Interface\\Icons\\inv_green_pink_elixir_1"] = {name="Concoction of the Dream Water", priority=3},
    ["Interface\\Icons\\INV_Potion_46"] = {name="Shadow Power", priority=3},
    ["Interface\\Icons\\INV_Potion_60"] = {name="Firepower", priority=3},
    ["Interface\\Icons\\INV_Potion_25"] = {name="Arcane Elixir", priority=3},
    ["Interface\\Icons\\INV_Potion_08"] = {name="Arcane Giant", priority=3},
    ["Interface\\Icons\\INV_Potion_43"] = {name="Fortitude", priority=3},
    ["Interface\\Icons\\INV_Potion_10"] = {name="Greater Intellect", priority=3},
    ["Interface\\Icons\\INV_Potion_22"] = {name="Greater Nature", priority=3},
    ["Interface\\Icons\\INV_Potion_03"] = {name="Frost Power", priority=3},
    ["Interface\\Icons\\INV_Potion_28"] = {name="Gift of Arthas", priority=3},
    ["Interface\\Icons\\inv_potion_113"] = {name="Dreamshard", priority=3},
    ["Interface\\Icons\\inv_yellow_purple_elixir_2"] = {name="Concoction of the Arcane Giant", priority=3},
    ["Interface\\Icons\\inv_green_pink_elixir_1"] = {name="Concoction of the Dream Water", priority=3},
    ["Interface\\Icons\\inv_blue_gold_elixir_2"] = {name="Concoction of the Emerald Mongoose", priority=3},
    ["Interface\\Icons\\INV_Potion_79"] = {name="Trolls Blood", priority=3},
    ["Interface\\Icons\\INV_Potion_44"] = {name="Elixir of Fort", priority=3},
    ["Interface\\Icons\\INV_Potion_86"] = {name="Elixir of Def", priority=3},
    ["Interface\\Icons\\INV_Potion_93"] = {name="Greater AGI", priority=3},
    ["Interface\\Icons\\inv_drink_33"] = {name="Rum", priority=3},
    ["Interface\\Icons\\Spell_Nature_ManaRegenTotem"] = {name="MP5 Food", priority=3},
    ["Interface\\Icons\\Spell_Holy_FlashHeal"] = {name="Greater Arcane Power", priority=3},
    ["Interface\\Icons\\Spell_Holy_Devotion"] = {name="Instant Strength Food", priority=3},
    
    -- WORLD BUFFS, FOOD & SPECIALS (Priority 4)
    ["Interface\\Icons\\INV_Misc_MonsterScales_07"] = {name="Juju Might", priority=4},
    ["Interface\\Icons\\INV_Misc_MonsterScales_11"] = {name="Juju Power", priority=4},
    ["Interface\\Icons\\INV_Potion_92"] = {name="Firewater", priority=4},
    ["Interface\\Icons\\INV_Potion_31"] = {name="Zanza", priority=4},
    ["Interface\\Icons\\Spell_Nature_Strength"] = {name="Rage of Ages", priority=4}, 
    ["Interface\\Icons\\Spell_Misc_Food"] = {name="Well Fed", priority=4},
    ["Interface\\Icons\\INV_Misc_Dust_02"] = {name="Scorpok", priority=4},
    ["Interface\\Icons\\Spell_Ice_Lament"] = {name="Cerebral Cortex", priority=4},
    ["Interface\\Icons\\inv_potion_114"] = {name="Dreamtonic", priority=4},
}

-- --- GUI SETUP ---

local headers = CreateFrame("Frame", nil, mainFrame)
headers:SetWidth(400)
headers:SetHeight(20)
headers:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 15, -35)

local nameHeader = headers:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
nameHeader:SetPoint("LEFT", headers, "LEFT", 25, 0) -- Moved right to fit Ready Icon
nameHeader:SetWidth(NAME_WIDTH)
nameHeader:SetJustifyH("LEFT")
nameHeader:SetText("Name")
nameHeader:SetTextColor(0.8, 0.8, 0.8)

-- Header Icons with Tooltips
for i = 1, 9 do
    local iconBtn = CreateFrame("Button", nil, headers)
    iconBtn:SetWidth(ICON_SIZE)
    iconBtn:SetHeight(ICON_SIZE)
    iconBtn:SetPoint("LEFT", headers, "LEFT", NAME_WIDTH + ((i-1) * COL_WIDTH) + 2, 0)
    
    local tex = iconBtn:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints(iconBtn)
    tex:SetTexture(classBuffCols[i].icon)
    iconBtn.texture = tex
    
    iconBtn.tooltipText = classBuffCols[i].name
    iconBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText(this.tooltipText, 1, 1, 1)
        GameTooltip:Show()
    end)
    iconBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local consumeHeader = headers:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
consumeHeader:SetPoint("LEFT", headers, "LEFT", NAME_WIDTH + (9 * COL_WIDTH) + 10, 0)
consumeHeader:SetText("Consumables")
consumeHeader:SetTextColor(0.8, 0.8, 0.8)

-- Store vertical lines to resize them later
local verticalLines = {}

local function CreateVerticalLine(xOffset)
    local line = mainFrame:CreateTexture(nil, "ARTWORK")
    line:SetWidth(1)
    line:SetHeight((MAX_ROWS * ROW_HEIGHT) + 25) -- Initial height
    line:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 15 + xOffset, -30)
    line:SetTexture(1, 1, 1, 0.1)
    table.insert(verticalLines, line)
    return line
end

CreateVerticalLine(NAME_WIDTH)
for i = 1, 9 do
    CreateVerticalLine(NAME_WIDTH + (i * COL_WIDTH))
end

local rows = {}
local function CreateRows()
    for i = 1, MAX_ROWS do
        local row = CreateFrame("Frame", nil, mainFrame)
        row:SetWidth(450)
        row:SetHeight(ROW_HEIGHT)
        row:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 15, -55 - ((i-1) * ROW_HEIGHT))
        
        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints(row)
        if math.mod(i, 2) == 0 then
            row.bg:SetTexture(0.2, 0.2, 0.2, 0.3)
        else
            row.bg:SetTexture(0, 0, 0, 0)
        end

        -- Ready Icon
        row.readyIcon = row:CreateTexture(nil, "OVERLAY")
        row.readyIcon:SetWidth(12)
        row.readyIcon:SetHeight(12)
        row.readyIcon:SetPoint("LEFT", row, "LEFT", 2, 0)
        row.readyIcon:SetTexture("")

        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.name:SetPoint("LEFT", row, "LEFT", 20, 0) -- Shifted right
        row.name:SetWidth(NAME_WIDTH - 20)
        row.name:SetJustifyH("LEFT")
        
        -- Class Icons (Now Buttons)
        row.classIcons = {}
        for c = 1, 9 do
            local iconBtn = CreateFrame("Button", nil, row)
            iconBtn:SetWidth(ICON_SIZE)
            iconBtn:SetHeight(ICON_SIZE)
            iconBtn:SetPoint("LEFT", row, "LEFT", NAME_WIDTH + ((c-1) * COL_WIDTH) + 2, 0)
            
            local tex = iconBtn:CreateTexture(nil, "OVERLAY")
            tex:SetAllPoints(iconBtn)
            tex:SetTexture(classBuffCols[c].icon)
            tex:SetVertexColor(1, 1, 1, 0.1) -- Dim by default
            iconBtn.texture = tex
            
            -- Tooltip for Class Buffs
            iconBtn.tooltipText = classBuffCols[c].name
            iconBtn:SetScript("OnEnter", function()
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                GameTooltip:SetText(this.tooltipText, 1, 1, 1)
                GameTooltip:Show()
            end)
            iconBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
            
            table.insert(row.classIcons, iconBtn)
        end
        
        -- Consumable Icons (Now Buttons)
        row.consumeIcons = {}
        for j = 1, 8 do
            local iconBtn = CreateFrame("Button", nil, row)
            iconBtn:SetWidth(ICON_SIZE)
            iconBtn:SetHeight(ICON_SIZE)
            local startX = NAME_WIDTH + (9 * COL_WIDTH) + 10
            iconBtn:SetPoint("LEFT", row, "LEFT", startX + ((j-1) * (ICON_SIZE + 2)), 0)
            
            local tex = iconBtn:CreateTexture(nil, "OVERLAY")
            tex:SetAllPoints(iconBtn)
            iconBtn.texture = tex
            
            iconBtn:Hide()
            
            iconBtn:SetScript("OnEnter", function()
                if this.tooltipText then
                    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                    GameTooltip:SetText(this.tooltipText, 1, 1, 1)
                    GameTooltip:Show()
                end
            end)
            iconBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
            
            table.insert(row.consumeIcons, iconBtn)
        end
        
        table.insert(rows, row)
    end
end

-- --- LOGIC ---

-- Ready Check State Table (Name -> Status)
local raidReadyStatus = {}

local function GetClassColor(class)
    if class == "DRUID" then return 1.0, 0.49, 0.04
    elseif class == "HUNTER" then return 0.67, 0.83, 0.45
    elseif class == "MAGE" then return 0.41, 0.80, 0.94
    elseif class == "PALADIN" then return 0.96, 0.55, 0.73
    elseif class == "PRIEST" then return 1.0, 1.0, 1.0
    elseif class == "ROGUE" then return 1.0, 0.96, 0.41
    elseif class == "SHAMAN" then return 0.0, 0.44, 0.87
    elseif class == "WARLOCK" then return 0.58, 0.51, 0.79
    elseif class == "WARRIOR" then return 0.78, 0.61, 0.43
    else return 0.5, 0.5, 0.5 end
end

local function UsesMana(class)
    if class == "WARRIOR" or class == "ROGUE" then return false end
    return true
end

local function NeedsMight(class)
    if class == "WARRIOR" or class == "SHAMAN" or class == "PALADIN" or class == "DRUID" or class == "ROGUE" or class == "HUNTER" then return true end
    return false
end

local function ScanRaid()
    local numRaid = GetNumRaidMembers()
    
    local displayRows = numRaid
    if displayRows == 0 then displayRows = 1 end
    
    mainFrame:SetHeight(90 + (displayRows * ROW_HEIGHT))
    
    for _, line in pairs(verticalLines) do
        line:SetHeight((displayRows * ROW_HEIGHT) + 25)
    end

    for i = 1, MAX_ROWS do
        local row = rows[i]
        
        if i > displayRows then
            row:Hide()
        else
            row:Show()
            row.name:SetText("")
            row.readyIcon:SetTexture("") -- Clear ready icon by default
            for _, iconBtn in pairs(row.classIcons) do iconBtn.texture:SetVertexColor(1, 1, 1, 0.1) end
            for _, iconBtn in pairs(row.consumeIcons) do iconBtn:Hide() end

            if numRaid == 0 then
                if i == 1 then
                    row.name:SetText("Not in raid.")
                    row.name:SetTextColor(1, 1, 1)
                end
            else
                local unit = "raid"..i
                local name = UnitName(unit)
                local _, class = UnitClass(unit)
                
                if name then
                    local r, g, b = GetClassColor(class)
                    row.name:SetText(name)
                    row.name:SetTextColor(r, g, b)
                    
                    -- Update Ready Icon based on stored state
                    if raidReadyStatus[name] == "ready" then
                        row.readyIcon:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Ready")
                    elseif raidReadyStatus[name] == "notready" then
                        row.readyIcon:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-NotReady")
                    elseif raidReadyStatus[name] == "waiting" then
                        row.readyIcon:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Waiting")
                    end
                    
                    local foundConsumes = {}
                    
                    for b = 1, 32 do
                        local texture = UnitBuff(unit, b)
                        if not texture then break end
                        
                        if classBuffTextures[texture] then
                            local colIndex = classBuffTextures[texture]
                            row.classIcons[colIndex].texture:SetVertexColor(1, 1, 1, 1.0)
                        end
                        
                        if importantBuffs[texture] then
                            table.insert(foundConsumes, {texture = texture, data = importantBuffs[texture]})
                        end
                    end
                    
                    table.sort(foundConsumes, function(a, b) return a.data.priority < b.data.priority end)
                    
                    for idx, buff in pairs(foundConsumes) do
                        if idx <= 8 then
                            local iconBtn = row.consumeIcons[idx]
                            iconBtn.texture:SetTexture(buff.texture)
                            iconBtn.tooltipText = buff.data.name
                            iconBtn:Show()
                        end
                    end
                end
            end
        end
    end
end

-- --- ANNOUNCE LOGIC ---
local function AnnounceMissing()
    if GetNumRaidMembers() == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("Not in a raid.")
        return
    end

    -- 1. Scan and Collect Missing Buffs
    local missingData = {
        ["Fortitude"] = {},
        ["Mark"] = {},
        ["Intellect"] = {},
        ["Spirit"] = {},
        ["Shadow"] = {},
        ["Might"] = {},
        ["Kings"] = {},
        ["Wisdom"] = {},
        ["Salvation"] = {}
    }
    
    for i = 1, GetNumRaidMembers() do
        local unit = "raid"..i
        local name = UnitName(unit)
        local _, class = UnitClass(unit)
        
        -- Ignore Dead or Offline
        if UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) then
            
            -- Check what they HAVE
            local hasFort, hasMark, hasInt, hasSpirit, hasShadow, hasMight, hasKings, hasWisdom, hasSalv = false, false, false, false, false, false, false, false, false
            
            for b = 1, 32 do
                local texture = UnitBuff(unit, b)
                if not texture then break end
                
                if classBuffTextures[texture] == 1 then hasFort = true end
                if classBuffTextures[texture] == 2 then hasMark = true end
                if classBuffTextures[texture] == 3 then hasInt = true end
                if classBuffTextures[texture] == 4 then hasSpirit = true end
                if classBuffTextures[texture] == 5 then hasShadow = true end
                if classBuffTextures[texture] == 6 then hasMight = true end
                if classBuffTextures[texture] == 7 then hasKings = true end
                if classBuffTextures[texture] == 8 then hasWisdom = true end
                if classBuffTextures[texture] == 9 then hasSalv = true end
            end
            
            -- Check what they NEED
            
            -- Universal Checks (Everyone needed)
            if not hasFort then table.insert(missingData["Fortitude"], name) end
            if not hasMark then table.insert(missingData["Mark"], name) end
            if not hasShadow then table.insert(missingData["Shadow"], name) end
            
            -- Paladin Checks
            if not hasKings then table.insert(missingData["Kings"], name) end
            
            -- Might: Melee/Hunters Only
            if NeedsMight(class) then
                if not hasMight then table.insert(missingData["Might"], name) end
            end

            -- Wisdom: Mana Users Only (Excludes Rogues/Warriors)
            if UsesMana(class) then
                if not hasWisdom then table.insert(missingData["Wisdom"], name) end
            end

            
            -- Mana User Checks (Int/Spirit)
            if UsesMana(class) then
                if not hasInt then table.insert(missingData["Intellect"], name) end
                if not hasSpirit then table.insert(missingData["Spirit"], name) end
            end
        end
    end
    
    -- 2. Announce to Raid Chat
    SendChatMessage("--- Unzip THUD Missing Class Buffs ---", "RAID")
    
    local function SendList(buffName, playerList)
        if table.getn(playerList) > 0 then
            local msg = "Missing " .. buffName .. ": " .. table.concat(playerList, ", ")
            SendChatMessage(msg, "RAID")
        end
    end
    
    SendList("Fortitude", missingData["Fortitude"])
    SendList("Mark", missingData["Mark"])
    SendList("Shadow Prot", missingData["Shadow"])
    SendList("Intellect", missingData["Intellect"])
    SendList("Spirit", missingData["Spirit"])
    SendList("Might", missingData["Might"])
    SendList("Kings", missingData["Kings"])
    SendList("Wisdom", missingData["Wisdom"])
    SendList("Salvation", missingData["Salvation"])
    
    SendChatMessage("---Thank you for using Unzip THUD Raid Tools---", "RAID")
end

-- --- EVENT HANDLERS FOR READY CHECK ---

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("READY_CHECK")
eventFrame:RegisterEvent("READY_CHECK_CONFIRM")
eventFrame:RegisterEvent("READY_CHECK_FINISHED")

eventFrame:SetScript("OnEvent", function()
    if event == "READY_CHECK" then
        -- Reset all statuses to "waiting"
        raidReadyStatus = {}
        for i=1, GetNumRaidMembers() do
            local name = UnitName("raid"..i)
            if name then raidReadyStatus[name] = "waiting" end
        end
        ScanRaid()
        
    elseif event == "READY_CHECK_CONFIRM" then
        -- arg1 = UnitID, arg2 = IsReady (1 or 0)
        local unit = arg1
        local isReady = arg2
        local name = UnitName(unit)
        if name then
            if isReady == 1 then
                raidReadyStatus[name] = "ready"
            else
                raidReadyStatus[name] = "notready"
            end
        end
        ScanRaid() -- Refresh UI to show new icon
        
    elseif event == "READY_CHECK_FINISHED" then
        -- Optional: Clear icons after a delay, or keep them up. Keeping them up for now.
    end
end)


-- --- FLASK CHECK LOGIC (Priority 1) ---

local function ReportMissingFlasks()
    if GetNumRaidMembers() == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("Not in a raid.")
        return
    end

    local missingFlasks = {}

    for i = 1, GetNumRaidMembers() do
        local unit = "raid"..i
        local name = UnitName(unit)
        
        if UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) then
            local hasFlask = false
            for b = 1, 32 do
                local texture = UnitBuff(unit, b)
                if not texture then break end
                
                -- Check if texture exists in importantBuffs AND is Priority 1
                if importantBuffs[texture] and importantBuffs[texture].priority == 1 then
                    hasFlask = true
                    break
                end
            end

            if not hasFlask then
                table.insert(missingFlasks, name)
            end
        end
    end

    SendChatMessage("--- THUD Raid Tools: Missing Flasks (Priority 1) ---", "OFFICER")
    if table.getn(missingFlasks) > 0 then
        SendChatMessage("Missing Flask: " .. table.concat(missingFlasks, ", "), "OFFICER")
    else
        SendChatMessage("Everyone has a Flask!", "OFFICER")
    end
end

-- --- BUTTONS ---

-- 1. Refresh Button
local refreshBtn = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
refreshBtn:SetWidth(80)
refreshBtn:SetHeight(22)
refreshBtn:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 15, 10)
refreshBtn:SetText("Refresh")
refreshBtn:SetScript("OnClick", ScanRaid)

-- 2. Ready Check Button
local readyBtn = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
readyBtn:SetWidth(90)
readyBtn:SetHeight(22)
readyBtn:SetPoint("LEFT", refreshBtn, "RIGHT", 5, 0)
readyBtn:SetText("Ready Check")
readyBtn:SetScript("OnClick", function() DoReadyCheck() end)

-- 3. Check Flasks (Officer) Button
local flaskBtn = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
flaskBtn:SetWidth(100)
flaskBtn:SetHeight(22)
flaskBtn:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -15, 35) -- Stacked above announce
flaskBtn:SetText("Check Flasks (O)")
flaskBtn:SetScript("OnClick", ReportMissingFlasks)

-- 4. Announce Missing Button
local announceBtn = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
announceBtn:SetWidth(100)
announceBtn:SetHeight(22)
announceBtn:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -15, 10)
announceBtn:SetText("Announce Buffs")
announceBtn:SetScript("OnClick", AnnounceMissing)

-- Initialize
CreateRows()

-- Slash Command
SLASH_RAIDINSPECT1 = "/TRT"
SLASH_RAIDINSPECT2 = "/THUDinspect"
SlashCmdList["RAIDINSPECT"] = function()
    mainFrame:Show()
    ScanRaid()
end