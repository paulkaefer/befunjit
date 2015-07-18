'use strict'

LazyRuntime = ->
	@playfield = null
	@pathSet = null

	# used for statistics/debugging
	@stats =
		compileCalls: 0
		jumpsPerformed: 0

	return


LazyRuntime::_getPath = (x, y, dir) ->
	path = new bef.Path()
	pointer = new bef.Pointer x, y, dir, @playfield.getSize()

	loop
		currentChar = @playfield.getAt pointer.x, pointer.y

		# processing string
		if currentChar == '"'
			path.push pointer.x, pointer.y, pointer.dir, currentChar
			loop
				pointer.advance()
				currentChar = @playfield.getAt pointer.x, pointer.y
				if currentChar == '"'
					path.push pointer.x, pointer.y, pointer.dir, currentChar
					break
				path.push pointer.x, pointer.y, pointer.dir, currentChar, true
			pointer.advance()
			continue

		pointer.turn currentChar

		if path.hasNonString pointer.x, pointer.y, pointer.dir
			splitPosition = (path.getEntryAt pointer.x, pointer.y, pointer.dir).index
			if splitPosition > 0
				initialPath = path.prefix splitPosition
				loopingPath = path.suffix splitPosition
				loopingPath.looping = true
				return {
					type: 'composed'
					initialPath: initialPath
					loopingPath: loopingPath
				}
			else
				path.looping = true
				return {
					type: 'looping'
					loopingPath: path
				}

		path.push pointer.x, pointer.y, pointer.dir, currentChar

		if currentChar in ['|', '_', '?', '@']
			return {
				type: 'simple'
				path: path
			}

		if currentChar == '#'
			pointer.advance()

		pointer.advance()


LazyRuntime::put = (x, y, e, currentX, currentY, currentDir, currentIndex) ->
	return if not @playfield.isInside x, y # exit early

	paths = @playfield.getPathsThrough x, y
	paths.forEach (path) =>
		@pathSet.remove path
		@playfield.removePath path
	@playfield.setAt x, y, e

	lastEntry = @currentPath.getLastEntryThrough x, y
	if lastEntry?.index > currentIndex
		@programState.flags.pathInvalidatedAhead = true
		@programState.flags.exitPoint =
			x: currentX
			y: currentY
			dir: currentDir

	return


LazyRuntime::get = (x, y) ->
	return 0 if not @playfield.isInside x, y

	char = @playfield.getAt x, y
	char.charCodeAt 0


LazyRuntime::_registerPath = (path, compiler) ->
	@stats.compileCalls++
	compiler.compile path
	if path.list.length
		@pathSet.add path
		@playfield.addPath path

	return


LazyRuntime::_getCurrentPath = ({ x, y, dir }, compiler) ->
	path = @pathSet.getStartingFrom x, y, dir

	if not path?
		newPath = @_getPath x, y, dir

		path = switch newPath.type
			when 'simple'
				@_registerPath newPath.path, compiler
				newPath.path
			when 'looping'
				@_registerPath newPath.loopingPath, compiler
				newPath.loopingPath
			when 'composed'
				@_registerPath newPath.initialPath, compiler
				@_registerPath newPath.loopingPath, compiler
				newPath.initialPath

	path


LazyRuntime::_turn = (pointer, char) ->
	if char == '|'
		if @programState.pop() == 0
			pointer.turn 'v'
		else
			pointer.turn '^'
		pointer.advance()
	else if char == '_'
		if @programState.pop() == 0
			pointer.turn '>'
		else
			pointer.turn '<'
		pointer.advance()
	else if char == '?'
		pointer.turn '^<v>'[Math.random() * 4 | 0]
		pointer.advance()
	else
		pointer.turn char


LazyRuntime::execute = (@playfield, options, input = []) ->
	options ?= {}
	options.jumpLimit ?= -1
	options.compiler ?= bef.OptimizingCompiler

	@stats.compileCalls = 0
	@stats.jumpsPerformed = 0

	@pathSet = new bef.PathSet()
	@programState = new bef.ProgramState @
	@programState.setInput input
	pointer = new bef.Pointer 0, 0, '>', @playfield.getSize()

	loop
		# artificial limit to prevent potentially non-breaking loops
		break if @stats.jumpsPerformed == options.jumpLimit

		@stats.jumpsPerformed++

		@currentPath = @_getCurrentPath pointer, options.compiler

		# executing the compiled path
		@currentPath.body @programState

		if @programState.flags.pathInvalidatedAhead
			@programState.flags.pathInvalidatedAhead = false
			exitPoint = @programState.flags.exitPoint
			pointer.set exitPoint.x, exitPoint.y, exitPoint.dir
			pointer.advance()
			continue

		if @currentPath.list.length
			pathEndPoint = @currentPath.getEndPoint()
			pointer.set pathEndPoint.x, pathEndPoint.y, pathEndPoint.dir

			if @currentPath.looping
				pointer.advance()
				continue

		currentChar = @playfield.getAt pointer.x, pointer.y

		# program ended
		break if currentChar == '@'

		@_turn pointer, currentChar

	return


window.bef ?= {}
window.bef.LazyRuntime = LazyRuntime