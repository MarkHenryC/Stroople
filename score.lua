-- Mark H Carolan
--
-- Stroople project
-- © 2010 Mark H Carolan, Gregory S Hooper

module(..., package.seeall)

require "globals"
require "highscores"
require "ui"

local returnFunction
local background

local homeButton
local scoreboard
local yourScore

local hits, misses

local soundCorrect = media.newEventSound( "correct.aif" )
local soundIncorrect = media.newEventSound( "incorrect.aif" )
local soundMiss = media.newEventSound( "miss.aif" )

local missSoundPlaying = false
local prevFrameTime, prevTimeoutTime

local levelTimes =
{
	0, 0, 0, 0
}

function getHitsAndMisses()
	return hits, misses
end

function getCurLevelTime()
	return globals.getLevelAggregateTime() + (system.getTimer() - globals.getLevelStartTime())
end

function testSound()
	if globals.isSoundOn() then
		media.playEventSound(soundCorrect)
	end
end

function startLevel(n)
	hits = 0
	misses = 0
	globals.setLevelID(n)
	globals.resetLevelAggregateTime()	
	local now = system.getTimer()
	globals.setLevelStartTime(now)
	prevFrameTime = now
	prevTimeoutTime = now
end

function isTimedOut(timeout)
	local now = system.getTimer()
	local timeoutTime = now - prevTimeoutTime
	if timeoutTime >= timeout then
		prevTimeoutTime = now
		return true
	end
	return false
end

function elapsedSinceLastFrame()
	local now = system.getTimer()
	local elapsed = now - prevFrameTime
	prevFrameTime = now
	return elapsed
end

function pause()
	local elapsed = system.getTimer() - globals.getLevelStartTime()
	globals.addToLevelAggregateTime(elapsed)	
end

function resume()
	globals.setLevelStartTime(system.getTimer())
	prevFrameTime = globals.getLevelStartTime()
end

function endLevel(endScore)
	return highscores.isHighScore(getCurLevelTime(), endScore)	
end

function setScore(n)
	globals.setScore(n)
end

function getScore()
	return globals.getScore()
end

function add(n)
	hits = hits + 1
	globals.addScore(n)
	lightHit(true)
	if globals.isSoundOn() then
		media.playEventSound(soundCorrect)
	end
end

function sub(n)
	misses = misses + n
	globals.addScore(-n)
	lightMiss(true)
	if globals.isSoundOn() then
		media.playEventSound(soundIncorrect)
	end
end

local function soundMissComplete()
	missSoundPlaying = false
end

function miss(n)
	misses = misses + n
	globals.addScore(-n)
	lightMiss(true)
	if globals.isSoundOn() and not missSoundPlaying then
		missSoundPlaying = true
		media.playEventSound(soundMiss, soundMissComplete)
	end
end

function frame()
	lightHit()
	lightMiss()
end

local function removeMenuButtons()
	homeButton:removeSelf()
	homeButton = nil
	scoreboard:removeSelf()
	scoreboard = nil
	if yourScore then 
		yourScore:removeSelf()
		yourScore = nil
	end
end

local function onMainMenu()
	background.isVisible = false
	removeMenuButtons()	
	returnFunction()
end

function showScoreMenu(hsTime)

	background.isVisible = true
	background.parent:insert(background)
	
	scoreboard = highscores.newScoreboard(hsTime)
	if not homeButton then
	
		homeButton = ui.newButton
		{
			default = "home.png",
			over = "homeH.png",
			onRelease = onMainMenu,
			x = globals.W2,
			y = globals.H - 30
		}

	end
	
end

function init(returnFunc)
	returnFunction = returnFunc
	background = display.newImage("background.png")
end

function cleanup()
	scoreboard:removeSelf()
	scoreboard = nil
	removeMenuButtons()
	background:removeSelf()
end