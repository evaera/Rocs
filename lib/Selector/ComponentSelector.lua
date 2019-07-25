local BaseSelector = require(script.Parent.BaseSelector)

local ComponentSelector = setmetatable({}, BaseSelector)
ComponentSelector.__index = ComponentSelector

function ComponentSelector.new(rocs, componentResolvable, properties, metaComponents)
	local self = setmetatable(BaseSelector.new(rocs), ComponentSelector)

	self._componentResolvable = componentResolvable
	self._properties = properties
	self._metaComponents = metaComponents

	-- TODO handle properties and metaComponents

	return self
end

-- TODO handle properties and metaComponents
function ComponentSelector:setup()
	if self.ready then
		return
	end
	self.ready = true

	self._rocs:registerComponentHook(
		self._componentResolvable,
		"onAdded",
		function(...)
			self:_trigger("onAdded", ...)
		end
	)

	self._rocs:registerComponentHook(
		self._componentResolvable,
		"onRemoved",
		function(...)
			self:_trigger("onRemoved", ...)
		end
	)

	self._rocs:registerComponentHook(
		self._componentResolvable,
		"onUpdated",
		function(...)
			self:_trigger("onUpdated", ...)
		end
	)

	self._rocs:registerComponentHook(
		self._componentResolvable,
		"onParentUpdated",
		function(...)
			self:_trigger("onParentUpdated", ...)
		end
	)

	return self
end

function ComponentSelector:get()
	local cache = {}

	for _, component in pairs(self._rocs:getComponents(self._componentResolvable)) do
		local entity = self._rocs:getEntity(component.instance)
		cache[entity] = true
	end

	for entity in pairs(cache) do
		table.insert(cache, entity)
		cache[entity] = nil
	end

	return cache
end

-- TODO handle properties and metaComponents
function ComponentSelector:check(entity)
	return entity:getComponent(self._componentResolvable) ~= nil
end

return ComponentSelector
