'use strict'

List = bef.List


assemble = (graph, options = {}) ->
	cycledNodes = new Set

	wrapIfLooping = (node, code) ->
		if cycledNodes.has node
			"""
				while (programState.isAlive()) _#{node}: {
					#{code}
				}
			"""
		else
			code


	df = (node, prev, stack) ->
		# for debugging only
		return '' unless graph.nodes[node]?

		if (stack.find node)?
			cycledNodes.add node
			"break _#{node};"
		else
			neighbours = graph.nodes[node]

			newStack = stack.con node

			switch neighbours.length
				when 4
					# only '?'
					branch0 = df neighbours[0].to, neighbours[0], newStack
					branch1 = df neighbours[1].to, neighbours[1], newStack
					branch2 = df neighbours[2].to, neighbours[2], newStack
					branch3 = df neighbours[3].to, neighbours[3], newStack

					randomCode = """
						var choice = programState.randInt(4);
						switch (choice) {
							case 0:
								#{neighbours[0].assemble()}
								#{branch0}
								break;
							case 1:
								#{neighbours[1].assemble()}
								#{branch1}
								break;
							case 2:
								#{neighbours[2].assemble()}
								#{branch2}
								break;
							case 3:
								#{neighbours[3].assemble()}
								#{branch3}
								break;
						}
					"""

					wrapIfLooping node, randomCode

				when 2
					if node == neighbours[0].to
						branch1 = df neighbours[1].to, neighbours[1], newStack
						maybeTight = (neighbours[0].assembleTight ? neighbours[0].assemble)()

						selectCode = if typeof maybeTight == 'string'
							"""
								while (branchFlag) {
									#{maybeTight}
								}
								#{neighbours[1].assemble()}
								#{branch1}
							"""
						else
							"""
								if (branchFlag) {
									#{maybeTight.pre}
									while (branchFlag) {
										#{maybeTight.body}
									}
									#{maybeTight.post}
								}
								#{neighbours[1].assemble()}
								#{branch1}
							"""
					else if node == neighbours[1].to
						branch0 = df neighbours[0].to, neighbours[0], newStack
						maybeTight = (neighbours[1].assembleTight ? neighbours[1].assemble)()

						selectCode = if typeof maybeTight == 'string'
							"""
								while (!branchFlag) {
									#{neighbours[1].assemble()}
								}
								#{neighbours[0].assemble()}
								#{branch0}
							"""
						else
							"""
								if (!branchFlag) {
									#{maybeTight.pre}
									while (!branchFlag) {
										#{maybeTight.body}
									}
									#{maybeTight.post}
								}
								#{neighbours[0].assemble()}
								#{branch0}
							"""
					else
						branch0 = df neighbours[0].to, neighbours[0], newStack
						branch1 = df neighbours[1].to, neighbours[1], newStack

						selectCode = """
							if (branchFlag) {
								#{neighbours[0].assemble()}
								#{branch0}
							} else {
								#{neighbours[1].assemble()}
								#{branch1}
							}
						"""

					wrapIfLooping node, selectCode

				when 1
					branch = df neighbours[0].to, neighbours[0], newStack

					pBit = if prev?.path.path?.ending.char == 'p'
						{ path } = prev.path
						{ ending } = path
						"""
							var x = programState.pop();
							var y = programState.pop();
							var e = programState.pop();
							programState.put(x, y, e, #{ending.x}, #{ending.y}, '#{ending.dir}', '#{path.from}', '#{path.to}');
							if (programState.flags.pathInvalidatedAhead) {
								return;
							}
						"""
					else
						''

					edgeCode = """
						#{pBit}
						#{neighbours[0].assemble()}
						#{branch}
					"""

					wrapIfLooping node, edgeCode

				when 0
					'return;'

	"""
		var stack = programState.stack
		var branchFlag = 0
		#{df graph.start, null, List.EMPTY}
	"""


GraphCompiler =
	assemble: assemble


window.bef ?= {}
window.bef.GraphCompiler = GraphCompiler