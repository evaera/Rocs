local RunService = game:GetService("RunService")

local LIFECYCLE_ADDED = "onAdded"
local LIFECYCLE_REMOVED = "onRemoved"
local LIFECYCLE_UPDATED = "onUpdated"

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
	aggregateMap = aggregateMap or self._lastAggregateMap

	for _, hook in ipairs(self._dependency._hooks) do
		if hook.type == stage then
			hook.handler(
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
	end
	self._lastAggregateMap = aggregateMap;
end

function EntityDependency:destroy()
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
		_entityDependencies = setmetatable({}, {
			__index = function(self, k)
				self[k] = {}
				return self[k]
			end;
		});
		_connections = nil;
	}, Dependency)
end

function Dependency:tap(instance, target)
	local staticTarget = getmetatable(target)
	local aggregateMap = self._step:evaluateMap(instance, staticTarget)

	if aggregateMap and not self._entityDependencies[instance][staticTarget] then
		self._entityDependencies[instance][staticTarget] = EntityDependency.new(self, instance)
		self._entityDependencies[instance][staticTarget]:_dispatchLifecycle(LIFECYCLE_ADDED, aggregateMap, target)
	end

	local entityDependency = self._entityDependencies[instance][staticTarget]

	if entityDependency then
		entityDependency:_dispatchLifecycle(LIFECYCLE_UPDATED, aggregateMap, target)
	end

	if not aggregateMap and entityDependency then
		entityDependency:_dispatchLifecycle(LIFECYCLE_REMOVED, nil, target)
		entityDependency:destroy()

		self._entityDependencies[instance][staticTarget] = nil

		if next(self._entityDependencies[instance]) == nil then
			self._entityDependencies[instance] = nil
		end
	end

	self:_tapEvents(entityDependency and entityDependency.system)
end

function Dependency:_tapEvents(system)
	if next(self._entityDependencies) ~= nil and self._connections == nil then
		self:_connectEvents(system)
	elseif next(self._entityDependencies) == nil and self._connections ~= nil then
		self:_disconnectEvents()
	end
end

function Dependency:_connectEvents(system)
	self._connections = {}

	for _, hook in ipairs(self._hooks) do
		-- TODO: Break this out
		if hook.type == "onEvent" then
			local connection = hook.event:Connect(function(...)
				return hook.handler(system, ...)
			end)
			table.insert(self._connections, function()
				connection:Disconnect()
			end)
		elseif hook.type == "onInterval" then
			local continue = true

			spawn(function()
				while continue do
					local dt = wait(hook.length)

					if continue then
						hook.handler(system, dt)
					end
				end
			end)

			table.insert(self._connections, function()
				continue = false
			end)
		end
	end
end

function Dependency:_disconnectEvents()
	for _, disconnect in ipairs(self._connections) do
		disconnect()
	end

	self._connections = {}
end

return Dependency
