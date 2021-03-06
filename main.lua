local inspect = require("include.inspect")		--https://github.com/kikito/inspect.lua
local button = require("button") 				--My own script available in the github you're probably reading right now.

function touching(a, b)
	if a.x + a.w >= b.x and a.x <= b.x + b.w and a.y + a.h >= b.y and a.y <= b.y + b.h then
		return true
	else
		return false
	end
end

function copy(prototype)			--shallow copy
	local cp = {}
	for key, value in pairs(prototype) do
		cp[key] = value
	end
	return cp
end

ParentAgent = {agents = {}}
ParentAgent.__index = ParentAgent
ParentAgent.moveto = function(self, target, dt) --https://love2d.org/forums/viewtopic.php?t=79168
		-- find the agent's "step" distance for this frame
		local step = self.speed * dt

		-- find the distance to target
		local distx, disty = target.x - self.x, target.y - self.y
		local dist = math.sqrt(distx*distx + disty*disty)

		if dist <= step then
			-- we have arrived
			self.x = target.x
			self.y = target.y
			self.waypoint = self.waypoint + 1
			return true
		end

		  -- get the normalized vector between the target and self
		local nx, ny = distx/dist, disty/dist

		  -- find the movement vector for this frame
		local dx, dy = nx * step, ny * step

		  -- keep moving
		self.x = self.x + dx
		self.y = self.y + dy
		return false
end

function newAgent(x, y, prototype)
	local agent = {}
	agent.x = x
	agent.y = y
	agent.waypoint = 1
	agent.speed = prototype.speed or 400	
	agent.w = prototype.width or 50
	agent.h = prototype.height or 50
	agent.health = prototype.health or 10
	agent.color = prototype.color or {1, 1, 1}
	numenems = numenems + 1
	setmetatable(agent, ParentAgent)
	table.insert(ParentAgent.agents, agent)
	agent.id = numenems
end

protos = {																	--agent prototypes
	{speed = 300, width = 50, height = 50, health = 50, color = {1, 0, 0}},	--standard, red bloon equivalent.
	{speed = 200, width = 40, height = 40, health = 60, color = {0, 0, 1}},
	{speed = 100, width = 40, height = 40, health = 80, color = {0, 0, 1}}
}

tprotos = {
	{w = 30, h = 30, range = 1, dartproperties = {speed = 500, dmg = 60, lifetime = 1}, firespeed = 120},
	{w = 40, h = 40, range = 2, dartproperties = {speed = 500, dmg = 60, lifetime = 1}, firespeed = 30}
}

ParentTower = {towers = {}}
ParentTower.__index = ParentTower
ParentTower.fire = function(self, tx, ty)
	local dart = {}
	dart.x = self.x
	dart.y = self.y
	dart.tx, dart.ty = tx, ty --target x, y
	dart.w = 5
	dart.h = 10
	dart.speed = self.dartproperties.speed
	dart.dmg = self.dartproperties.dmg
	dart.lifetime = self.dartproperties.lifetime
	dart.vectors = {x = "", y = ""}
	local distx, disty = dart.tx - self.x, dart.ty - self.y
	local dist = math.sqrt(distx*distx + disty*disty)
	dart.vectors.x, dart.vectors.y = distx/dist, disty/dist
	table.insert(darts, dart)
end
ParentTower.check = function(self)
	if self.tick <= 0 then
		for _,v in pairs(agents) do
			if (v.x + v.w >= self.range.x and v.x <= self.range.x + self.range.w) and v.y + v.w >= self.range.y and v.y <= self.range.y + self.range.h then
				self:fire(v.x, v.y)
				self.tick = self.fspeed
				break
			end
		end
	end
end
ParentTower.drawrange = function(self)
	love.graphics.rectangle("line", self.range.x, self.range.y, self.range.w, self.range.h)
end
ParentTower.click = function(self)
	menumode = "upgrade"
	to_upgrade = self
	print(tprotos[1].dartproperties, self.dartproperties)
end
ParentTower.ranges = function(self, r)
	local rgs =	{
	{x = self.x - (self.w / 4), y = 0, w = self.w + (self.w / 2), h = 800},
	{x = self.x - 40, y = self.y - 40, w = 120, h = 120}
	}
	return rgs[r]
end
ParentTower.uprange = function(self)
	local discrep = ((self.range.w * self.multiplier) - self.range.w) / 2
	self.range = {
		w = self.range.w * self.multiplier,
		h = self.range.h * self.multiplier,
		x = self.range.x - discrep,
		y = self.range.y - discrep
	}
end

function newTower(x, y, prototype)
	local tower = {}
	tower.x = x
	tower.y = y
	tower.w = prototype.w
	tower.h = prototype.h
	tower.dartproperties = copy(prototype.dartproperties)
	tower.fspeed = prototype.firespeed
	tower.tick = 0
	tower.multiplier = 1
	tower.range = ParentTower.ranges(tower, prototype.range)
	
	setmetatable(tower, ParentTower)
	table.insert(ParentTower.towers, tower)
end

function love.mousepressed(mx, my, btn)
	if btn == 1 then
		if cursor ~= nil then
			if my < 700 then
				newTower(mx, my, cursor)
				cursor = nil
			end
		else
			button.pressSense(mx, my)
			for i,t in ipairs(towers) do
				if touching(t, {x = mx, y = my, w = 1, h = 1}) then
					t:click()
				end
			end
		end
	end
end

function love.load()
	menumode = false
	cursor = nil
	to_upgrade = nil
	numenems = 0
	lives = 50	
	towers = ParentTower.towers	--towers on screen
	line = {}	--the line of the path
	waypoints = {}	--waypoints on current line
	agents = ParentAgent.agents	--agents on screen
	darts = {}	--darts on screen
	wstack = {} --stack of waves to actively spawn
	math.randomseed(os.time())
	for i = 0, 800, 100 do
		local wp = {x = i, y = math.random(100, 600)}
		table.insert(line, wp.x)
		table.insert(line, wp.y)
		table.insert(waypoints, wp)
	end
	print(inspect(line))
	--{A, B, C, D} --A is the agent types to spawn, B is the number of them to spawn, C is the frames between spawns, D is the frames before the next set.
	waves = {
		{{1, 10, 60, 120}, {2, 5, 60, 60}, {1, 3, 10, 20}, {1, 3, 10, 60}},
		{{3, 10000, 60, 0}}
	}
	wstack = waves[1]
	binit()
end

t1, t2, t3, as, newmax = 0, 0, 0, 0, 0	--t1 is nothing, t2 is time between "clusters" of similar agents, t3 is the time between individual agent spawns. as is agents spawned.
function love.update(dt)
	for ai,agent in ipairs(agents) do
		if waypoints[agent.waypoint] == nil then
			table.remove(agents, ai)
			lives = lives - 1
		else
			agent:moveto(waypoints[agent.waypoint], dt)
			for di,d in ipairs(darts) do
				if touching(agent, d) then
					agent.health = agent.health - d.dmg
					if agent.health <= 0 then
						table.remove(agents, ai)
					end
					d.lifetime = d.lifetime - 1
					if d.lifetime == 0 then
						table.remove(darts, di)
					end
				end
			end
		end
	end
	for _,tower in pairs(towers) do
		tower.tick = tower.tick - 1
		tower:check()
	end
	for d,dart in ipairs(darts) do
		dart.x = dart.x + dart.vectors.x * dart.speed * dt
		dart.y = dart.y + dart.vectors.y * dart.speed * dt
		if dart.x < 0 or dart.x > 800 or dart.y > 800 or dart.y < 0 then
			table.remove(darts, d)
		end
	end
	if t2 >= newmax then
		local subwave = waves[1][1]
		if subwave ~=nil and subwave[1] ~= nil then
			local p = subwave[1]
			t3 = t3 + 1
			if t3 >= subwave[3] then
				newAgent(line[1], line[2], protos[p])
				as = as + 1
				t3 = 0
				if as >= subwave[2] then
					newmax = subwave[4]
					t2 = 0
					as = 0
					table.remove(waves[1], 1)
				end
			end
		else
			--the wave has stopped spawning, the way this is set up so far, it immediately starts the next wave. Todo: Make sure wave can only be counted as "ended" once all bloons are gone, add button to start next wave.
			table.remove(waves, 1)
		end
	end
	t1 = t1 + 1
	t2 = t2 + 1
	if cursor ~= nil then
		cursor.x = love.mouse.getX()
		cursor.y = love.mouse.getY()
	end
end

function love.keypressed(key)
	if key == "escape" then
		cursor = nil
		to_upgrade = nil
		menumode = "purchase"
	end
end

function printstats(s, x, y)
	local dp = s.dartproperties
	local str = "Fire-delay = "..s.fspeed.."frames, dartspeed = "..dp.speed..", dartlifetime = "..dp.lifetime
	love.graphics.print(str, x, y)
end

function love.draw()
	love.graphics.setLineStyle("smooth")
	love.graphics.setLineWidth(15)
	love.graphics.line(line)
	love.graphics.setColor(1, 1, 1)
	if menumode == "upgrade" then printstats(to_upgrade, 0, 675) end
	love.graphics.rectangle("fill", 0, 700, 800, 200)						--button shelf
	for _,agent in pairs(agents) do
		love.graphics.setColor(agent.color)
		love.graphics.rectangle("fill", agent.x, agent.y, agent.w, agent.h)
	end
	love.graphics.setColor(1, 1, 1)
	love.graphics.setLineWidth(1)
	for _,tower in ipairs(towers) do
		if to_upgrade == tower then love.graphics.setColor(1, 0, 0) end
		love.graphics.rectangle("line", tower.x, tower.y, tower.w, tower.h)
		tower:drawrange()
		love.graphics.setColor(1, 1, 1)
	end
	for _,dart in ipairs(darts) do
		love.graphics.circle("fill", dart.x, dart.y, dart.w)
	end
	for _,b in ipairs(button.buttons) do
		b:draw()
	end
	love.graphics.print(tostring(lives), 750, 750)
	if cursor ~= nil then
		love.graphics.rectangle("line", cursor.x, cursor.y, cursor.w, cursor.h)
	end
end

--[[====================================================================
Button construction via button.lua. Also contains callbacks those buttons rely on. I leave this down here for code neatness, and I leave the code in the function "binit" so I can wait until love.load completes to call it.
I really REALLY wanted to just leave the callback functions easily dropped in but I can't pass parameters through a function being passed as a parameter so... yikes!
====================================================================]]--
function binit()
	function prepTower(topro) --tower prototype
		cursor = topro
		cursor.x, cursor.y = 0, 0
	end

	t1p = button.new("1", 0, 700, 100, 100, {0, 1, 0, 0.5}, function() return menumode == "purchase" end)
	t1p.onPress = function()
		prepTower(tprotos[1])
	end
	redb = button.new("2", 700, 700, 100, 100, {1, 0, 0, 1}, function() return true end)
	redb.onPress = function()
		print("PRESSED RED B")
		if menumode then
			menumode = false
		else
			menumode = "purchase"
		end
		print(menumode)
	end
	t2p = button.new("3", 100, 700, 100, 100, {0, 1, 0, 1}, function() return menumode == "purchase" end)
	t2p.onPress = function()
		prepTower(tprotos[2])
	end
	upgradeFspeed = button.new("Upgrade firing speed", 0, 700, 100, 100, {1, 1, 0, 1}, function() return menumode == "upgrade" end)
	upgradeFspeed.onPress = function()
		to_upgrade.fspeed = to_upgrade.fspeed - 5
	end
	upgradeDspeed = button.new("Upgrade dart speed", 100, 700, 100, 100, {1, 1, 0, 1}, function() return menumode == "upgrade" end)
	upgradeDspeed.onPress = function() 
		to_upgrade.dartproperties.speed = to_upgrade.dartproperties.speed + 50 
	end
	upgradeDlifetime = button.new("+1 Hit before dart disintegrates", 200, 700, 100, 100, {1, 1, 0, 1}, function() return menumode == "upgrade" end)
	upgradeDlifetime.onPress = function()
		to_upgrade.dartproperties.lifetime = to_upgrade.dartproperties.lifetime + 1 
	end
	upgradeRange = button.new("Upgrade range", 300, 700, 100, 100, {0, 1, 1}, function() return menumode == "upgrade" end)
	upgradeRange.onPress = function()
		to_upgrade.multiplier = to_upgrade.multiplier + 0.1
		to_upgrade:uprange()
		print(inspect(to_upgrade.range))
	end
end