-- Mark H Carolan
--
-- Stroople project
-- © 2010 Mark H Carolan, Gregory S Hooper

module(..., package.seeall)

local isSimulator = system.getInfo("environment") == "simulator" and true or false

local info = print

function print(...)		
	if isSimulator then
		local params = {...}
		local txt = ""
		for i = 1, #params do	
			local v = params[i]		
			local t = type(v)
				
			if t == "string" or t == "number" then
				txt = txt .. v .. " "
			elseif t == "boolean" then
				v = v and "true " or "false "
				txt = txt .. v
			elseif t == "table" then
				info("{")
				for k, v in pairs(v) do
					info("    ", k, v)
				end
				info("}")
			else				
				txt = txt .. "[" .. t .. "] "
			end
		end
		info(txt)
	end
end
