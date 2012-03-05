local addonName, privateTable = ...

if (GetLocale() == "ruRU")  then
privateTable.L = setmetatable({enabled="Включить", level="Прятать уровни ниже", timedelta="Задержка повторных сообщений"},  
	{__index = function(table, index) return index end})
	
end

if (GetLocale() == "enUS") or (GetLocale() == "enGB") then
privateTable.L = setmetatable({enabled="Enable", level="Hide levels below", timedelta="Delay the duplicate messages for"},  
	{__index = function(table, index) return index end})
	
end

if (GetLocale() == "deDE") then 
privateTable.L = setmetatable({enabled="Aktivieren", level="Verstecken Ebenen unterhalb", timedelta="Verzögerung die doppelten Nachrichten"},  
	{__index = function(table, index) return index end})
end