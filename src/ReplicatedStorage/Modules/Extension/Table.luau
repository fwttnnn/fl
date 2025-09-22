--!strict
local _table = {}

function _table.filter(tbl: {any}, fn: (any) -> boolean): {any}
    local result = {}

    for i, v in ipairs(tbl) do
        if fn(v) then
            table.insert(result, v)
        end
    end

    return result
end

function _table.find(tbl: {any}, fn: (any) -> boolean): any
    for i, v in ipairs(tbl) do
        if fn(v) then
            return v
        end
    end

    return nil
end

function _table.index(tbl: {any}, fn: (any) -> boolean): number
    for i, v in ipairs(tbl) do
        if fn(v) then
            return i
        end
    end

    return 0
end

return _table
