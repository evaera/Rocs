local RunService = game:GetService("RunService")

local LIFECYCLE_ADDED = "onAdded"
local LIFECYCLE_REMOVED = "onRemoved"
local LIFECYCLE_UPDATED = "onUpdated"

local DEPENDENCY_EVENTS = {
	onHeartbeat = RunService.Heartbeat;
	onRenderStepped = RunService.RenderStepped;
	onStepped = RunService.Stepped;
}

local EntityDependency = {}
EntityDependency.__index = EntityDependency

function EntityDependency.new(dependency, instance)
	return setmetatable({
		_dependency = dependency;
		instance = instance;
		system = dependency._rocs:_getSystem(dependency._staticSystem);
		_lastAggregateMap = nil;
	}, EntityDependency)
end

function EntityDependency:_dispatchLifecycle(stage, aggregateMap, target)
	if self._dependency._hooks[stage] then
		self._dependency._hooks[stage](
			self.system,
			{
				entity = self._dependency._rocs:getEntity(
					self.instance,
					"system__" .. self._dependency._staticSystem.name
				);
				components = aggregateMap;
				target = target;
				data = target.data;
				lastData = target.lastData;
			}
		)
	end
	self._lastAggregateMap = aggregateMap;
end

function EntityDependency:destroy(target)
	self:_dispatchLifecycle(LIFECYCLE_REMOVED, self._lastAggregateMap, target)
	self._dependency._rocs:_reduceSystemConsumers(self._dependency._staticSystem)
end

local Dependency = {}
Dependency.__index = Dependency

function Dependency.new(rocs, system, step, hooks)
	return setmetatable({
		_rocs = rocs;
		_staticSystem = system;
		_step = step;
		_hooks = hooks;
		_entityDependencies = {};
		_connections = nil;
	}, Dependency)
end

function Dependency:tap(instance, target)
	local aggregateMap = self._step:evaluateMap(instance)

	if aggregateMap and not self._entityDependencies[instance] then
		self._entityDependencies[instance] = EntityDependency.new(self, instance)
		self._entityDependencies[instance]:_dispatchLifecycle(LIFECYCLE_ADDED, aggregateMap, target)
	elseif not aggregateMap and self._entityDependencies[instance] then
		self._entityDependencies[instance]:destroy(target)
		self._entityDependencies[instance] = nil
	end

	if aggregateMap then
		self._entityDependencies[instance]:_dispatchLifecycle(LIFECYCLE_UPDATED, aggregateMap, target)
	end

	self:_tapEvents()
end

function Dependency:_tapEvents()
	if next(self._entityDependencies) ~= nil and self._connections == nil then
		self:_connectEvents()
	elseif next(self._entityDependencies) == nil and self._connections ~= nil then
		self:_disconnectEvents()
	end
end

function Dependency:_connectEvents()
	self._connections = {}

	for name, event in pairs(DEPENDENCY_EVENTS) do
		if self._hooks[name] then
			table.insert(self._connections, event:Connect(self._hooks[name]))
		end
	end
end

function Dependency:_disconnectEvents()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end

	self._connections = {}
end

return Dependency
