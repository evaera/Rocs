local BaseSelector = require(script.Parent.BaseSelector)

local ComponentSelector = setmetatable({}, BaseSelector)
ComponentSelector.__index = ComponentSelector

function ComponentSelector.new(rocs, componentResolvable, properties, metaComponents)
	assert(componentResolvable)
	local self = setmetatable(BaseSelector.new(rocs), ComponentSelector)

	self._componentResolvable = componentResolvable
	self._properties = properties
	self._metaComponents = metaComponents

	return self
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

	if self.properties then
		-- TODO handle properties
	end

	if self.metaComponents then
		-- TODO handle metacomponents
	end

	return true
end

return ComponentSelector
