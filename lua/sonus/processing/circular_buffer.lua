function Sonus.lib.NewCircularBuffer(size)
    local t = {}

    function t:insert(val)
        while #self >= size do
            table.remove(self,1)
        end

        self[#self + 1] = val
    end

    return t
end
