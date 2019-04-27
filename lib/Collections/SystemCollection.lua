local t = require(script.Parent.Parent.t)
local I = require(script.Parent.Parent.Interfaces)
local Dependency = require(script.Parent.Parent.Dependency.Dependency)
local Constants = require(script.Parent.Parent.Constants)

local SystemCollection = {}
SystemCollection.__index = SystemCollection

function SystemCollection.new(rocs)
	return setmetatable({
		rocs = rocs;
		_systems = {};
		_active = {};
	}, SystemCollection)
end

function SystemCollection:register(systemDefinition, dependencies)
	assert(t.tuple(I.SystemDefinition, I.SystemDependencies)(systemDefinition, dependencies))

	systemDefinition.__index = systemDefinition.__index or systemDefinition

	systemDefinition.new = systemDefinition.new or function()
		return setmetatable({}, systemDefinition)
	end

	self._systems[systemDefinition.name] = systemDefinition

	local stepBehaviors = {}
	for _, behavior in ipairs(dependencies) do
		if stepBehaviors[behavior.step] == nil then
			stepBehaviors[behavior.step] = {}
		end

		table.insert(stepBehaviors[behavior.step], behavior)
	end

	for step, behaviors in pairs(stepBehaviors) do
		local dependency = Dependency.new(self.rocs, systemDefinition, step, behaviors)
		if step._dependencies == true then
			table.insert(self.rocs._dependencies[Constants.ALL_COMPONENTS], dependency)
		else
			for _, componentResolvable in ipairs(step._dependencies) do
				local staticAggregate = self.rocs._aggregates:getStatic(componentResolvable)

				table.insert(self.rocs._dependencies[staticAggregate], dependency)
			end
		end
	end

	return systemDefinition
end

function SystemCollection:construct(staticSystem)
	local system = staticSystem.new()

	assert(
		getmetatable(system) == staticSystem,
		"Metatable of constructed system must be static system"
	)

	system._consumers = 0

	if system.initialize then
		system:initialize()
	end

	return system
end

function SystemCollection:deconstruct(staticSystem)
	local existingSystem = self._active[staticSystem]
	assert(existingSystem ~= nil, "Attempt to deconstruct non-existent system")

	if existingSystem.destroy then
		existingSystem:destroy()
	end

	self._active[staticSystem] = nil
end

function SystemCollection:get(staticSystem)
	local existingSystem = self._active[staticSystem]
	if existingSystem then
		existingSystem._consumers = existingSystem._consumers + 1
		return existingSystem
	end

	local newSystem = self:construct(staticSystem)
	self._active[staticSystem] = newSystem

	return newSystem
end

function SystemCollection:finished(staticSystem)
	local existingSystem = self._active[staticSystem]
	assert(existingSystem ~= nil, "Attempt to reduce consumers of non-existent system")

	existingSystem._consumers = existingSystem._consumers - 1

	if existingSystem._consumers <= 0 then
		self:deconstruct(staticSystem)
	end
end

return SystemCollection
