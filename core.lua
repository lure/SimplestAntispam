--[[ 
	blocks repeating messages, allowing it appear with 1 min interval. 
	'seen' table was moved to SimplestAntispamCharacterDB in order to clean added by addon friends after 
	spirituous disconnect or interface reloading
	
	Known bugs: 		
		If enemy faction player was added to 'seen' there are no chance it will be ever cleared except reload ui / relogin
]] --
local addonName, ptable = ...
local L = ptable.L
local _ = 0

SimplestAntispam = {
	frame = CreateFrame("Frame"),
	player = "|Hplayer:"..UnitName("player").."-.+:", --throttler  .."-"..GetRealmName():gsub("%s", "")
	banned = {},
	allowed = {},
	isInstance = false,
	lastFriendsCount=0,	--lowlevel filter
	defaults = {
		TIMEDELTA = 120,
		LEVEL = 0,
		enabled = true,
	}
}
				   
function SimplestAntispam:ConsoleCommand(arg)
	InterfaceOptionsFrame_OpenToCategory(_G["SimplestAntispamOptionsPanel"])
end
SlashCmdList.SIMPLESTANTISPAM = SimplestAntispam.ConsoleCommand
SLASH_SIMPLESTANTISPAM1 = '/sa'

SimplestAntispam.frame:RegisterEvent("PLAYER_LOGIN")
SimplestAntispam.frame.PLAYER_LOGIN = function(...)
	if (SimplestAntispamCharacterDB == nil) then
		_G.SimplestAntispamCharacterDB = CopyTable(SimplestAntispam.defaults)
	end
	if not SimplestAntispamCharacterDB.loot then
		SimplestAntispamCharacterDB.loot = CopyTable(SimplestAntispam.defaults.loot)
	end

	SimplestAntispamCharacterDB.NeedInitialization = true
	C_FriendList.ShowFriends()
	if (SimplestAntispamCharacterDB.enabled) then
		SimplestAntispam:Enable()
	end

	-- initializing seen table.
	if not SimplestAntispamCharacterDB.seen then
		SimplestAntispamCharacterDB.seen = {}
	else
		for name in pairs(SimplestAntispamCharacterDB.seen) do
			--Antispam currently adds guys from instance group to seen list that is wrong. 
			if (not name:match("(.+)-(.+)") and (GetFriendInfo(name)) ) then
				RemoveFriend(name)
			end
		end
		wipe(SimplestAntispamCharacterDB.seen)
	end
	SimplestAntispam:LibDataStructure()
end

SimplestAntispam.frame.ZONE_CHANGED_NEW_AREA = function(...)
	-- no reason to keep possible stale data 
	--wipe(SimplestAntispamCharacterDB.seen)
	
	--Don't clear any tables on enter or exit BG
	if (not SimplestAntispam.isInstance) and (IsInInstance() == 1) then
		for i = 1, NUM_CHAT_WINDOWS do
			local frame = _G["ChatFrame"..i]
			if (frame ~= COMBATLOG) and frame.spamtable then
				wipe(frame.spamtable)
			end
		end
	end
	
	--flag used to disable antispam on BG
	SimplestAntispam.isInstance = IsInInstance() == 1
end

SimplestAntispam.frame:SetScript("OnEvent", function(self, event, ...)
    self[event](...)
end)

--[[ CHAT THROTTLER ]]--
-- Here we maintain the hashmap where key is a text and value - it's timestamp.
-- copy this to chat to see stored messages /run table.foreach(SimplestAntispam.spamtable, print) 
local YELLPATTERN = CHAT_YELL_GET:format("|r]|h").."(.+)" --"|r]|h кричит: (.+)"
local function hook_addMessage(self, text, ...)
	if text:match(SimplestAntispam.player) then
		self:_BlizzardAddMessage(text, ...)
		return
	end
	if text:match("|Hchannel:channel") or text:match(":YELL|h") then
		local msg = text:match("]|h: (.+)") or text:match(YELLPATTERN)
		if msg then
			msg = msg:gsub("|T.+|t", "") -- removing raid target icons
			msg = msg:gsub("[%s%c%z%p]","") -- removing any spaces %W does not work as WoW LUA doesn't support UTF8
			msg = msg:upper()  -- uppercase it
			
			local current = time()
			local value = self.spamtable[msg]
			if (not value) or ((current-value) > SimplestAntispamCharacterDB.TIMEDELTA) then
				self.spamtable[msg] = current
				local txt = text:gsub("|T%S+|t", "")
				self:_BlizzardAddMessage(txt, ...)
			end
		end
	else
		self:_BlizzardAddMessage(text, ...)
	end
end


--[[ LOW LEVEL SPAM REMOVER ]]--
-- InitAllowed tracks friend list updates made by player. If any adds new names to allowed list
function SimplestAntispam:InitAllowed(clean)
	if ( clean ) then
		wipe(self.allowed)
		self.allowed[UnitName("player")] = 100
	end
	
	self.lastFriendsCount = GetNumFriends()
	for index=1, GetNumFriends() do
		local name, level = GetFriendInfo(index)
		if ( name ) then
			self.allowed[name] = level
		end
	end
end

SimplestAntispam.frame.FRIENDLIST_UPDATE= function(...)
	if (SimplestAntispamCharacterDB.NeedInitialization) then
		SimplestAntispam:InitAllowed(true)
		SimplestAntispamCharacterDB.NeedInitialization = false
	end

	--not our call.  User added a friend manually
	if not next(SimplestAntispamCharacterDB.seen) and ( SimplestAntispam.lastFriendsCount ~= GetNumFriends() )then
		SimplestAntispam:InitAllowed(false)
		return
	end

	for seenName,_ in pairs(SimplestAntispamCharacterDB.seen) do
		local name, level = GetFriendInfo(seenName)
		if ( name ) then
			if (not SimplestAntispam.allowed[name]) and (not SimplestAntispam.banned[name]) then
				RemoveFriend(name)
			end
			
			-- right after remove call is made, continue to consider what to do with a person
			if (level < SimplestAntispamCharacterDB.LEVEL) then
				SimplestAntispam.banned[name] = ""
			else
				SimplestAntispam.allowed[name] = level -- no real reason to save level here, but why not?
			end		
		else
			-- looks like we got oppsite faction (dalaran, yelling maybe)
			SimplestAntispam.allowed[seenName] = nil
		end
	end	
end

local function myChatFilter(self, event, msg, author, ...)
	if #author==0 or SimplestAntispam.isInstance or SimplestAntispamCharacterDB.LEVEL == 0 then
		return false, msg, author, ...
	end 

	if (SimplestAntispam.banned[author]) then 
		return true
	elseif (SimplestAntispam.allowed[author]) then
		return false, msg, author, ...
	end

	-- maybe player just added this guy to the list manually. 
	local name, level = GetFriendInfo(author)
	if ( name ) and ( not SimplestAntispamCharacterDB.seen[author] ) then 
		SimplestAntispam.allowed[author] = level
		return false, msg, author, ...
	end

	--UnitLevel usually doesn't work 
	if (not SimplestAntispamCharacterDB.seen[author]) and (not author:match("(.+)-(.+)"))then
		SimplestAntispamCharacterDB.seen[author] = ""
		AddFriend(author)
	end
	return false, msg, author, ...
end

-- no need to form special string and guess about string declision!!! 'format' from wow lua does it automatically 	
local function myErrorFilter(self, event, msg, author, ...)
	if msg == ERR_FRIEND_WRONG_FACTION and next(SimplestAntispamCharacterDB.seen) then --note that next(table)  result may be wrongly intrepreted for table[false] = "someval"
		return true
	end
	for k in pairs(SimplestAntispamCharacterDB.seen) do
		if msg == format(ERR_FRIEND_ADDED_S, k) then
			return true
		end
		if msg == format(ERR_FRIEND_OFFLINE_S, k) then
			return true
		end
		if msg == format(ERR_FRIEND_REMOVED_S, k) then
			SimplestAntispamCharacterDB.seen[k] = nil
			return true
		end
	end
	return false, msg, author, ...
end

--[[ ENABLE/DISABLE ]]--
function SimplestAntispam:Enable()
	self.frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	for i=1,NUM_CHAT_WINDOWS do
		local frame = _G["ChatFrame"..i]
		if (frame ~= COMBATLOG) then
			frame._BlizzardAddMessage = frame.AddMessage
			frame.AddMessage = hook_addMessage
			frame.spamtable = {}
		end
	end		
end

function SimplestAntispam:Disable()
	self.frame:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
	for i=1,NUM_CHAT_WINDOWS do
		local frame = _G["ChatFrame"..i]
		if (frame ~= COMBATLOG) then 
			frame.AddMessage = frame._BlizzardAddMessage
		end
	end	
	self:ToggleLevelFilter(false)
end


function SimplestAntispam:ToggleLevelFilter(enabled)
	local func
	if enabled then
		self.frame:RegisterEvent("FRIENDLIST_UPDATE")
		func = ChatFrame_AddMessageEventFilter
	else
		self.frame:UnregisterEvent("FRIENDLIST_UPDATE")
		func = ChatFrame_RemoveMessageEventFilter
	end
	func("CHAT_MSG_SYSTEM", myErrorFilter)
	func("CHAT_MSG_CHANNEL", myChatFilter)
	func("CHAT_MSG_YELL", myChatFilter)	
end

--[[
	DATA BROKER STRUCTURES
--]]
-- see https://github.com/tekkub/libdatabroker-1-1/wiki/api
function SimplestAntispam:LibDataStructure()
	if not SimplestAntispam.ldb then
		local LDB = LibStub:GetLibrary("LibDataBroker-1.1", true)
		if LDB then
			SimplestAntispam.ldb = LDB:NewDataObject("SimplestAntispam", {
			type = "launcher",
			icon = "Interface\\AddOns\\SimplestAntispam\\Icon",
			OnClick = function(clickedframe, button)
				if SettingsPanel and SettingsPanel:IsVisible() then
					HideUIPanel(GameMenuFrame)
					HideUIPanel(SettingsPanel)
				else
					Settings.OpenToCategory(addonName)
				end
			end,
			OnTooltipShow = function(tooltip)
				tooltip:AddLine(addonName, 1, 1, 1)
				tooltip:AddLine("This addon allows repeatable messages from the same player")
				tooltip:AddLine("only once in a customizable while. The mesasges from characters below")
				tooltip:AddLine("customizable levels may be ignored completely")
				tooltip:AddLine("Left mouse button shows options.")				
			end
		})
		end
	end
end

--[[
https://github.com/Xruptor/xanMiniRolls/issues/1
debug shortcuts =)
/run for i,k in pairs(SimplestAntispam.banned) do print(i) end	
/run for i,k in pairs(SimplestAntispamCharacterDB.seen) do print(i) end	
/run for i,k in pairs(SimplestAntispam.allowed) do print(i) end	
|Hlcopy|h01:45:04|h |Hchannel:channel:4|h[4]|h |Hplayer:Онеоне:817:CHANNEL:4|h[|cff0070ddОнеоне|r]|h: |TInterface\TargetingFrame\UI-RaidTargetingIcon_1:0|t|TInterface\TargetingFrame\UI-RaidTargetingIcon_1:0|tВ статик ДД10 3\8 Хм (рт пн-чт с 20.45-00) нид: ШП 390+ил - вступление в гильдию(25лвл) |TInterface\TargetingFrame\UI-RaidTargetingIcon_1:0|t™
]]--