local Util = {}

function Util.assign(toObj, ...)
	for _, fromObj in ipairs({...}) do
		for key, value in pairs(fromObj) do
			toObj[key] = value
		end
	end

	return toObj
end

return Util
