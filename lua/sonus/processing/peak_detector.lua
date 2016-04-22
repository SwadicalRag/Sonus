function Sonus.lib.GetDeltas(array)
    local deltas = {}

    local lastVal = array[1]
    for i=2,#array - 1 do
        deltas[#deltas + 1] = array[i] - lastVal
        lastVal = array[i]
    end

    return deltas
end

DELTA_PEAK,DELTA_TROUGH,DELTA_FLAT = 1,2,3

function Sonus.lib.PeakDetectEx(array,callback)
    local deltas = Sonus.lib.GetDeltas(array)

    local lastDelta,lastPeak,lastTrough = 0,array[1],array[1]
    for i,delta in ipairs(deltas) do
        local val = array[i + 1]

        if lastDelta then
            if delta > 0 then
                if lastDelta < 0 then
                    if callback(DELTA_TROUGH,delta,i,val - lastPeak) then return end
                    lastTrough = val
                end
            elseif delta < 0 then
                if lastDelta > 0 then
                    if callback(DELTA_PEAK,delta,i,val - lastTrough) then return end
                    lastPeak = val
                end
            else
                callback(DELTA_FLAT,i,0)
            end
        end

        lastDelta = delta
    end
end

function Sonus.lib.PeakDetectReverseEx(array,callback)
    local deltas = Sonus.lib.GetDeltas(array)

    local lastDelta,lastPeak,lastTrough = 0,array[1],array[1]
    for i=#deltas,1,-1 do
        local delta = deltas[i]
        local val = array[i + 1]

        if lastDelta then
            if delta > 0 then
                if lastDelta < 0 then
                    if callback(DELTA_PEAK,delta,i+1,val - lastTrough) then return end
                    lastPeak = val
                end
            elseif delta < 0 then
                if lastDelta > 0 then
                    if callback(DELTA_TROUGH,delta,i+1,val - lastPeak) then return end
                    lastTrough = val
                end
            else
                callback(DELTA_FLAT,0,i,0)
            end
        end

        lastDelta = delta
    end
end

function Sonus.lib.PeakDetectAll(array,threshold)
    local peaks,troughs = {},{}
    local lookup_peaks,lookup_troughs = {},{}

    Sonus.lib.PeakDetectEx(array,function(type,delta,idx,total_delta)
        if math.abs(total_delta) < threshold then return end

        if type == DELTA_PEAK then
            peaks[#peaks + 1] = {
                idx = idx,
                delta = total_delta
            }
            lookup_peaks[idx] = true
        elseif type == DELTA_TROUGH then
            troughs[#troughs + 1] = {
                idx = idx,
                delta = total_delta
            }
            lookup_troughs[idx] = true
        end
    end)

    return peaks,lookup_peaks,troughs,lookup_troughs
end

function Sonus.lib.PeakDetect(array,threshold)
    local found,found_idx,found_delta = false

    Sonus.lib.PeakDetectReverseEx(array,function(type,delta,idx,total_delta)
        if math.abs(total_delta) < threshold then return end

        if type == DELTA_PEAK then
            found = true
            found_idx = idx
            found_delta = total_delta
            return true
        end
    end)

    return found,found_idx,found_delta
end

function Sonus.lib.TroughDetect(array,threshold)
    local found,found_idx,found_delta = false

    Sonus.lib.PeakDetectReverseEx(array,function(type,delta,idx,total_delta)
        if math.abs(total_delta) < threshold then return end

        if type == DELTA_TROUGH then
            found = true
            found_idx = idx
            found_delta = total_delta
            return true
        end
    end)

    return found,found_idx,found_delta
end
