local Constants = require(script.Parent.Parent.Constants)

local Lens = {}
Lens.__index = Lens

function Lens:get(...)
	local object = self.data

	if object == nil then
		return
	end

	for _, field in ipairs({...}) do
		object = object[field]

		if object == nil then
			return
		end
	end

	return object
end

function Lens:getOr(...)
	local path = {...}
	local default = table.remove(path, #path)

	local value = self:get(unpack(path))

	if value ~= nil then
		return value
	elseif type(default) == "function" then
		return default(unpack(path))
	else
		return default
	end
end

function Lens:getAnd(...)
	local path = {...}
	local callback = table.remove(path, #path)

	local value = self:get(unpack(path))

	if value ~= nil then
		return callback(value)
	end
end

function Lens:set(...)
		local path = {...}
		local value = table.remove(path, #path)

		assert(value ~= nil, "Must provide a value to set")

		if value == Constants.None then
			value = nil
		end

		local currentValue = self.components[Constants.SCOPE_BASE] or {}

		while #path > 1 do
			currentValue = currentValue[table.remove(path, 1)]
		end

		if path[1] then
			currentValue[path[1]] = value
		else
			currentValue = value
		end

		return self.rocs._lenses:addLayer(self.instance, getmetatable(self), Constants.SCOPE_BASE, currentValue)
end

function Lens:listen(eventName, callback)
	if not self._listeners then
		self._listeners = {}
	end

	if not self._listeners[eventName] then
		self._listeners[eventName] = {}
	end

	table.insert(self._listeners[eventName], callback)

	return callback
end

function Lens:removeListener(eventName, callback)
	if self._listeners and self._listeners[eventName] then
		for i, listener in ipairs(self._listeners[eventName]) do
			if listener == callback then
				table.remove(self._listeners[eventName], i)
				break
			end
		end

		if #self._listeners[eventName] == 0 then
			self._listeners[eventName] = nil

			if next(self._listeners) == nil then
				self._listeners = nil
			end
		end
	end
end

function Lens:dispatch(eventName, ...)
	if self[eventName] then
		self[eventName](self, ...)
	end

	if self._listeners and self._listeners[eventName] then
		for _, listener in ipairs(self._listeners[eventName]) do
			listener(...)
		end
	end
end

function Lens:__tostring()
	return ("Lens(%s)"):format(self.name)
end

return Lens
