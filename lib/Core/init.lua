local Entity = require(script.Entity)
local Util = require(script.Parent.Shared.Util)
local t = require(script.Parent.Shared.t)
local Constants = require(script.Constants)
local Reducers = require(script.Operators.Reducers)
local Comparators = require(script.Operators.Comparators)
local inspect = require(script.Parent.Shared.Inspect)

local AggregateCollection = require(script.Aggregate.AggregateCollection)

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
			global = setmetatable({}, Util.easyIndex(1));
			component = setmetatable({}, Util.easyIndex(2));
			instance = setmetatable({}, Util.easyIndex(3));
			registration = {};
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

	return hook
end

function Rocs:unregisterComponentHook(component, lifecycle, hook)
	local staticAggregate = self._aggregates:getStatic(componentResolvable)
	local hooks = self._lifecycleHooks.component[lifecycle][staticAggregate]
	for i, v in ipairs(hooks) do
		if v == hook then
			table.remove(hooks, i)

			if #hooks == 0 then
				self._lifecycleHooks.component[lifecycle][staticAggregate] = nil
			end

			break
		end
	end
end

function Rocs:registerEntityComponentHook(instance, componentResolvable, lifecycle, hook)
	local staticAggregate = self._aggregates:getStatic(componentResolvable)

	table.insert(self._lifecycleHooks.instance[instance][lifecycle][staticAggregate], hook)

	if typeof(instance) == "Instance" then
		instance.AncestryChanged:Connect(function()
			if not instance:IsDescendantOf(game) then
				self._lifecycleHooks.instance[instance] = nil
			end
		end)
	end
end

function Rocs:registerComponentRegistrationHook(hook)
	table.insert(self._lifecycleHooks.registration, hook)
end

function Rocs:registerComponent(...)
	local staticAggregate = self._aggregates:register(...)

	for _, hook in ipairs(self._lifecycleHooks.registration) do
		hook(staticAggregate)
	end

	return staticAggregate
end

function Rocs:getComponents(componentResolvable)
	return self._aggregates._aggregates[self._aggregates:getStatic(componentResolvable)] or {}
end

function Rocs:resolveAggregate(componentResolvable)
	return self._aggregates:resolve(componentResolvable)
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


function Rocs:_dispatchLifecycleHooks(aggregate, stagePool, stage)
	stage = stage or stagePool
	local staticAggregate = getmetatable(aggregate)

	for _, hook in ipairs(self._lifecycleHooks.global[stagePool]) do
		hook(aggregate, stage)
	end

	if rawget(self._lifecycleHooks.component[stagePool], staticAggregate) then
		local hooks = self._lifecycleHooks.component[stagePool][staticAggregate]

		for _, hook in ipairs(hooks) do
			hook(aggregate, stage)
		end
	end

	if
		rawget(self._lifecycleHooks.instance, aggregate.instance)
		and rawget(self._lifecycleHooks.instance[aggregate.instance], stagePool)
		and rawget(self._lifecycleHooks.instance[aggregate.instance][stagePool], staticAggregate)
	then
		local hooks = self._lifecycleHooks.instance[aggregate.instance][stagePool][staticAggregate]

		for _, hook in ipairs(hooks) do
			hook(aggregate, stage)
		end
	end
end

function Rocs:_dispatchLifecycle(aggregate, stage)
	self:_dispatchLifecycleHooks(aggregate, stage)
	self:_dispatchLifecycleHooks(aggregate, "global", stage)
end

function Rocs:warn(text, ...)
	return warn(("[Rocs %s]"):format(self.name), text:format(Util.mapTuple(function(obj)
		return typeof(obj) == "Instance"
			and obj:GetFullName()
			or tostring(obj)
	end, ...)))
end

return Rocs
