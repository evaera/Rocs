local Rocs = require(script.Parent.Rocs)

Rocs:registerComponent({
	name = "Red";

	onAdded = function(self)
		self.instance.BrickColor = BrickColor.new("Really red")
	end;

	entityCheck = {"BasePart"};
})
