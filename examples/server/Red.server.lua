local Rocs = require(script.Parent.Rocs)

Rocs:registerLayer({
	name = "Red";
	tag = "Red";

	pipelineCheck = {"BasePart"};

	components = {
		Replicated = {
			players = {};
		};
	};

	defaults = {
		color = "Really red"
	};

	randomize = function(self)
		self:set("color", BrickColor.random().Name)
	end;
})
