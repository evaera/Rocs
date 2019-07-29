local Replicator = require(script.Replicator)

return function (rocs)
	rocs.replicator = Replicator.new(rocs)
end
