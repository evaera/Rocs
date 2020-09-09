local BaseSelector = require(script.Parent.BaseSelector)

local LayerSelector = setmetatable({}, BaseSelector)
LayerSelector.__index = LayerSelector

function LayerSelector.new(rocs, componentResolvable, properties, metaLayers)
	assert(componentResolvable)
	local self = setmetatable(BaseSelector.new(rocs), LayerSelector)

	self._componentResolvable = componentResolvable
	self._properties = properties or {}
	self._metaLayers = metaLayers or {}

	return self
end

function LayerSelector:_listen()

	self._rocs:registerLayerHook(
		self._componentResolvable,
		"onAdded",
		function(lens)
			local instance = lens.instance
			if not self._lookup[instance] and self:check(instance) then
				self._lookup[instance] = true
				self:_trigger("onAdded", lens)
			end
		end
	)

	self._rocs:registerLayerHook(
		self._componentResolvable,
		"onRemoved",
		function(lens)
			local instance = lens.instance
			if self._lookup[instance] then
				self._lookup[instance] = nil
				self:_trigger("onRemoved", lens)
			end
		end
	)

	self._rocs:registerLayerHook(
		self._componentResolvable,
		"onUpdated",
		function(lens)
			local instance = lens.instance
			if self._lookup[instance] then
				if self:check(instance) then
					self:_trigger("onUpdated", lens)
				else
					self._lookup[instance] = nil
					self:_trigger("onRemoved", lens)
				end
			else
				if self:check(instance) then
					self._lookup[instance] = true
					self:_trigger("onAdded", lens)
				else
					self:_trigger("onUpdated", lens)
				end
			end
		end
	)

	-- TODO: is this right?
	self._rocs:registerLayerHook(
		self._componentResolvable,
		"onParentUpdated",
		function(lens)
			if self._lookup[lens.instance] then
				self:_trigger("onParentUpdated", lens)
			end
		end
	)

end

function LayerSelector:instances()
	local instances = {}

	for _, component in pairs(self._rocs:getLayers(self._componentResolvable)) do
		instances[component.instance] = true
	end

	for instance in pairs(instances) do
		table.insert(instances, instance)
		instances[instance] = nil
	end

	return instances
end

function LayerSelector:check(instance)
	local component = self._rocs:getPipeline(instance):getLayer(self._componentResolvable)
	if not component then
		return false
	end

	for key, property in pairs(self._properties) do
		-- TODO handle properties
	end

	for name, _ in pairs(self._metaLayers) do
		-- TODO handle meta-components
	end

	return true
end

return LayerSelector
