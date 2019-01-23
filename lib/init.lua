local Util = require(script.Util)
local I = require(script.Interfaces)
local ComponentAggregate = require(script.ComponentAggregate)
local Entity = require(script.Entity)
local t = require(script.t)

local Rocs = {}
Rocs.__index = Rocs

function Rocs.new()
	return setmetatable({
		_entities = {};
		_components = {};
		_systems = {};
	}, Rocs)
end

function Rocs:registerSystem(systemDefinition)
	assert(I.System(systemDefinition))


end

function Rocs:registerComponent(componentDefinition)
	assert(I.ComponentDefinition(componentDefinition))

	componentDefinition.__index = componentDefinition.__index or componentDefinition
	componentDefinition.__tostring = ComponentAggregate.__tostring

	local component = setmetatable(componentDefinition, ComponentAggregate)
	self._components[componentDefinition.name] = component

	return component
end

local getEntityCheck = t.tuple(t.Instance, t.string)
function Rocs:getEntity(instance, scope)
	assert(getEntityCheck(instance, scope))

	return Entity.new(self, instance, scope)
end

function Rocs:_getStaticComponentAggregate(componentResolvable)
	if type(componentResolvable) == "string" then
		return self._components[componentResolvable] or error(("Cannot resolve component %s"):format(componentResolvable))
	end

	return getmetatable(componentResolvable) == ComponentAggregate
		and componentResolvable
		or error("Invalid value passed in place of static component aggregate", 2)
end

function Rocs:_constructSystem(systemBase)
	local system = setmetatable({}, systemBase)

	if system.initialize then
		system.initialize()
	end

	return system
end

function Rocs:_constructComponentAggregate(staticComponentAggregate, instance)
	local aggregate = setmetatable({
		components = {};
		data = {};
		instance = instance;
	}, staticComponentAggregate)

	if aggregate.initialize then
		aggregate.initialize()
	end

	return aggregate
end

local addComponentCheck = t.tuple(t.Instance, t.table, t.string, t.table)
function Rocs:_addComponent(instance, staticComponentAggregate, scope, data)
	assert(addComponentCheck(instance, staticComponentAggregate, scope, data))

	if self._entities[instance] == nil then
		self._entities[instance] = {}
	end

	if self._entities[instance][staticComponentAggregate] == nil then
		self._entities[instance][staticComponentAggregate] =
			self:_constructComponentAggregate(staticComponentAggregate, instance)
	end

	self._entities[instance][staticComponentAggregate].components[scope] = data

	-- TODO: Dispatch Update to dependent systems
end

function Rocs:_removeComponent(instance, staticComponentAggregate, scope)
	if
		self._entities[instance] == nil
		or self._entities[instance][staticComponentAggregate] == nil
	then
		return
	end

	self._entities[instance][staticComponentAggregate].components[scope] = nil

	-- TODO: Dispatch Update to dependent systems
end

function Rocs:_getComponentAggregate(instance, staticComponentAggregate)
	return
		self._entities[instance]
		and self._entities[instance][staticComponentAggregate]
end

return Rocs
