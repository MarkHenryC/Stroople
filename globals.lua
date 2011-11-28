-- Mark H Carolan
--
-- Stroople project
-- © 2010 Mark H Carolan, Gregory S Hooper

module(..., package.seeall)

require "storage"
require "db"

--
-- this is for development only
--
usingOpenFeint = false

W = display.contentWidth
H = display.contentHeight

distractorProbability = 7 -- i.e. 1 in 8
rotatorProbability = 9

local soundOff = false
local levelID = 1
local levelStartTime = 0
local levelAggregateTime = 0 -- to account for pausing
local selectedLanguage = 1
local defaultPlayer = system.getInfo("model")
local currentPlayer
local score = 0
local levelTime = 0 -- time for current level
local isPaused = false
local systemLanguage
local isSimulator = system.getInfo("environment") == "simulator" and true or false

local gamePrefs = {}
local highScores = {}
local players = {}

--
-- tag for file IDs etc (such as loading flag icons)
--
languageNames = { "english", "spanish", "french", "german",  }

function init()
	local e = system.getInfo("environment")
	local ui = system.getInfo("ui", "language")
	local localeCountry = system.getInfo("locale", "country")
	local localeIdentifier = system.getInfo("locale", "identifier")
	local localeLanguage = system.getInfo("locale", "language")
	db.print("system info:", e, ui, localeCountry, localeIdentifier, localeLanguage)

	--
	-- Central place for storing relative coords. init() is called first thing in main.lua
	--
	W2 = W/2
	H2 = H/2
	W4 = W/4
	H4 = H/4
	W6 = W/6
	H6 = H/5
	W8 = W/8
	H8 = H/8
	W16 = W/16
	H16 = H/16
	W24 = W/24
	H24 = H/24	
end

function getIsSimulator()
	return isSimulator
end

function toggleSound()
	soundOff = not soundOff
end

function getSoundOff()
	return soundOff
end

function isSoundOn()
	return not soundOff
end

function getLevelID()
	return levelID
end

function setLevelID(id)
	levelID = id
end

function getLevelStartTime()
	return levelStartTime
end

function setLevelStartTime(t)
	levelStartTime = t
end

function resetLevelAggregateTime()
	levelAggregateTime = 0
end

function addToLevelAggregateTime(elapsed)
	levelAggregateTime = levelAggregateTime + elapsed
end

function getLevelAggregateTime()
	return levelAggregateTime
end

function getSelectedLanguage()
	return selectedLanguage
end

function setSelectedLanguage(id)
	selectedLanguage = id
end

function getCurrentPlayer()
	return currentPlayer
end

function getDefaultPlayer()
	return defaultPlayer
end

function setCurrentPlayer(p)
	currentPlayer = p
end

function getScore()
	return score
end

function setScore(s)
	score = s
end

function addScore(s)
	score = score + s	
end

function getLevelTime()
	return levelTime
end

function setLevelTime(t)
	levelTime = t
end

function getIsPaused()
	return isPaused
end

function setIsPaused(p)
	isPaused = p
end

function loadPrefs()
	gamePrefs = storage.loadPrefs("game")
	local a = tonumber(gamePrefs["soundOff"])
	soundOff = (a == 1) and true or false
	currentPlayer = gamePrefs["currentPlayer"] or defaultPlayer
	local b = tonumber(gamePrefs["selectedLanguage"])
	selectedLanguage = b or 1
	highScores = storage.loadPrefs("scores")
	--players = storage.loadList("players")
end

function savePrefs()
	gamePrefs["selectedLanguage"] = selectedLanguage
	gamePrefs["soundOff"] = soundOff and 1 or 0
	gamePrefs["currentPlayer"] = currentPlayer
	storage.savePrefs(gamePrefs, "game")
	storage.savePrefs(highScores, "scores")
	--storage.saveList(players, "players")
end

function updateHighScores(scoreTable)
	--
	-- convert from sorted list to kv table
	--
	highScores = nil	
	highScores = {}
	
	db.print("scoreTable size", #scoreTable)
	for i = 1, #scoreTable do
		db.print(scoreTable[i][1], scoreTable[i][2])
		highScores[scoreTable[i][1]] = scoreTable[i][2]
	end
	db.print("highScores size", #highScores)
	storage.savePrefs(highScores, "scores")
end

function getHighScores()
	return highScores
end

function updatePlayers(names)
	players = nil
	players = {}
	for i = 1, #names do
		players[#players+1] = names[i]
	end
end

function getPlayers()
	return players
end

function foundInList(list, item)
	for i = 1, #list do
		if list[i] == item then return true end
	end
	return false
end

function positionInList(list, item)
	for i = 1, #list do
		if list[i] == item then return i end
	end
	return 0
end