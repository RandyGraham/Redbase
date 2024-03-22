local util = require("redbaselib.util")
local memman = require("redbaselib.memman")
local trie = require("redbaselib.trie")
local msgpack = require("redbaselib.MessagePack")

local Redbase = {}
Redbase.__index = Redbase

function Redbase.connect(file_path)
    local object = {}

    local file_handle
    if not util.exists(file_path) then 
        file_handle = util.get_file_handle(file_path, "wb")
        file_handle:write("redbase") --header [1-7]
        file_handle:write(util.packchar(0)) -- Major Version [8]
        file_handle:write(util.packchar(1)) -- Minor Version [9]
        file_handle:write(util.zeros(4)) -- Table Index Pointer [10-13]
        file_handle:write(util.zeros(4)) -- Memory Manager Record Head Pointer [14-17]
        file_handle:flush()
        -- Initialize Master Table Index
        trie.new(file_handle, 10)
        -- Initialize Memory Manager
        memman.new(file_handle, 14)
        file_handle:close()
    end
    file_handle = util.get_file_handle(file_path, "r+b")
    object.unmanaged_allocator = util.unman_allocator.load(file_handle)
    object.file_handle = file_handle
    object.index = trie.load(file_handle, 10, object.unmanaged_allocator)
    object.memory_manager = memman.load(file_handle, 14)
    return setmetatable(object, Redbase)
end

function Redbase:close()
    self.file_handle:close()
end

return Redbase