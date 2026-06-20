--- 1. UI AND MAIN FRAME (RESIZABLE & WITH SLIDER) ---

local uiFrame = CreateFrame("Frame", "HeroicGroupsUI", UIParent)
uiFrame:SetSize(450, 300)
uiFrame:SetPoint("CENTER")
uiFrame:SetMinResize(300, 150)
uiFrame:SetMaxResize(800, 600)
uiFrame:SetResizable(true) -- OPRAVA: Vráceno zpět, WotLK to vyžaduje pro změnu velikosti!
uiFrame:Hide()

-- Main background
uiFrame.bg = uiFrame:CreateTexture(nil, "BACKGROUND")
uiFrame.bg:SetAllPoints(true)
uiFrame.bg:SetTexture(0, 0, 0, 0.8)

-- Background Watermark Logo
uiFrame.logo = uiFrame:CreateTexture(nil, "BACKGROUND", nil, 1)
uiFrame.logo:SetSize(128, 128)
uiFrame.logo:SetPoint("CENTER", uiFrame, "CENTER", 0, 0)
uiFrame.logo:SetTexture("Interface\\Icons\\INV_Misc_GroupLooking")
uiFrame.logo:SetAlpha(0.08)

-- Title text (Main)
uiFrame.title = uiFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
uiFrame.title:SetPoint("TOP", 0, -10)
uiFrame.title:SetText("Heroic Groups (LFG/LFM)")

-- Subtitle text
uiFrame.subtitle = uiFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
uiFrame.subtitle:SetPoint("TOP", uiFrame.title, "BOTTOM", 0, -3)
uiFrame.subtitle:SetText("Nostrum HC Runs Groups")
uiFrame.subtitle:SetTextColor(0.7, 0.7, 0.7)

-- Close button
local closeBtn = CreateFrame("Button", nil, uiFrame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", -5, -5)

-- OPACITY SLIDER (Posunutý více doprava a lehce dolů, aby nekryl nadpis)
local opSlider = CreateFrame("Slider", "HeroicGroupsOpacitySlider", uiFrame, "OptionsSliderTemplate")
opSlider:SetSize(100, 16)
opSlider:SetPoint("TOPRIGHT", -20, -30)
opSlider:SetMinMaxValues(0.1, 1.0)
opSlider:SetValueStep(0.05)
opSlider:SetValue(0.8)
_G[opSlider:GetName() .. 'Low']:SetText('10%')
_G[opSlider:GetName() .. 'High']:SetText('100%')

opSlider:SetScript("OnValueChanged", function(self, value)
    uiFrame.bg:SetAlpha(value)
end)

-- RESIZE HANDLE (Trojúhelník v rohu pro změnu velikosti)
local resizeHandle = CreateFrame("Button", nil, uiFrame)
resizeHandle:SetSize(16, 16)
resizeHandle:SetPoint("BOTTOMRIGHT", -2, -2)
resizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")

resizeHandle:SetScript("OnMouseDown", function(self, button)
    uiFrame:StartSizing("BOTTOMRIGHT")
end)
resizeHandle:SetScript("OnMouseUp", function(self, button)
    uiFrame:StopMovingOrSizing()
end)

-- Movable Frame Logic
uiFrame:SetMovable(true)
uiFrame:EnableMouse(true)
uiFrame:RegisterForDrag("LeftButton")
uiFrame:SetScript("OnDragStart", uiFrame.StartMoving)
uiFrame:SetScript("OnDragStop", uiFrame.StopMovingOrSizing)


-- Message log area (Posunuto lehce níž a dál od pravého dolního rohu)
uiFrame.messageArea = CreateFrame("ScrollingMessageFrame", nil, uiFrame)
uiFrame.messageArea:SetPoint("TOPLEFT", 10, -60)
uiFrame.messageArea:SetPoint("BOTTOMRIGHT", -25, 20)
uiFrame.messageArea:SetFontObject(ChatFontNormal)
uiFrame.messageArea:SetJustifyH("LEFT")
uiFrame.messageArea:SetFading(false)
uiFrame.messageArea:SetMaxLines(100)

uiFrame.messageArea:SetScript("OnHyperlinkClick", function(self, link, text, button)
    local linkType, playerName = strsplit(":", link)
    if linkType == "player" then
        ChatFrame_OpenChat("/w " .. playerName .. " ")
    end
end)

SLASH_HEROICGROUPS1 = "/hc"
SlashCmdList["HEROICGROUPS"] = function()
    if uiFrame:IsShown() then uiFrame:Hide() else uiFrame:Show() end
end


--- 2. MINIMAP BUTTON ---

local minimapBtn = CreateFrame("Button", "HeroicGroupsMinimapBtn", Minimap)
minimapBtn:SetSize(32, 32)
minimapBtn:SetFrameStrata("MEDIUM")
minimapBtn:SetFrameLevel(8)
minimapBtn:SetPoint("CENTER", Minimap, "CENTER", -78, -40)

minimapBtn.icon = minimapBtn:CreateTexture(nil, "BACKGROUND")
minimapBtn.icon:SetTexture("Interface\\Icons\\INV_Misc_GroupLooking")
minimapBtn.icon:SetSize(21, 21)
minimapBtn.icon:SetPoint("TOPLEFT", 6, -5)

minimapBtn.border = minimapBtn:CreateTexture(nil, "OVERLAY")
minimapBtn.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
minimapBtn.border:SetSize(54, 54)
minimapBtn.border:SetPoint("TOPLEFT", 0, 0)

minimapBtn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
minimapBtn:SetScript("OnClick", function()
    if uiFrame:IsShown() then uiFrame:Hide() else uiFrame:Show() end
end)

minimapBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Heroic Groups Nostrum")
    GameTooltip:AddLine("Left-click to toggle the UI.", 1, 1, 1)
    GameTooltip:AddLine("Hold Left-click to drag the icon.", 0.5, 1, 0.5)
    GameTooltip:Show()
end)
minimapBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

minimapBtn:RegisterForDrag("LeftButton")
minimapBtn:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function(self)
        local mx, my = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        mx, my = mx / scale, my / scale
        local cx, cy = Minimap:GetCenter()
        local angle = math.atan2(my - cy, mx - cx)
        local radius = 80
        self:ClearAllPoints()
        self:SetPoint("CENTER", Minimap, "CENTER", radius * math.cos(angle), radius * math.sin(angle))
    end)
end)
minimapBtn:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)


--- 3. CHAT PARSER LOGIC ---

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_CHANNEL")

local keywords = {
    " lfg ", " lfm ", " lf1m ", " lf2m ", " lf3m ", " lf4m ", " lf5m ",
    " lf ", " looking for ",
    " hc ", " heroic ",
    " need tank ", " need heal ", " need dps ", " need healer "
}

local blacklist = {
    "guild", "recruit", "community", "discord",
    "lockbox", "open", "wts", "wtb", "sell", "buy", "trade", "craft", "enchant",
    "addon", "testing"
}

local classColors = {
    ["DRUID"] = "ffff7d0a", ["HUNTER"] = "ffabd473", ["MAGE"] = "ff69ccf0",
    ["PALADIN"] = "fff58cba", ["PRIEST"] = "ffffffff", ["ROGUE"] = "fffff569",
    ["SHAMAN"] = "ff0070de", ["WARLOCK"] = "ff9482c9", ["WARRIOR"] = "ffc79c6e",
    ["DEATHKNIGHT"] = "ffc41f3b"
}

eventFrame:SetScript("OnEvent", function(self, event, msg, sender, _, _, _, _, _, _, _, _, _, guid)
    if event == "CHAT_MSG_CHANNEL" then
        local lowerMsg = string.lower(msg)

        for _, badWord in ipairs(blacklist) do
            if string.find(lowerMsg, badWord) then return end
        end

        local noHcTag = string.gsub(lowerMsg, "%[hc%]", "")
        local cleanMsg = string.gsub(noHcTag, "[%p]", " ")
        cleanMsg = " " .. cleanMsg .. " "

        local isMatch = false
        for _, word in ipairs(keywords) do
            if string.find(cleanMsg, word) then
                isMatch = true
                break
            end
        end

        if isMatch then
            local timeStamp = "|cff888888[" .. date("%H:%M") .. "]|r"
            local colorHex = "ffffd200"
            if guid then
                local _, englishClass = GetPlayerInfoByGUID(guid)
                if englishClass and classColors[englishClass] then
                    colorHex = classColors[englishClass]
                end
            end
            local senderLink = "|Hplayer:" .. sender .. "|h|c" .. colorHex .. "[" .. sender .. "]|r|h"
            local formattedMsg = "|cffffffff" .. msg .. "|r"
            uiFrame.messageArea:AddMessage(timeStamp .. " " .. senderLink .. ": " .. formattedMsg)
        end
    end
end)

uiFrame.messageArea:AddMessage("|cffffff00[System]|r Addon loaded. Bugs report to discord - .mattmatt")
