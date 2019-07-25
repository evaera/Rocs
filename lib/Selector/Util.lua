local Util = {}

local ComponentSelector = require(script.Parent.ComponentSelector)

function Util.resolve(rocs, selectorResolvable)
	if typeof(selectorResolvable) == "string" then
		return ComponentSelector.new(rocs, selectorResolvable)
	end
	return selectorResolvable
end

return Util
