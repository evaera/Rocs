local TagWatcher = require(script.TagWatcher)

return function (rocs)
	rocs.tags = TagWatcher.new(rocs)
end
