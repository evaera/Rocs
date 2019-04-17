local Util = require(script.Parent.Util)

local DependencyStep = {}
DependencyStep.__index = DependencyStep

function DependencyStep.new(factory, qualifier, dependencies)
	return setmetatable({
		_factory = factory;
		_rocs = factory._rocs;
		_qualifier = qualifier;
		_dependencies = dependencies;
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

local function makeHook(type, ...)
	local fields = {...}

	return function (step, ...)
		local params = {...}

		local hook = {
			handler = table.remove(params, #params);
			step = step;
			type = type;
		}

		assert(#fields == #params, ("Hook %q accepts %d parameters, but %d were given."):format(
			type,
			#fields,
			#params
		))

		for i = 1, #fields do
			hook[fields[i]] = params[i]
		end

		return hook
	end
end

for _, hook in ipairs({
	{"Event", "event"};
	{"Interval", "length"};
	{"Added"};
	{"Updated"};
	{"Removed"};
}) do
	DependencyStep["on" .. hook[1]] = makeHook("on" .. hook[1], select(2, unpack(hook)))
end

return DependencyStep
