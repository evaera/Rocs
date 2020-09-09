local Rocs = require(script.Parent.Rocs)

Rocs:registerLayer({
	name = "WalkSpeed";

	onUpdated = function(self)
		print("New speed is", self:getOr("speed", "back to default"))
	end
})
