local Rocs = require(script.Parent.Rocs)

Rocs:registerLayer({
	name = "Red";

	onUpdated = function(self)
		self.instance.BrickColor = BrickColor.new(self:get("color"))
	end;

	pipelineCheck = {"BasePart"};
})
