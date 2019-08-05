local Rocs = require(script.Parent.Rocs)
local Players = game:GetService("Players")

Rocs:registerComponent({
	name = "WalkSpeed";

	onUpdated = function(self)
		self.instance.WalkSpeed = self:getOr("speed", 16)
	end;

	components = {
		Replicated = true;
	};

	entityCheck = {"Humanoid"};

})

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		wait(1) -- magic wait always works
		local humanoid = character:WaitForChild("Humanoid")

		local entity = Rocs:getEntity(humanoid, "test")

		while true do
			if math.random(1, 10) == 1 then
				entity:removeComponent("WalkSpeed")
			else
				entity:addComponent("WalkSpeed", {
					speed = math.random(2, 40)
				})
			end

			wait(2)
		end
	end)
end)
