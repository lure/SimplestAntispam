local addonName, ptable = ...
local L = ptable.L
local TempConfig = nil 
--[[ 
	Thanks to LoseControl author Kouri for ideas and direction 
	http://forums.wowace.com/showthread.php?t=15763
	http://www.wowwiki.com/UI_Object_UIDropDownMenu
	группа -> выбор( [] нид [] грид [] пас ) ролл ( [] нид [] грид [] пас ) 
	рейд -> выбор( [] нид [] грид [] пас) ролл ( [] нид [] грид [] пас ) 
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
local Enable = CreateFrame("CheckButton", O.."Enable", OptionsPanel, "OptionsCheckButtonTemplate")
_G[Enable:GetName().."Text"]:SetText(L["enabled"])
Enable:SetScript("OnClick", function(self) 
	TempConfig.enabled = self:GetChecked() == 1 
	if (TempConfig.enabled) then 
		SimplestAntispam:Enable()
	else 
		SimplestAntispam:Disable()
	end
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

local function CreateCheckbox(name, parent, marginx, marginy, text)
	local cb = CreateFrame("CheckButton", parent:GetName()..name,  parent, "OptionsCheckButtonTemplate")
	cb:SetPoint("LEFT", parent, marginx, marginy)
	_G[cb:GetName().."Text"]:SetText(L[text])
	cb:SetScript("OnClick", function(self)
		TempConfig.loot[name] = self:GetChecked() == 1 
	end)
	return cb
end 

local function CreateLabel(parent, marginx, marginy, text)
	local label = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	label:SetText(text)
	label:SetPoint("LEFT", parent, marginx, marginy)
end

-- Party and Raid loot decision hiding 
local PartyOptionPanel = CreateFrame("Frame", O.."PartyOptionsPanel",  OptionsPanel, "OptionsBoxTemplate")
PartyOptionPanel:SetWidth(590)
PartyOptionPanel:SetHeight(90) 
_G[PartyOptionPanel:GetName().."Title"]:SetText("Hide loot decisions and rolls for party");
CreateLabel(PartyOptionPanel, 8, 30, "decision")
CreateLabel(PartyOptionPanel, 8, -10, "roll")

CreateCheckbox("wdis", PartyOptionPanel, 5, 11, "disenchant")
CreateCheckbox("wneed", PartyOptionPanel, 150, 11, "need")
CreateCheckbox("wgreed", PartyOptionPanel, 295, 11, "greed")
CreateCheckbox("wpass", PartyOptionPanel, 440, 11, "pass")

CreateCheckbox("wrdis", PartyOptionPanel, 5, -28, "disenchant")
CreateCheckbox("wrneed", PartyOptionPanel, 150, -28, "need")
CreateCheckbox("wrgreed", PartyOptionPanel, 295, -28, "greed")


local RaidOptionPanel = CreateFrame("Frame", O.."RaidOptionsPanel",  OptionsPanel, "OptionsBoxTemplate")
RaidOptionPanel:SetWidth(590)
RaidOptionPanel:SetHeight(90) 
_G[RaidOptionPanel:GetName().."Title"]:SetText("Hide loot decisions and rolls for raids");
CreateLabel(RaidOptionPanel, 8, 30, "decision")
CreateLabel(RaidOptionPanel, 8, -10, "roll")

CreateCheckbox("rdis", RaidOptionPanel, 5, 11, "disenchant")
CreateCheckbox("rneed", RaidOptionPanel, 150, 11, "need")
CreateCheckbox("rgreed", RaidOptionPanel, 295, 11, "greed")
CreateCheckbox("rpass", RaidOptionPanel, 440, 11, "pass")

CreateCheckbox("rrdis", RaidOptionPanel, 5, -28, "disenchant")
CreateCheckbox("rrneed", RaidOptionPanel, 150, -28, "need")
CreateCheckbox("rrgreed", RaidOptionPanel, 295, -28, "greed")


--[[ Control placement ]]--
title:SetPoint("TOPLEFT", 16, -16)
subText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
Enable:SetPoint("TOPLEFT", subText, "BOTTOMLEFT", 0, -16)
LevelSlider:SetPoint("TOPLEFT", Enable, "BOTTOMLEFT", 0, -24)
TimeSlider:SetPoint("TOPLEFT", LevelSlider, "BOTTOMLEFT", 0, -28)
PartyOptionPanel:SetPoint("TOPLEFT", TimeSlider, "BOTTOMLEFT", 0, -30)
RaidOptionPanel:SetPoint("TOPLEFT", PartyOptionPanel, "BOTTOMLEFT", 0, -24)

--[[ 
/run SimplestAntispamOptionsPanelPartyOptionsPanelwneed:SetPoint("LEFT", SimplestAntispamOptionsPanelPartyOptionsPanel, 150, 0)
/run print(SimplestAntispamOptionsPanelWGreed:GetPoint())
/run print(SimplestAntispamOptionsPanelPartyOptionsPanel:GetPoint())
/run print(SimplestAntispamOptionsPanelRaidOptionsPanel:SetHeight(90))

]]--

OptionsPanel.refresh = function()
	TempConfig = CopyTable(SimplestAntispamCharacterDB)
	Enable:SetChecked(TempConfig.enabled)
	LevelSlider:SetValue(TempConfig.LEVEL)
	TimeSlider:SetValue(TempConfig.TIMEDELTA / 60)
	
	for k,v in pairs (TempConfig.loot) do
		local cb = _G[RaidOptionPanel:GetName()..k]
		if ( cb ) then 
			cb:SetChecked(v)
		else 
			cb = _G[PartyOptionPanel:GetName()..k]
			cb:SetChecked(v)
		end		
	end
end

OptionsPanel.default = function() 
	TempConfig = CopyTable(SimplestAntispam.defaults)
end

OptionsPanel.okay = function()
	SimplestAntispamCharacterDB = CopyTable(TempConfig)
end


InterfaceOptions_AddCategory(OptionsPanel)