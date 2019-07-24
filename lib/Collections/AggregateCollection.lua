local CollectionService = game:GetService("CollectionService")
-- local inspect = require(script.Parent.Parent.Inspect).inspect

local I = require(script.Parent.Parent.Interfaces)
local Util = require(script.Parent.Parent.Util)
local Constants = require(script.Parent.Parent.Constants)

local AggregateCollection = {}
AggregateCollection.__index = AggregateCollection

function AggregateCollection.new(rocs)
	return setmetatable({
		rocs = rocs;
		_components = {};
		_entities = {};
		_aggregates = {};
		_tags = {};
	}, AggregateCollection)
end

local function makeComponentSetter(collection, staticAggregate)
	return function (self, ...)
		local path = {...}
		local value = table.remove(path, #path)

		assert(value ~= nil, "Must provide a value to set")

		if value == Constants.None then
			value = nil
		end

		local currentValue = collection:getComponent(self.instance, staticAggregate, Constants.SCOPE_BASE)

		while #path > 1 do
			currentValue = currentValue[table.remove(path, 1)]
		end

		if path[1] then
			currentValue[path[1]] = value
		else
			currentValue = value
		end

		return collection:addComponent(self.instance, staticAggregate, Constants.SCOPE_BASE, currentValue)
	end
end

local function componentGetProperty(component, ...)
	local object = component.data

	for _, field in ipairs({...}) do
		object = object[field]

		if object == nil then
			return
		end
	end

	return object
end

function AggregateCollection:register(componentDefinition)
	assert(I.ComponentDefinition(componentDefinition))

	componentDefinition._address = tostring(componentDefinition) --! No
	componentDefinition.__tostring = Util.makeToString("Aggregate")
	componentDefinition.__index = componentDefinition.__index or componentDefinition

	componentDefinition.__index.get = componentGetProperty
	componentDefinition.__index.set = makeComponentSetter(self, componentDefinition)

	componentDefinition.new = componentDefinition.new or function()
		return setmetatable({}, componentDefinition)
	end

	self._components[componentDefinition.name] = componentDefinition
	self._components[componentDefinition] = componentDefinition

	if componentDefinition.tag then
		self:listenForTag(componentDefinition.tag, componentDefinition)
	end

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

	if aggregate.initialize then
		aggregate:initialize()
	end

	return aggregate
end

function AggregateCollection:deconstruct(aggregate)
	-- destroy is called in removeComponent for correct timing

	local staticAggregate = getmetatable(aggregate)
	self._entities[aggregate.instance][staticAggregate] = nil

	local array = self._aggregates[staticAggregate]

	for i = 1, #array do
		if array[i] == aggregate then
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

	self.rocs:_dispatchComponentChange(aggregate)

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
				self.rocs:_dispatchLifecycle(
					metacomponentAggregate,
					Constants.LIFECYCLE_PARENT_UPDATED
				)
			end
		end
	end

	return aggregate, isNew
end

function AggregateCollection:removeAllComponents(instance)
	if self._entities[instance] == nil then
		return
	end

	for _, aggregate in ipairs(self:getAll(instance)) do
		self:deconstruct(aggregate)

		self.rocs:_dispatchComponentChange(aggregate)

		if aggregate.destroy then
			aggregate:destroy()
		end
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

	local shouldDestroy = next(aggregate.components) == nil
	if shouldDestroy then
		self:deconstruct(aggregate)
	end

	self.rocs:_dispatchComponentChange(
		aggregate
	)

	if shouldDestroy and aggregate.destroy then
		aggregate:destroy()
	end
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
		self._components[componentResolvable]
		or (type(componentResolvable) == "table" and componentResolvable)
		or error(("Cannot resolve component %s"):format(componentResolvable))
end

function AggregateCollection:reduce(aggregate)
	local values = { aggregate.components[Constants.SCOPE_REMOTE] }
	table.insert(values, aggregate.components[Constants.SCOPE_BASE])

	for name, component in pairs(aggregate.components) do
		if Constants.RESERVED_SCOPES[name] == nil then
			table.insert(values, component)
		end
	end

	return Util.runReducer(getmetatable(aggregate), values, self.rocs.reducers.default)
end

function AggregateCollection:listenForTag(tag, staticAggregate)
	assert(self._tags[tag] == nil, ("Tag %q is already in use!"):format(tag))
	self._tags[tag] = true

	local function addFromTag(instance)
		local data = {}
		if
			instance:FindFirstChild(staticAggregate.name)
			and instance[staticAggregate.name].ClassName == "ModuleScript"
		then
			data = require(instance[staticAggregate.name])
		end

		self:_addComponent(instance, staticAggregate, Constants.SCOPE_BASE, data)
	end

	local function removeFromTag(instance)
		self:_removeComponent(instance, staticAggregate, Constants.SCOPE_BASE)
	end

	CollectionService:GetInstanceRemovedSignal(tag):Connect(removeFromTag)
	CollectionService:GetInstanceAddedSignal(tag):Connect(addFromTag)
	for _, instance in ipairs(CollectionService:GetTagged(tag)) do
		addFromTag(instance)
	end
end

return AggregateCollection
