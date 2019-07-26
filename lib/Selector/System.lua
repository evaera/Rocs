local AllSelector = require(script.Parent.AllSelector)
local Util = require(script.Parent.Util)
local ComponentSelector = require(script.Parent.ComponentSelector)

local RunService = game:GetService("RunService")

local System = setmetatable({}, AllSelector)
System.__index = System

function System.new(rocs, scope, ...)
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

	self.scope = scope

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

	for _, instance in (self:instances()) do
		local entity = self._rocs:getEntity(instance, self.scope)
		table.insert(self.entities, entity)
		self.lookup[instance] = entity
	end

	if #self.entities > 0 then
		self:_start()
	end

	for _, selector in pairs(self.selectors) do
		selector:setup()

		selector:onAdded(
			function(aggregate)
				local instance = aggregate.instance
				if self:check(instance) then
					if not self.lookup[instance] then
						local entity = self._rocs:getEntity(instance, self.scope)
						table.insert(self.entities, entity)
						self.lookup[instance] = entity
						if #self.entities == 1 then
							self:_start()
						end
						self:_trigger("onAdded", entity, aggregate)
					end
					self:_trigger("onComponentAdded", aggregate)
				end
			end
		)

		selector:onRemoved(
			function(aggregate)
				local instance = aggregate.instance
				if self.lookup[instance] then
					if not self:check(instance) then
						local entity = self.lookup[instance]
						self.lookup[instance] = nil
						for key, value in pairs(self.entities) do
							if value == entity then
								table.remove(self.entities, key)
								break
							end
						end
						if #self.entities == 0 then
							self:_stop()
						end
						self:_trigger("onRemoved", entity, aggregate)
					end
					self:_trigger("onComponentRemoved", aggregate)
				end
			end
		)

		-- TODO: is this right?
		selector:onUpdated(
			function(aggregate)
				local instance = aggregate.instance
				if self.lookup[instance] then
					self:_trigger("onUpdated", self.lookup[instance], aggregate)
					self:_trigger("onComponentChanged", aggregate)
				end
			end
		)

		-- TODO: is this right?
		selector:onParentChanged(
			function(aggregate)
				local instance = aggregate.instance
				if self.lookup[instance] then
					self:_trigger("onParentChanged", self.lookup[instance], aggregate)
					self:_trigger("onComponentParentChanged", aggregate)
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
