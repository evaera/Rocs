local Util = require(script.Parent.Parent.Util)
local DependencyStep = require(script.Parent.DependencyStep)

local DependencyFactory = {}
DependencyFactory.__index = DependencyFactory

function DependencyFactory.new(rocs)
	return setmetatable({
		_rocs = rocs;
	}, DependencyFactory)
end

function DependencyFactory.isDependencyStep(value)
	return type(value) == "table" and getmetatable(value) == DependencyStep
end

function DependencyFactory:hasComponent(componentResolvable)
	return DependencyStep.new(
		self,
		function(instance)
			local staticAggregate = self._rocs._aggregates:getStatic(componentResolvable)

			return {self._rocs._aggregates:get(instance, staticAggregate)}
		end,
		{componentResolvable}
	)
end

function DependencyFactory:isEntity(goalEntity)
	return DependencyStep.new(
		self,
		function(checkEntity)
			return goalEntity == checkEntity or nil
		end,
		{goalEntity}
	)
end

function DependencyFactory:hasMetadata(metadata)
	return DependencyStep.new(
		self,
		function(instance)
			local aggregates = {}

			for _, aggregate in ipairs(self._rocs._aggregates:getAll(instance)) do
				if aggregate:get(metadata) ~= nil then
					aggregates[#aggregates + 1] = aggregate
				end
			end

			return aggregates
		end,
		true
	)
end

function DependencyFactory:_resolveStep(step)
	if DependencyFactory.isDependencyStep(step) then
		return step
	elseif self._rocs._metadata:get(step) then
		return self:hasMetadata(step)
	elseif type(step) == "string" then
		return self:hasComponent(step)
	elseif typeof(step) == "Instance" then --? Should work for tables?
		return self:hasEntity(step)
	end

	error("Invalid dependency in sequence", 2)
end

function DependencyFactory:_resolveSteps(steps)
	local resolvedSteps = {}

	for i, step in ipairs(steps) do
		resolvedSteps[i] = self:_resolveStep(step)
	end

	return resolvedSteps
end

function DependencyFactory:all(...)
	local steps = self:_resolveSteps({...})

	return DependencyStep.new(
		self,
		function (instance)
			local components = {}

			for _, step in ipairs(steps) do
				local stepComponents = step:evaluate(instance)

				if stepComponents == nil then
					return
				end

				if type(stepComponents) == "table" then
					components[#components + 1] = stepComponents
				end
			end

			return Util.concat(unpack(components))
		end,
		DependencyStep.combineDependencies(steps)
	)
end

function DependencyFactory:any(...)
	local steps = self:_resolveSteps({...})

	return DependencyStep.new(
		self,
		function (instance)
			local components = {}
			for _, step in ipairs(steps) do
				local stepComponents = step:evaluate(instance)

				if type(stepComponents) == "table" then
					components[#components + 1] = stepComponents
				end
			end

			if #components == 0 then
				return
			end

			return Util.concat(unpack(components))
		end,
		DependencyStep.combineDependencies(steps)
	)
end

return DependencyFactory
