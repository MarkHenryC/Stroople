-- Mark H Carolan
--
-- Stroople project
-- © 2010 Mark H Carolan, Gregory S Hooper
-- alterations to distractorLanguageTable GSH 15-12-2010

module(..., package.seeall)

require "globals"

colorNames =
{
	{"Red", 		{253, 	30,		18		}},
	{"Green", 	{23, 		195, 		0		}},
	{"Blue", 	{0, 		105, 		248	}},
	{"Yellow", 	{255, 	244, 		0		}},
	{"Pink",		{244,	164,		216	}},
	{"Brown",	{205,	133,		63		}}
}

--
-- languageOptions isn't accessed by index, but the order of
-- languages must conform to the ordering in the tables
-- below. A selection from the language menu returns a
-- unity-based index to the chosen language (so far 1..4)
--

languageOptions =
{
	"English", "Español", "Français", "Deutsch",
}

function name()
	return languageOptions[globals.getSelectedLanguage()]
end

local oldlevelMenu =
{
	{ "level one", "level two", "level three", "level four", },
	{ "nivel uno", "nivel dos", "nivel tres", "nivel cuatro", },
	{ "niveau un", "niveau deux", "niveau trois", "niveau quatre", },
	{ "Niveau eins", "Niveau zwei", "Niveau drei", "Niveau vier", },
}

local levelMenu =
{
	{ "start", },
	{ "inicio", },
	{ "commencer", },
	{ "Start", },

}

function levelText(n)
	return levelMenu[globals.getSelectedLanguage()][n]
end

local menuButton =
{
	"menu", "menú", "menu", "Menü",
}

function menuText()
	return menuButton[globals.getSelectedLanguage()]
end

local infoButton =
{
	"info", "info", "info", "info",
}

function infoText()
	return infoButton[globals.getSelectedLanguage()]
end


local optionsButton =
{
	"options", "opciones", "options", "Wahlen",
}

function optionsText()
	return optionsButton[globals.getSelectedLanguage()]
end

local playButton =
{
	"play", "juego", "jeu", "Spiel",
}

function playText()
	return playButton[globals.getSelectedLanguage()]
end

local scoreButton =
{
	"score", "cuenta", "points", "Kerbe",
}

local yourScoreText =
{
	"You", "You", "You", "You",
}

function getYourScoreText()
	return yourScoreText[globals.getSelectedLanguage()]
end

function scoreText()
	return scoreButton[globals.getSelectedLanguage()]
end

local playersButton = -- where we set player names
{
	"players", "jugadores", "joueurs", "Spieler",
}

function playersText()
	return playersButton[globals.getSelectedLanguage()]
end

local colorNameTable =
{
	{ "Red", "Green", "Blue", "Yellow", "Pink", "Brown"},
	{ "Rojo", "Verde", "Azul", "Amarillo", "Rosa", "Marrón"},
	{ "Rouge", "Vert", "Bleu", "Jaune", "Rose", "Marron"},
	{ "Rot", "Grün", "Blau", "Gelb", "Rosa", "Braun"},

}

local distractorLanguageTable =
{
	-- each in order red, green, blue, yellow, pink, brown
	-- english
	--Greg altered english to be harder and get rid of french conflict
	{
		{"Reb", "Rede"},
		{"Greem", "Greer"},
		{"Bluu", "Lbue"},
		{"Yelow", "Yellew"},
		{"Pinky", "Pimk"},
		{"Bnown", "Bronw"},

	},
	-- spanish
	{
		{"Rujo", "Rolo"},
		{"Varde", "Verbe"},
		{"Azlu", "Aznl"},
		{"Amanillo", "Emarillo"},
		{"Sora", "Roso"},
		{"Mannór", "Mórran"},

	},
	-- french
	-- Greg altered to get rid of english conflict
	{
		{"Ruoge", "Nouge"},
		{"Vart", "Wert"},
		{"Lbeu", "Bluu"},
		{"Juane", "Jaure"},
		{"Sore", "Reso"},
		{"Mannor", "Morran"},

	},
	-- german
	{
		{"Rod", "Rol"},
		{"Gnür", "Grüm"},
		{"Blüa", "Dlüa"},
		{"Jelb", "Galb"},
		{"Sora", "Raso"},
		{"Rbaun", "Bnaur"},

	},


}

function getDistractor()
	local distractor = {}
	local distractorColors = distractorLanguageTable[globals.getSelectedLanguage()]
	--db.print(distractorColors)
	local colorIndex = math.random(1, #distractorColors)
	local subIndex = math.random(1, #distractorColors[colorIndex])
	table.insert(distractor, distractorColors[colorIndex][subIndex])
	table.insert(distractor, colorNames[colorIndex][2])

	return distractor, colorIndex
end

function setColorNames()
	local rgby = colorNameTable[globals.getSelectedLanguage()]

	for i = 1, #colorNames do
		colorNames[i][1] = rgby[i]
	end
end

function colorText(n) -- n is color index RGBY
	return colorNameTable[globals.getSelectedLanguage()][n]
end

local soundButtonTable =
{
	{ "sound on", "sound off" },
	{ "sonido", "sonido off" },
	{ "son sur", "pas de son" },
	{ "Ton", "Ton aus" },

}

function soundText(n)
	return soundButtonTable[globals.getSelectedLanguage()][n]
end
