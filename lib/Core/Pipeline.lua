local I = require(script.Parent.Types)
local t = require(script.Parent.Parent.Shared.t)
local Constants = require(script.Parent.Constants)

local Pipeline = {}
Pipeline.__index = Pipeline

function Pipeline.new(rocs, instance, scope, overrideReserveCheck)
	assert(
		overrideReserveCheck == true or
		Constants.RESERVED_SCOPES[scope] == nil,
		("Pipeline scope cannot be %q"):format(scope)
	)

	return setmetatable({
		rocs = rocs;
		instance = instance;
		scope = scope;
	}, Pipeline)
end

function Pipeline:__tostring()
	return ("Pipeline(%s)"):format(tostring(self.instance))
end

local getLayerOpValuesCheck = t.tuple(
	I.LayerResolvable,
	t.optional(t.string)
)
function Pipeline:_getLayerOpValues(componentResolvable, scope, ...)
	assert(getLayerOpValuesCheck(componentResolvable, scope))
	return
		self.instance,
		self.rocs._lenses:getStatic(componentResolvable),
		scope or self.scope,
		...
end

function Pipeline:addLayer(componentResolvable, data, metacomponents)
	if self.rocs.debug then
		warn("ADD", self.instance, componentResolvable, data)
	end
	return self.rocs._lenses:addLayer(
		self:_getLayerOpValues(componentResolvable, nil, data or {}, metacomponents)
	)
end

function Pipeline:removeLayer(componentResolvable)
	if self.rocs.debug then
		warn("REMOVE", self.instance, componentResolvable)
	end
	return self.rocs._lenses:removeLayer(
		self:_getLayerOpValues(componentResolvable)
	)
end

function Pipeline:addBaseLayer(componentResolvable, data, metacomponents)
	return self.rocs._lenses:addLayer(
		self:_getLayerOpValues(componentResolvable, Constants.SCOPE_BASE, data or {}, metacomponents)
	)
end

function Pipeline:removeBaseLayer(componentResolvable)
	return self.rocs._lenses:removeLayer(
		self:_getLayerOpValues(componentResolvable, Constants.SCOPE_BASE)
	)
end

function Pipeline:getLayer(componentResolvable)
	return self.rocs._lenses:get(
		self:_getLayerOpValues(componentResolvable)
	)
end

function Pipeline:getAllLayers()
	return self.rocs._lenses:getAll(self.instance)
end

function Pipeline:removeAllLayers()
	return self.rocs._lenses:removeAllLayers(self.instance)
end

function Pipeline:getScope(newScope)
	return self.rocs:getPipeline(self.instance, newScope)
end

return Pipeline
