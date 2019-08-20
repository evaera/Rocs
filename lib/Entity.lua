local I = require(script.Parent.Types)
local t = require(script.Parent.t)
local Constants = require(script.Parent.Constants)

local Entity = {}
Entity.__index = Entity

function Entity.new(rocs, instance, scope, overrideReserveCheck)
	assert(
		overrideReserveCheck == true or
		Constants.RESERVED_SCOPES[scope] == nil,
		("Entity scope cannot be %q"):format(scope)
	)

	return setmetatable({
		rocs = rocs;
		instance = instance;
		scope = scope;
	}, Entity)
end

function Entity:__tostring()
	return ("Entity(%s)"):format(tostring(self.instance))
end

local getComponentOpValuesCheck = t.tuple(
	I.ComponentResolvable,
	t.optional(t.string)
)
function Entity:_getComponentOpValues(componentResolvable, scope, ...)
	assert(getComponentOpValuesCheck(componentResolvable, scope))
	return
		self.instance,
		self.rocs._aggregates:getStatic(componentResolvable),
		scope or self.scope,
		...
end

function Entity:addComponent(componentResolvable, data, metacomponents)
	if self.rocs.debug then
		warn("ADD", self.instance, componentResolvable, data)
	end
	return self.rocs._aggregates:addComponent(
		self:_getComponentOpValues(componentResolvable, nil, data or {}, metacomponents)
	)
end

function Entity:removeComponent(componentResolvable)
	if self.rocs.debug then
		warn("REMOVE", self.instance, componentResolvable)
	end
	return self.rocs._aggregates:removeComponent(
		self:_getComponentOpValues(componentResolvable)
	)
end

function Entity:addBaseComponent(componentResolvable, data, metacomponents)
	return self.rocs._aggregates:addComponent(
		self:_getComponentOpValues(componentResolvable, Constants.SCOPE_BASE, data or {}, metacomponents)
	)
end

function Entity:removeBaseComponent(componentResolvable)
	return self.rocs._aggregates:removeComponent(
		self:_getComponentOpValues(componentResolvable, Constants.SCOPE_BASE)
	)
end

function Entity:getComponent(componentResolvable)
	return self.rocs._aggregates:get(
		self:_getComponentOpValues(componentResolvable)
	)
end

function Entity:getAllComponents()
	return self.rocs._aggregates:getAll(self.instance)
end

function Entity:removeAllComponents()
	return self.rocs._aggregates:removeAllComponents(self.instance)
end

function Entity:getScope(newScope)
	return self.rocs:getEntity(self.instance, newScope)
end

return Entity
