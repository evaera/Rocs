-- local inspect = require(script.Parent.Parent.Inspect).inspect

local I = require(script.Parent.Parent.Types)
local Util = require(script.Parent.Parent.Util)
local Aggregate = require(script.Parent.Aggregate)
local Constants = require(script.Parent.Parent.Constants)

local AggregateCollection = {}
AggregateCollection.__index = AggregateCollection

function AggregateCollection.new(rocs)
	return setmetatable({
		rocs = rocs;
		_components = {};
		_entities = {};
		_aggregates = {};
	}, AggregateCollection)
end

function AggregateCollection:register(componentDefinition)
	assert(I.ComponentDefinition(componentDefinition))
	assert(self._components[componentDefinition.name] == nil, "A component with this name is already registered!")

	setmetatable(componentDefinition, Aggregate)

	componentDefinition.__index = componentDefinition
	componentDefinition.__tostring = Aggregate.__tostring
	componentDefinition.rocs = self.rocs

	componentDefinition.new = componentDefinition.new or function()
		return setmetatable({}, componentDefinition)
	end

	self._components[componentDefinition.name] = componentDefinition
	self._components[componentDefinition] = componentDefinition

	return componentDefinition
end

function AggregateCollection:construct(staticAggregate, instance)
	local aggregate = staticAggregate.new()

	assert(
		getmetatable(aggregate) == staticAggregate,
		"Metatable of constructed component aggregate must be static component aggregate"
	)

	aggregate.components = {}
	aggregate.instance = instance

	self:_dispatchLifecycle(aggregate, "initialize")

	return aggregate
end

function AggregateCollection:deconstruct(aggregate)
	-- destroy is called in removeComponent for correct timing

	local staticAggregate = getmetatable(aggregate)
	self._entities[aggregate.instance][staticAggregate] = nil

	local array = self._aggregates[staticAggregate]

	for i, v in ipairs(array) do
		if v == aggregate then
			table.remove(array, i)
			break
		end
	end

	if #array == 0 then
		self._aggregates[staticAggregate] = nil
	end

	if next(self._entities[aggregate.instance]) == nil then
		self._entities[aggregate.instance] = nil
	end

	self:removeAllComponents(aggregate)
end

function AggregateCollection:addComponent(instance, staticAggregate, scope, data, metacomponents)
	if data == nil then
		return self:removeComponent(instance, staticAggregate, scope), false
	end

	assert(Util.runEntityCheck(staticAggregate, instance))

	if self._entities[instance] == nil then
		self._entities[instance] = {}
	end

	if self._aggregates[staticAggregate] == nil then
		self._aggregates[staticAggregate] = {}
	end

	local aggregate = self._entities[instance][staticAggregate]
	local isNew = false

	if aggregate == nil then
		isNew = true
		aggregate = self:construct(staticAggregate, instance)
		self._entities[instance][staticAggregate] = aggregate

		table.insert(self._aggregates[staticAggregate], aggregate)
	end

	aggregate.components[scope] = data

	self:_dispatchComponentChange(aggregate)

	local pendingParentUpdated = {}

	if isNew and staticAggregate.components then
		for componentResolvable, metacomponentData in pairs(staticAggregate.components) do
			local metacomponentStaticAggregate = self:getStatic(componentResolvable)

			local metacomponentAggregate = self:addComponent(
				aggregate,
				metacomponentStaticAggregate,
				Constants.SCOPE_BASE,
				metacomponentData
			)

			pendingParentUpdated[metacomponentAggregate] = true
		end
	end

	if metacomponents then
		for componentResolvable, metacomponentData in pairs(metacomponents) do
			local metacomponentStaticAggregate = self:getStatic(componentResolvable)

			local metacomponentAggregate, wasNew = self:addComponent(
				aggregate,
				metacomponentStaticAggregate,
				scope,
				metacomponentData
			)

			if wasNew then
				pendingParentUpdated[metacomponentAggregate] = true
			end
		end
	end

	-- De-duplicate onParentUpdated calls in case both tables have same
	for metacomponentAggregate in pairs(pendingParentUpdated) do
		self:_dispatchLifecycle(
			metacomponentAggregate,
			Constants.LIFECYCLE_PARENT_UPDATED
		)
	end

	return aggregate, isNew
end

function AggregateCollection:removeAllComponents(instance)
	if self._entities[instance] == nil then
		return
	end

	for _, aggregate in ipairs(self:getAll(instance)) do
		aggregate.components = {}

		self:deconstruct(aggregate)

		self:_dispatchComponentChange(aggregate)

		self:_dispatchLifecycle(aggregate, "destroy")
	end
end

function AggregateCollection:removeComponent(instance, staticAggregate, scope)
	if
		self._entities[instance] == nil
		or self._entities[instance][staticAggregate] == nil
	then
		return
	end

	local aggregate = self._entities[instance][staticAggregate]

	aggregate.components[scope] = nil

	self:_dispatchComponentChange(aggregate)

	local shouldDestroy = next(aggregate.components) == nil
	if shouldDestroy then
		self:deconstruct(aggregate)
	end

	if shouldDestroy then
		self:_dispatchLifecycle(aggregate, "destroy")
	end

	-- TODO: Should destroy be deffered to end-of-frame?
end

function AggregateCollection:getComponent(instance, staticAggregate, scope)
	if
		self._entities[instance] == nil
		or self._entities[instance][staticAggregate] == nil
	then
		return
	end

	return self._entities[instance][staticAggregate].components[scope]
end

function AggregateCollection:getAll(instance)
	local aggregates = {}

	if self._entities[instance] ~= nil then
		for _, aggregate in pairs(self._entities[instance]) do
			table.insert(aggregates, aggregate)
		end
	end

	return aggregates
end

function AggregateCollection:get(instance, staticAggregate)
	return
		self._entities[instance]
		and self._entities[instance][staticAggregate]
end

function AggregateCollection:getStatic(componentResolvable)
	return
		self:resolve(componentResolvable)
		or error(("Cannot resolve component %s"):format(componentResolvable))
end

function AggregateCollection:resolve(componentResolvable)
	return self._components[componentResolvable]
		or (
			type(componentResolvable) == "table"
			and getmetatable(componentResolvable) == Aggregate
			and componentResolvable
		)
end

function AggregateCollection:reduce(aggregate)
	if next(aggregate.components) == nil then
		return
	end

	local values = { aggregate.components[Constants.SCOPE_REMOTE] }
	table.insert(values, aggregate.components[Constants.SCOPE_BASE])

	for name, component in pairs(aggregate.components) do
		if Constants.RESERVED_SCOPES[name] == nil then
			table.insert(values, component)
		end
	end

	return Util.runReducer(getmetatable(aggregate), values, self.rocs.reducers.default)
end

function AggregateCollection:_dispatchLifecycle(aggregate, stage)
	aggregate:dispatch(stage)

	self.rocs:_dispatchLifecycle(aggregate, stage)
end

function AggregateCollection:_dispatchComponentChange(aggregate)
	local lastData = aggregate.data
	local newData = self:reduce(aggregate)

	aggregate.data = newData
	aggregate.lastData = lastData

	if lastData == nil and newData ~= nil then
		self:_dispatchLifecycle(aggregate, Constants.LIFECYCLE_ADDED)
	end

	local staticAggregate = getmetatable(aggregate)

	if (staticAggregate.shouldUpdate or self.rocs.comparators.default)(newData, lastData) then
		self:_dispatchLifecycle(aggregate, Constants.LIFECYCLE_UPDATED)

		local childAggregates = self:getAll(aggregate)
		for _, childAggregate in ipairs(childAggregates) do
			self:_dispatchLifecycle(
				childAggregate,
				Constants.LIFECYCLE_PARENT_UPDATED
			)
		end
	end

	if newData == nil then
		self:_dispatchLifecycle(aggregate, Constants.LIFECYCLE_REMOVED)
	end

	aggregate.lastData = nil
end

return AggregateCollection
