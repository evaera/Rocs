local AllSelector = require(script.Parent.Selectors.AllSelector)
local LayerSelector = require(script.Parent.Selectors.LayerSelector)
local Util = require(script.Parent.Selectors.Util)

local intervalSignal = game:GetService("RunService").Stepped

local System = setmetatable({}, AllSelector)
System.__index = System

-- TODO: look into logic of lens/component events

function System.new(rocs, scope, ...)
	local args = {...}

	local base
	if #args == 1 then
		if Util.inheritsBase(args[1]) then
			base = args[1]
		elseif type(args[1]) == "string" then
			base = LayerSelector.new(rocs, args[1])
		end
	end

	local self = setmetatable(base or AllSelector.new(rocs, ...), System)

	self._entities = {} -- keeping track of what entities are in system
						-- self._lookup: [instance] = pipeline

	self._events = {} -- {Event = RbxScriptSignal, Hook = function, Connection = nil/RbxScriptConnection}
	self._intervals = {} -- {Interval = num, Hook = function, LastInvoke = tick()}
	self._intervalConnection = nil

	self._hooks.onLayerAdded = {}
	self._hooks.onLayerRemoved = {}
	self._hooks.onLayerUpdated = {}
	self._hooks.onLayerParentUpdated = {}

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
			function(lens)
				local instance = lens.instance
				if self:check(instance, selector) then
					if not self._lookup[instance] then
						local pipeline = self._rocs:getPipeline(instance, self._scope)
						table.insert(self._entities, pipeline)
						self._lookup[instance] = pipeline
						if #self._entities == 1 then
							self:_start()
						end
						self:_trigger("onAdded", pipeline)
					end
					self:_trigger("onLayerAdded", lens)
				end
			end
		)

		selector:onRemoved(
			function(lens)
				local instance = lens.instance
				if self._lookup[instance] then
					if not self:check(instance) then
						local pipeline = self._lookup[instance]
						self._lookup[instance] = nil
						for key, value in pairs(self._entities) do
							if value == pipeline then
								table.remove(self._entities, key)
								break
							end
						end
						if #self._entities == 0 then
							self:_stop()
						end
						self:_trigger("onRemoved", pipeline)
					end
					self:_trigger("onLayerRemoved", lens)
				end
			end
		)

		-- TODO: is this right?
		selector:onUpdated(
			function(lens)
				local pipeline = self._lookup[lens.instance]
				if pipeline then
					self:_trigger("onUpdated", pipeline)
					self:_trigger("onLayerUpdated", lens)
				end
			end
		)

		-- TODO: is this right?
		selector:onParentUpdated(
			function(lens)
				local pipeline = self._lookup[lens.instance]
				if pipeline then
					self:_trigger("onParentUpdated", pipeline)
					self:_trigger("onLayerParentUpdated", lens)
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
		local pipeline = self._rocs:getPipeline(instance, self._scope)
		table.insert(self._entities, pipeline)
		self._lookup[instance] = pipeline
	end

	if #self._entities > 0 then
		self:_start()
	end

	return self
end

function System:destroy() -- override
	if not self._ready then
		return
	end
	self._ready = nil

	for category, _ in pairs(self._hooks) do
		self._hooks[category] = {}
	end

	for _, selector in pairs(self._selectors) do
		selector:destroy()
	end

	self._entities = {}
	self._lookup = {}

	self:_stop()

	return self
end

function System:catchup()
	for _, pipeline in pairs(self._entities) do
		self:_trigger("onAdded", pipeline)
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

function System:onLayerAdded(hook)
	table.insert(self._hooks.onLayerAdded, hook)
	return self
end

function System:onLayerRemoved(hook)
	table.insert(self._hooks.onLayerRemoved, hook)
	return self
end

function System:onLayerUpdated(hook)
	table.insert(self._hooks.onLayerUpdated, hook)
	return self
end

function System:onLayerParentUpdated(hook)
	table.insert(self._hooks.onLayerParentUpdated, hook)
	return self
end

return System
