--!strict
local Queue = {}
Queue.__index = Queue

export type Queue<T> = {
    _first: number,
    _last: number,
    _data: {[number]: T},
    Push: (self: Queue<T>, value: T) -> (),
    Pop: (self: Queue<T>) -> T?,
    Peek: (self: Queue<T>) -> T?,
    IsEmpty: (self: Queue<T>) -> boolean,
    Size: (self: Queue<T>) -> number,
}

function Queue.new<T>(): Queue<T>
    return setmetatable({
        _first = 0,
        _last = -1,
        _data = {},
    }, Queue)
end

function Queue:Push<T>(value: T)
    self._last += 1
    self._data[self._last] = value
end

function Queue:Pop<T>(): T?
    if self:IsEmpty() then return nil end
    local value = self._data[self._first]
    self._data[self._first] = nil
    self._first += 1
    return value
end

function Queue:Peek<T>(): T?
    return self._data[self._first]
end

function Queue:IsEmpty(): boolean
    return self._first > self._last
end

function Queue:Size(): number
    return self._last - self._first + 1
end

return Queue
