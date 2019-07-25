local BaseSelector = {}
BaseSelector.__index = BaseSelector

function BaseSelector.new(rocs)
	local self = {
		rocs = rocs,
		hooks = {
			onAdded = {},
			onRemoved = {},
			onUpdated = {},
			onParentUpdated = {}
		}
	}

	return setmetatable(self, BaseSelector)
end

function BaseSelector:_trigger(lifecycle, ...)
	for _, hook in self.hooks[lifecycle] do
		hook(...)
	end
end

function BaseSelector:onAdded(hook)
	table.insert(self.hooks.onAdded, hook)
end

function BaseSelector:onRemoved(hook)
	table.insert(self.hooks.onRemoved, hook)
end

function BaseSelector:onUpdated(hook)
	table.insert(self.hooks.onUpdated, hook)
end

function BaseSelector:onParentUpdated(hook)
	table.insert(self.hooks.onParentUpdated, hook)
end

return BaseSelector
