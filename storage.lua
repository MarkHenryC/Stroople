-- Mark H Carolan
--
-- Stroople project
-- © 2010 Mark H Carolan, Gregory S Hooper

module(..., package.seeall)

local delimiter = ":"

function loadPrefs(name)
	local prefsTable = {}
	local path = system.pathForFile( name..".txt", system.DocumentsDirectory )
	local file = io.open( path, "r" )
	if file then -- nil if no file found
		while true do
		   	local line = file:read( "*l" )
			if not line then break end		
		   	-- split into two values here
		   	for k, v in string.gmatch(line, "(%w+)" .. delimiter .. "([%w%s]+)") do
		   		db.print("loading", k, v)
				prefsTable[k] = v
		   	end
		end
		io.close(file)
	end
	return prefsTable
end

function loadList(name)
	local list = {}
	local path = system.pathForFile( name..".txt", system.DocumentsDirectory )
	local file = io.open( path, "r" )
	if file then -- nil if no file found
		while true do
		   	local line = file:read( "*l" )
			if not line then break end
			print("loading", line)
			list[#list+1] = line
		end
		io.close(file)
	end
	return list
end
	
function savePrefs(prefsTable, name)
	local path = system.pathForFile( name..".txt", system.DocumentsDirectory )	
	local file = io.open( path, "w+" )
	if file then
		for k,v in pairs(prefsTable) do 
			print("saving", k, v)
			file:write(k .. delimiter .. v .. "\n") 
		end
		io.close(file)
	end
end

function saveList(list, name)
	local path = system.pathForFile( name..".txt", system.DocumentsDirectory )	
	local file = io.open( path, "w+" )
	if file then
		for i = 1, #list do
			print("saving", list[i])
			file:write( list[i] .. "\n") 
		end
		io.close(file)
	end
end