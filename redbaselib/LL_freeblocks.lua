local util = require("redbaselib.util")

local freeblocks_payload = {}
-- Filled 1B (Position (4B), Size_Blocks (4B), Size_Stored (4B), Free (1B) x 64)
freeblocks_payload.size = 1 + ((4+4+4+1)*64)

function freeblocks_payload.load(bytes)
    local data = {}
    data.occupiedcount= util.unpack("B", bytes:sub(1,1))
    data.positions = {}
    data.size_blocks = {}
    data.size = {}
    data.free = {}

    -- skip past the first byte
    local bytes = bytes:sub(2)

    -- Load the main records table
    for i=0, 63 do 
        table.insert(data.positions, util.unpack(">I4", bytes:sub( (i*13)+1, (i*13)+4 )))
        table.insert(data.size_blocks, util.unpack(">I4", bytes:sub( (i*13)+5, (i*13)+8 )))
        table.insert(data.size, util.unpack(">I4", bytes:sub( (i*13)+9, (i*13)+12 )))
        table.insert(data.free, util.unpack("B", bytes:sub( (i*13)+13 )))
    end

    return data
end

function freeblocks_payload.save(data)
    local buffer = ""
    local occupiedcount = 64
    for i=1, 64 do 
        buffer = buffer .. string.pack(">I4", data.positions[i])
        buffer = buffer .. string.pack(">I4", data.size_blocks[i])
        buffer = buffer .. string.pack(">I4", data.size[i])
        buffer = buffer .. string.pack("B", data.free[i])
        if data.free[i] == 0 then 
            occupiedcount = occupiedcount - 1
        end
    end
    buffer = util.packchar(occupiedcount) .. buffer
    return buffer .. util.zeros(freeblocks_payload.size-#buffer) --Add padding
end

return freeblocks_payload