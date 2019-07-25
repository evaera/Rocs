local AllSelector = require(script.Parent.AllSelector)
local Util = require(script.Parent.Util)
local ComponentSelector = require(script.Parent.ComponentSelector)

local RunService = game:GetService("RunService")

local System = setmetatable({}, AllSelector)
System.__index = System

function System.new(rocs, ...)
	local args = {...}

	local base
	if #args == 1 then
		if Util.inheritsBase(args[1]) then
			base = args[1]
		elseif type(args[1]) == "string" then
			base = ComponentSelector.new(rocs, args[1])
		end
	end

	local self = setmetatable(base or AllSelector.new(rocs, ...), AllSelector)

	self.entities = {} -- keeping track of what entities are in system
	self.lookup = {}

	self.events = {} -- {Event = RbxScriptSignal, Hook = function, Connection = nil/RbxScriptConnection}
	self.intervals = {} -- {Interval = num, Hook = function, LastInvoke = tick()}
	self.intervalConnection = nil

	return self
end

function System:_stop()
	for _, entry in pairs(self.events) do
		if entry.Connection then
			entry.Connection:Disconnect()
			entry.Connection = nil
		end
	end

	if self.intervalConnection then
		self.intervalConnection:Disconnect()
		self.intervalConnection = nil
	end
end

function System:_start()
	for _, entry in pairs(self.events) do
		if not entry.Connection then
			entry.Connection = entry.Event:Connect(entry.Hook)
		end
	end

	if not self.intervalConnection then
		self.intervalConnection = RunService.Stepped:Connect(
			function()
				for _, interval in pairs(self.intervals) do
					local lastInvoke = interval.LastInvoke
					local timestamp = tick()
					if not lastInvoke then
						interval.LastInvoke = timestamp
						interval.Hook(0)
					elseif timestamp - lastInvoke >= interval.Interval then
						interval.LastInvoke = timestamp
						interval.Hook(timestamp - lastInvoke)
					end
				end
			end
		)
	end
end

function System:setup()
	if self._ready then
		return
	end
	self._ready = true

	self.entities = getmetatable(self).get(self)
	for _, entity in (self.entities) do
		self.lookup[entity] = true
	end

	for _, selector in pairs(self.selectors) do
		selector:setup()

		selector:onAdded(
			function(entity, ...)
				if not self.lookup[entity] and self:check(entity) then
					table.insert(self.entities, entity)
					self.lookup[entity] = true
					if #self.entities == 1 then
						self:_start()
					end
					self:_trigger("onAdded", entity, ...)
				end
			end
		)

		selector:onRemoved(
			function(entity, ...)
				if self.lookup[entity] then
					for key, value in pairs(self.entities) do
						if entity == value then
							table.remove(self.entities, key)
							break
						end
					end
					self.lookup[entity] = nil
					if #self.entities == 0 then
						self:_stop()
					end
					self:_trigger("onRemoved", entity, ...)
				end
			end
		)

		selector:onChanged(
			function(entity, ...)
				if self.lookup[entity] then
					self:_trigger("onChanged", entity, ...)
				end
			end
		)

		selector:onParentChanged(
			function(entity, ...)
				if self.lookup[entity] then
					self:_trigger("onParentChanged", entity, ...)
				end
			end
		)
	end

	return self
end

function System:onInterval(interval, hook)
	table.insert(self.intervals, {
		Interval = interval,
		Hook = hook
	})

	if #self.entities > 0 then
		self:_start()
	end
end

function System:onEvent(event, hook)
	table.insert(self.events, {
		Event = event,
		Hook = hook
	})

	if #self.entities > 0 then
		self:_start()
	end
end

function System:get()
	return self.entities
end

return System
