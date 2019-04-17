local EntityDependency = require(script.Parent.EntityDependency)
local inspect = require(script.Parent.Inspect).inspect

local LIFECYCLE_ADDED = "onAdded"
local LIFECYCLE_REMOVED = "onRemoved"
local LIFECYCLE_UPDATED = "onUpdated"

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

function Dependency:entities()
	return function()


	end
end

function Dependency:tap(instance, target)
	local staticTarget = getmetatable(target)
	local aggregateMap = self._step:evaluateMap(instance, staticTarget)

	if aggregateMap and not self._entityDependencies[instance] then
		self._entityDependencies[instance] = EntityDependency.new(self, instance)
		self._entityDependencies[instance]:_dispatchLifecycle(LIFECYCLE_ADDED, aggregateMap, target)
	end

	local entityDependency = self._entityDependencies[instance]
	local didExistPreviously = entityDependency and entityDependency._lastAggregateMap[staticTarget.name] ~= nil

	if didExistPreviously then
		entityDependency:_dispatchLifecycle(LIFECYCLE_UPDATED, aggregateMap, target)

		if not aggregateMap then
			entityDependency:_dispatchLifecycle(LIFECYCLE_REMOVED, nil, target)
			entityDependency:destroy()

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
