local addonName, privateTable = ...

if (GetLocale() == "ruRU")  then
privateTable.L = setmetatable({
			enabled="Включить", level="Прятать уровни ниже", timedelta="Задержка повторных сообщений",
			SELF="Вы сказали:", SELF_AP="Вы пропускаете розыгрыш предмета",
			decision="решение", roll="бросок",
			disenchant="распылить", need="нужно", greed="не откажусь", pass="отказ",
			partylootheader="Прятать броски и решения по луту, если в группе", raidlootheader="Прятать броски и решения по луту, если в рейде",
			
			CHOICE_DE=': "Распылить"', CHOICE_GR=': "Не откажусь"', CHOICE_NE=': "Мне это нужно"', CHOICE_PA='отказывается от предмета',
			AUTO_PA="поскольку не может его забрать",
			ROLL_DE='%("Распылить"%) за предмет', ROLL_GR='%("Не откажусь"%) за предмет', ROLL_NE='%("Нужно"%) за предмет',
	},  
	{__index = function(table, index) return index end})
end

if (GetLocale() == "enUS") or (GetLocale() == "enGB") then
privateTable.L = setmetatable({
			enabled="Enable", level="Hide levels below", timedelta="Delay the duplicate messages for",
			partylootheader="Hide loot decisions and rolls while in a party", raidlootheader="Hide loot decisions and rolls while in a raid",
			
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
			decision="Entscheidung", roll="würfeln",
			disenchant="Entzauberung", need="Bedarf", greed="Gier", pass="passen", 
			partylootheader="Hide loot decisions and rolls while in a party", raidlootheader="Hide loot decisions and rolls while in a raid",
			
			SELF="Ihr habt", SELF_AP="Ihr passt automtisch bei",
			CHOICE_DE='Entzauberung gewählt', CHOICE_GR="'Gier' ausgewählt", CHOICE_NE="'Bedarf' ausgewählt", CHOICE_PA="würfelt nicht für",
			AUTO_PA="passt automatisch bei", 
			ROLL_DE='Entzauberungswurf:', ROLL_GR='Wurf für Gier', ROLL_NE='Wurf für Bedarf',			
	},
	{__index = function(table, index) return index end})
end
