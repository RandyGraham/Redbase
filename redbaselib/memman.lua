local util = require("redbaselib.util")
local fb_pb_man = require("redbaselib.LL_freeblocks")
local LL = require("redbaselib.linkedlist")

local MemoryManager = {}
MemoryManager.__index = MemoryManager

function MemoryManager.new(file_handle, head_ptr_ptr)
    local pointer = util.allocate(file_handle, fb_pb_man.size + 8)
    util.write(file_handle, head_ptr_ptr, string.pack(">I4", pointer))
end

function MemoryManager.init(file_handle, head_ptr_ptr)
    local object = {}
    object.block_size = 16
    object.file_handle = file_handle
    object.head_ptr_ptr = head_ptr_ptr
    return setmetatable(object, MemoryManager)
end

function MemoryManager:get_head()
    local head_ptr = util.unpack(">I4", util.read(self.file_handle, self.head_ptr_ptr, 4))
    return LL.load(self.file_handle, head_ptr, fb_pb_man)
end

function MemoryManager:allocate_fast(size)
    local size_blocks
    if size % self.block_size == 0 then 
        size_blocks = math.floor(size / self.block_size)
    else
        size_blocks = math.floor(size / self.block_size) + 1
    end
    local head = self:get_head()
    if head.data.occupiedcount == 64 then 
        -- Record is full
        head:append()
        head:save()
        util.write(self.file_handle, self.head_ptr_ptr, util.packint(head.next_ptr))
        head = head:get_next()
    end
    local new_pointer = util.allocate(self.file_handle, size_blocks*self.block_size)
    for i=1,64 do 
        if head.data.free[i] == 0 and (head.data.size_blocks[i] == 0 or head.data.size_blocks[i] > size_blocks) then
            head.data.free[i] = 1
            if head.data.size_blocks[i] == 0 then 
                head.data.size_blocks[i] = size_blocks
            end
            head.data.size[i] = size
            head.data.positions[i] = new_pointer
            head:save()
            print("Memory Manager :: New block of size " .. size_blocks*self.block_size .. " @ " .. new_pointer)
            return new_pointer
        end
    end
end

function MemoryManager:free(pointer)

    local head = self:get_head()

    while head.prev_ptr > 0 do 
        for i=1,64 do 
            if head.data.position[i] == pointer then 
                head.data.free[i] = 0
                print("Freed " .. head.data.size_blocks[i] " blocks @ position " .. head.data.position[i])
                head:save()
                return
            end
        end
        head = head:get_prev()
    end
end

return MemoryManager