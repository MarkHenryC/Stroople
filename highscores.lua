-- Mark H Carolan
--
-- Stroople project
-- © 2010 Mark H Carolan, Gregory S Hooper

module(..., package.seeall)

require "storage"
require "globals"
require "languages"
require "db"

local maxEntries = 8

if globals.usingOpenFeint then
	require "openfeint"
end

--
-- IDs for setting individual high scores at OF
--
local levelIDs = 
{
	522144, 522154, 522164, 522174
}

local scoreTable = {}

function init()
	-- highScore table is key, value, so not sorted
	-- move to local table for sorted display
	--
	local scores = globals.getHighScores()

	-- Returns key, value pairs: score, player - not sorted
	for k, v in pairs(scores) do
		scoreTable[#scoreTable + 1] = {tonumber(k), v}
		db.print("restoring", k, v)
	end

	table.sort(scoreTable,  
		function(a, b)
			return a[1] > b[1]
		end
	)		
	
end

local function setOFHighScore(amount)
	if globals.usingOpenFeint then
		if system.getInfo("environment") ~= "simulator" then
			openfeint.setHighScore
			{ 
				leaderboardID=levelIDs[globals.getLevelID()], 
				score=amount
			}
		end
	end
end

function newScoreboard(hsScore)
	local sb = display.newGroup()
	local spacing = 32
	local endPos = 10 -- default if no high scores
	for i = 1, #scoreTable do
		local entry = scoreTable[i] -- score, player
		local text1 = string.format("%000d", tonumber(entry[1]))
		local t1 = display.newText(text1, 0, 0, nil, 24)
		local t2 =  display.newText(entry[2], 0, 0, nil, 24)
		t1:setTextColor(255, 100, 100)
		t2:setTextColor(200, 200, 200)		
		sb:insert(t1)
		sb:insert(t2)
		t1:setReferencePoint(display.TopRightReferencePoint)
		t2:setReferencePoint(display.TopLeftReferencePoint)
		t1.y = i * spacing
		t2.y = i * spacing
		t1.x = globals.W2 - 20
		t2.x = globals.W2 +20
		endPos = i
	end
	
	if hsScore then

		local num = string.format("%000d", hsScore)

		local tick = display.newImage("tick.png")
		local cross = display.newImage("cross.png")
		
		tick:setReferencePoint(display.CenterReferencePoint)
		cross:setReferencePoint(display.CenterReferencePoint)
		
		sb:insert(tick)
		sb:insert(cross)
		
		tick.xScale = 0.25
		tick.yScale = 0.25

		cross.xScale = 0.25
		cross.yScale = 0.25

		local divs = globals.W / 12
		
		tick.x = divs * 2.5
		tick.y = (endPos + 2) * spacing
		
		cross.x = divs * 6
		cross.y = (endPos + 2) * spacing
		
		local hits, misses = score.getHitsAndMisses()

		local hitText = display.newText(hits, 0, 0, nil, 24)
		hitText:setTextColor(160, 160, 255)
		hitText.y = (endPos + 2) * spacing
		hitText.x = divs 
		
		local missText = display.newText(misses, 0, 0, nil, 24)
		missText:setTextColor(160, 160, 255)
		missText.y = (endPos + 2) * spacing
		missText.x = divs * 4.5
		
		sb:insert(hitText)
		sb:insert(missText)
		
		local arrow = display.newImage("yellow_arrow_small.png")
		arrow.xScale = 0.5
		arrow.yScale = 0.5
		arrow.y = (endPos + 2) * spacing
		arrow.x = divs * 8
		
		yourScore = display.newText(num, 0, 0, nil, 24)
		yourScore:setTextColor(160, 160, 255)		
		yourScore.y = (endPos + 2) * spacing
		yourScore.x = divs * 10

		yourScore:setReferencePoint(display.TopCenterReferencePoint)
		sb:insert(yourScore)
	end	
	return sb
end

function isNameHighScorer(name)
	db.print("isNameHighScorer", name, "#scoreTable", #scoreTable)
	for i = 1, #scoreTable do
		local n = scoreTable[i][2]
		db.print("Comparing", name, "with", n)
		if name == n then
			return true
		end
	end
	db.print("isNameHighScorer returning false")
	return false
end

function deleteEntry(name)
	for i = 1, #scoreTable do
		if name == scoreTable[i][2] then
			table.remove(scoreTable, i)
			globals.updateHighScores(scoreTable)
			return true
		end
	end
	return false
end

function isHighScore(gameTime, amount)
	local isTop = false
	local isIn = false
	local rVal = "not in high scores"	
	local rank = -1
	
	db.print("isHighScore()", amount)
	
	if amount > 0 then
		if #scoreTable == 0 then
			db.print("First entry");
			return true, true, "First entry in hi-scores", 1, amount		
		end
		
		for i = 1, #scoreTable do
			db.print("comparing to:", scoreTable[i][1], scoreTable[i][2])
			if amount > scoreTable[i][1] then
				if i <= maxEntries then 
					rVal = "In high scores"
					db.print(rVal)
					isIn = true
					if i == 1 then
						rVal = "Top score"
						db.print(rVal)
						isTop = true 
					end
					rank = i
					break
				end
			end
		end	
		
		if #scoreTable < maxEntries and not isIn then -- append since there are empty slots
			rVal = "early entry in hi-scores"
			db.print(rVal)
			rank = #scoreTable+1
			isIn = true
		end
	else
		isTop, isIn, rVal = false, false, "no score"
	end
	
	db.print("isTop", isTop, "isIn", isIn, "message", rVal, "rank", rank)
	return isTop, isIn, rVal, rank, gameTime

end

function submitName(amount, name)
	local isTop = false
	local isIn = false
	local rVal = "not in high scores"	

	if #scoreTable == 0 then
		db.print("submitName:", amount, name)
		table.insert(scoreTable, { amount, name })	
		globals.updateHighScores(scoreTable)
		return true, true, "First entry in hi-scores"
	
	elseif #scoreTable < maxEntries then		
		rVal = "Early entry in hi-scores"
	end
	
	for i = 1, #scoreTable do
		db.print(name, amount, scoreTable[i][1])
		if amount > scoreTable[i][1] then
			if i <= maxEntries then 
				isIn = true
				if i == 1 then
					isTop = true 
				end
				table.insert(scoreTable, i, { amount, name })
				break
			end
		end
	end	
	
	if #scoreTable < maxEntries and not isIn then -- append since there are empty slots
		table.insert(scoreTable, { amount, name })
		isIn = true
	end
	
	--
	-- Trim back to maxEntries items
	--
	for i = #scoreTable, (maxEntries+1), -1 do
		table.remove(scoreTable)
	end	
	
	db.print("scoreTable length", #scoreTable)
	
	if isIn then globals.updateHighScores(scoreTable) end
	
	return isTop, isIn, rVal
end

function submit(amount)
	local isTop = false
	local isIn = false
	local rVal		

	if #scoreTable == 0 then
		table.insert(scoreTable, { amount, globals.getCurrentPlayer() })	
		globals.updateHighScores(scoreTable)
		return true, true, "First entry in hi-scores"
	elseif #scoreTable < maxEntries then		
		rVal = "Early entry in hi-scores"
	end
	
	for i = 1, #scoreTable do

		if amount > scoreTable[i][1] then
			if i <= maxEntries then 
				isIn = true
				if i == 1 then
					isTop = true 
				end
				table.insert(scoreTable, i, { amount, globals.getCurrentPlayer() })
				break
			end
		end
	end	
	
	if #scoreTable < maxEntries and not isIn then -- append since there are empty slots
		table.insert(scoreTable, { amount, globals.getCurrentPlayer() })
		isIn = true
	end
	
	--
	-- Trim back to maxEntries items
	--
	for i = #scoreTable, (maxEntries+1), -1 do
		table.remove(scoreTable)
	end	
	
	db.print("scoreTable length", #scoreTable)
	
	if isIn then globals.updateHighScores(scoreTable) end
	
	return isTop, isIn, rVal
end
