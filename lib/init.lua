local I = require(script.Interfaces)
local Entity = require(script.Entity)
local Util = require(script.Util)
local t = require(script.t)
local Constants = require(script.Constants)
local Reducers = require(script.Operators.Reducers)
local Comparators = require(script.Operators.Comparators)

local AggregateCollection = require(script.Collections.AggregateCollection)

local Rocs = {
	debug = false;
	None = Constants.None;
	Internal = Constants.Internal;
	reducers = Reducers;
	comparators = Comparators;
}
Rocs.__index = Rocs

function Rocs.new(name)
	local self = setmetatable({
		name = name or "global";
		_lifecycleHooks = {
			global = setmetatable({}, Util.easyIndex);
			component = {
				global = setmetatable({}, Util.easyIndex);
				[Constants.LIFECYCLE_ADDED] = setmetatable({}, Util.easyIndex);
				[Constants.LIFECYCLE_REMOVED] = setmetatable({}, Util.easyIndex);
				[Constants.LIFECYCLE_UPDATED] = setmetatable({}, Util.easyIndex);
				[Constants.LIFECYCLE_PARENT_UPDATED] = setmetatable({}, Util.easyIndex);
			}
		}
	}, Rocs)

	self._aggregates = AggregateCollection.new(self)

	return self
end

function Rocs:registerLifecycleHook(lifecycle, hook)
	table.insert(self._lifecycleHooks.global[lifecycle], hook)
end

function Rocs:registerComponentHook(componentResolvable, lifecycle, hook)
	local staticAggregate = self._aggregates:getStatic(componentResolvable)

	table.insert(self._lifecycleHooks.component[lifecycle][staticAggregate], hook)

	return {
		disconnect = function()
			local hooks = self._lifecycleHooks.component[lifecycle][staticAggregate]
			for i = 1, #hooks do
				if hooks[i] == hook then
					table.remove(hooks, i)

					if #hooks == 0 then
						self._lifecycleHooks.component[lifecycle][staticAggregate] = nil
					end

					break
				end
			end
		end
	}
end

function Rocs:registerComponent(...)
	return self._aggregates:register(...)
end

function Rocs:getComponents(componentResolvable)
	return self._aggregates._aggregates[self._aggregates:getStatic(componentResolvable)] or {}
end

function Rocs:registerComponentsIn(instance)
	return Util.requireAllInAnd(instance, self.registerComponent, self)
end

local getEntityCheck = t.tuple(t.union(t.Instance, t.table), t.string)
function Rocs:getEntity(instance, scope, override)
	assert(getEntityCheck(instance, scope))
	assert(override == nil or override == Rocs.Internal)

	return Entity.new(self, instance, scope, override ~= nil)
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

	aggregate.lastData = nil
end

function Rocs:_dispatchComponentLifecycleHooks(aggregate, stagePool, stage)
	stage = stage or stagePool
	local staticAggregate = getmetatable(aggregate)

	if rawget(self._lifecycleHooks.component[stagePool], staticAggregate) then
		local hooks = self._lifecycleHooks.component[stagePool][staticAggregate]

		for i = 1, #hooks do
			hooks[i](aggregate, stage)
		end
	end
end

function Rocs:_dispatchGlobalLifecycleHooks(aggregate, stagePool, stage)
	stage = stage or stagePool

	for i = 1, #self._lifecycleHooks.global[stagePool] do
		self._lifecycleHooks.global[stagePool][i](aggregate, stage)
	end
end

function Rocs:_dispatchLifecycle(aggregate, stage)
	if aggregate[stage] then
		aggregate[stage](aggregate)
	end

	self:_dispatchComponentLifecycleHooks(aggregate, stage)
	self:_dispatchComponentLifecycleHooks(aggregate, "global", stage)
	self:_dispatchGlobalLifecycleHooks(aggregate, stage)
	self:_dispatchGlobalLifecycleHooks(aggregate, "global", stage)
end

return Rocs
