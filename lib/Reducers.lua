local Util = require(script.Parent.Util)

return function (rocs)
	local Reducers = {}

	function Reducers.last(values)
		return values[#values]
	end

	function Reducers.first(values)
			return values[1]
	end

	function Reducers.add(values)
		local reducedValue = 0

		for _, value in ipairs(values) do
			reducedValue = reducedValue + value
		end

		return reducedValue
	end

	function Reducers.propertyReducer(propertyReducers)
		return function(values)
			local properties = {}

			for _, value in ipairs(values) do
				for propName, propValue in pairs(value) do
					if properties[propName] == nil then
						properties[propName] = {}
					end

					table.insert(properties[propName], propValue)
				end
			end

			local reducedValue = {}

			for propName, propValues in pairs(properties) do
				if rocs and rocs:_getMetadata(propName) then
					local reducible = rocs:_getMetadata(propName)

					reducedValue[propName] = Util.runReducer(reducible, propValues)
				else
					reducedValue[propName] =
						(propertyReducers[propName] or Reducers.last)(propValues)
				end
			end

			return reducedValue
		end
	end

	Reducers.default = Reducers.propertyReducer({})

	return Reducers
end
