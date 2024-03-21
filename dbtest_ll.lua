local ll = require("redbaselib.linkedlist")
local util = require("redbaselib.util")
local freeblocks_payload = require("redbaselib.LL_freeblocks")
local memman = require("redbaselib.memman")

local file_handle = util.get_file_handle("data.rb", "w+b")

util.allocate(file_handle, 4)

memman.new(file_handle, 0)

local memory = memman.init(file_handle, 0)

local userin
while true do 
    userin = io.read()
    local pointer = memory:allocate_fast(#userin)
    print(pointer)
    util.write(file_handle, pointer, userin)
end
-- local llfb = ll.load(file_handle, pointer, freeblocks_payload)
-- llfb.data.positions[1] = 100
-- llfb.data.size_blocks[1] = 10
-- llfb.data.size[1] = 1000
-- llfb.data.free[1] = 1
-- llfb:save()

-- local llfb = ll.load(file_handle, pointer, freeblocks_payload)
-- print(llfb.data.positions[1])

-- for i = 1, 100 do 
--     llfb:append()
--     llfb.data.positions[i%64] = i
--     llfb.data.size_blocks[i%64] = i
--     llfb.data.size[i%64] = i
--     llfb.data.free[i%64] = i
--     llfb:save()
--     llfb = llfb:get_next()
-- end

-- llfb = ll.load(file_handle, pointer, freeblocks_payload)

-- for i=1, 100 do 
--     print(llfb.data.positions[i%64])
--     print(llfb.data.size_blocks[i%64])
--     print(llfb.data.size[i%64])
--     print(llfb.data.free[i%64])
--     print(llfb.data.freecount)
--     print("====================")
--     llfb = llfb:get_next()
-- end