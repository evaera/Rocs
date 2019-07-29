local Rocs = require(script.Parent.Rocs)
local Players = game:GetService("Players")

Rocs:registerComponent({
	name = "WalkSpeed";

	onUpdated = function(self)
		local data = self.data or {
			speed = 16
		}

		self.instance.WalkSpeed = data.speed
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
			entity:addComponent("WalkSpeed", {
				speed = math.random(2, 40)
			})

			wait(2)
		end
	end)
end)
