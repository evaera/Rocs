local Constants = require(script.Parent.Parent.Constants)

local Aggregate = {}
Aggregate.__index = Aggregate

function Aggregate:get(...)
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

function Aggregate:getOr(...)
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

function Aggregate:getAnd(...)
	local path = {...}
	local callback = table.remove(path, #path)

	local value = self:get(unpack(path))

	if value ~= nil then
		return callback(value)
	end
end

function Aggregate:set(...)
		local path = {...}
		local value = table.remove(path, #path)

		assert(value ~= nil, "Must provide a value to set")

		if value == Constants.None then
			value = nil
		end

		local currentValue = self.data or {}

		while #path > 1 do
			currentValue = currentValue[table.remove(path, 1)]
		end

		if path[1] then
			currentValue[path[1]] = value
		else
			currentValue = value
		end

		return self.rocs._aggregates:addComponent(self.instance, getmetatable(self), Constants.SCOPE_BASE, currentValue)
end

function Aggregate:__tostring()
	return ("Aggregate(%s)"):format(self.name)
end

return Aggregate