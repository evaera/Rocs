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
		lookup = {}
	}

	return setmetatable(self, BaseSelector)
end

function BaseSelector:_trigger(lifecycle, ...)
	for _, hook in self._hooks[lifecycle] do
		hook(...)
	end
end

function BaseSelector:setup()
	if self.ready then
		return
	end
	self.ready = true

	self._rocs:registerComponentHook(
		self._componentResolvable,
		"onAdded",
		function(aggregate)
			local instance = aggregate.instance
			if not self.lookup[instance] and self:check(instance) then
				self.lookup[instance] = true
				self:_trigger("onAdded", aggregate)
			end
		end
	)

	self._rocs:registerComponentHook(
		self._componentResolvable,
		"onRemoved",
		function(aggregate)
			local instance = aggregate.instance
			if self.lookup[instance] then
				self.lookup[instance] = nil
				self:_trigger("onRemoved", aggregate)
			end
		end
	)

	self._rocs:registerComponentHook(
		self._componentResolvable,
		"onUpdated",
		function(aggregate)
			local instance = aggregate.instance
			if self.lookup[instance] then
				if self:check(instance) then
					self:_trigger("onUpdated", aggregate)
				else
					self.lookup[instance] = nil
					self:_trigger("onRemoved", aggregate)
				end
			else
				if self:check(instance) then
					self.lookup[instance] = true
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
			if self.lookup[aggregate.instance] then
				self:_trigger("onParentUpdated", aggregate)
			end
		end
	)

	return self
end

function BaseSelector:onAdded(hook)
	table.insert(self._hooks.onAdded, hook)
end

function BaseSelector:onRemoved(hook)
	table.insert(self._hooks.onRemoved, hook)
end

function BaseSelector:onUpdated(hook)
	table.insert(self._hooks.onUpdated, hook)
end

function BaseSelector:onParentUpdated(hook)
	table.insert(self._hooks.onParentUpdated, hook)
end

return BaseSelector
