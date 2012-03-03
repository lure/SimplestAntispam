local addonName, ptable = ...
ptable.L = {enabled="включить", level="уровень", timedelta="задержка"}
local L = ptable.L
--[[ 
	Thanks to LoseControl author Kouri for ideas and direction 
	http://forums.wowace.com/showthread.php?t=15763
	http://www.wowwiki.com/UI_Object_UIDropDownMenu
]]-- 
local O = addonName .. "OptionsPanel"
local OptionsPanel = CreateFrame("Frame", O)
OptionsPanel.name=addonName
-- Title
local title = OptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetText(addonName)
-- Description
local notes = GetAddOnMetadata(addonName, "Notes-" .. GetLocale())
notes = notes or GetAddOnMetadata(addonName, "Notes")
local subText = OptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
subText:SetText(notes)

-- 'Enable' CheckBox
local Enable = CreateFrame("CheckButton", O.."Enable", OptionsPanel, "OptionsCheckButtonTemplate")
_G[O.."EnableText"]:SetText(L["enabled"])
Enable:SetScript("OnClick", function(self) 
	SimplestAntispamCharacterDB.enabled = self:GetChecked() == 1 
	if (SimplestAntispamCharacterDB.enabled) then 
		SimplestAntispam:EnableEvents()
	else 
		SimplestAntispam:DisableEvents()
	end
end)

-- Slider helper function, thanks to Kollektiv, LoseControl
local function CreateSlider(text, parent, low, high, step)
	local name = parent:GetName() .. text
	local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
	slider:SetWidth(160)
	slider:SetMinMaxValues(low, high)
	slider:SetValueStep(step)
	--_G[name .. "Text"]:SetText(text)
	_G[name .. "Low"]:SetText(low)
	_G[name .. "High"]:SetText(high)
	return slider
end

local LevelSlider = CreateSlider(L["level"], OptionsPanel, 1, 85, 1)
LevelSlider:SetScript("OnValueChanged", function(self, value)
	_G[self:GetName() .. "Text"]:SetText(L["level"] .. " (" .. value .. ")")
	SimplestAntispamCharacterDB.LEVEL = value
end)

local TimeSlider = CreateSlider(L["timedelta"], OptionsPanel, 1, 60, 1)
TimeSlider:SetScript("OnValueChanged", function(self, value)
	_G[self:GetName() .. "Text"]:SetText(L["timedelta"] .. " (" .. value .. "min)")
	SimplestAntispamCharacterDB.TIMEDELTA = value*60
end)

-- Control placement
title:SetPoint("TOPLEFT", 16, -16)
subText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
Enable:SetPoint("TOPLEFT", subText, "BOTTOMLEFT", 0, -16)
LevelSlider:SetPoint("TOPLEFT", Enable, "BOTTOMLEFT", 0, -24)
TimeSlider:SetPoint("TOPLEFT", LevelSlider, "BOTTOMLEFT", 0, -24)

OptionsPanel.refresh = function()
	Enable:SetChecked(SimplestAntispamCharacterDB.enabled)
	LevelSlider:SetValue(SimplestAntispamCharacterDB.LEVEL)
	TimeSlider:SetValue(SimplestAntispamCharacterDB.TIMEDELTA / 60)
end

OptionsPanel.default = function() 
	SimplestAntispamCharacterDB = CopyTable(AutoTurnIn.defaults)
end

InterfaceOptions_AddCategory(OptionsPanel)