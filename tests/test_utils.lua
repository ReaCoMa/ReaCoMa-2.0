package.path = 'lib/?.lua;' .. package.path
require 'busted.runner'()
local utils = require('utils')

describe("Split a table in various ways", function ()
	it("should split evenly", function()
		local items = { "one", "two", "three", "four" }
		local split_1, split_2 = utils.split_table(items, #items / 2)
		assert.are.same(split_1, { "one", "two" })
		assert.are.same(split_2, { "three", "four" })
	end)
end)

describe("Reverse Table", function()
  it("should reverse a table", function()
    foo = {1, 2, 3, 4, 5}
    rev = {5, 4, 3, 2, 1}
    utils.reverse_table(foo)
    assert.are_same(foo, rev)
  end)
end)

describe("Samples to seconds", function()
  it("Should return the proper conversion for the sample rate", function()
    c1 = 44100
    c2 = 22050
    c3 = 4410
    c4 = 17640
    assert.are_same(utils.sampstos(c1, 44100), 1)
    assert.are_same(utils.sampstos(c1, 48000), 0.91875)
    assert.are_same(utils.sampstos(c2, 44100), 0.5)
    assert.are_same(utils.sampstos(c3, 44100), 0.1)
    assert.are_same(utils.sampstos(c4, 44100), 0.4)
  end)
end)

describe("Seconds to samples", function()
  it("Should return the proper conversion for the sample rate", function()
    c1 = 1
    c2 = 1.5
    c3 = 2
    c4 = 3
    assert.are_same(utils.stosamps(c1, 44100), 44100)
    assert.are_same(utils.stosamps(c1, 48000), 48000)
    assert.are_same(utils.stosamps(c2, 44100), 66150)
    assert.are_same(utils.stosamps(c3, 44100), 88200)
    assert.are_same(utils.stosamps(c4, 44100), 132300)
  end)
end)

describe("Get the base dir", function()
  it("Return only the base dir", function()
    c1 = "/home/james/path/foo.lua"
    c2 = "/home/james/path/"
    c3 = "/home/james/path"
    c4 = "/home/james/path/foo"
    assert.are_same(utils.dir_parent(c1), "/home/james/path/")
    assert.are_same(utils.dir_parent(c2), "/home/james/path/")
    assert.are_same(utils.dir_parent(c3), "/home/james/")
    assert.are_same(utils.dir_parent(c4), "/home/james/path/")
  end)
end)

describe("Get the base name", function()
  it("Return only the name of the file", function()
    c1 = "/home/james/path/foo.lua"
    c2 = "/home/james/path/"
    c3 = "/home/james/path"
    c4 = "/home/james/path/foo"
    assert.are_same(utils.basename(c1), "/home/james/path/foo")
    assert.are_same(utils.basename(c2), nil)
    assert.are_same(utils.basename(c3), nil)
    assert.are_same(utils.basename(c4), nil)
  end)
end)

describe("Remove trailing slash", function()
  it("Removes a trailing slash from a path", function()
    c1 = "/home/james/path/foo.lua/"
    c2 = "/home/james/path/"
    assert.are_same(utils.rm_trailing_slash(c1), "/home/james/path/foo.lua")
    assert.are_same(utils.rm_trailing_slash(c2), "/home/james/path")
  end)
end)

describe("Check comma splitting is predictable", function()
  it("Split them commas", function()
    c1 = "param1,param2,param3,param5"
    test_case = {
      "param1",
      "param2",
      "param3",
      "param5"
    }
    assert.are_same(utils.split_comma(c1), test_case)
  end)
end)

describe("Check space splitting is predictable", function()
  it("Split them spaces", function()
    c1 = "param1 param2 param3    param5"
    test_case = {
      "param1",
      "param2",
      "param3",
      "param5"
    }
    assert.are_same(utils.split_space(c1), test_case)
  end)

  it("Split spaces with other characters in them", function()
    c1 = "1024 -1 -1"
    test_case = {
      "1024",
      "-1",
      "-1"
    }
    assert.are_same(utils.split_space(c1), test_case)
  end)
end)

describe("Lacing tables is predictable", function()
  it("Lace them together", function()
    c1 = "param1 param2 param3    param5"
    left = {0.0, 100.0, 300.1}
    right = {78.0, 299.0}
    expected = {0.0, 78.0, 100.0, 299.0, 300.1}
    assert.are_same(utils.lace_tables(left, right), expected)
  end)
end)

describe("wrap_quotes a string for CLI", function()
  it("Should return something that is double quoted", function()
    local c1 = '/home/james/Documents/Max 8/Packages/Worst Path Ever'
    local c2 = "/home/james/Documents/Max 8/Packages/Worst Path Ever"

    local expected = '"/home/james/Documents/Max 8/Packages/Worst Path Ever"'

    assert.are_same(utils.wrap_quotes(c1), expected)
    assert.are_same(utils.wrap_quotes(c2), expected)

  end)
end)

describe('comparing item tables', function ()
  it('should be true', function()
    local a = {1, 2, 3, 4, 5}
    local b = {1, 2, 3, 4, 5}
    local equality = utils.compare_item_tables(a, b)
    assert.are_same(equality, true)
  end)

  it('should not be true', function ()
    local a = {1, 2, 3, 4, 5}
    local b = {1, 2, 3, 4, 6}
    local equality = utils.compare_item_tables(a, b)
    assert.are_same(equality, false)
  end)

  it('should be true for deep tables', function ()
    local a = {1, 2, 3, 4, help = {1, 2, 3, 4, 5}}
    local b = {1, 2, 3, 4, help = {1, 2, 3, 4, 5}}
    local equality = utils.compare_item_tables(a, b)
    assert.are_same(equality, true)
  end)
  
end)
