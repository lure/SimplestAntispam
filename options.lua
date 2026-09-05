local addonName, private = ...
local addon, L = SimplestAntispam, private.L
local pending, refreshing = CopyTable(addon.defaults), false
local panel = CreateFrame("Frame", addonName .. "OptionsPanel")
panel.name = addonName
panel:Hide()

local function Save()
	if not refreshing and SimplestAntispamCharacterDB then addon:ApplySettings(pending) end
end

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText(addonName)

local description = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
description:SetWidth(520)
description:SetJustifyH("LEFT")
description:SetText(C_AddOns.GetAddOnMetadata(addonName, "Notes-" .. GetLocale()) or
	C_AddOns.GetAddOnMetadata(addonName, "Notes"))

local enabled = CreateFrame("CheckButton", addonName .. "Enable", panel, "UICheckButtonTemplate")
enabled:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -16)
enabled.Text:SetText(L["enabled"])
enabled:SetScript("OnClick", function(self)
	pending.enabled = self:GetChecked()
	Save()
end)

local function CreateSlider(suffix, label, low, high, key, multiplier)
	local slider = CreateFrame("Slider", addonName .. suffix, panel, "UISliderTemplateWithLabels")
	slider:SetWidth(300)
	slider:SetHeight(17)
	slider:SetMinMaxValues(low, high)
	slider:SetValueStep(1)
	slider:SetObeyStepOnDrag(true)
	slider.Low:SetText(low)
	slider.High:SetText(high)
	slider:SetScript("OnValueChanged", function(self, value)
		value = math.floor(value + 0.5)
		self.Text:SetText(label .. ": " .. value)
		pending[key] = value * multiplier
		Save()
	end)
	return slider
end

local level = CreateSlider("Level", L["level"], 0, GetMaxLevelForLatestExpansion(), "LEVEL", 1)
level:SetPoint("TOPLEFT", enabled, "BOTTOMLEFT", 4, -32)
local interval = CreateSlider("Interval", L["intervalMinutes"], 1, 60, "TIMEDELTA", 60)
interval:SetPoint("TOPLEFT", level, "BOTTOMLEFT", 0, -48)

local help = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
help:SetPoint("TOPLEFT", interval, "BOTTOMLEFT", 0, -32)
help:SetWidth(520)
help:SetJustifyH("LEFT")
help:SetText(L["levelHelp"])

function panel:OnRefresh()
	refreshing = true
	local db = SimplestAntispamCharacterDB or addon.defaults
	pending = { enabled = db.enabled, LEVEL = db.LEVEL, TIMEDELTA = db.TIMEDELTA }
	enabled:SetChecked(pending.enabled)
	level:SetValue(pending.LEVEL)
	interval:SetValue(pending.TIMEDELTA / 60)
	-- SetValue need not fire OnValueChanged when the value is unchanged.
	level.Text:SetText(L["level"] .. ": " .. pending.LEVEL)
	interval.Text:SetText(L["intervalMinutes"] .. ": " .. math.floor(pending.TIMEDELTA / 60 + 0.5))
	refreshing = false
end

function panel:OnDefault()
	if SimplestAntispamCharacterDB then addon:ApplySettings(addon.defaults) end
	self:OnRefresh()
end

panel:SetScript("OnShow", panel.OnRefresh)
addon.category = Settings.RegisterCanvasLayoutCategory(panel, addonName)
Settings.RegisterAddOnCategory(addon.category)
