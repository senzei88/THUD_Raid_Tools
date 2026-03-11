-- =============================================================================
-- THUD Raid Tools - Core Utilities (Standalone)
-- =============================================================================

THUD = THUD or {}

-- Schedule a function to execute after a delay (in seconds)
function THUD.ScheduleFunc(func, delay)
  local frame = CreateFrame("Frame")
  local elapsed = 0
  frame:SetScript("OnUpdate", function()
    elapsed = elapsed + (arg1 or 0)
    if elapsed >= delay then
      frame:SetScript("OnUpdate", nil)
      func()
    end
  end)
  return frame
end

-- Cancel a scheduled function
function THUD.CancelScheduledFunc(frame)
  if frame and frame.SetScript then
    frame:SetScript("OnUpdate", nil)
  end
end

-- Strips color codes and special characters for clean string comparison
function THUD.CleanString(str)
    if not str then return "" end
    local clean = string.gsub(str, "|c%x%x%x%x%x%x%x%x", "")
    clean = string.gsub(clean, "|r", "")
    return clean
end

-- Simple trim for input boxes
function THUD.Trim(s)
    if not s then return "" end
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end
