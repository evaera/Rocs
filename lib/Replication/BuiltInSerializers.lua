local Aggregate = require(script.Parent.Parent.Aggregate.Aggregate)

return {
	serializers = {
		[Aggregate] = function(aggregate, rocs)

			return {
				type = "_aggregate";
				name = aggregate.name;
				instance = rocs.replicator:_serialize(aggregate.instance);
			}
		end
	};

	deserializers = {
		_aggregate = function(data, rocs)
			local instance = rocs.replicator:_deserialize(data.instance)

			return rocs:getEntity(instance, "replicator"):getComponent(data.name)
		end
	};
}
