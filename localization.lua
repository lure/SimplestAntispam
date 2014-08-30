local addonName, privateTable, _ = ...

if (GetLocale() == "ruRU")  then
privateTable.L = setmetatable({
			enabled="Включить", level="Прятать уровни ниже", timedelta="Задержка повторных сообщений",
			
			decision="решение", 
			partylootheader="Группа: фильтр решений и бросков по луту", raidlootheader="Рейд: фильтр решений и бросков по луту",
			showall="показать всё", showneed="показать 'нужно'", hideall="скрыть всё", hiderolls="скрыть результаты бросков",
			
			SELF="Вы сказали:", SELF_AP="Вы пропускаете розыгрыш предмета",
			CHOICE_DE=': "Распылить"', CHOICE_GR=': "Не откажусь"', CHOICE_NE=': "Мне это нужно"', CHOICE_PA='отказывается от предмета',
			AUTO_PA="поскольку не может его забрать",
			ROLL_DE='%("Распылить"%) за предмет', ROLL_GR='%("Не откажусь"%) за предмет', ROLL_NE='%("Нужно"%) за предмет',
	},  
	{__index = function(table, index) return index end})
end

if (GetLocale() == "enUS") or (GetLocale() == "enGB") then
privateTable.L = setmetatable({
			enabled="Enable", level="Hide levels below", timedelta="Delay the duplicate messages for",
			
			partylootheader="Party: filter loot decisions and rolls", raidlootheader="Raid: filter loot decisions and rolls",
			showall="Show any", showneed="Show 'need' only", hideall="Hide any", hiderolls="Hide roll results",
			
			SELF="You have selected", SELF_AP="You automatically passed on:",
			CHOICE_DE='has selected Disenchant for:', CHOICE_GR="has selected Greed for:", CHOICE_NE="has selected Need for:", CHOICE_PA="passed on:",
			AUTO_PA="automatically passed on:", 
			ROLL_DE='Disenchant Roll -', ROLL_GR='Greed Roll - ', ROLL_NE='Need Roll - ',
	},  	
	{__index = function(table, index) return index end})
end

if (GetLocale() == "deDE") then 
privateTable.L = setmetatable({
			enabled="Aktivieren", level="Verstecken Ebenen unterhalb", timedelta="Verzögerung die doppelten Nachrichten",
			
			decision="Entscheidung",
			partylootheader="Party: filter loot decisions and rolls", raidlootheader="Raid: filter loot decisions and rolls",
			showall="Show any", showneed="Show 'Bedarf' only", hideall="Hide any", hiderolls="Hide roll results",			
			
			SELF="Ihr habt", SELF_AP="Ihr passt automtisch bei",
			CHOICE_DE='Entzauberung gewählt', CHOICE_GR="'Gier' ausgewählt", CHOICE_NE="'Bedarf' ausgewählt", CHOICE_PA="würfelt nicht für",
			AUTO_PA="passt automatisch bei", 
			ROLL_DE='Entzauberungswurf:', ROLL_GR='Wurf für Gier', ROLL_NE='Wurf für Bedarf',			
	},
	{__index = function(table, index) return index end})
end
