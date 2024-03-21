local M = {}

M.lua_version = {major=tonumber(string.match(_VERSION, "(%d)%.%d$")), minor=tonumber(string.match(_VERSION, "%d%.(%d)$"))}
M.debug = true

function M.dprint(...)
    if M.debug then
        print(...)
    end
end

function M.ensure(...)
    local args
    if M.lua_version.minor > 2 then
        args = table.pack(...)
    else
        args = arg
    end
    if #args%2 ~= 0 then 
        error("Guard recieved uneven number of arguments")
    end
    local argument
    local type_
    local skip
    for i=1,#args,2 do 
        skip = false
        argument = args[i]
        type_ = args[i+1]
        --Optional Parameter
        if type_[1] == "?" then
            type_ = string.sub(type_, 2)
            if not argument then 
                skip = true
            end
        end
        --Asset arguement type == expected type
        if skip == false and type_ ~= type(argument) then 
            error("Guard Error: Expected arguement of type " .. type_ .. " Got argument of type " .. type(argument) .. " (" .. tostring(argument) .. ")" .. " @ pos " .. math.floor(i/2))
        end
    end
end

function M.print_bytes(bytes)
    M.ensure(bytes, "string")
    local buffer = ""
    for i=1, #bytes-1 do 
        buffer = buffer .. string.byte(string.sub(bytes, i, i)) .. " "
    end
    buffer = buffer .. string.byte(string.sub(bytes, #bytes, #bytes))
end

function M.zeros(n) 
    return string.rep(string.char(0), n)
end

function M.write(file_handle, location, bytes)
    file_handle:seek("set", location)
    file_handle:write(bytes)
    file_handle:flush()
    print("wrote " .. #bytes .. " bytes")
end

function M.read(file_handle, location, size)
    file_handle:seek("set", location)
    local bytes = file_handle:read(size)
    print("Read " .. size .. " bytes")
    return bytes
end

function M.allocate(file_handle, size)
    local position = file_handle:seek("end", 0)
    file_handle:write(M.zeros(size))
    file_handle:flush()
    print("Allocated " .. size .. " bytes")
    return position
end

function M.slice(array, start, stop)
    local slice = {}
    for i=start, stop do 
        table.insert(slice, array[i])
    end
    return slice
end

function M.get_file_handle(path, mode) 
    if not fs then 
        return io.open(path, mode)
    else
        return fs.open(path, mode)
    end
end

function M.exists(path) 
    if not fs then
        local f = io.open(path)
        if f ~= nil then
            io.close(f)
            return true
        else
            return false
        end
    else
        return fs.exists(path)
    end
end

function M.unpack(fmt, s) 
    local value = table.pack(string.unpack(fmt, s))[1]
    if not value then
        error("Got nil when unpacking value")
    end
    return value
end

function M.packint(number)
    return string.pack(">I4", number)
end

function M.unpackint(bytes)
    return table.pack(string.unpack(">I4", bytes))[1]
end

function M.packchar(char)
    return string.pack("B", char)
end

function M.unpackchar(bytes)
    return table.pack(string.unpack(">I4", bytes))[1]
end

return M