local Rocs = require(script.Parent.Rocs)
local Players = game:GetService("Players")

Rocs:registerLayer({
	name = "WalkSpeed";

	onUpdated = function(self)
		self.instance.WalkSpeed = self:getOr("speed", 16)
	end;

	components = {
		Replicated = {
			mask = {
				speed = true;
			}
		};
	};

	pipelineCheck = {"Humanoid"};

})

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		wait(1) -- magic wait always works
		local humanoid = character:WaitForChild("Humanoid")

		local pipeline = Rocs:getPipeline(humanoid, "test")

		while true do
			if math.random(1, 10) == 1 then
				pipeline:removeLayer("WalkSpeed")
			else
				pipeline:addLayer("WalkSpeed", {
					speed = math.random(2, 40);
					secret = "very secret";
				})
			end

			wait(2)
		end
	end)
end)
