local Util = {}

local LayerSelector = require(script.Parent.LayerSelector)
local BaseSelector = require(script.Parent.BaseSelector)

function Util.inheritsBase(object)
	local depth = 0
	while type(object) == "table" do
		object = getmetatable(object)
		depth = depth + 1
		if object == BaseSelector then
			return depth >= 2
		end
	end
	return false
end

function Util.resolve(rocs, selectorResolvable)
	if type(selectorResolvable) == "string" then
		return LayerSelector.new(rocs, selectorResolvable)
	end
	assert(Util.inheritsBase(selectorResolvable))
	return selectorResolvable
end

return Util
