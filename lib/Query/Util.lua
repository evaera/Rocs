local Util = {}

local ComponentSelector = require(script.Parent.Selectors.ComponentSelector)
local BaseSelector = require(script.Parent.Selectors.BaseSelector)

function Util.resolve(rocs, selectorResolvable)
	if type(selectorResolvable) == "string" then
		return ComponentSelector.new(rocs, selectorResolvable)
	end
	return selectorResolvable
end

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

return Util
