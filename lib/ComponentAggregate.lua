local ComponentAggregate = {}
ComponentAggregate.__index = ComponentAggregate

function ComponentAggregate:__tostring()
	return ("ComponentAggregate(%s)"):format(self.name)
end

function ComponentAggregate:getEntities()

end

return ComponentAggregate
