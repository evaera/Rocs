local Chainer = require(script.Chainer)

return function (rocs)
	rocs.chaining = Chainer.new(rocs)
end
