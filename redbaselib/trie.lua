local util = require("redbaselib.util")

local TrieNodeSize = (4+4+1)*16

local Node = {}

if not bit32 then
    bit32 = require("redbaselib.bit32")
end

local function prepkey(key)
    local keybytes = {}
    for i=1, #key do 
        table.insert(keybytes, bit32.rshift(string.byte(string.sub(key, i, i)), 4)+1)
        table.insert(keybytes, bit32.band(string.byte(string.sub(key, i, i)), 15)+1)
    end
    return keybytes
end

function Node.load(file_handle, position)
    util.ensure(file_handle, "userdata", position, "number")
    print("Loading Node@"..position)
    local node = {}
    local bytes = util.read(file_handle, position, TrieNodeSize)
    if not bytes then 
        error("Couldn't load Trie Node. Bytes was nil")
    end
    node.position = position
    node.next_pointers = {}
    node.record_pointers = {}
    node.flags = {}
    local offset
    for i=0,15 do 
        offset = i*9
        table.insert(node.next_pointers, util.unpack(">I4", string.sub(bytes, offset+1, offset+4)))

        table.insert(node.record_pointers, util.unpack(">I4", string.sub(bytes, offset+5, offset+8)))

        table.insert(node.flags, util.unpack("B", string.sub(bytes, offset+9, offset+9)))

        if node.next_pointers[i+1] > 0 or node.record_pointers[i+1] ~= 0 then 
            print("[" .. i+1 .. "] NEXT: " .. node.next_pointers[i+1] .. "    RECORD: " .. node.record_pointers[i+1])
        end
    end
    return node
end

function Node.save(file_handle, node)
    util.ensure(file_handle, "userdata", node, "table")
    print("Saving Node@"..node.position)
    local bytes = ""
    for i=1,16 do 
        bytes = bytes .. string.pack(">I4", node.next_pointers[i])

        bytes = bytes .. string.pack(">I4", node.record_pointers[i])

        bytes = bytes .. string.pack("B", node.flags[i])
    end
    util.write(file_handle, node.position, bytes)
end

local Trie = {}
Trie.__index = Trie

function Trie.new(file_handle, root_ptr_ptr)
    local root_ptr = util.allocate(file_handle, TrieNodeSize)
    util.write(file_handle, root_ptr_ptr, string.pack(">I4", root_ptr))
end

function Trie.load(file_handle, root_ptr)
   local object = {}
   object.file_handle = file_handle
   object.root_ptr = root_ptr
   return setmetatable(object, Trie) 
end

function Trie:lookup(key)
    print("Looking up", key)
    local current_node = Node.load(self.file_handle, self.root_ptr)
    local keybytes = prepkey(key)
    local keybyte
    for i=1, #keybytes-1 do 
        keybyte = keybytes[i]
        if current_node.next_pointers[keybyte] == 0 then
            return nil
        else
            current_node = Node.load(self.file_handle, current_node.next_pointers[keybyte])
        end
    end
    keybyte = keybytes[#keybytes]
    print(keybyte)
    if current_node.record_pointers[keybyte] == 0 then
        return nil
    else
        return current_node.record_pointers[keybyte]
    end
end

function Trie:insert(key, value)
    print("Inserting", key, value)
    local current_node = Node.load(self.file_handle, self.root_ptr)
    local keybytes = prepkey(key)
    local keybyte
    for i=1, #keybytes-1 do 
        keybyte = keybytes[i]
        print(keybyte)
        if current_node.next_pointers[keybyte] == 0 then
            local new_node = util.allocate(self.file_handle, TrieNodeSize)
            current_node.next_pointers[keybyte] = new_node
            print("     ", new_node)
            Node.save(self.file_handle, current_node)
            current_node = Node.load(self.file_handle, new_node)
        else
            current_node = Node.load(self.file_handle, current_node.next_pointers[keybyte])
        end
    end
    keybyte = keybytes[#keybytes]
    current_node.record_pointers[keybyte] = value
    Node.save(self.file_handle, current_node)
end

return Trie