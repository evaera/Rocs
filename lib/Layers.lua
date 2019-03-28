return function (rocs)
	local layers = {}

	layers.system = {
		{
			name = "Layers";
		};
		{
			rocs.dependencies:hasMetadata(rocs.metadata("_layer"))
			:onUpdated(function(_, e)
				for instance, components in pairs(e.data) do
					if not rocs:_getMetadata(instance) then
						local entity = rocs:getEntity(instance, e.data[rocs.metadata("_layer")])

						for component, data in pairs(components) do
							entity:addComponent(component, data)
						end
					end
				end

				if e.lastData then
					for instance, components in pairs(e.lastData) do
						if not rocs:_getMetadata(instance) then
							local entity = rocs:getEntity(instance, e.lastData[rocs.metadata("_layer")])

							for component, data in pairs(components) do
								if not e.data[instance] or not e.data[instance][component] then
									entity:removeComponent(component)
								end
							end
						end
					end
				end
			end)
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
		name = "_layer";
		reducer = rocs.reducers.propertyReducerAll(
			rocs.reducers.propertyReducerAll(
				rocs.reducers.propertyReducerAll(
					rocs.reducers.last,
					true
				)
			)
		);
	}

	layers.metadata = {
		name = "_layer";
	}

	return layers
end
