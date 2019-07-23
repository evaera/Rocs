local I = require(script.Interfaces)
local Entity = require(script.Entity)
local Util = require(script.Util)
local t = require(script.t)
local Constants = require(script.Constants)
local makeReducers = require(script.Operators.Reducers)
local makeComparators = require(script.Operators.Comparators)

local AggregateCollection = require(script.Collections.AggregateCollection)
local MetadataCollection = require(script.Collections.MetadataCollection)

local Rocs = {
	None = Constants.None;
}
Rocs.__index = Rocs

function Rocs.new(name)
	local self = setmetatable({
		name = name or "global";
		_layerComponents = setmetatable({}, {
			__mode = "kv";
		});
	}, Rocs)

	self._aggregates = AggregateCollection.new(self)
	self._metadata = MetadataCollection.new(self)

	self.reducers = makeReducers(self)
	self.comparators = makeComparators(self)

	return self
end

function Rocs.metadata(name)
	return Constants.METADATA_IDENTIFIER .. name
end

function Rocs:registerComponent(...)
	return self._aggregates:register(...)
end

function Rocs:registerMetadata(...)
	return self._metadata:register(...)
end

function Rocs:registerComponentsIn(instance)
	return Util.requireAllInAnd(instance, self.registerCompoent, self)
end

function Rocs:registerMetadataIn(instance)
	return Util.requireAllInAnd(instance, self.registerMetadata, self)
end

local getEntityCheck = t.tuple(t.union(t.Instance, t.table), t.string)
function Rocs:getEntity(instance, scope)
	assert(getEntityCheck(instance, scope))

	return Entity.new(self, instance, scope)
end

function Rocs:_dispatchComponentChange(aggregate, data)
	local lastData = aggregate.data
	local newData = self._aggregates:reduce(aggregate)

	aggregate.data = newData
	aggregate.lastData = lastData

	if lastData == nil and newData ~= nil then
		self:_dispatchLifecycle(aggregate, Constants.LIFECYCLE_ADDED)
	end

	local staticAggregate = getmetatable(aggregate)

	if (staticAggregate.shouldUpdate or self.comparators.default)(newData, lastData) then
		self:_dispatchLifecycle(aggregate, Constants.LIFECYCLE_UPDATED)
	end

	if newData == nil then
		self:_dispatchLifecycle(aggregate, Constants.LIFECYCLE_REMOVED)
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
