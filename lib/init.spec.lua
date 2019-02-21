local t = require(script.Parent.t)
local Util = require(script.Parent.Util)
local Rocs = require(script.Parent)

local function makeTestCmp(rocs, callCounts)
	callCounts = callCounts or Util.callCounter()

	local reducers = rocs.reducers

	return {
		name = "Test";
		initialize = function(self)
			expect(self).to.be.ok()
			callCounts:call("testCmpInit")
		end;
		destroy = function(self)
			expect(self).to.be.ok()
			callCounts:call("testCmpDestroy")
		end;
		defaults = {
			[Rocs.metadata("Replicated")] = true;
			testDefault = 5;
		};
		reducer = reducers.propertyReducer({
			nested = reducers.propertyReducer({
				value = reducers.last;
			})
		});
		check = t.interface({});
		entityCheck = t.instance("Workspace");
		tag = "Test";
	}
end

return function()
	describe("Components", function()
		local rocs = Rocs.new()
		local callCounts = Util.callCounter()
		local testCmp = makeTestCmp(rocs, callCounts)
		rocs:registerComponent(testCmp)

		local reducers = rocs.reducers
		rocs:registerMetadata({
			name = "MtTest";
			reducer = reducers.propertyReducer({
				num = reducers.add;
			});
			check = t.interface({
				num = t.number;
			})
		})

		it("should apply components", function()
			local ent = rocs:getEntity(workspace, "foo")

			expect(callCounts.testCmpInit).to.equal(0)
			ent:addComponent(testCmp, {
				one = 1;
				[Rocs.metadata("MtTest")] = {
					num = 2;
				}
			})
			expect(callCounts.testCmpInit).to.equal(1)
			ent:addBaseComponent("Test", {
				two = 2;
				[Rocs.metadata("MtTest")] = {
					num = 1;
				}
			})

			local cmpAg = rocs._entities[workspace] and rocs._entities[workspace][testCmp]

			expect(cmpAg).to.be.ok()

			expect(cmpAg.components.base).to.be.ok()
			expect(cmpAg.components.base.two).to.equal(2)

			expect(cmpAg.components.foo).to.be.ok()
			expect(cmpAg.components.foo.one).to.equal(1)

			expect(cmpAg:get()).to.equal(cmpAg.data)

			expect(cmpAg:get("one")).to.equal(1)
			expect(cmpAg:get("two")).to.equal(2)
			expect(cmpAg:get("testDefault")).to.equal(5)

			expect(cmpAg:get(Rocs.metadata("MtTest"), "num")).to.equal(3)

			expect(tostring(cmpAg)).to.equal("aggregate(Test)")

			ent:removeComponent(testCmp)
			ent:removeBaseComponent(testCmp)
			expect(callCounts.testCmpDestroy).to.equal(1)
		end)
	end)

	describe("Systems", function()
		local rocs = Rocs.new()
		rocs:registerComponent(makeTestCmp(rocs))

		it("should fire lifecycle methods", function()
			local dep = rocs.dependencies:hasComponent("Test")

			local counter = Util.callCounter()
			rocs:registerSystem({
				name = "test";

				initialize = function(self)
					counter:call("initialize")
					expect(self).to.be.ok()
				end;

				destroy = function(self)
					counter:call("destroy")
					expect(self).to.be.ok()
				end;

				[dep] = {
					onAdded = function(self, entity, map)
						expect(getmetatable(self).name).to.equal("test")
						expect(entity.scope).to.equal("system__test")
						expect(map.Test).to.be.ok()
						expect(map.Test:get("one")).to.equal(1)

						counter:call("added")
					end;
					onUpdated = function(self, entity, map)
						expect(getmetatable(self).name).to.equal("test")
						expect(entity.scope).to.equal("system__test")
						expect(map.Test).to.be.ok()
						expect(map.Test:get("one")).to.equal(1)

						counter:call("updated")
					end;
					onRemoved = function(self, entity, map)
						expect(getmetatable(self).name).to.equal("test")
						expect(entity.scope).to.equal("system__test")
						expect(map.Test).to.be.ok()
						expect(map.Test:get("one")).to.equal(nil)

						counter:call("removed")
					end;
				}
			})
			local ent = rocs:getEntity(workspace, "foo")

			expect(counter.initialize).to.equal(0)
			ent:addBaseComponent("Test", { one = 1})
			expect(counter.initialize).to.equal(1)

			expect(counter.destroy).to.equal(0)
			ent:removeBaseComponent("Test")
			expect(counter.destroy).to.equal(1)

			expect(counter.added).to.equal(1)
			expect(counter.updated).to.equal(1)
			expect(counter.removed).to.equal(1)
		end)
	end)
end
