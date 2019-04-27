local HttpService = game:GetService("HttpService")

local I = require(script.Parent.Interfaces)
local t = require(script.Parent.t)
local Constants = require(script.Parent.Constants)

local RESERVED_SCOPES = {
	[Constants.SCOPE_BASE] = true;
	[Constants.SCOPE_REMOTE] = true;
}

local Entity = {}
Entity.__index = Entity

function Entity.new(rocs, instance, scope)
	assert(RESERVED_SCOPES[scope] == nil, ("Entity scope cannot be %q"):format(scope))

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

function Entity:addComponent(componentResolvable, data)
	warn("ADD", self.instance, componentResolvable, data)
	return self.rocs._aggregates:addComponent(
		self:_getComponentOpValues(componentResolvable, nil, data or {})
	)
end

function Entity:removeComponent(componentResolvable)
	warn("REMOVE", self.instance, componentResolvable)
	return self.rocs._aggregates:removeComponent(
		self:_getComponentOpValues(componentResolvable)
	)
end

function Entity:addBaseComponent(componentResolvable, data)
	return self.rocs._aggregates:addComponent(
		self:_getComponentOpValues(componentResolvable, Constants.SCOPE_BASE, data or {})
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

function Entity:addLayer(layer, layerId, componentResolvable)
	layerId = layerId or HttpService:GenerateGUID()

	local layerComponent = self.rocs:_getLayerComponent(
		layerId,
		componentResolvable or self.rocs._aggregates:getStatic(Constants.LAYER_IDENTIFIER)
	)

	assert(layerComponent ~= nil)

	layer[self.rocs.metadata(Constants.LAYER_IDENTIFIER)] = layerId

	self.rocs._aggregates:addComponent(
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

	self.rocs._aggregates:removeComponent(
		self.instance,
		layerComponent,
		self.scope
	)
end

return Entity
