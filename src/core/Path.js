// Generated by CoffeeScript 1.12.4
(function() {
  'use strict';
  var Path, getHash, getId, idCounter;

  idCounter = 0;

  getId = function() {
    return idCounter++;
  };

  getHash = function(x, y, dir, string) {
    return x + "_" + y + "_" + dir + (string ? '_s' : '');
  };

  Path = function(list) {
    var entry, i, len;
    if (list == null) {
      list = [];
    }
    this.id = getId();
    this.entries = {};
    this.list = [];
    this.looping = false;
    for (i = 0, len = list.length; i < len; i++) {
      entry = list[i];
      this.push(entry.x, entry.y, entry.dir, entry.char, entry.string);
    }
  };

  Path.prototype.push = function(x, y, dir, char, string) {
    var hash;
    if (string == null) {
      string = false;
    }
    hash = getHash(x, y, dir, string);
    this.entries[hash] = {
      char: char,
      index: this.list.length,
      string: string
    };
    return this.list.push({
      x: x,
      y: y,
      dir: dir,
      char: char,
      string: string
    });
  };

  Path.prototype.prefix = function(length) {
    var prefixList;
    prefixList = this.list.slice(0, length);
    return new Path(prefixList);
  };

  Path.prototype.suffix = function(length) {
    var suffixList;
    suffixList = this.list.slice(length);
    return new Path(suffixList);
  };

  Path.prototype.has = function(x, y, dir) {
    var hash1, hash2;
    hash1 = getHash(x, y, dir);
    hash2 = getHash(x, y, dir, true);
    return (this.entries[hash1] != null) || (this.entries[hash2] != null);
  };

  Path.prototype.hasNonString = function(x, y, dir) {
    var hash;
    hash = getHash(x, y, dir);
    return this.entries[hash] != null;
  };

  Path.prototype.getEntryAt = function(x, y, dir) {
    var hash;
    hash = getHash(x, y, dir);
    return this.entries[hash];
  };

  Path.prototype.getLastEntryThrough = function(x, y) {
    var entry, hash, i, lastEntry, len, max, possibleEntries;
    possibleEntries = [getHash(x, y, '^'), getHash(x, y, '<'), getHash(x, y, 'V'), getHash(x, y, '>'), getHash(x, y, '^', true), getHash(x, y, '<', true), getHash(x, y, 'V', true), getHash(x, y, '>', true)];
    max = -1;
    lastEntry = null;
    for (i = 0, len = possibleEntries.length; i < len; i++) {
      hash = possibleEntries[i];
      entry = this.entries[hash];
      if ((entry != null ? entry.index : void 0) > max) {
        max = entry.index;
        lastEntry = entry;
      }
    }
    return lastEntry;
  };

  Path.prototype.getAsList = function() {
    return this.list.slice(0);
  };

  Path.prototype.getEndPoint = function() {
    var lastEntry;
    lastEntry = this.list[this.list.length - 1];
    return {
      x: lastEntry.x,
      y: lastEntry.y,
      dir: lastEntry.dir
    };
  };

  if (window.bef == null) {
    window.bef = {};
  }

  window.bef.Path = Path;

}).call(this);