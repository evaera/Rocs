local Util = require(script.Parent.Parent.Util)

local DependencyStep = {}
DependencyStep.__index = DependencyStep

function DependencyStep.new(factory, qualifier, dependencies)
	return setmetatable({
		_factory = factory;
		_rocs = factory._rocs;
		_qualifier = qualifier;
		_dependencies = dependencies;
		_entityDependencies = nil;
	}, DependencyStep)
end

function DependencyStep.combineDependencies(steps)
	local dependencies = {}

	for i, dependencyStep in ipairs(steps) do
		if dependencyStep._dependencies == true then
			return true -- "poison" chain removing component optimization
		end

		dependencies[i] = dependencyStep._dependencies
	end

	return Util.concat(unpack(dependencies))
end

function DependencyStep:entities(system)
	local entityDependencies = self._entityDependencies

	if not entityDependencies then
		error("DependencyStep:entities() can only be called on a top-level dependency step.")
	end

	local instance, entityDependency
	return function()
		instance, entityDependency = next(entityDependencies, instance)

		return instance, entityDependency and entityDependency._currentAggregateMap
	end
end

function DependencyStep:evaluate(...)
	return self._qualifier(...)
end

function DependencyStep:evaluateMap(instance, targetFilter)
	local aggregateArray = self:evaluate(instance)
	if aggregateArray == true then
		return {}
	elseif aggregateArray == nil or #aggregateArray == 0 then
		return nil
	end

	local map = {}
	local targetFilterMet = nil

	for _, aggregate in ipairs(aggregateArray) do
		map[getmetatable(aggregate).name] = aggregate

		if getmetatable(aggregate) == targetFilter then
			targetFilterMet = true
		end
	end

	return targetFilterMet and map
end

local function makeBehavior(type, ...)
	local fields = {...}

	return function (step, ...)
		local params = {...}

		local behavior = {
			handler = table.remove(params, #params);
			step = step;
			type = type;
		}

		assert(#fields == #params, ("Behavior %q accepts %d parameters, but %d were given."):format(
			type,
			#fields,
			#params
		))

		for i = 1, #fields do
			behavior[fields[i]] = params[i]
		end

		return behavior
	end
end

for _, behavior in ipairs({
	{"Event", "event"};
	{"Interval", "length"};
	{"Added"};
	{"Updated"};
	{"Removed"};
}) do
	DependencyStep["on" .. behavior[1]] = makeBehavior("on" .. behavior[1], select(2, unpack(behavior)))
end

return DependencyStep
