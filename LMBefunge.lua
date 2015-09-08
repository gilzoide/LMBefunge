#!/usr/bin/env lua

local mosaic = require 'mosaic'
local color = mosaic.color

-- Need a Mosaic, sorry...
if not arg[1] then
	print ('Usage: ' .. arg[0] .. ' FILE_NAME')
	os.exit (-1)
end

-- maybe called with debug mode =]
if arg[2] == 'debug' then
	debugMode = true
end

mos = assert (mosaic.io.Load (arg[1]))

-- What we need to know when interpreting befunge
y = 1
x = 0
direction = 'right'
allDirections = {
	'right',
	'left',
	'down',
	'up'
}
stack = {
	push = table.insert,
	peek = function (self) return self[#self] end,
	pop = function (self) return table.remove (self) or 0 end
}
local char
stringMode = false

function move (dir)
	if dir == 'right' then
		x = x + 1
	elseif dir == 'left' then
		x = x - 1
	elseif dir == 'down' then
		y = y + 1
	else -- up
		y = y - 1
	end

	-- check for line wrapping
	if x < 1 then
		x = mos:GetWidth ()
	elseif x > mos:GetWidth () then
		x = 1
	end
	-- check for collumn wrapping
	if y < 1 then
		y = mos:GetHeight ()
	elseif y > mos:GetHeight () then
		y = 1
	end
end

local outBuffer = {}
function output (msg)
	if not debugMode then
		io.write (msg)
	else	-- debugMode
		table.insert (outBuffer, msg)
	end
end

while true do
	move (direction)
	char = mos:GetCh (y, x)


	-- Debug Mode: print where it is and what's on stack
	if debugMode then
		-- clear screen, please
		os.execute ('clear')
		-- print debug stuff
		print ('Where: ' .. x .. 'x' .. y .. '\tchar: ' .. char .. '\tStack: [' .. table.concat (stack, ', ') .. ']')
		for i = 1, mos:GetHeight () do
			for j = 1, mos:GetWidth () do
				if i == y and j == x then
					color.Tcolor (color.NR)
					io.write (mos:GetCh (i, j))
					color.Tcolor (color.Normal)
				else
					io.write (mos:GetCh (i, j))
				end
			end
			print ()
		end
		print ('\n\nOutput\n' .. table.concat (outBuffer))
		-- wait for user input
		io.read ()
	end


	-- toggle string mode
	if char == '"' then
		stringMode = not stringMode
	-- in string mode, anything is pushed (as string)
	elseif stringMode then
		stack:push (char)
	-- exit befunge program
	elseif char == '@' then
		break
	-- digit: push it
	elseif char:match ('%d') then
		stack:push (math.tointeger (char))
	-- change directions
	elseif char == '>' then
		direction = 'right'
	elseif char == '<' then
		direction = 'left'
	elseif char == '^' then
		direction = 'up'
	elseif char == 'v' then
		direction = 'down'
	-- arithmetic operations
	elseif char == '+' then
		a = stack:pop ()
		b = stack:pop ()
		stack:push (b + a)
	elseif char == '-' then
		a = stack:pop ()
		b = stack:pop ()
		stack:push (b - a)
	elseif char == '*' then
		a = stack:pop ()
		b = stack:pop ()
		stack:push (b * a)
	elseif char == '/' then
		a = stack:pop ()
		b = stack:pop ()
		-- do a `floor` because '/' denotes a integer division
		stack:push (math.floor (b / a))
	elseif char == '%' then
		a = stack:pop ()
		b = stack:pop ()
		stack:push (b % a)
	-- logical not
	elseif char == '!' then
		a = stack:pop ()
		stack:push (a == 0 and 1 or 0)
	-- greater than
	elseif char == '`' then
		a = stack:pop ()
		b = stack:pop ()
		stack:push (b > a and 1 or 0)
	-- random direction
	elseif char == '?' then
		newDir = math.random (4)
		direction = allDirections[newDir]
	-- horizontal branch
	elseif char == '_' then
		cond = stack:pop ()
		if cond == 0 then
			direction = 'right'
		else
			direction = 'left'
		end
	-- vertical branch
	elseif char == '|' then
		cond = stack:pop ()
		if cond == 0 then
			direction = 'down'
		else
			direction = 'up'
		end
	-- duplicate value on top of stack
	elseif char == ':' then
		stack:push (stack:peek ())
	-- swap
	elseif char == '\\' then
		a = stack:pop ()
		b = stack:pop ()
		stack:push (a)
		stack:push (b)
	-- pop, discarding value
	elseif char == '$' then
		stack:pop ()
	-- print number
	elseif char == '.' then
		output (stack:pop ())
	-- print char
	elseif char == ',' then
		output (stack:pop ())
	-- jump
	elseif char == '#' then
		move (direction)
	-- put call
	elseif char == 'p' then
		local y = stack:pop ()
		local x = stack:pop ()
		v = stack:pop ()

		-- resize Mosaic if needed
		if y > mos:GetHeight () then
			mos:Resize (y, mos:GetWidth ())
		end
		if x > mos:GetWidth () then
			mos:Resize (mos:GetHeight (), x)
		end

		-- now put value in Mosaic
		mos:SetCh (y, x, v)
	-- get call
	elseif char == 'g' then
		local y = stack:pop ()
		local x = stack:pop ()
		-- check for boundaries
		if mos:OutOfBoundaries (y, x) then
			stack:push (0)
		else
			stack:push (mos:GetCh (y, x))
		end
	-- read number
	elseif char == '&' then
		stack:push (io.read ('n') or 0)
	-- read string
	elseif char == '~' then
		stack:push (io.read ('l') or 0)
	end
end
