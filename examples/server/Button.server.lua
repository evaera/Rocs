local Rocs = require(script.Parent.Rocs)

Rocs:registerComponent({
	name = "Button";
	tag = "Button";

	entityCheck = {"BasePart"};

	chainingEvents = {"click"};

	onAdded = function(self)
		self._clickDetector = Instance.new("ClickDetector", self.instance)

		self._clickDetector.MouseClick:Connect(function(...)
			self:dispatch("click", ...)
		end)
	end;

	onRemoved = function(self)
		self._clickDetector:Destroy()
	end
})
