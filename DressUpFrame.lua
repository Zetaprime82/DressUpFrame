-- DressUpFrame Scale Controller
-- Slider range: 0.0 to 10.0
-- Type a value in the box and press Enter to apply it.
-- Use /dressupframe or /duf to open/close the menu.

local DEFAULT_SCALE = 1.0
local MIN_SCALE = 0
local MAX_SCALE = 10
local STEP = 0.1

-- Color of the ring around the portrait icon in the menu (red, green, blue 0-1).
local RING_COLOR = { 0.78, 0.78, 0.8 }

local currentScale = DEFAULT_SCALE
local menu
local SetMinimapButtonShown -- defined below

local function ClampScale(value)
    value = tonumber(value)
    if not value then
        return currentScale
    end

    value = math.max(MIN_SCALE, math.min(MAX_SCALE, value))
    return math.floor(value * 10 + 0.5) / 10
end

local function ApplyScale(value)
    currentScale = ClampScale(value)
    DressUpFrame:SetScale(currentScale)
    if DressUpFrameDB then DressUpFrameDB.scale = currentScale end

    if menu then
        menu.slider:SetValue(currentScale)
        menu.editBox:SetText(string.format("%.1f", currentScale))
    end
end

local function CreateScaleMenu()
    if menu then
        return menu
    end

    menu = CreateFrame("Frame", "DressUpFrameScaleMenu", UIParent, "BackdropTemplate")
    menu:SetSize(300, 175)
    menu:SetPoint("CENTER")
    menu:SetFrameStrata("DIALOG")
    menu:SetMovable(true)
    menu:EnableMouse(true)
    menu:RegisterForDrag("LeftButton")
    menu:SetScript("OnDragStart", menu.StartMoving)
    menu:SetScript("OnDragStop", menu.StopMovingOrSizing)

    menu:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })

    -- Round portrait icon in the top-left corner of the menu.
    local portrait = CreateFrame("Frame", nil, menu)
    portrait:SetSize(96, 96)
    portrait:SetPoint("TOPLEFT", -20, 20)
    portrait:SetFrameLevel(menu:GetFrameLevel() + 5)

    local portraitBg = portrait:CreateTexture(nil, "BACKGROUND")
    portraitBg:SetSize(39, 39)
    portraitBg:SetPoint("TOPLEFT", 12, -10)
    portraitBg:SetColorTexture(0, 0, 0, 1)

    local portraitIcon = portrait:CreateTexture(nil, "ARTWORK")
    portraitIcon:SetSize(39, 39)
    portraitIcon:SetPoint("TOPLEFT", 12, -10)
    portraitIcon:SetTexture("Interface\\AddOns\\DressUpFrame\\icon")

    -- Crop the icon to a circle when the game supports masks.
    pcall(function()
        local mask = portrait:CreateMaskTexture()
        mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
        mask:SetAllPoints(portraitIcon)
        portraitIcon:AddMaskTexture(mask)
        portraitBg:AddMaskTexture(mask)
    end)

    local portraitRing = portrait:CreateTexture(nil, "OVERLAY")
    portraitRing:SetSize(96, 96)
    portraitRing:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    portraitRing:SetPoint("TOPLEFT")
    portraitRing:SetDesaturated(true)
    portraitRing:SetVertexColor(RING_COLOR[1], RING_COLOR[2], RING_COLOR[3])

    local title = menu:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -12)
    title:SetText("DressUpFrame Menu")

    local label = menu:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", 65, -45)
    label:SetText("Scale:")

    local editBox = CreateFrame("EditBox", nil, menu, "InputBoxTemplate")
    editBox:SetSize(65, 24)
    editBox:SetPoint("TOPLEFT", 110, -40)
    editBox:SetAutoFocus(false)
    editBox:SetText(string.format("%.1f", currentScale))
    editBox:SetMaxLetters(5)
    menu.editBox = editBox

    editBox:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText())
        if value then
            ApplyScale(value)
        else
            self:SetText(string.format("%.1f", currentScale))
        end
        self:ClearFocus()
    end)

    editBox:SetScript("OnEscapePressed", function(self)
        self:SetText(string.format("%.1f", currentScale))
        self:ClearFocus()
    end)

    local slider = CreateFrame("Slider", nil, menu, "OptionsSliderTemplate")
    slider:SetSize(240, 18)
    slider:SetPoint("TOP", 0, -75)
    slider:SetMinMaxValues(MIN_SCALE, MAX_SCALE)
    slider:SetValueStep(STEP)
    slider:SetObeyStepOnDrag(true)
    slider:SetValue(currentScale)
    slider.Low:SetText("0")
    slider.High:SetText("10")
    slider.Text:SetText("")
    menu.slider = slider

    slider:SetScript("OnValueChanged", function(self, value)
        value = ClampScale(value)
        currentScale = value
        DressUpFrame:SetScale(value)
        if DressUpFrameDB then DressUpFrameDB.scale = value end
        editBox:SetText(string.format("%.1f", value))
    end)

    local minimapCheck = CreateFrame("CheckButton", nil, menu, "UICheckButtonTemplate")
    minimapCheck:SetSize(24, 24)
    minimapCheck:SetPoint("TOPLEFT", 20, -105)
    minimapCheck.text = minimapCheck.text or minimapCheck.Text
    minimapCheck.text:SetText("Show minimap button")
    minimapCheck:SetChecked(not (DressUpFrameDB and DressUpFrameDB.hideMinimap))
    minimapCheck:SetScript("OnClick", function(self)
        SetMinimapButtonShown(self:GetChecked())
    end)
    menu.minimapCheck = minimapCheck

    local closeButton = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate")
    closeButton:SetSize(70, 24)
    closeButton:SetPoint("BOTTOM", 0, 12)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function()
        menu:Hide()
    end)

    menu:Hide()
    return menu
end

local function ToggleScaleMenu()
    local frame = CreateScaleMenu()

    if frame:IsShown() then
        frame:Hide()
    else
        frame.slider:SetValue(currentScale)
        frame.editBox:SetText(string.format("%.1f", currentScale))
        frame.minimapCheck:SetChecked(not DressUpFrameDB.hideMinimap)
        frame:Show()
    end
end

SLASH_DRESSUPFRAMESCALE1 = "/dressupframe"
SLASH_DRESSUPFRAMESCALE2 = "/duf"

-- Open or close the Dressing Room window.
local function ToggleDressingRoom()
    if DressUpFrame:IsShown() then
        HideUIPanel(DressUpFrame)
    elseif DressUpFrame_Show then
        DressUpFrame_Show(DressUpFrame)
    else
        ShowUIPanel(DressUpFrame)
    end
end

-- Minimap button (no external libraries needed).
-- Left-click: open/close the menu. Right-click: open/close the Dressing Room. Drag: move around the minimap.
-- /duf minimap: show/hide the button.
local ICON_TEXTURE = "Interface\\AddOns\\DressUpFrame\\icon"
local BUTTON_RADIUS = 5 -- extra distance outside the minimap edge

local minimapButton

SetMinimapButtonShown = function(show)
    DressUpFrameDB.hideMinimap = not show
    if minimapButton then minimapButton:SetShown(show) end
    if menu and menu.minimapCheck then menu.minimapCheck:SetChecked(show) end
end

local function UpdateMinimapButtonPosition()
    if not minimapButton then return end
    local angle = math.rad(DressUpFrameDB.minimapAngle or 215)
    local x, y = math.cos(angle), math.sin(angle)
    local radius = (Minimap:GetWidth() / 2) + BUTTON_RADIUS

    -- Respect square minimaps from other addons.
    local shape = GetMinimapShape and GetMinimapShape() or "ROUND"
    if shape == "SQUARE" then
        local half = Minimap:GetWidth() / 2 + BUTTON_RADIUS
        x = math.max(-half, math.min(half, x * radius * 1.4142))
        y = math.max(-half, math.min(half, y * radius * 1.4142))
    else
        x, y = x * radius, y * radius
    end

    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function CreateMinimapButton()
    if minimapButton then return end

    local b = CreateFrame("Button", "DressUpFrameMinimapButton", Minimap)
    b:SetSize(31, 31)
    b:SetFrameStrata("MEDIUM")
    b:SetFrameLevel(8)
    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:RegisterForDrag("LeftButton")

    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(20, 20)
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    bg:SetPoint("TOPLEFT", 7, -5)

    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetTexture(ICON_TEXTURE)
        icon:SetPoint("TOPLEFT", 7, -5)
    b.icon = icon

    local border = b:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetPoint("TOPLEFT")

    b:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            ToggleDressingRoom()
        else
            ToggleScaleMenu()
        end
    end)

    b:SetScript("OnDragStart", function(self)
        self.dragging = true
        GameTooltip:Hide()
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local scale = Minimap:GetEffectiveScale()
            local cx, cy = GetCursorPosition()
            cx, cy = cx / scale, cy / scale
            DressUpFrameDB.minimapAngle = math.deg(math.atan2(cy - my, cx - mx))
            UpdateMinimapButtonPosition()
        end)
    end)

    b:SetScript("OnDragStop", function(self)
        self.dragging = false
        self:SetScript("OnUpdate", nil)
    end)

    b:SetScript("OnEnter", function(self)
        if self.dragging then return end
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("DressUpFrame")
        GameTooltip:AddLine("|cffffffffLeft-click:|r open/close scale menu", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("|cffffffffRight-click:|r open/close Dressing Room", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("|cffffffffDrag:|r move this button", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)

    minimapButton = b
    UpdateMinimapButtonPosition()
    b:SetShown(not DressUpFrameDB.hideMinimap)
end

local loadFrame = CreateFrame("Frame")
loadFrame:RegisterEvent("ADDON_LOADED")
loadFrame:SetScript("OnEvent", function(self, event, addon)
    if addon ~= "DressUpFrame" then return end
    self:UnregisterEvent("ADDON_LOADED")
    DressUpFrameDB = DressUpFrameDB or {}
    if DressUpFrameDB.minimapAngle == nil then DressUpFrameDB.minimapAngle = 215 end
    -- Restore the saved scale (falls back to the default on first run).
    currentScale = ClampScale(DressUpFrameDB.scale or DEFAULT_SCALE)
    DressUpFrameDB.scale = currentScale
    DressUpFrame:SetScale(currentScale)
    CreateMinimapButton()
end)

SlashCmdList.DRESSUPFRAMESCALE = function(msg)
    msg = strlower(strtrim(msg or ""))
    if msg == "minimap" then
        SetMinimapButtonShown(DressUpFrameDB.hideMinimap and true or false)
        print("|cff00ff00DressUpFrame|r: minimap button " .. (DressUpFrameDB.hideMinimap and "hidden" or "shown") .. ".")
    else
        ToggleScaleMenu()
    end
end

-- Announce the slash commands in chat once when the player enters the world.
local announcementFrame = CreateFrame("Frame")
announcementFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
announcementFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    print("|cff00ff00DressUpFrame|r: Click the minimap icon or type |cffffff00/duf|r to open the menu.")
end)

-- Original default scale.
DressUpFrame:SetScale(DEFAULT_SCALE)
