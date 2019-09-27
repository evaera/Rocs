local BaseSelector = {}
BaseSelector.__index = BaseSelector

function BaseSelector.new(rocs)
	local self = {
		_rocs = rocs,
		_hooks = {
			onAdded = {},
			onRemoved = {},
			onUpdated = {},
			onParentUpdated = {}
		},
		_lookup = {},
		_selectors = {}
	}

	return setmetatable(self, BaseSelector)
end

function BaseSelector:_trigger(lifecycle, ...)
	for _, hook in self._hooks[lifecycle] do
		hook(...)
	end
end

function BaseSelector:fetch()
	if self._ready then
		local instances = {}

		for instance in pairs(self._lookup) do
			table.insert(instances, instance)
		end

		return instances
	else
		return self:instances()
	end
end

function BaseSelector:setup()
	if self._ready then
		return
	end
	self._ready = true

	self:_listen()

	for _, selector in pairs(self._selectors) do
		selector:setup()
	end

	for _, instance in pairs(self:instances()) do
		self._lookup[instance] = true
	end

	return self
end

function BaseSelector:destroy()
	if not self._ready then
		return
	end
	self._ready = nil

	for category, _ in pairs(self._hooks) do
		self._hooks[category] = {}
	end

	for _, selector in pairs(self._selectors) do
		selector:destroy()
	end

	self._lookup = {}

	return self
end

function BaseSelector:onAdded(hook)
	table.insert(self._hooks.onAdded, hook)
	return self
end

function BaseSelector:onRemoved(hook)
	table.insert(self._hooks.onRemoved, hook)
	return self
end

function BaseSelector:onUpdated(hook)
	table.insert(self._hooks.onUpdated, hook)
	return self
end

function BaseSelector:onParentUpdated(hook)
	table.insert(self._hooks.onParentUpdated, hook)
	return self
end

return BaseSelector
