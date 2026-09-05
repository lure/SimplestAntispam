local addonName, private = ...
local L = private.L
local LOOKUP_NOTE = "SimplestAntispam temporary level lookup"
local LOOKUP_INTERVAL, LOOKUP_TIMEOUT, CACHE_LIFETIME = 5, 15, 300

SimplestAntispam = {
	frame = CreateFrame("Frame"),
	defaults = { TIMEDELTA = 120, LEVEL = 0, enabled = true },
	histories = setmetatable({}, { __mode = "k" }),
	levels = {},
	attempts = {},
	removing = {},
	systemMessages = {},
	nextLookup = 0,
}
local addon = SimplestAntispam

local function IsReadable(value)
	return not issecretvalue(value)
end

local function ChatIsRestricted()
	return C_ChatInfo.InChatMessagingLockdown()
end

local function IntegerSetting(value, default, low, high)
	if type(value) ~= "number" or value ~= value then value = default end
	return math.max(low, math.min(high, math.floor(value + 0.5)))
end

function addon:ApplySettings(settings)
	local db = SimplestAntispamCharacterDB
	local enabled = type(settings.enabled) ~= "boolean" or settings.enabled
	local interval = IntegerSetting(settings.TIMEDELTA, self.defaults.TIMEDELTA, 60, 3600)
	local level = IntegerSetting(settings.LEVEL, self.defaults.LEVEL, 0, GetMaxLevelForLatestExpansion())
	if enabled ~= db.enabled or interval ~= db.TIMEDELTA or level ~= db.LEVEL then
		wipe(self.histories)
	end
	db.enabled, db.TIMEDELTA, db.LEVEL = enabled, interval, level
	if db.enabled then self:Enable() else self:Disable() end
end

-- Only same-realm characters can be queried through the legacy friend list.
function addon:LocalName(name)
	if not IsReadable(name) or type(name) ~= "string" or name == "" then return nil end
	local character, realm = name:match("^([^-]+)%-(.+)$")
	if not character then return name end
	if realm:gsub("%s", ""):lower() == self.realm then return character end
end

local function StripRaidIcons(message)
	message = message:gsub("{([^{}]+)}", function(tag)
		local key = tag:lower()
		local icon = ICON_TAG_LIST and ICON_TAG_LIST[key]
		if (type(icon) == "number" and icon >= 1 and icon <= 8) or key:match("^rt[1-8]$") then
			return ""
		end
	end)
	return message:gsub("|T.-|t", function(texture)
		if texture:lower():find("interface\\targetingframe\\ui%-raidtargetingicon_[1-8]:") then
			return ""
		end
	end)
end

function addon:FilterChat(chatFrame, event, message, author, ...)
	local db = SimplestAntispamCharacterDB
	if not db or not db.enabled or ChatIsRestricted() or not IsReadable(message) or not IsReadable(author) then
		return false
	end
	if type(message) ~= "string" or type(author) ~= "string" then return false end
	local guid = select(10, ...)
	local localName = self:LocalName(author)
	if (IsReadable(guid) and guid == self.playerGUID) or (localName and localName == self.playerName) then
		return false
	end

	local now = GetTime()
	local history = self.histories[chatFrame]
	if not history then
		history = { messages = {}, nextCleanup = now + 30 }
		self.histories[chatFrame] = history
	end
	-- A filter may run repeatedly for a line; each chat window needs its own
	-- decision so displaying a line in one window does not hide it in another.
	local lineID = select(9, ...)
	local hasLineID = IsReadable(lineID) and type(lineID) == "number" and lineID > 0
	if hasLineID and history.lineID == lineID and history.event == event then
		return history.blocked, history.message, author, ...
	end
	if now >= history.nextCleanup then
		for key, timestamp in pairs(history.messages) do
			if now - timestamp >= db.TIMEDELTA then history.messages[key] = nil end
		end
		history.nextCleanup = now + 30
	end

	local blocked = false
	if db.LEVEL > 0 and not self.isInstance and localName then
		blocked = self:IsLowLevel(localName, now)
	end
	local cleaned = StripRaidIcons(message)
	if not blocked then
		local key = cleaned:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("[%s%c%z%p]", ""):upper()
		-- Punctuation-only messages still need distinct keys.
		if key == "" then key = cleaned end
		local previous = history.messages[key]
		blocked = previous ~= nil and now - previous < db.TIMEDELTA
		if not blocked then history.messages[key] = now end
	end
	history.lineID = hasLineID and lineID or nil
	history.event, history.blocked, history.message = event, blocked, cleaned
	return blocked, cleaned, author, ...
end

local function ChatFilter(...)
	return addon:FilterChat(...)
end

-- Filters run once per window. Remember notifications without consuming them,
-- and perform friend cleanup outside the filter.
function addon:RememberFriendMessages(name, now)
	for _, template in ipairs({ ERR_FRIEND_ADDED_S, ERR_FRIEND_REMOVED_S, ERR_FRIEND_OFFLINE_S }) do
		self.systemMessages[template:format(name)] = now + LOOKUP_TIMEOUT
	end
end

local function SystemFilter(_, _, message)
	if ChatIsRestricted() or not IsReadable(message) or type(message) ~= "string" then return false end
	local expires = addon.systemMessages[message]
	return expires ~= nil and GetTime() < expires
end

function addon:FriendListAvailable()
	return not ChatIsRestricted() and (not C_FriendList.IsLegacyFriendSystemEnabled or
		C_FriendList.IsLegacyFriendSystemEnabled())
end

function addon:IsLowLevel(name, now)
	if not self.friendsReady or not self:FriendListAvailable() then return false end
	local info = C_FriendList.GetFriendInfo(name)
	-- Friends explicitly added by the player are always allowed.
	if info and not SimplestAntispamCharacterDB.seen[name] then return false end
	local cached = self.levels[name]
	if cached and now < cached.expires then
		return cached.level < SimplestAntispamCharacterDB.LEVEL
	end
	if not info and not self.pending and now >= self.nextLookup and
		(not self.attempts[name] or now >= self.attempts[name]) and
		not next(SimplestAntispamCharacterDB.seen) then
		self.pending = { name = name, expires = now + LOOKUP_TIMEOUT }
		self.nextLookup = now + LOOKUP_INTERVAL
		self.attempts[name] = now + CACHE_LIFETIME
		SimplestAntispamCharacterDB.seen[name] = true
		self:RememberFriendMessages(name, now)
		C_FriendList.AddFriend(name, LOOKUP_NOTE)
	end
	-- Unknown levels pass through while the asynchronous lookup is pending.
	return false
end

function addon:UpdateFriends()
	if not self:FriendListAvailable() then return end
	local now = GetTime()
	local seen = SimplestAntispamCharacterDB.seen
	for name, ownership in pairs(seen) do
		local info = C_FriendList.GetFriendInfo(name)
		if info then
			if IsReadable(info.level) and type(info.level) == "number" and info.level > 0 then
				self.levels[name] = { level = info.level, expires = now + CACHE_LIFETIME }
			end
			-- The note identifies our additions after a reload. Preserve a friend
			-- if the user changed the note while the lookup was in flight.
			local owned = IsReadable(info.notes) and (info.notes == LOOKUP_NOTE or
				(ownership == "" and (info.notes == nil or info.notes == "")))
			if owned then
				if not self.removing[name] or now >= self.removing[name] then
					self.removing[name] = now + LOOKUP_TIMEOUT
					self:RememberFriendMessages(name, now)
					C_FriendList.RemoveFriend(name)
				end
				-- Keep ownership until a later update confirms removal.
			else
				seen[name], self.removing[name] = nil, nil
			end
			if self.pending and self.pending.name == name then self.pending = nil end
		elseif self.friendsReady and (not self.pending or self.pending.name ~= name or now >= self.pending.expires) then
			seen[name], self.removing[name] = nil, nil
			if self.pending and self.pending.name == name then self.pending = nil end
		end
	end
end

function addon:Maintenance()
	self:UpdateFriends()
	local now = GetTime()
	for name, expires in pairs(self.attempts) do
		if now >= expires then self.attempts[name] = nil end
	end
	for name, entry in pairs(self.levels) do
		if now >= entry.expires then self.levels[name] = nil end
	end
	for message, expires in pairs(self.systemMessages) do
		if now >= expires then self.systemMessages[message] = nil end
	end
end

function addon:Enable()
	if self.active then return end
	self.active = true
	ChatFrameUtil.AddMessageEventFilter("CHAT_MSG_CHANNEL", ChatFilter)
	ChatFrameUtil.AddMessageEventFilter("CHAT_MSG_YELL", ChatFilter)
end

function addon:Disable()
	if not self.active then return end
	self.active = false
	ChatFrameUtil.RemoveMessageEventFilter("CHAT_MSG_CHANNEL", ChatFilter)
	ChatFrameUtil.RemoveMessageEventFilter("CHAT_MSG_YELL", ChatFilter)
	wipe(self.histories)
	-- Pending friend cleanup continues even with filtering disabled.
	self:UpdateFriends()
end

function addon:OpenOptions()
	if self.category then Settings.OpenToCategory(self.category:GetID()) end
end

SlashCmdList.SIMPLESTANTISPAM = function() addon:OpenOptions() end
SLASH_SIMPLESTANTISPAM1 = "/sa"

function addon:LibDataStructure()
	local broker = LibStub and LibStub:GetLibrary("LibDataBroker-1.1", true)
	if self.ldb or not broker then return end
	self.ldb = broker:NewDataObject(addonName, {
		type = "launcher",
		icon = "Interface\\AddOns\\SimplestAntispam\\Icon",
		OnClick = function() addon:OpenOptions() end,
		OnTooltipShow = function(tooltip)
			tooltip:AddLine(addonName, 1, 1, 1)
			tooltip:AddLine(L["launcherTooltip"])
		end,
	})
end

function addon:UpdateInstance()
	local inside = IsInInstance()
	if inside ~= self.isInstance then wipe(self.histories) end
	self.isInstance = inside
end

function addon:RecoverLookups()
	if not self:FriendListAvailable() then return end
	for index = 1, C_FriendList.GetNumFriends() or 0 do
		local info = C_FriendList.GetFriendInfoByIndex(index)
		if info and IsReadable(info.notes) and info.notes == LOOKUP_NOTE then
			local name = self:LocalName(info.name)
			if name then SimplestAntispamCharacterDB.seen[name] = true end
		end
	end
	self:UpdateFriends()
end

function addon:Login()
	if type(SimplestAntispamCharacterDB) ~= "table" then SimplestAntispamCharacterDB = {} end
	local db = SimplestAntispamCharacterDB
	self.playerName = UnitName("player")
	self.playerGUID = UnitGUID("player")
	self.realm = GetNormalizedRealmName():lower()
	local seen = {}
	for name, ownership in pairs(type(db.seen) == "table" and db.seen or {}) do
		local localName = self:LocalName(name)
		-- Old versions could track instance players from other realms even
		-- though they were never eligible for a temporary friend lookup.
		if localName and (ownership == true or ownership == "") then seen[localName] = ownership end
	end
	db.seen, db.NeedInitialization = seen, nil
	self:UpdateInstance()
	self:ApplySettings(db)
	self:LibDataStructure()
	self.frame:RegisterEvent("FRIENDLIST_UPDATE")
	if C_FriendList.IsLegacyFriendSystemEnabled then
		self.frame:RegisterEvent("LEGACY_FRIEND_SYSTEM_STATUS_UPDATED")
	end
	self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	self.frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	ChatFrameUtil.AddMessageEventFilter("CHAT_MSG_SYSTEM", SystemFilter)
	if self:FriendListAvailable() then C_FriendList.ShowFriends() end
	self:RecoverLookups()
	self.ticker = C_Timer.NewTicker(5, function() addon:Maintenance() end)
end

addon.frame:RegisterEvent("PLAYER_LOGIN")
addon.frame:SetScript("OnEvent", function(frame, event)
	if event == "PLAYER_LOGIN" then
		frame:UnregisterEvent("PLAYER_LOGIN")
		addon:Login()
	elseif event == "FRIENDLIST_UPDATE" then
		addon.friendsReady = true
		addon:RecoverLookups()
	elseif event == "LEGACY_FRIEND_SYSTEM_STATUS_UPDATED" then
		addon.friendsReady = false
		if addon:FriendListAvailable() then C_FriendList.ShowFriends() end
	else
		addon:UpdateInstance()
	end
end)
