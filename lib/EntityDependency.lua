local EntityDependency = {}
EntityDependency.__index = EntityDependency

function EntityDependency.new(dependency, instance)
	return setmetatable({
		_dependency = dependency;
		instance = instance;
		system = dependency._rocs:_getSystem(dependency._staticSystem);
		_lastAggregateMap = nil;
		_currentAggregateMap = nil;
	}, EntityDependency)
end

function EntityDependency:_dispatchLifecycle(stage, aggregateMap, target)
	aggregateMap = aggregateMap or self._lastAggregateMap

	self._currentAggregateMap = aggregateMap

	for _, behavior in ipairs(self._dependency._behaviors) do
		if behavior.type == stage then
			behavior.handler(
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

return EntityDependency
