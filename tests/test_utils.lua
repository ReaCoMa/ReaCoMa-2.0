package.path = '../lib/?.lua;' .. package.path
require 'busted.runner'()
require 'utils'

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

describe("Find next power of two from string", function()
  it("Should be true for these common cases", function()
    c1 = "500 1 1"
    c2 = "1023 1 1"
    c3 = "2040 1 1"
    c4 = "4091 1 1"
    c5 = "8183 1 1"
    c6 = "400 1 512"
    c7 = "1000 1 1024"
    c8 = "2001 1 2048"
    c9 = "4003 1 4096"
    c10 = "8100 1 8192"
    assert.are.same(utils.get_max_fft_size(c1), "512")
    assert.are.same(utils.get_max_fft_size(c2), "1024")
    assert.are.same(utils.get_max_fft_size(c3), "2048")
    assert.are.same(utils.get_max_fft_size(c4), "4096")
    assert.are.same(utils.get_max_fft_size(c5), "8192")
    assert.are.same(utils.get_max_fft_size(c6), "512")
    assert.are.same(utils.get_max_fft_size(c7), "1024")
    assert.are.same(utils.get_max_fft_size(c8), "2048")
    assert.are.same(utils.get_max_fft_size(c9), "4096")
    assert.are.same(utils.get_max_fft_size(c10), "8192")
  end)
end)

describe("Find next power of 2", function()
  it("Return a power of two for these", function()
    c1 = 3
    c2 = 5
    c3 = 7
    c4 = 9
    c5 = 12
    c6 = 40000
    c7 = 19
    c8 = 500
    c9 = 1000
    assert.are_same(utils.next_pow_str(c1), '4')
    assert.are_same(utils.next_pow_str(c2), '8')
    assert.are_same(utils.next_pow_str(c3), '8')
    assert.are_same(utils.next_pow_str(c4), '16')
    assert.are_same(utils.next_pow_str(c5), '16')
    assert.are_same(utils.next_pow_str(c6), '65536')
    assert.are_same(utils.next_pow_str(c7), '32')
    assert.are_same(utils.next_pow_str(c8), '512')
    assert.are_same(utils.next_pow_str(c9), '1024')
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

describe("Remove delimiters", function()
  it("Should have no delimiters in the string", function()
    delimited = "foo.bar is the best.worst"
    expected = "foobaristhebestworst"
    assert.are_same(utils.rmdelim(delimited), expected)
  end)
end)

describe("wrap_quotes a string for CLI", function()
  it("Should return something that is double quoted", function()
    c1 = '/home/james/Documents/Max 8/Packages/Worst Path Ever'
    c2 = "/home/james/Documents/Max 8/Packages/Worst Path Ever"

    expected = '"/home/james/Documents/Max 8/Packages/Worst Path Ever"'

    assert.are_same(utils.wrap_quotes(c1), expected)
    assert.are_same(utils.wrap_quotes(c2), expected)

  end)
end)

-- describe("Check line splitting is predictable", function()
--   it("Split them commas", function()
--     c1 = "param1\rparam2\rparam3\rparam5  "
--     c2 = "param1\nparam2\nparam3\nparam5"
--     c3 = "param1\rparam2\nparam3\rparam5"

--     test_case = {
--       [1] = "param1",
--       "param2",
--       "param3",
--       "param5"
--     }
--     assert.are.equals(utils.split_line(c1), test_case)
--     assert.are.equals(utils.split_line(c2), test_case)
--     assert.are.equals(utils.split_line(c3), test_case)

--   end)
-- end)
