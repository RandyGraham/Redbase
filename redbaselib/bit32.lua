local M = {}

function M.band(a, b) 
    return a & b
end

function M.rshift(a, b)
    return a >> b
end

return M