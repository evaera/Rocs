local Pipeline = require(script.Pipeline)
local Util = require(script.Parent.Shared.Util)
local t = require(script.Parent.Shared.t)
local Constants = require(script.Constants)
local Reducers = require(script.Operators.Reducers)
local Comparators = require(script.Operators.Comparators)
local inspect = require(script.Parent.Shared.Inspect)

local LensCollection = require(script.Lens.LensCollection)

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

	self._lenses = LensCollection.new(self)

	return self
end

function Rocs:registerLifecycleHook(lifecycle, hook)
	table.insert(self._lifecycleHooks.global[lifecycle], hook)
end

function Rocs:registerLayerHook(componentResolvable, lifecycle, hook)
	local staticLens = self._lenses:getStatic(componentResolvable)

	table.insert(self._lifecycleHooks.component[lifecycle][staticLens], hook)

	return hook
end

function Rocs:unregisterLayerHook(component, lifecycle, hook)
	local staticLens = self._lenses:getStatic(componentResolvable)
	local hooks = self._lifecycleHooks.component[lifecycle][staticLens]
	for i, v in ipairs(hooks) do
		if v == hook then
			table.remove(hooks, i)

			if #hooks == 0 then
				self._lifecycleHooks.component[lifecycle][staticLens] = nil
			end

			break
		end
	end
end

function Rocs:registerPipelineLayerHook(instance, componentResolvable, lifecycle, hook)
	local staticLens = self._lenses:getStatic(componentResolvable)

	table.insert(self._lifecycleHooks.instance[instance][lifecycle][staticLens], hook)

	if typeof(instance) == "Instance" then
		instance.AncestryChanged:Connect(function()
			if not instance:IsDescendantOf(game) then
				self._lifecycleHooks.instance[instance] = nil
			end
		end)
	end
end

function Rocs:registerLayerRegistrationHook(hook)
	table.insert(self._lifecycleHooks.registration, hook)
end

function Rocs:registerLayer(...)
	local staticLens = self._lenses:register(...)

	for _, hook in ipairs(self._lifecycleHooks.registration) do
		hook(staticLens)
	end

	return staticLens
end

function Rocs:getLayers(componentResolvable)
	return self._lenses._lenses[self._lenses:getStatic(componentResolvable)] or {}
end

function Rocs:resolveLens(componentResolvable)
	return self._lenses:resolve(componentResolvable)
end

function Rocs:registerLayersIn(instance)
	return Util.requireAllInAnd(instance, self.registerLayer, self)
end

local getPipelineCheck = t.tuple(t.union(t.Instance, t.table), t.string)
function Rocs:getPipeline(instance, scope, override)
	assert(getPipelineCheck(instance, scope))
	assert(override == nil or override == Rocs.Internal)

	return Pipeline.new(self, instance, scope, override ~= nil)
end


function Rocs:_dispatchLifecycleHooks(lens, stagePool, stage)
	stage = stage or stagePool
	local staticLens = getmetatable(lens)

	for _, hook in ipairs(self._lifecycleHooks.global[stagePool]) do
		hook(lens, stage)
	end

	if rawget(self._lifecycleHooks.component[stagePool], staticLens) then
		local hooks = self._lifecycleHooks.component[stagePool][staticLens]

		for _, hook in ipairs(hooks) do
			hook(lens, stage)
		end
	end

	if
		rawget(self._lifecycleHooks.instance, lens.instance)
		and rawget(self._lifecycleHooks.instance[lens.instance], stagePool)
		and rawget(self._lifecycleHooks.instance[lens.instance][stagePool], staticLens)
	then
		local hooks = self._lifecycleHooks.instance[lens.instance][stagePool][staticLens]

		for _, hook in ipairs(hooks) do
			hook(lens, stage)
		end
	end
end

function Rocs:_dispatchLifecycle(lens, stage)
	self:_dispatchLifecycleHooks(lens, stage)
	self:_dispatchLifecycleHooks(lens, "global", stage)
end

function Rocs:warn(text, ...)
	return warn(("[Rocs %s]"):format(self.name), text:format(Util.mapTuple(function(obj)
		return typeof(obj) == "Instance"
			and obj:GetFullName()
			or tostring(obj)
	end, ...)))
end

return Rocs
