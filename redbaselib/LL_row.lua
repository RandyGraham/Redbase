local util = require("redbaselib.util")
local msgpack = require("redbaselib.MessagePack")

local freeblocks_payload = {}
-- Filled 1B (Position (4B), Size_Blocks (4B), Size_Stored (4B), Free (1B) x 64)
freeblocks_payload.size = 1 + ((4+4+4+1)*64)

function freeblocks_payload.load(bytes)
    local data = {}


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