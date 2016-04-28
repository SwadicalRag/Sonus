function Sonus.lib.LowPassFilter(tbl,amt,len,from)
    len = len or #tbl
    local entries = math.floor(len/amt + 0.5)

    local out = {0}

    for i=from,from+len-1 do
        if i % entries == 0 then
            out[#out] = out[#out]/entries
            out[#out + 1] = 0
        else
            out[#out] = out[#out] + tbl[i]
        end
    end

    if len % entries ~= 0 then
        out[#out] = out[#out]/(#tbl % entries)
    else
        out[#out] = nil
    end

    return out
end

function Sonus.lib.SmoothFilter(array,passes)
    ::smooth::
    for i=2,#array-1 do
        array[i] = (array[i-1] + array[i] + array[i+1])/3
    end
    if passes and passes > 0 then passes = passes - 1 goto smooth end
end
