--!strict
local _table = {}

function _table.filter<T>(tbl: {T}, fn: (T) -> boolean): {T}
    local result = {}

    for i, v in ipairs(tbl) do
        if fn(v) then
            table.insert(result, v)
        end
    end

    return result
end

function _table.remove<T>(tbl: {T}, fn: (T) -> boolean): ()
	for i = #tbl, 1, -1 do
		if fn(tbl[i]) then
			table.remove(tbl, i)
		end
	end
end

function _table.shift<T>(tbl: {T}, n: number): {T}
    n = n % #tbl  -- handles n > #tbl
    if n == 0 then return tbl end

    local last = {}
    for i = #tbl - n + 1, #tbl do
        table.insert(last, tbl[i])
    end

    local saved = {}
    for i = 1, #tbl - n do
        table.insert(saved, tbl[i])
    end

    local count = 1

    for i = 1, #last do
        tbl[count] = last[i]
        count += 1
    end

    for i = 1, #saved do
        tbl[count] = saved[i]
        count += 1
    end

    return tbl
end

function _table.find<T>(tbl: {T}, fn: (T) -> boolean): T
    for i, v in ipairs(tbl) do
        if fn(v) then
            return v
        end
    end

    return nil
end

function _table.index<T>(tbl: {T}, fn: (T) -> boolean): number
    for i, v in ipairs(tbl) do
        if fn(v) then
            return i
        end
    end

    return 0
end

return _table
