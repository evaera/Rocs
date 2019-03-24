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

	local data = setmetatable(reducedValue, {
		__index = staticAggregate.defaults
	})

	if staticAggregate.check then
		assert(staticAggregate.check(data))
	end

	return data
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

function Util.callCounter()
	return setmetatable({
		call = function(self, key)
			self[key] = self[key] + 1
		end
	}, {
		__index = function(self, key)
			self[key] = 0
			return 0
		end
	})
end

function Util.uniqueIdCounter(prefix)
	prefix = prefix or ""
	local count = 0

	return function ()
		count = count + 1
		return prefix .. count
	end
end

local function makeArrayEntityCheck(array)
	return function(instance)
		for _, className in ipairs(array) do
			if instance.ClassName == className then
				return true
			end
		end

		return
			false,
			("Instance type %q is not allowed to have this component!")
				:format(instance.ClassName)
	end
end
function Util.runEntityCheck(staticAggregate, instance)
	if staticAggregate.entityCheck == nil then
		return true
	end

	if type(staticAggregate.entityCheck) == "table" then
		staticAggregate.entityCheck = makeArrayEntityCheck(staticAggregate.entityCheck)
	end

	return staticAggregate.entityCheck(instance)
end

return Util
