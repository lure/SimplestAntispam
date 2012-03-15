﻿--[[ 
	blocks repeating messages, allowing it appear with 1 min interval. 
]] --
local addonName, ptable = ...
local L = ptable.L
local config = nil

SimplestAntispam = {frame = CreateFrame("Frame"), player = "|Hplayer:"..UnitName("player")..":", --throttler	  
				    seen = {}, banned = {},  allowed = {}, isBattleField = false, 								 --lowlevel filter
					defaults = {TIMEDELTA = 120, LEVEL = 10, enabled = true}
				   }
				   
function SimplestAntispam:ConsoleCommand(arg)
	InterfaceOptionsFrame_OpenToCategory(_G["SimplestAntispamOptionsPanel"])
end
SlashCmdList.SIMPLESTANTISPAM = SimplestAntispam.ConsoleCommand
SLASH_SIMPLESTANTISPAM1 = '/sa'

SimplestAntispam.frame:RegisterEvent("PLAYER_LOGIN")
SimplestAntispam.frame.PLAYER_LOGIN = function(...)
	config = _G.SimplestAntispamCharacterDB
	if (config == nil) then 
		_G.SimplestAntispamCharacterDB = CopyTable(SimplestAntispam.defaults)		
		config = _G.SimplestAntispamCharacterDB
	end
	
	config.NeedInitialization = true
	ShowFriends()
	if (config.enabled) then
		SimplestAntispam:EnableThrottle()
	end	
end

SimplestAntispam.frame.ZONE_CHANGED_NEW_AREA = function(...)
	SimplestAntispam.isBattlefield = GetNumBattlefieldStats() > 0
	for i=1,NUM_CHAT_WINDOWS do
		local frame = _G["ChatFrame"..i]
		if (frame ~= COMBATLOG) and frame.spamtable then 
			wipe(frame.spamtable)
		end
	end	
end

SimplestAntispam.frame:SetScript("OnEvent", function(self, event, ...)
    self[event](...)
end)

-- Here we maintain the hashmap where key is a text and value - it's timestamp.
-- copy this to chat to see stored messages /run table.foreach(SimplestAntispam.spamtable, print) 
local YELLPATTERN = CHAT_YELL_GET:format("|r]|h").."(.+)" --"|r]|h кричит: (.+)"
local function hook_addMessage(self, text, ...)

	if text:match(SimplestAntispam.player) then 
		self:LurUI_AddMessage(text, ...)	
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
			if (not value) or ((current-value) > config.TIMEDELTA) then
				self.spamtable[msg] = current
				local txt = text:gsub("|T%S+|t", "")
				self:LurUI_AddMessage(txt, ...)
			end		
		end	
	else		
		self:LurUI_AddMessage(text, ...)			
	end
end

function SimplestAntispam:InitAllowed()
	wipe(self.allowed)
	self.allowed[UnitName("player")] = 85
	for index=1, GetNumFriends() do
		local name, level = GetFriendInfo(index)
		if (name) then
			self.allowed[name] = level
		end
	end
end

--[[ SPAM REMOVER ]]--
SimplestAntispam.frame.FRIENDLIST_UPDATE= function(...)
	if (config.NeedInitialization) then 
		SimplestAntispam:InitAllowed()
		if (config.enabled) then
			SimplestAntispam:EnableLevelFilter()
		end	
		config.NeedInitialization = false
	end 
	
	--not our call. 
	if not next(SimplestAntispam.seen) then 
		return 
	end
	
	for index=1, GetNumFriends() do
		local name, level = GetFriendInfo(index)
		if SimplestAntispam.seen[name] then
			if (not SimplestAntispam.allowed[name]) and (not SimplestAntispam.banned[name]) then 
				RemoveFriend(name)		
			end
			if (level < config.LEVEL) then 
				SimplestAntispam.banned[name] = ""
			else
				SimplestAntispam.allowed[name] = level -- no real reason to save level here, but why not?
			end
		end
	end
end

local function myChatFilter(self, event, msg, author, ...)
	if #author==0 or SimplestAntispam.isBattleField or config.LEVEL == 0 then
		return false, msg, author, ...
	end 
	
	if (SimplestAntispam.banned[author]) then 
		return true
	elseif (SimplestAntispam.allowed[author]) then 
		return false, msg, author, ...
	end
	
	--UnitLevel usually doesn't work 
	if not SimplestAntispam.seen[author] then 		
		SimplestAntispam.seen[author]=""
		AddFriend(author)
	end
	return false, msg, author, ...
end

-- no need to form special string and guess about string declision!!! 'format' from wow lua does it automatically 	
local function myErrorFilter(self, event, msg, author, ...)
	if msg == ERR_FRIEND_WRONG_FACTION and next(SimplestAntispam.seen) then --note that next(table)  result may be wrongly intrepreted for table[false] = "someval"
		return true
	end
	for k in pairs(SimplestAntispam.seen) do	
		if msg == format(ERR_FRIEND_ADDED_S, k) then
			return true
		end
		if msg == format(ERR_FRIEND_OFFLINE_S, k) then 
			return true
		end
		if msg == format(ERR_FRIEND_REMOVED_S, k) then 
			SimplestAntispam.seen[k] = nil
			return true
		end 
	end
	return false, msg, author, ...
end

--[[ ENABLE/DISABLE ]]--
function SimplestAntispam:EnableThrottle()
	self.frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")	
	
	-- handling every window except combat log
	for i=1,NUM_CHAT_WINDOWS do
		local frame = _G["ChatFrame"..i]
		if (frame ~= COMBATLOG) then 
			frame.LurUI_AddMessage=frame.AddMessage
			frame.AddMessage = hook_addMessage
			frame.spamtable = {}
		end
	end
end

function SimplestAntispam:DisableThrottle()
	self.frame:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
	local frame = _G["ChatFrame1"]
	frame.AddMessage = frame.LurUI_AddMessage
end

function SimplestAntispam:EnableLevelFilter()
	self.frame:RegisterEvent("FRIENDLIST_UPDATE")				
	ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", myErrorFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", myChatFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", myChatFilter)		
end

function SimplestAntispam:DisableLevelFilter()
	self.frame:UnregisterEvent("FRIENDLIST_UPDATE")
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_CHANNEL", myChatFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_YELL", myChatFilter)	
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", myErrorFilter)
end

function SimplestAntispam:Enable()
	self:EnableThrottle()
	self:EnableLevelFilter()
end 

function SimplestAntispam:Disable()
	self:DisableLevelFilter()
	self:DisableThrottle()
end

--[[
debug shortcuts =)
/run for i,k in pairs(SimplestAntispam.banned) do print(i) end	
/run for i,k in pairs(SimplestAntispam.seen) do print(i) end	
/run for i,k in pairs(SimplestAntispam.allowed) do print(i) end	
|Hlcopy|h01:45:04|h |Hchannel:channel:4|h[4]|h |Hplayer:Онеоне:817:CHANNEL:4|h[|cff0070ddОнеоне|r]|h: |TInterface\TargetingFrame\UI-RaidTargetingIcon_1:0|t|TInterface\TargetingFrame\UI-RaidTargetingIcon_1:0|tВ статик ДД10 3\8 Хм (рт пн-чт с 20.45-00) нид: ШП 390+ил - вступление в гильдию(25лвл) |TInterface\TargetingFrame\UI-RaidTargetingIcon_1:0|t™
LOOT_ROLL_ROLLED_DE = "Disenchant Roll - %d for %s by %s";
LOOT_ROLL_ROLLED_GREED = "Greed Roll - %d for %s by %s";
LOOT_ROLL_ROLLED_NEED = "Need Roll - %d for %s by %s";

22:53:05 Вы отказались от предмета: [Шплинтованные поножи]
17:13:20 Результат броска Хенни ("Нужно") за предмет [Окаменевшее грибное сердце]: 176 с бонусом роли.
17:13:20 Тхалиса выигрывает: [Окаменевшее грибное сердце]
17:13:21 Тхалиса получает добычу: [Окаменевшее грибное сердце].

17:10:15 Итазурана отказывается от предмета [Окаменевшее грибное сердце].
17:10:10 Разыгрывается: [Отделанные мохом наплечные щитки]. Швюрбиц: "Распылить".
17:10:07 Разыгрывается: [Отделанные мохом наплечные щитки]. Куф: "Не откажусь".
17:09:56 Разыгрывается: [Окаменевшее грибное сердце]. Хенни: "Мне это нужно".
]]--