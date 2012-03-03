--[[ 
	blocks repeating messages, allowing it appear with 1 min interval. 
]] --
LurUI.antispam = {spamtable = {}, 
				  TIMEDELTA = 120, 
				  frame = CreateFrame("Frame"),
				  player = "|Hplayer:"..UnitName("player")..":",
				  seen = {},
				  banned = {},
				  allowed = {},
				  LEVEL = 10,
				  isBattleField = false
				  }
local AS = LurUI.antispam

AS.frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
AS.frame:RegisterEvent("FRIENDLIST_UPDATE")
AS.frame.ZONE_CHANGED_NEW_AREA = function(...)
	LurUI.antispam.isBattlefield = GetNumBattlefieldStats() > 0
	LurUI.antispam.spamtable = {}
end

AS.frame:SetScript("OnEvent", function(self, event, ...)
    self[event](...)
end)

local YELLPATTERN = CHAT_YELL_GET:format("|r]|h").."(.+)" --"|r]|h кричит: (.+)"

-- Here we maintain the hashmap where key is a text and value - it's timestamp.
-- copy this to chat to see stored messages /run table.foreach(LurUI.antispam.spamtable, print) 
local function hook_addMessage(self, text, ...)

	if text:match(AS.player) then 
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
			local value = AS.spamtable[msg]
			if (not value) or ((current-value) > AS.TIMEDELTA) then
				AS.spamtable[msg] = current
				local txt = text:gsub("|T%S+|t", "")
				self:LurUI_AddMessage(txt, ...)
			end		
		end	
	else		
		self:LurUI_AddMessage(text, ...)			
	end
end

local frame = _G["ChatFrame1"]
frame.LurUI_AddMessage=frame.AddMessage
frame.AddMessage = hook_addMessage

--[[ SPAM REMOVER ]]--
for index=1, GetNumFriends() do
	local name, level = GetFriendInfo(index)
	AS.allowed[name] = level
end	
AS.frame.FRIENDLIST_UPDATE= function(...) 

	for index=1, GetNumFriends() do
		local name, level = GetFriendInfo(index)
		if AS.seen[name] then
			if (not AS.allowed[name]) and (not AS.banned[name]) then 
				RemoveFriend(name)		
			end
			if (level < AS.LEVEL) then 
				AS.banned[name] = ""
			end
			AS.allowed[name] = level -- no real reason to save it here, but why not?
		end
	end

end
local function myChatFilter(self, event, msg, author, ...)
	if #author==0 or AS.isBattleField then
		return false, msg, author, ...
	end 
	
	if (AS.banned[author]) then 
		return true
	elseif (AS.allowed[author]) then 
		return false, msg, author, ...
	end
	
	--UnitLevel usually doesn't work 
	if not AS.seen[author] then 		
		AS.seen[author]=""
		AddFriend(author)
	end
	return false, msg, author, ...
end

-- no need to form special string and guess about string declision!!! 'format' from wow lua does it automatically 	
local function myErrorFilter(self, event, msg, author, ...)
	if msg == ERR_FRIEND_WRONG_FACTION and next(AS.seen) then --note that next(table)  result may be wrongly intrepreted for table[false] = "someval"
		return true
	end
	for k in pairs(AS.seen) do	
		if msg == format(ERR_FRIEND_ADDED_S, k) then
			return true
		end 	

		if msg == format(ERR_FRIEND_REMOVED_S, k) then 
			AS.seen[k] = nil
			return true
		end 
	end
	return false, msg, author, ...
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", myChatFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", myErrorFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", myChatFilter)
--[[
ERR_FRIEND_NOT_FOUND	
/run for i,k in pairs(LurUI.antispam.banned) do print(i) end	
/run for i,k in pairs(LurUI.antispam.seen) do print(i) end	
|Hlcopy|h01:45:04|h |Hchannel:channel:4|h[4]|h |Hplayer:Онеоне:817:CHANNEL:4|h[|cff0070ddОнеоне|r]|h: |TInterface\TargetingFrame\UI-RaidTargetingIcon_1:0|t|TInterface\TargetingFrame\UI-RaidTargetingIcon_1:0|tВ статик ДД10 3\8 Хм (рт пн-чт с 20.45-00) нид: ШП 390+ил - вступление в гильдию(25лвл) |TInterface\TargetingFrame\UI-RaidTargetingIcon_1:0|t™
]]--