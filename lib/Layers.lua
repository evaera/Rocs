return function (rocs)
	local layers = {}

	layers.system = {
		[rocs.dependencies:hasMetadata(rocs.metadata("_layer"))] = {
			onUpdated = function(_, e)
				for instance, components in pairs(e.target.data) do
					if not rocs:isMetadata(instance) then
						local entity = rocs:getEntity(instance, e.target.data[rocs.metadata("_layer")])

						for component, data in pairs(components) do
							entity:addComponent(component, data)
						end
					end
				end
			end
		}
	}
	--[[
		{
			Instance = {
				Component = {
					(data)
				}
			}
		}
	]]

	layers.component = {
		reducer = rocs.reducers.propertyReducerAll(
			rocs.reducers.propertyReducerAll(
				rocs.reducers.propertyReducerAll(
					rocs.reducers.last,
					true
				)
			)
		);
	}

	return layers
end
