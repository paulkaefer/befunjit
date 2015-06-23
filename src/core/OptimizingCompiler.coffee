'use strict'

isNumber = (obj) ->
  typeof obj == 'number'


digitPusher = (digit) ->
  (x, y, dir, index, stack) ->
    stack.push digit
    "/* #{digit} */"


binaryOperator = (operatorFunction, operatorChar, stringFunction) ->
  (x, y, dir, index, stack) ->
    operand1 = if stack.length then stack.pop() else 'runtime.pop()'
    operand2 = if stack.length then stack.pop() else 'runtime.pop()'
    if (isNumber operand1) and (isNumber operand2)
      stack.push operatorFunction operand1, operand2
      "/* #{operatorChar} */"
    else
      "/* #{operatorChar} */  runtime.push(#{stringFunction operand1, operand2})"


codeMap =
  ' ': -> '/*   */'


  '0': digitPusher 0
  '1': digitPusher 1
  '2': digitPusher 2
  '3': digitPusher 3
  '4': digitPusher 4
  '5': digitPusher 5
  '6': digitPusher 6
  '7': digitPusher 7
  '8': digitPusher 8
  '9': digitPusher 9


  '+': binaryOperator ((o1, o2) -> o1 + o2), '+', (o1, o2) -> "#{o1} + #{o2}"
  '-': binaryOperator ((o1, o2) -> o1 - o2), '-', (o1, o2) -> "#{o1} - #{o2}"
  '*': binaryOperator ((o1, o2) -> o1 * o2), '*', (o1, o2) -> "#{o1} * #{o2}"
  '/': binaryOperator ((o1, o2) -> Math.floor(o1 / o2)), '/', (o1, o2) -> "Math.floor(#{o1} / #{o2})"
  '%': binaryOperator ((o1, o2) -> o1 % o2), '%', (o1, o2) -> "#{o1} % #{o2}"


  '!': (x, y, dir, index, stack) ->
    if stack.length
      stack.push +!stack.pop()
      '/* ! */'
    else
      '/* ! */  runtime.push(+!runtime.pop())'


  '`': binaryOperator ((o1, o2) -> +(o1 > o2)), '`', (o1, o2) -> "+(#{o1} > #{o2})"


  '^': -> '/* ^ */'
  '<': -> '/* < */'
  'v': -> '/* v */'
  '>': -> '/* > */'
  '?': -> '/* ? */  return;'
  '_': -> '/* _ */  return;'
  '|': -> '/* | */  return;'
  '"': -> '/* " */'


  ':': (x, y, dir, index, stack) ->
    if stack.length
      stack.push stack[stack.length - 1]
      '/* : */'
    else
      '/* : */  runtime.duplicate()'


  '\\': (x, y, dir, index, stack) ->
    if stack.length > 1
      e1 = stack[stack.length - 1]
      e2 = stack[stack.length - 2]
      stack[stack.length - 1] = e2
      stack[stack.length - 2] = e1
      '/* \\ */'
    else
      '/* \\ */  runtime.swap()'


  '$': (x, y, dir, index, stack) ->
    if stack.length
      stack.pop()
      '/* $ */'
    else
      '/* $ */  runtime.pop()'


  '.': (x, y, dir, index, stack) ->
    if stack.length
      "/* . */  runtime.out(#{stack.pop()})"
    else
      '/* . */  runtime.out(runtime.pop())'


  ',': (x, y, dir, index, stack) ->
    if stack.length
      char = String.fromCharCode stack.pop()
      if char == "'"
        char = "\\'"
      else if char == '\\'
        char = '\\\\'
      "/* , */  runtime.out('#{char}')"
    else
      '/* , */  runtime.out(String.fromCharCode(runtime.pop()))'


  '#': -> '/* # */'


  'p': (x, y, dir, index, stack) ->
    operand1 = if stack.length then stack.pop() else 'runtime.pop()'
    operand2 = if stack.length then stack.pop() else 'runtime.pop()'
    operand3 = if stack.length then stack.pop() else 'runtime.pop()'
    "/* p */  runtime.put(#{operand1}, #{operand2}, #{operand3}, #{x}, #{y}, '#{dir}', #{index})\n" +
    "if (runtime.flags.pathInvalidatedAhead) {" +
    "#{if stack.length then "runtime.push(#{stack.join ', '});" else ''}" +
    " return; }"


  'g': (x, y, dir, index, stack) ->
    operand1 = if stack.length then stack.pop() else 'runtime.pop()'
    operand2 = if stack.length then stack.pop() else 'runtime.pop()'
    "/* g */  runtime.push(runtime.get(#{operand1}, #{operand2}))"


  # require special handling
  '&': -> '/* & */  runtime.push(runtime.next())'
  '~': -> '/* ~ */  runtime.push(runtime.nextChar())'


  '@': -> '/* @ */  return;'


OptimizinsCompiler = ->


OptimizinsCompiler.assemble = (path) ->
  charList = path.getAsList()

  stack = []
  lines = charList.map (entry, i) ->
    if entry.string
      stack.push entry.char.charCodeAt 0
      "/* '#{entry.char}' */"
    else
      codeGenerator = codeMap[entry.char]
      if codeGenerator?
        ret = ''
        if entry.char == '&' or entry.char == '~'
          # dump the stack
          if stack.length
            ret += "runtime.push(#{stack.join ', '});\n"
          stack = []
        ret += codeGenerator entry.x, entry.y, entry.dir, i, stack
        ret
      else
        "/* __ #{entry.char} */"

  if stack.length
    lines.push "runtime.push(#{stack.join ', '})"

  lines.join '\n'


OptimizinsCompiler.compile = (path) ->
  code = OptimizinsCompiler.assemble path
  path.code = code #storing this just for debugging
  compiled = new Function 'runtime', code
  path.body = compiled


window.bef ?= {}
window.bef.OptimizinsCompiler = OptimizinsCompiler