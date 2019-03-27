local HttpService = game:GetService("HttpService")

local I = require(script.Parent.Interfaces)
local t = require(script.Parent.t)

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

local getComponentOpValuesCheck = t.tuple(
	I.ComponentResolvable,
	t.optional(t.string)
)
function Entity:_getComponentOpValues(componentResolvable, scope, ...)
	assert(getComponentOpValuesCheck(componentResolvable, scope))
	return
		self.instance,
		self.rocs:_getStaticAggregate(componentResolvable),
		scope or self.scope,
		...
end

function Entity:addComponent(componentResolvable, data)
	warn("ADD", self.instance, componentResolvable, data)
	return self.rocs:_addComponent(
		self:_getComponentOpValues(componentResolvable, nil, data or {})
	)
end

function Entity:removeComponent(componentResolvable)
	warn("REMOVE", self.instance, componentResolvable)
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

function Entity:addLayer(layer, layerId, componentResolvable)
	layerId = layerId or HttpService:GenerateGUID()

	local layerComponent = self.rocs:_getLayerComponent(
		layerId,
		componentResolvable or self.rocs._layers.component
	)

	assert(layerComponent ~= nil)

	layer[self.rocs.metadata("_layer")] = layerId

	self.rocs:_addComponent(
		self.instance,
		layerComponent,
		self.scope,
		layer
	)

	return layerId
end

function Entity:addSelfLayer(layerData, ...)
	return self:addLayer({
		[self.instance] = layerData
	}, ...)
end

function Entity:removeLayer(layerId)
	local layerComponent = self.rocs._layerComponents[layerId]

	assert(layerComponent ~= nil, "Layer ID invalid")

	self.rocs:_removeComponent(
		self.instance,
		layerComponent,
		self.scope
	)
end

return Entity
