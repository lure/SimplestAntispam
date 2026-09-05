local _, private = ...
local english = {
	enabled = "Enable",
	level = "Hide levels below",
	intervalMinutes = "Repeat delay (minutes)",
	launcherTooltip = "Click to open settings.",
	levelHelp = "Level 0 disables the level filter. Unknown levels are allowed. Same-realm players may be added as friends briefly to check their level. Level checks pause inside instances; chat filtering pauses while chat is restricted.",
}
local translations = {
	ruRU = {
		enabled = "Включить",
		level = "Прятать уровни ниже",
		intervalMinutes = "Задержка повторов (минуты)",
		launcherTooltip = "Нажмите, чтобы открыть настройки.",
		levelHelp = "Уровень 0 отключает фильтр уровней. Сообщения игроков с неизвестным уровнем разрешены. Игроки вашего сервера могут временно добавляться в друзья для проверки уровня. Проверка уровней отключена в подземельях, рейдах и на полях боя; фильтрация чата приостановлена при ограничении доступа к сообщениям.",
	},
	deDE = {
		enabled = "Aktivieren",
		level = "Spieler unter diesem Level ausblenden",
		intervalMinutes = "Wiederholungsverzögerung (Minuten)",
		launcherTooltip = "Klicken, um die Einstellungen zu öffnen.",
		levelHelp = "Level 0 deaktiviert den Levelfilter. Unbekannte Level werden zugelassen. Spieler desselben Realms können zur Levelprüfung kurzzeitig als Freunde hinzugefügt werden. In Instanzen pausiert die Levelprüfung; bei eingeschränktem Chatzugriff pausiert die Chatfilterung.",
	},
}
private.L = setmetatable(translations[GetLocale()] or {}, {
	__index = function(_, key) return english[key] or key end,
})
