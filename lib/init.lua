local I = require(script.Interfaces)
local Entity = require(script.Entity)
local Util = require(script.Util)
local t = require(script.t)
local Constants = require(script.Constants)
local Reducers = require(script.Operators.Reducers)
local Comparators = require(script.Operators.Comparators)

local AggregateCollection = require(script.Collections.AggregateCollection)

local Rocs = {
	None = Constants.None;
	reducers = Reducers;
	comparators = Comparators;
}
Rocs.__index = Rocs

function Rocs.new(name)
	local self = setmetatable({
		name = name or "global",
	}, Rocs)

	self._aggregates = AggregateCollection.new(self)

	return self
end

function Rocs:registerComponent(...)
	return self._aggregates:register(...)
end

function Rocs:getComponents(componentResolvable)
	return self._aggregates._aggregates[self._aggregates:getStatic(componentResolvable)] or {}
end

function Rocs:registerComponentsIn(instance)
	return Util.requireAllInAnd(instance, self.registerCompoent, self)
end

local getEntityCheck = t.tuple(t.union(t.Instance, t.table), t.string)
function Rocs:getEntity(instance, scope)
	assert(getEntityCheck(instance, scope))

	return Entity.new(self, instance, scope)
end

function Rocs:_dispatchComponentChange(aggregate)
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

		local childAggregates = self._aggregates:getAll(aggregate)
		for i = 1, #childAggregates do
			local childAggregate = childAggregates[i]

			self:_dispatchLifecycle(
				childAggregate,
				Constants.LIFECYCLE_PARENT_UPDATED
			)
		end
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

return Rocs
