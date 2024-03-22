local util = require("redbaselib.util")
local msgpack = require("redbaselib.MessagePack")
local trie = require("redbaselib.trie")

local Row = {}

function Row.load(file_handle, pointer)
    local size = util.unpackint(util.read(file_handle, pointer, 4))
    local data = {}
    data.row = msgpack.unpack(util.read(file_handle, pointer+4, size))
    data.next_row = util.unpackint(util.read(file_handle, pointer, 4))
    return data
end

function Row.save(file_handle, pointer, allocator, data)
    local bytes = msgpack.pack(data.row)
    local buffer = util.packint(#bytes) .. bytes .. util.packint(data.next_row)
    return buffer
end

function Row.next(file_handle, row)
    if row.next_row == 0 then
        return nil
    end
    return Row.load(file_handle, row.next_row)
end


local Table = {}
Table.__index = Table
--[[
    Table Format
    primay_key = Char (Says which column is the primary key)
    column_names = String* (";" is the delimiter)
    rows = Row_LL*
    primary_key_index = Trie*
    rowid_index = Trie*
]]
function Table.new(file_handle, allocator, root_ptr_ptr, primary_key_index, column_names)
    local pointer = allocator.allocate(1 + 4 + 4 + 4 + 4)
    util.write(file_handle, root_ptr_ptr, util.packint(pointer))
    local buffer = util.packchar(primary_key_index)

    local column_names_packed = msgpack.pack(column_names)
    local column_names = util.packint(#column_names_packed) .. column_names_packed

    local column_names_pointer = allocator.allocate(#column_names)
    util.write(file_handle, column_names_pointer, column_names)

    buffer = buffer .. util.packint(column_names_pointer) -- Column_Names String*

    buffer = buffer .. util.packint(0) --Row_LL*

    local primary_key_index_ptr = trie.new(allocator)

    buffer = buffer .. util.packint(primary_key_index_ptr)

    local rowid_index_ptr = trie.new(allocator)

    buffer = buffer .. util.packint(rowid_index_ptr)

    util.write(file_handle, pointer, buffer)
end

function Table.load(file_handle, allocator, pointer)
    local object = {}

    object.file_handle = file_handle

    object.allocator = allocator

    object.position = pointer

    local bytes = util.write(file_handle, pointer, 17)

    object.primary_key_index = util.unpackchar(bytes:sub(1,1))

    object.column_names_pointer = util.unpackint(bytes:sub(2,5))

    local column_names_size = util.unpackint(util.read(file_handle, object.column_names_pointer, 4))
    
    object.column_names = msgpack.unpack( util.read(file_handle, object.column_names_pointer+4, column_names_size) )

end

function Table:insert()
    
end

function Table:update()
    
end

function Table:delete()
    
end

function Table:query()
    
end

return Table