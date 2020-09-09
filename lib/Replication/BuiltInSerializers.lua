local Lens = require(script.Parent.Parent.Core.Lens.Lens)

return {
	serializers = {
		[Lens] = function(lens, rocs)

			return {
				type = "_lens";
				name = lens.name;
				instance = rocs.replicator:_serialize(lens.instance);
			}
		end
	};

	deserializers = {
		_lens = function(data, rocs)
			local instance = rocs.replicator:_deserialize(data.instance)

			return rocs:getPipeline(instance, "replicator"):getLayer(data.name)
		end
	};
}
