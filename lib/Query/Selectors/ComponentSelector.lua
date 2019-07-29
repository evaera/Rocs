local BaseSelector = require(script.Parent.BaseSelector)

local ComponentSelector = setmetatable({}, BaseSelector)
ComponentSelector.__index = ComponentSelector

function ComponentSelector.new(rocs, componentResolvable, properties, metaComponents)
	assert(componentResolvable)
	local self = setmetatable(BaseSelector.new(rocs), ComponentSelector)

	self._componentResolvable = componentResolvable
	self._properties = properties or {}
	self._metaComponents = metaComponents or {}

	return self
end

function ComponentSelector:_listen()

	self._rocs:registerComponentHook(
		self._componentResolvable,
		"onAdded",
		function(aggregate)
			local instance = aggregate.instance
			if not self._lookup[instance] and self:check(instance) then
				self._lookup[instance] = true
				self:_trigger("onAdded", aggregate)
			end
		end
	)

	self._rocs:registerComponentHook(
		self._componentResolvable,
		"onRemoved",
		function(aggregate)
			local instance = aggregate.instance
			if self._lookup[instance] then
				self._lookup[instance] = nil
				self:_trigger("onRemoved", aggregate)
			end
		end
	)

	self._rocs:registerComponentHook(
		self._componentResolvable,
		"onUpdated",
		function(aggregate)
			local instance = aggregate.instance
			if self._lookup[instance] then
				if self:check(instance) then
					self:_trigger("onUpdated", aggregate)
				else
					self._lookup[instance] = nil
					self:_trigger("onRemoved", aggregate)
				end
			else
				if self:check(instance) then
					self._lookup[instance] = true
					self:_trigger("onAdded", aggregate)
				else
					self:_trigger("onUpdated", aggregate)
				end
			end
		end
	)

	-- TODO: is this right?
	self._rocs:registerComponentHook(
		self._componentResolvable,
		"onParentUpdated",
		function(aggregate)
			if self._lookup[aggregate.instance] then
				self:_trigger("onParentUpdated", aggregate)
			end
		end
	)

end

function ComponentSelector:instances()
	local instances = {}

	for _, component in pairs(self._rocs:getComponents(self._componentResolvable)) do
		instances[component.instance] = true
	end

	for instance in pairs(instances) do
		table.insert(instances, instance)
		instances[instance] = nil
	end

	return instances
end

function ComponentSelector:check(instance)
	local component = self._rocs:getEntity(instance):getComponent(self._componentResolvable)
	if not component then
		return false
	end

	for key, property in pairs(self._properties) do
		-- TODO handle properties
	end

	for name, _ in pairs(self._metaComponents) do
		-- TODO handle meta-components
	end

	return true
end

return ComponentSelector
