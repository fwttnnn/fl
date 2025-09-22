--!strict

function table.filter(tbl, fn)
    local result = {}

    for i, v in ipairs(tbl) do
        if fn(v) then
            table.insert(result, v)
        end
    end

    return result
end

function table._find(tbl, fn)
    for i, v in ipairs(tbl) do
        if fn(v) then
            return v
        end
    end

    return nil
end

function table.index(tbl, fn)
    for i, v in ipairs(tbl) do
        if fn(v) then
            return i
        end
    end

    return 0
end
