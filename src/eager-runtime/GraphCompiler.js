// Generated by CoffeeScript 1.10.0
(function() {
  'use strict';
  var GraphCompiler, List, assemble, computeIndegree;

  List = bef.List;

  computeIndegree = function(nodes) {
    return (Object.keys(nodes)).reduce(function(indegree, nodeName) {
      nodes[nodeName].forEach(function(edge) {
        var to;
        to = edge.to;
        if (indegree.has(to)) {
          return indegree.set(to, (indegree.get(to)) + 1);
        } else {
          return indegree.set(to, 1);
        }
      });
      return indegree;
    }, new Map);
  };

  assemble = function(graph, options) {
    var cycledNodes, df, fastConditionals, wrapIfLooping;
    fastConditionals = options != null ? options.fastConditionals : void 0;
    cycledNodes = new Set;
    wrapIfLooping = function(node, code) {
      if (cycledNodes.has(node)) {
        return "while (programState.isAlive()) _" + node + ": {\n	" + code + "\n}";
      } else {
        return code;
      }
    };
    df = function(node, stack) {
      var branch, branch0, branch1, branch2, branch3, conditionalChunk, edgeCode, neighbours, newStack, randomCode, selectCode;
      if (graph.nodes[node] == null) {
        return '';
      }
      if ((stack.find(node)) != null) {
        cycledNodes.add(node);
        return "break _" + node + ";";
      } else {
        neighbours = graph.nodes[node];
        newStack = stack.con(node);
        switch (neighbours.length) {
          case 4:
            branch0 = df(neighbours[0].to, newStack);
            branch1 = df(neighbours[1].to, newStack);
            branch2 = df(neighbours[2].to, newStack);
            branch3 = df(neighbours[3].to, newStack);
            randomCode = (fastConditionals ? 'programState.push(branchFlag);' : '') + "\nvar choice = programState.randInt(4);\nswitch (choice) {\n	case 0:\n		" + neighbours[0].code + "\n		" + branch0 + "\n		break;\n	case 1:\n		" + neighbours[1].code + "\n		" + branch1 + "\n		break;\n	case 2:\n		" + neighbours[2].code + "\n		" + branch2 + "\n		break;\n	case 3:\n		" + neighbours[3].code + "\n		" + branch3 + "\n		break;\n}";
            return wrapIfLooping(node, randomCode);
          case 2:
            conditionalChunk = fastConditionals ? 'branchFlag' : 'programState.pop()';
            if (node === neighbours[0].to) {
              branch1 = df(neighbours[1].to, newStack);
              selectCode = "while (" + conditionalChunk + ") {\n	" + neighbours[0].code + "\n}\n" + neighbours[1].code + "\n" + branch1;
            } else if (node === neighbours[1].to) {
              branch0 = df(neighbours[0].to, newStack);
              selectCode = "while (!" + conditionalChunk + ") {\n	" + neighbours[1].code + "\n}\n" + neighbours[0].code + "\n" + branch0;
            } else {
              branch0 = df(neighbours[0].to, newStack);
              branch1 = df(neighbours[1].to, newStack);
              selectCode = "if (" + conditionalChunk + ") {\n	" + neighbours[0].code + "\n	" + branch0 + "\n} else {\n	" + neighbours[1].code + "\n	" + branch1 + "\n}";
            }
            return wrapIfLooping(node, selectCode);
          case 1:
            branch = df(neighbours[0].to, newStack);
            edgeCode = (fastConditionals ? 'var branchFlag = 0' : '') + "\n" + neighbours[0].code + "\n" + branch;
            return wrapIfLooping(node, edgeCode);
          case 0:
            return 'return;';
        }
      }
    };
    return df(graph.start, List.EMPTY);
  };

  GraphCompiler = {
    assemble: assemble
  };

  if (window.bef == null) {
    window.bef = {};
  }

  window.bef.GraphCompiler = GraphCompiler;

}).call(this);