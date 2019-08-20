local Rocs = require(script.Parent.Rocs)

Rocs:registerComponent({
	name = "Red";

	onUpdated = function(self)
		self.instance.BrickColor = BrickColor.new(self:get("color"))
	end;

	entityCheck = {"BasePart"};
})
