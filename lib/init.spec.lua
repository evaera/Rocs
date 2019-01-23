return function()
	local Rocs = require(script.Parent)

	describe("Components", function()
		local rocs = Rocs.new()
		local testCmp = rocs:registerComponent({
			name = "Test";
			initialize = function() print'init' end;
		})

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

			expect(cmpAg.getEntities).to.be.ok()
			expect(tostring(cmpAg)).to.equal("ComponentAggregate(Test)")
		end)
	end)
end
