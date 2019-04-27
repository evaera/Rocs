local I = require(script.Interfaces)
local Entity = require(script.Entity)
local t = require(script.t)
local DependencyFactory = require(script.Dependency.DependencyFactory)
local MakeReducers = require(script.Reducers)
local Constants = require(script.Constants)

local AggregateCollection = require(script.Collections.AggregateCollection)
local SystemCollection = require(script.Collections.SystemCollection)
local MetadataCollection = require(script.Collections.MetadataCollection)

local Rocs = {}
Rocs.__index = Rocs

function Rocs.new(name)
	local self = setmetatable({
		_name = name or "global";
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

	self._systems = SystemCollection.new(self)
	self._aggregates = AggregateCollection.new(self)
	self._metadata = MetadataCollection.new(self)

	self.dependencies = DependencyFactory.new(self)
	self.reducers = MakeReducers(self)

	self:_registerIntrinsics()

	return self
end

function Rocs.metadata(name)
	return Constants.METADATA_IDENTIFIER .. name
end

function Rocs:registerSystem(...)
	return self._systems:register(...)
end

function Rocs:registerComponent(...)
	return self._aggregates:register(...)
end

function Rocs:registerMetadata(...)
	return self._metadata:register(...)
end

local getEntityCheck = t.tuple(t.union(t.Instance, t.table), t.string)
function Rocs:getEntity(instance, scope)
	assert(getEntityCheck(instance, scope))

	return Entity.new(self, instance, scope)
end

function Rocs:makeUniqueComponent(componentResolvable)
	assert(I.ComponentResolvable(componentResolvable))

	local staticAggregate = self._aggregates:getStatic(componentResolvable)

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

function Rocs:_registerIntrinsics()
	for _, module in ipairs(script.Intrinsics:GetChildren()) do
		require(module)(self)
	end
end

function Rocs:_dispatchComponentChange(aggregate, data)
	local lastData = aggregate.data
	local newData = self._aggregates:reduce(aggregate)

	aggregate.data = newData
	aggregate.lastData = lastData

	if lastData == nil and newData ~= nil then
		self:_dispatchLifecycle(aggregate, Constants.LIFECYCLE_ADDED)
	end

	if newData ~= lastData then
		self:_dispatchLifecycle(aggregate, Constants.LIFECYCLE_UPDATED)
	end

	if newData == nil then
		self:_dispatchLifecycle(aggregate, Constants.LIFECYCLE_REMOVED)
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
	for _, dependency in ipairs(self._dependencies[Constants.ALL_COMPONENTS]) do
		dependency:tap(aggregate.instance, aggregate)
	end
end

function Rocs:_dispatchLifecycle(aggregate, stage)
	if aggregate[stage] then
		aggregate[stage](self:getEntity(aggregate.instance, aggregate._address))
	end
end

function Rocs:_getLayerComponent(layerId, componentResolvable)
	local staticAggregate = self._aggregates:getStatic(componentResolvable)

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

return Rocs
