local Rocs = require(script.Parent.Rocs)

Rocs:registerComponent({
	name = "Red";
	tag = "Red";

	entityCheck = {"BasePart"};

	components = {
		Replicated = true;
	};
})
