local trie = require("redbaselib.trie")
local util = require("redbaselib.util")

local file_handle = util.get_file_handle("data.rb", "w+b")

util.allocate(file_handle, 4)

trie.new(file_handle, 0)

local data = string.unpack(">I4", util.read(file_handle, 0, 4))
local testtrie = trie.init(file_handle, data)

while true do 
    local userin = io.read()
    testtrie:insert(userin, 69)
    print(testtrie:lookup(userin))
end
