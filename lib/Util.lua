local Util = {}

function Util.assign(toObj, ...)
	for _, fromObj in ipairs({...}) do
		for key, value in pairs(fromObj) do
			toObj[key] = value
		end
	end

	return toObj
end

function Util.runReducer(staticAggregate, values, defaultReducer)
	local reducedValue = (staticAggregate.reducer or defaultReducer)(values)

	if staticAggregate.check then
		assert(staticAggregate.check(reducedValue))
	end

	return setmetatable(reducedValue, {
		__index = staticAggregate.defaults
	})
end

function Util.makeToString(staticName)
	return function(self)
		return ("%s(%s)"):format(staticName, getmetatable(self).name)
	end
end

function Util.concat(list, ...)
	local args = { ... }
	local result = {}
	for i = 1, #list do
		result[i] = list[i]
	end
	for i = 1, #args do
		local value = args[i]
		for j = 1, #value do
			result[#result + 1] = value[j]
		end
	end
	return result
end

return Util
