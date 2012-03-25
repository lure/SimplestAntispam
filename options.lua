local addonName, ptable = ...
local L = ptable.L
local TempConfig = nil 
--[[ 
	Thanks to LoseControl author Kouri for ideas and direction 
	http://forums.wowace.com/showthread.php?t=15763
	http://www.wowwiki.com/UI_Object_UIDropDownMenu
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

local function LootDecisionButton_OnClick(self)
	local owner = self:GetParent();
	local id = self:GetID();		
	if ( id == owner.selectedRadioButton ) then
		return;
	else
		owner.selectedRadioButton = id;
	end
	local radioButtons = owner.radioButtons;
	local radioButton;
	for i=1, #radioButtons do
		radioButton = radioButtons[i];
		if ( i == owner.selectedRadioButton ) then
			radioButton:SetChecked(1);
			radioButton:Disable();
		else
			radioButton:SetChecked(0);
			radioButton:Enable();
		end
	end
end

local function CreateRadioButton(parent, marginx, marginy, text)
	parent.radiocounter = parent.radiocounter and parent.radiocounter + 1 or 1;
	
	local cb = CreateFrame("CheckButton", "$parentRadioButton"..parent.radiocounter,  parent, "UIRadioButtonTemplate")
	cb:SetID( parent.radiocounter )
	cb:SetPoint("LEFT", parent, marginx, marginy)
	cb:SetScript("OnClick", LootDecisionButton_OnClick)	
	
	local label = cb:CreateFontString("$parentText", "BACKGROUND", "GameFontNormal")
	label:SetPoint("LEFT", cb, "RIGHT", 5, 0)
	label:SetText(L[text])
	
	return cb
end



local function CreateCheckbox(name, parent, marginx, marginy, text)
	local cb = CreateFrame("CheckButton", "$parent"..name,  parent, "OptionsCheckButtonTemplate")
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
PartyOptionPanel:SetHeight(70) 
_G[PartyOptionPanel:GetName().."Title"]:SetText(L["partylootheader"])
CreateLabel(PartyOptionPanel, 8, 25, L["decision"])
PartyOptionPanel.radioButtons = {
	CreateRadioButton(PartyOptionPanel, 12, 8, L["showall"]), 
	CreateRadioButton(PartyOptionPanel, 180, 8, L["showneed"]),
	CreateRadioButton(PartyOptionPanel, 400, 8, L["hideall"]), 
}
CreateCheckbox("phideroll", PartyOptionPanel, 10, -20, L["hiderolls"])

local RaidOptionPanel = CreateFrame("Frame", O.."RaidOptionsPanel",  OptionsPanel, "OptionsBoxTemplate")
RaidOptionPanel:SetWidth(590)
RaidOptionPanel:SetHeight(70) 
_G[RaidOptionPanel:GetName().."Title"]:SetText(L["raidlootheader"])
CreateLabel(RaidOptionPanel, 8, 25, L["decision"])
RaidOptionPanel.radioButtons = {
	CreateRadioButton(RaidOptionPanel, 12, 8, L["showall"]),
	CreateRadioButton(RaidOptionPanel, 180, 8, L["showneed"]),
	CreateRadioButton(RaidOptionPanel, 400, 8, L["hideall"]),
}
CreateCheckbox("rhideroll", RaidOptionPanel, 10, -20, L["hiderolls"])



--[[ Control placement ]]--
title:SetPoint("TOPLEFT", 16, -16)
subText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
Enable:SetPoint("TOPLEFT", subText, "BOTTOMLEFT", 0, -16)
LevelSlider:SetPoint("TOPLEFT", Enable, "BOTTOMLEFT", 0, -24)
TimeSlider:SetPoint("TOPLEFT", LevelSlider, "BOTTOMLEFT", 0, -28)
PartyOptionPanel:SetPoint("TOPLEFT", TimeSlider, "BOTTOMLEFT", 0, -30)
RaidOptionPanel:SetPoint("TOPLEFT", PartyOptionPanel, "BOTTOMLEFT", 0, -24)


OptionsPanel.refresh = function()
	TempConfig = CopyTable(SimplestAntispamCharacterDB)
	
	Enable:SetChecked(TempConfig.enabled)
	LevelSlider:SetValue(TempConfig.LEVEL)
	TimeSlider:SetValue(TempConfig.TIMEDELTA / 60)
	
	LootDecisionButton_OnClick(PartyOptionPanel.radioButtons[TempConfig.loot.ploot])
	_G[PartyOptionPanel:GetName().."phideroll"]:SetChecked(L[TempConfig.loot.phideroll])
	
	LootDecisionButton_OnClick(RaidOptionPanel.radioButtons[TempConfig.loot.rloot])
	_G[RaidOptionPanel:GetName().."rhideroll"]:SetChecked(L[TempConfig.loot.rhideroll])
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
	
	TempConfig.loot.rloot = RaidOptionPanel.selectedRadioButton
	TempConfig.loot.ploot = PartyOptionPanel.selectedRadioButton
	SimplestAntispamCharacterDB = CopyTable(TempConfig)
end


InterfaceOptions_AddCategory(OptionsPanel)