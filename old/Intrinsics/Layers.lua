-- local inspect = require(script.Parent.Parent.Inspect).inspect
local Constants = require(script.Parent.Parent.Constants)

return function (rocs)
	rocs:registerSystem({
			name = "Layers";
		}, {
			rocs.dependencies:hasMetadata(rocs.metadata(Constants.LAYER_IDENTIFIER))
			:onUpdated(function(_, e)
				for instance, components in pairs(e.data) do
					if not rocs._metadata:get(instance) then
						local entity = rocs:getEntity(instance, e.data[rocs.metadata(Constants.LAYER_IDENTIFIER)])

						for component, data in pairs(components) do
							entity:addComponent(component, data)
						end
					end
				end

				if e.lastData then
					for instance, components in pairs(e.lastData) do
						if not rocs._metadata:get(instance) then
							local entity = rocs:getEntity(instance, e.lastData[rocs.metadata(Constants.LAYER_IDENTIFIER)])

							for component in pairs(components) do
								if not e.data[instance] or not e.data[instance][component] then
									entity:removeComponent(component)
								end
							end
						end
					end
				end
			end)
		}
	)

	rocs:registerComponent({
		name = Constants.LAYER_IDENTIFIER;
		reducer = rocs.reducers.map(
			rocs.reducers.map(
				rocs.reducers.map(
					rocs.reducers.last,
					true
				)
			)
		);
	})

	rocs:registerMetadata({
		name = Constants.LAYER_IDENTIFIER;
	})
end
