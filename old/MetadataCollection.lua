local I = require(script.Parent.Parent.Interfaces)
local Constants = require(script.Parent.Parent.Constants)

local MetadataCollection = {}
MetadataCollection.__index = MetadataCollection

function MetadataCollection.new(rocs)
	return setmetatable({
		rocs = rocs;
		_metadata = {};
	}, MetadataCollection)
end

function MetadataCollection:register(metadataDefinition)
	assert(I.Reducible(metadataDefinition))

	self._metadata[metadataDefinition.name] = metadataDefinition

	return metadataDefinition
end

function MetadataCollection:get(name)
	return
		type(name) == "string"
		and name:sub(1, #Constants.METADATA_IDENTIFIER) == Constants.METADATA_IDENTIFIER
		and self._metadata[name:sub(#Constants.METADATA_IDENTIFIER + 1)]
		or nil
end

return MetadataCollection
