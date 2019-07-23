local QueryFilter = {}
QueryFilter.__index = QueryFilter

function QueryFilter.new(options)
	return setmetatable(options, QueryFilter)
end
