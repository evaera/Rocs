local Rocs = require(script.Parent.Rocs)

Rocs:registerLayer({
	name = "Button";
	tag = "Button";

	pipelineCheck = {"BasePart"};

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
