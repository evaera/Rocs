local AllSelector = require(script.Parent.AllSelector)
local ComponentSelector = require(script.Parent.ComponentSelector)
local Util = require(script.Parent.Selectors.Util)

local intervalSignal = game:GetService("RunService").Stepped

local System = setmetatable({}, AllSelector)
System.__index = System

-- TODO: look into logic of aggregate/component events

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

	local self = setmetatable(base or AllSelector.new(rocs, ...), System)

	self._entities = {} -- keeping track of what entities are in system
						-- self._lookup: [instance] = entity

	self._events = {} -- {Event = RbxScriptSignal, Hook = function, Connection = nil/RbxScriptConnection}
	self._intervals = {} -- {Interval = num, Hook = function, LastInvoke = tick()}
	self._intervalConnection = nil

	self._hooks.onComponentAdded = {}
	self._hooks.onComponentRemoved = {}
	self._hooks.onComponentUpdated = {}
	self._hooks.onComponentParentUpdated = {}

	self._scope = scope

	return self
end

function System:_stop()
	for _, entry in pairs(self._events) do
		if entry.connection then
			entry.connection:Disconnect()
			entry.connection = nil
		end
	end

	if self._intervalConnection then
		self._intervalConnection:Disconnect()
		self._intervalConnection = nil
	end
end

function System:_start()
	for _, entry in pairs(self.events) do
		if not entry.connection then
			entry.connection = entry.event:Connect(entry.hook)
		end
	end

	if not self._intervalConnection then
		self._intervalConnection = intervalSignal:Connect(
			function()
				for _, interval in pairs(self._intervals) do
					local lastInvoke = interval.lastInvoke
					local timestamp = tick()
					if not lastInvoke then
						interval.lastInvoke = timestamp
						interval.hook(0)
					elseif timestamp - lastInvoke >= interval.interval then
						interval.lastInvoke = timestamp
						interval.hook(timestamp - lastInvoke)
					end
				end
			end
		)
	end
end

function System:_listen() -- override
	for _, selector in pairs(self._selectors) do
		selector:onAdded(
			function(aggregate)
				local instance = aggregate.instance
				if self:check(instance, selector) then
					if not self._lookup[instance] then
						local entity = self._rocs:getEntity(instance, self._scope)
						table.insert(self._entities, entity)
						self._lookup[instance] = entity
						if #self._entities == 1 then
							self:_start()
						end
						self:_trigger("onAdded", entity)
					end
					self:_trigger("onComponentAdded", aggregate)
				end
			end
		)

		selector:onRemoved(
			function(aggregate)
				local instance = aggregate.instance
				if self._lookup[instance] then
					if not self:check(instance) then
						local entity = self._lookup[instance]
						self._lookup[instance] = nil
						for key, value in pairs(self._entities) do
							if value == entity then
								table.remove(self._entities, key)
								break
							end
						end
						if #self._entities == 0 then
							self:_stop()
						end
						self:_trigger("onRemoved", entity)
					end
					self:_trigger("onComponentRemoved", aggregate)
				end
			end
		)

		-- TODO: is this right?
		selector:onUpdated(
			function(aggregate)
				local entity = self._lookup[aggregate.instance]
				if entity then
					self:_trigger("onUpdated", entity)
					self:_trigger("onComponentUpdated", aggregate)
				end
			end
		)

		-- TODO: is this right?
		selector:onParentUpdated(
			function(aggregate)
				local entity = self._lookup[aggregate.instance]
				if entity then
					self:_trigger("onParentUpdated", entity)
					self:_trigger("onComponentParentUpdated", aggregate)
				end
			end
		)
	end
end

function System:setup() -- override
	if self._ready then
		return
	end
	self._ready = true

	self:_listen()

	for _, selector in pairs(self._selectors) do
		selector:setup()
	end

	for _, instance in pairs(self:instances()) do
		local entity = self._rocs:getEntity(instance, self._scope)
		table.insert(self._entities, entity)
		self._lookup[instance] = entity
	end

	if #self._entities > 0 then
		self:_start()
	end

	return self
end

function System:catchup()
	for _, entity in pairs(self._entities) do
		self:_trigger("onAdded", entity)
	end
	return self
end

function System:onInterval(interval, hook)
	table.insert(self._intervals, {
		interval = interval,
		hook = hook
	})

	if #self._entities > 0 then
		self:_start()
	end

	return self
end

function System:onEvent(event, hook)
	table.insert(self._events, {
		event = event,
		hook = hook
	})

	if #self._entities > 0 then
		self:_start()
	end

	return self
end

function System:get()
	return self._entities -- TODO: doc that user should not modify
end

function System:onComponentAdded(hook)
	table.insert(self._hooks.onComponentAdded, hook)
	return self
end

function System:onComponentRemoved(hook)
	table.insert(self._hooks.onComponentRemoved, hook)
	return self
end

function System:onComponentUpdated(hook)
	table.insert(self._hooks.onComponentUpdated, hook)
	return self
end

function System:onComponentParentUpdated(hook)
	table.insert(self._hooks.onComponentParentUpdated, hook)
	return self
end

return System
