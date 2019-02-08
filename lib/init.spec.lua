return function()
	local Rocs = require(script.Parent)

	local testCmp = {
		name = "Test";
		initialize = function() print'init' end;
		defaults = {
			[Rocs.metadata("Replicated")] = true
		};
		reducer = Rocs:propertyReducer({
			nested = Rocs:propertyReducer({
				value = Rocs.reducers.last;
			})
		})
	}

	describe("Components", function()
		local rocs = Rocs.new()
		rocs:registerComponent(testCmp)

		it("should apply components", function()
			local ent = rocs:getEntity(workspace, "foo")

			ent:addComponent(testCmp, { one = 1 })
			ent:addBaseComponent("Test", { two = 2 })

			local cmpAg = rocs._entities[workspace] and rocs._entities[workspace][testCmp]

			expect(cmpAg).to.be.ok()

			expect(cmpAg.components.base).to.be.ok()
			expect(cmpAg.components.base.two).to.equal(2)

			expect(cmpAg.components.foo).to.be.ok()
			expect(cmpAg.components.foo.one).to.equal(1)

			expect(cmpAg:get()).to.equal(cmpAg.data)

			expect(cmpAg:get("one")).to.equal(1)
			expect(cmpAg:get("two")).to.equal(2)

			expect(tostring(cmpAg)).to.equal("ComponentAggregate(Test)")
		end)
	end)

	describe("Systems", function()
		local rocs = Rocs.new()
		rocs:registerComponent(testCmp)

		it("should fire lifecycle methods", function()
			local dep = rocs.dependencies:hasComponent("Test")

			local addedCount = 0
			local updatedCount = 0
			local removedCount = 0
			rocs:registerSystem({
				name = "test";

				[dep] = {
					onAdded = function(self, entity, map)
						expect(getmetatable(self).name).to.equal("test")
						expect(entity.scope).to.equal("system__test")
						expect(map.Test).to.be.ok()
						expect(map.Test:get("one")).to.equal(1)

						addedCount = addedCount + 1
					end;
					onUpdated = function(self, entity, map)
						expect(getmetatable(self).name).to.equal("test")
						expect(entity.scope).to.equal("system__test")
						expect(map.Test).to.be.ok()
						expect(map.Test:get("one")).to.equal(1)

						updatedCount = updatedCount + 1
					end;
					onRemoved = function(self, entity, map)
						expect(getmetatable(self).name).to.equal("test")
						expect(entity.scope).to.equal("system__test")
						expect(map.Test).to.be.ok()
						expect(map.Test:get("one")).to.equal(nil)

						removedCount = removedCount + 1
					end;
				}
			})
			local ent = rocs:getEntity(workspace, "foo")

			ent:addBaseComponent("Test", { one = 1})

			ent:removeBaseComponent("Test")

			expect(addedCount).to.equal(1)
			expect(updatedCount).to.equal(1)
			expect(removedCount).to.equal(1)
		end)
	end)
end
