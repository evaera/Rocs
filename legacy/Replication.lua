
local entity = Rocs:getEntity(humanoid, "blah")

local aggregate = entiy:addBaseComponent("Stamina", {
	Current = 50;
	Max = 100;
	ServerONlyvalue = "sdfasf";
}, )

Rocs:getEntity(aggregate):addBaseComponent("Replicated", {
		Current = true;
		Max = true;
})

entity:getComponent("Stamina"):set("Current", 20)
