local addonName, ptable, _ = ...
local L = ptable.L
local TempConfig = nil
local interface10 = select(4, GetBuildInfo()) >= 100000
--[[ 
https://wowpedia.fandom.com/wiki/Using_the_Interface_Options_Addons_panel
]]-- 
local O = addonName .. "OptionsPanel"
local OptionsPanel = CreateFrame("Frame", O)
OptionsPanel.name = addonName
-- Title
local title = OptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetText(addonName)
-- Description
local notes = GetAddOnMetadata(addonName, "Notes-" .. GetLocale())
notes = notes or GetAddOnMetadata(addonName, "Notes")
local subText = OptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
subText:SetText(notes)

-- 'Enable' CheckBox
local Enable = CreateFrame("CheckButton", O.."Enable", OptionsPanel, interface10 and "UICheckButtonTemplate" or "OptionsCheckButtonTemplate")
_G[Enable:GetName().."Text"]:SetText(L["enabled"])
Enable:SetScript("OnClick", function(self) 
	TempConfig.enabled = self:GetChecked()
end)

-- Slider helper function, thanks to Kollektiv, LoseControl
local function CreateSlider(text, parent, low, high, step)
	local name = parent:GetName() .. text
	local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
	slider:SetWidth(300)
	slider:SetMinMaxValues(low, high)
	slider:SetValueStep(step)
	--_G[name .. "Text"]:SetText(text)
	_G[name .. "Low"]:SetText(low)
	_G[name .. "High"]:SetText(high)
	return slider
end

local LZF = " %02d";
local LevelSlider = CreateSlider(L["level"], OptionsPanel, 0, 85, 1)
LevelSlider:SetScript("OnValueChanged", function(self, value)
	_G[self:GetName() .. "Text"]:SetText(L["level"] .. LZF:format(value))
	TempConfig.LEVEL = value
end)
local LZTF = " %02dmin";
local TimeSlider = CreateSlider(L["timedelta"], OptionsPanel, 1, 60, 1)
TimeSlider:SetScript("OnValueChanged", function(self, value)
	_G[self:GetName() .. "Text"]:SetText(L["timedelta"] .. LZTF:format(value))
	TempConfig.TIMEDELTA = value*60
end)


--[[ Control placement ]]--
title:SetPoint("TOPLEFT", 16, -16)
subText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
Enable:SetPoint("TOPLEFT", subText, "BOTTOMLEFT", 0, -16)
LevelSlider:SetPoint("TOPLEFT", Enable, "BOTTOMLEFT", 0, -24)
TimeSlider:SetPoint("TOPLEFT", LevelSlider, "BOTTOMLEFT", 0, -28)

OptionsPanel.refresh = function()
	TempConfig = CopyTable(SimplestAntispamCharacterDB)
	
	Enable:SetChecked(TempConfig.enabled)
	LevelSlider:SetValue(TempConfig.LEVEL)
	TimeSlider:SetValue(TempConfig.TIMEDELTA / 60)
end

OptionsPanel.default = function()
	TempConfig = CopyTable(SimplestAntispam.defaults)
end

OptionsPanel.okay = function()	
	if (TempConfig.enabled ~= SimplestAntispamCharacterDB.enabled) then
		if ( TempConfig.enabled ) then 
			SimplestAntispam:Enable()
		else 
			SimplestAntispam:Disable()
		end
	end		
	SimplestAntispam:ToggleLevelFilter(TempConfig.enabled and (TempConfig.LEVEL > 0 and SimplestAntispamCharacterDB.LEVEL == 0))	
	SimplestAntispamCharacterDB = CopyTable(TempConfig)
end

ptable.SimplestAntispamOptionsPanel = InterfaceOptions_AddCategory(OptionsPanel)
