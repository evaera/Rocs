local Rocs = require(script.Parent.Rocs)

Rocs:registerComponent({
	name = "WalkSpeed";

	onUpdated = function(self)
		print("New speed is", self.data.speed)
	end
})
