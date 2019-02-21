local Entity = {}
Entity.__index = Entity

function Entity.new(rocs, instance, scope)
	assert(scope ~= "base", 'Entity scope cannot be "base"')

	return setmetatable({
		rocs = rocs;
		instance = instance;
		scope = scope;
	}, Entity)
end

function Entity:__tostring()
	return ("Entity(%s)"):format(tostring(self.instance))
end

function Entity:_getComponentOpValues(componentResolvable, scope, ...)
	return
		self.instance,
		self.rocs:_getstaticAggregate(componentResolvable),
		scope or self.scope,
		...
end

function Entity:addComponent(componentResolvable, data)
	return self.rocs:_addComponent(
		self:_getComponentOpValues(componentResolvable, nil, data or {})
	)
end

function Entity:removeComponent(componentResolvable)
	return self.rocs:_removeComponent(
		self:_getComponentOpValues(componentResolvable)
	)
end

function Entity:addBaseComponent(componentResolvable, data)
	return self.rocs:_addComponent(
		self:_getComponentOpValues(componentResolvable, "base", data or {})
	)
end

function Entity:removeBaseComponent(componentResolvable)
	return self.rocs:_removeComponent(
		self:_getComponentOpValues(componentResolvable, "base")
	)
end

function Entity:getComponent(componentResolvable)
	return self.rocs:_getAggregate(
		self:_getComponentOpValues(componentResolvable)
	)
end

return Entity
