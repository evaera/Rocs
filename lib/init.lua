local CollectionService = game:GetService("CollectionService")

local Util = require(script.Util)
local I = require(script.Interfaces)
local Entity = require(script.Entity)
local t = require(script.t)
local DependencyFactory = require(script.DependencyFactory)
local Dependency = require(script.Dependency)
local MakeReducers = require(script.Reducers)
local MakeLayers = require(script.Layers)

local METADATA_IDENTIFIER = "__rocs_metadata__"
local LIFECYCLE_ADDED = "onAdded"
local LIFECYCLE_REMOVED = "onRemoved"
local LIFECYCLE_UPDATED = "onUpdated"
local ERROR_SPECIFY_LAYER_ID = "Unable to automatically determine layer ID, please specify."
local ALL_COMPONENTS = {}

local function makeComponentPropertySetter(rocs, staticAggregate)
	return function (self, key, value)
		local currentValue = rocs:_getComponent(self.instance, staticAggregate, "base")

		currentValue[key] = value
		rocs:_addComponent(self.instance, staticAggregate, "base", currentValue)
	end
end

local function makeComponentSetter(rocs, staticAggregate)
	return function (self, key, value)
		rocs:_addComponent(self.instance, staticAggregate, "base", value)
	end
end

local Rocs = {}
Rocs.__index = Rocs

function Rocs.new(name)
	local self = setmetatable({
		_name = name or "global";
		_entities = {};
		_components = {};
		_systems = {};
		_metadata = {};
		_activeSystems = {};
		_tags = {};
		_layerComponents = setmetatable({}, {
			__mode = "kv";
		});
		_dependencies = setmetatable({}, {
			__index = function(self, k)
				self[k] = {}
				return self[k]
			end;
		});
	}, Rocs)

	self.dependencies = DependencyFactory.new(self)
	self.reducers = MakeReducers(self)
	self._layers = MakeLayers(self)

	self:registerSystem(unpack(self._layers.system))
	self:registerComponent(self._layers.component)
	self:registerMetadata(self._layers.metadata)

	return self
end

function Rocs:registerMetadata(metadataDefinition)
	assert(I.Reducible(metadataDefinition))

	self._metadata[metadataDefinition.name] = metadataDefinition
	return metadataDefinition
end

function Rocs:registerSystem(systemDefinition, dependencies)
	assert(t.tuple(I.SystemDefinition, I.SystemDependencies)(systemDefinition, dependencies))

	systemDefinition.__index = systemDefinition.__index or systemDefinition

	systemDefinition.new = systemDefinition.new or function()
		return setmetatable({}, systemDefinition)
	end

	self._systems[systemDefinition.name] = systemDefinition

	local stepHooks = {}
	for _, hook in ipairs(dependencies) do
		if stepHooks[hook.step] == nil then
			stepHooks[hook.step] = {}
		end

		table.insert(stepHooks[hook.step], hook)
	end

	for step, hooks in pairs(stepHooks) do
		local dependency = Dependency.new(self, systemDefinition, step, hooks)
		if step._dependencies == true then
			table.insert(self._dependencies[ALL_COMPONENTS], dependency)
		else
			for _, componentResolvable in ipairs(step._dependencies) do
				local staticAggregate = self:_getStaticAggregate(componentResolvable)

				table.insert(self._dependencies[staticAggregate], dependency)
			end
		end
	end

	return systemDefinition
end

function Rocs:_listenForTag(tag, staticAggregate)
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

		self:_addComponent(instance, staticAggregate, "base", data)
	end

	local function removeFromTag(instance)
		self:_removeComponent(instance, staticAggregate, "base")
	end

	CollectionService:GetInstanceRemovedSignal(tag):Connect(removeFromTag)
	CollectionService:GetInstanceAddedSignal(tag):Connect(addFromTag)
	for _, instance in ipairs(CollectionService:GetTagged(tag)) do
		addFromTag(instance)
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

function Rocs:registerComponent(componentDefinition)
	assert(I.ComponentDefinition(componentDefinition))

	componentDefinition._address = tostring(componentDefinition) --! No
	componentDefinition.__tostring = Util.makeToString("Aggregate")
	componentDefinition.__index = componentDefinition.__index or componentDefinition

	componentDefinition.__index.get = componentGetProperty
	componentDefinition.__index.set = makeComponentSetter(self, componentDefinition)
	componentDefinition.__index.setProp = makeComponentPropertySetter(self, componentDefinition)

	componentDefinition.new = componentDefinition.new or function()
		return setmetatable({}, componentDefinition)
	end

	self._components[componentDefinition.name] = componentDefinition
	self._components[componentDefinition] = componentDefinition

	if componentDefinition.tag then
		self:_listenForTag(componentDefinition.tag, componentDefinition)
	end

	return componentDefinition
end

local getEntityCheck = t.tuple(t.union(t.Instance, t.table), t.string)
function Rocs:getEntity(instance, scope)
	assert(getEntityCheck(instance, scope))

	return Entity.new(self, instance, scope)
end

function Rocs:_getStaticAggregate(componentResolvable)
	return
		self._components[componentResolvable]
		or (type(componentResolvable) == "table" and componentResolvable)
		or error(("Cannot resolve component %s"):format(componentResolvable))
end

function Rocs:_constructSystem(staticSystem)
	local system = staticSystem.new()

	assert(
		getmetatable(system) == staticSystem,
		"Metatable of constructed system must be static system"
	)

	system._consumers = 0

	if system.initialize then
		system:initialize()
	end

	return system
end

function Rocs:_deconstructSystem(staticSystem)
	local existingSystem = self._activeSystems[staticSystem]
	assert(existingSystem ~= nil, "Attempt to deconstruct non-existent system")

	if existingSystem.destroy then
		existingSystem:destroy()
	end

	self._activeSystems[staticSystem] = nil
end

function Rocs:_getSystem(staticSystem)
	local existingSystem = self._activeSystems[staticSystem]
	if existingSystem then
		existingSystem._consumers = existingSystem._consumers + 1
		return existingSystem
	end

	local newSystem = self:_constructSystem(staticSystem)
	self._activeSystems[staticSystem] = newSystem
	return newSystem
end

function Rocs:_reduceSystemConsumers(staticSystem)
	local existingSystem = self._activeSystems[staticSystem]
	assert(existingSystem ~= nil, "Attempt to reduce consumers of non-existent system")

	existingSystem._consumers = existingSystem._consumers - 1

	if existingSystem._consumers <= 0 then
		self:_deconstructSystem(staticSystem)
	end
end

function Rocs:_constructAggregate(staticAggregate, instance)
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

function Rocs:_deconstructAggregate(aggregate)
	-- destroy is called in removeComponent for correct timing

	self._entities[aggregate.instance][getmetatable(aggregate)] = nil

	if next(self._entities[aggregate.instance]) == nil then
		self._entities[aggregate.instance] = nil
	end
end

function Rocs:_addComponent(instance, staticAggregate, scope, data)
	assert(Util.runEntityCheck(staticAggregate, instance))

	if self._entities[instance] == nil then
		self._entities[instance] = {}
	end

	if self._entities[instance][staticAggregate] == nil then
		self._entities[instance][staticAggregate] =
			self:_constructAggregate(staticAggregate, instance)
	end

	self._entities[instance][staticAggregate].components[scope] = data

	self:_dispatchComponentChange(
		self._entities[instance][staticAggregate],
		data
	)
end

function Rocs:_removeComponent(instance, staticAggregate, scope)
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
		self:_deconstructAggregate(aggregate, staticAggregate)
	end

	self:_dispatchComponentChange(
		aggregate
	)

	if shouldDestroy and aggregate.destroy then
		aggregate:destroy()
	end
end

function Rocs:_dispatchComponentChange(aggregate, data)
	local lastData = aggregate.data
	local newData = self:_reduceAggregate(aggregate)

	aggregate.data = newData
	aggregate.lastData = lastData

	if lastData == nil and newData ~= nil then
		self:_dispatchLifecycle(aggregate, LIFECYCLE_ADDED)
	end

	if newData ~= lastData then
		self:_dispatchLifecycle(aggregate, LIFECYCLE_UPDATED)
	end

	if newData == nil then
		self:_dispatchLifecycle(aggregate, LIFECYCLE_REMOVED)
	end

	-- Component dependencies
	for _, dependency in ipairs(self._dependencies[getmetatable(aggregate)]) do
		dependency:tap(aggregate.instance, aggregate)
	end

	-- Entity dependencies
	if rawget(self._dependencies, aggregate.instance) then
		for _, dependency in ipairs(self._dependencies[aggregate.instance]) do
			dependency:tap(aggregate.instance, aggregate)
		end
	end

	-- "All" dependencies
	for _, dependency in ipairs(self._dependencies[ALL_COMPONENTS]) do
		dependency:tap(aggregate.instance, aggregate)
	end
end

function Rocs:_dispatchLifecycle(aggregate, stage)
	if aggregate[stage] then
		aggregate[stage](self:getEntity(aggregate.instance, aggregate._address))
	end
end

function Rocs:_getComponent(instance, staticAggregate, scope)
	if
		self._entities[instance] == nil
		or self._entities[instance][staticAggregate] == nil
	then
		return
	end

	return self._entities[instance][staticAggregate].components[scope]
end

function Rocs:_getAllAggregates(instance)
	local aggregates = {}

	if self._entities[instance] ~= nil then
		for _, aggregate in pairs(self._entities[instance]) do
			aggregates[#aggregates + 1] = aggregate
		end
	end

	return aggregates
end

function Rocs:_getAggregate(instance, staticAggregate)
	return
		self._entities[instance]
		and self._entities[instance][staticAggregate]
end

function Rocs:_reduceAggregate(aggregate)
	local values = { aggregate.components.base }

	for name, component in pairs(aggregate.components) do
		if name ~= "base" then
			values[#values + 1] = component
		end
	end

	return Util.runReducer(getmetatable(aggregate), values, self.reducers.default)
end

function Rocs:_getMetadata(name)
	return
		type(name) == "string"
		and name:sub(1, #METADATA_IDENTIFIER) == METADATA_IDENTIFIER
		and self._metadata[name:sub(#METADATA_IDENTIFIER + 1)]
		or nil
end

function Rocs:makeUniqueComponent(componentResolvable)
	local staticAggregate = self:_getStaticAggregate(componentResolvable)

	local component
	component = setmetatable({
		new = function (...)
			return setmetatable(staticAggregate.new(...), component)
		end;
	}, staticAggregate)
	component.__index = component
	component.__tostring = staticAggregate.__tostring

	return component
end

function Rocs:_getLayerComponent(layerId, componentResolvable)
	local staticAggregate = self:_getStaticAggregate(componentResolvable)

	if self._layerComponents[layerId] == nil then
		self._layerComponents[layerId] = self:makeUniqueComponent(staticAggregate)
	else
		assert(
			staticAggregate == self._layerComponents[layerId],
			"Layer component mismatched between addLayer calls"
		)
	end

	return self._layerComponents[layerId]
end

function Rocs.metadata(name)
	return METADATA_IDENTIFIER .. name
end

return Rocs
