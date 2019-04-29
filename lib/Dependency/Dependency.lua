local EntityDependency = require(script.Parent.EntityDependency)

local Constants = require(script.Parent.Parent.Constants)

local Dependency = {}
Dependency.__index = Dependency

function Dependency.new(rocs, system, step, behaviors)
	local entityDependencies = {}
	step._entityDependencies = entityDependencies

	return setmetatable({
		_rocs = rocs;
		_staticSystem = system;
		_step = step;
		_behaviors = behaviors;
		_entityDependencies = entityDependencies;
		_connections = nil;
	}, Dependency)
end

function Dependency:tap(instance, target)
	local staticTarget = getmetatable(target)
	local aggregateMap = self._step:evaluateMap(instance, staticTarget)

	if aggregateMap and not self._entityDependencies[instance] then
		self._entityDependencies[instance] = EntityDependency.new(self, instance)
		self._entityDependencies[instance]:dispatchLifecycle(Constants.LIFECYCLE_ADDED, aggregateMap, target)
	end

	local entityDependency = self._entityDependencies[instance]
	local didExistPreviously = entityDependency and entityDependency._lastAggregateMap[staticTarget.name] ~= nil

	if didExistPreviously then
		if
			not staticTarget.shouldUpdate
			or staticTarget.shouldUpdate(target.data, target.lastData)
		then
			entityDependency:dispatchLifecycle(Constants.LIFECYCLE_UPDATED, aggregateMap, target)
		end

		if not aggregateMap then
			entityDependency:dispatchLifecycle(Constants.LIFECYCLE_REMOVED, nil, target)
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

	for _, behavior in ipairs(self._behaviors) do
		-- TODO: Break this out
		if behavior.type == "onEvent" then
			local connection = behavior.event:Connect(function(...)
				return behavior.handler(system, ...)
			end)
			table.insert(self._connections, function()
				connection:Disconnect()
			end)
		elseif behavior.type == "onInterval" then
			local continue = true

			spawn(function()
				while continue do
					local dt = wait(behavior.length)

					if continue then
						behavior.handler(system, dt)
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
