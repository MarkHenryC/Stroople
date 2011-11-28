-- Mark H Carolan
--
-- Stroople project
-- © 2010 Mark H Carolan, Gregory S Hooper

module(..., package.seeall)

require "globals"

--
-- Set from main via init() only once
--

local returnFunction
local background
local images
local homeButton

local modulator = 4
local modCounter = 0
local transCounter = 0
local transDirection = 0.04
local startArrow

local function enterFrame(event)
	images[2].alpha = transCounter
--	images.logo.xScale = 0.5 + transCounter
--	images.logo.yScale = 0.5 + transCounter
	transCounter = transCounter + transDirection
	if transCounter > 1.0 then
		transCounter = 1.0
		transDirection = -0.04
	elseif transCounter < 0.5 then
		transCounter = 0.5
		transDirection = 0.04
	end
--	if images.arrow.y < startArrow-6 then
--		images.arrow.y = startArrow
--	elseif modCounter % modulator == 0 then
--		images.arrow.y = images.arrow.y-1
--	end
	modCounter = modCounter + 1
end

local function onMainMenu(event, param)
	Runtime:removeEventListener("enterFrame", enterFrame)
	
	background:removeSelf()
	background = nil
	images:removeSelf()
	images = nil
	homeButton:removeSelf()
	homeButton = nil
	
	returnFunction()
end

local function brainImage()
	if not images then images = display.newGroup() end
	
	local brain = display.newImage("brain.png")
	local brainH = display.newImage("brainH.png")
	
	images:insert(brain)
	images:insert(brainH)
	
	local arrow = display.newImage("yellow_arrow_small.png")
	arrow.x = globals.W2 + globals.W16
	arrow.y = globals.H24*9
	arrow.rotation = -90
	arrow.xScale = 0.5
	arrow.yScale = 0.5
	startArrow = arrow.y
	
	local logo = display.newImage("entryLogo.png")
	logo.x = globals.W2 + globals.W16
	logo.y = globals.H24*15
	images.logo = logo
	
	images:insert(arrow)
	images.arrow = arrow
	images:insert(logo)
	
	images.x = globals.W16*2
	transCounter = 0
	transDirection = 0.01	
	
	Runtime:addEventListener("enterFrame", enterFrame)
end

--
-- These functions accessible from outside:
--

function showInfo()
	if not background then
		background = display.newImage("background.png")
	end

	if not homeButton then
	
		homeButton = ui.newButton
		{
			default = "home.png",
			over = "homeH.png",
			onRelease = onMainMenu,
			x = globals.W2,
			y = display.contentHeight - 30
		}

	end
	
	brainImage()
end

function init(returnFunc)
	returnFunction = returnFunc
end

