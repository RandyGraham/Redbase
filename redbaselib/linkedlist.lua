local util = require("redbaselib.util")

local LL = {}

function LL.new(file_handle, payload_size)
    local pointer = util.allocate(file_handle, 8 + payload_size)
    return pointer
end

function LL.load(file_handle, position, payload_manager, allocator)
    local bytes = util.read(file_handle, position, 8+payload_manager.size)
    local object = {
        position = position,
        prev_ptr = util.unpack(">I4", string.sub(bytes, 1, 4)),
        data = payload_manager.load(string.sub(bytes, 5, 5+payload_manager.size-1)),
        payload_manager = payload_manager,
        file_handle = file_handle,
        allocator = allocator,
        next_ptr = util.unpack(">I4", string.sub(bytes, 5+payload_manager.size, 8+payload_manager.size)),
    }
    function object:get_next()
        if self.next_ptr == 0 then
            error("LL: Attempt to load next node from NULL pointer")
        end
        return LL.load(self.file_handle, self.next_ptr, self.payload_manager)
    end
    function object:get_prev()
        if self.prev_ptr == 0 then
            error("LL: Attempt to load prev node from NULL pointer")
        end
        return LL.load(self.file_handle, self.prev_ptr, self.payload_manager)
    end
    function object:has_next()
        return self.next_ptr > 0
    end
    function object:has_prev()
        return self.prev_ptr > 0
    end
    function object:save()
        local buffer = string.pack(">I4", self.prev_ptr) .. self.payload_manager.save(self.data) .. string.pack(">I4", self.next_ptr)
        util.write(file_handle, self.position, buffer)
    end
    function object:append()
        local pointer = util.allocate(file_handle, self.payload_manager.size + 8)
        self.next_ptr = pointer
        self:save()
        local next = self:get_next()
        next.prev_ptr = self.position
        next:save()
    end
    function object:insert()
        local pointer = util.allocate(file_handle, self.payload_manager.size + 8)
        if not self:has_next() then 
            self:append()
            return
        end
        local next = self:get_next()
        next.prev_ptr = pointer
        self.next_ptr = pointer
        next:save()
        self:save()
    end
    function object:free()
        self.allocator.free(self.position)
    end
    function object:free_forward()
        if self:has_next() then 
            self:get_next():free_forward()
        end
        self:free()
    end
    function object:free_backward()
        if self:has_prev() then
            self:get_prev():free_backward()
        end
        self:free()
    end
    function object:free_all()
        if self:has_next() then 
            local next = self:get_next()
            next:free_forward()
        end
        if self:has_prev() then
            local prev = self:get_prev()
            prev:free_backwards()
        end
        self:free()
    end
    return object
end

return LL