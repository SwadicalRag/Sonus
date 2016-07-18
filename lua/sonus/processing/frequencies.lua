Sonus.FrequencyCategories = {}

local responseData = {
    [0] = math.huge,
    [125] = -0.91,
    [250] = 0.53,
    [500] = 1.24,
    [750] = 0.61,
    [100] = 0.12,
    [1500] = 0.51,
    [2000] = 0.42,
    [3000] = 0.17,
    [4000] = 0.08,
    [6000] = 1.48,
    [8000] = 1.08,
    [10000] = 3.72,
    [11200] = 3.45,
    [12500] = 4.22,
    [14000] = 4.15,
    [15000] = 1.51,
    [16000] = 0.77,
    [17000] = -0.50,
    [18000] = 0.07,
    [19000] = -3.58,
    [20000] = math.huge
}

local function RegisterCategory(name,fq_response,min_fq,max_fq)
    if max_fq then
        Sonus.FrequencyCategories[name] = {
            min = min_fq,
            max = max_fq,
            response = fq_response
        }
    else
        Sonus.FrequencyCategories[name] = {
            callback = min_fq,
            response = fq_response
        }
    end
end

function Sonus.lib.IsAudible(reqFq,energy,adjustment)
    adjustment = adjustment or 40

    local db = Sonus.lib.EnergyToDecibels(energy)

    local lastFq,lastMin = 0,0

    for fq,min in pairs(responseData) do
        if fq > reqFq then
            local lerpMin = (min - lastMin) / (fq - lastFq) * (reqFq - lastFq) + lastMin

            -- print(db.." > "..(lerpMin * adjustment),db > (lerpMin * adjustment))

            return db > (lerpMin * adjustment)
        elseif fq == reqFq then
            return db > min
        end

        lastFq = fq
        lastMin = min
    end

    return false
end

function Sonus.lib.DecibelsToEnergy(db)
    return (10^(db/10) * STANDARD_THRESHOLD_OF_HEARING)^0.5
end

function Sonus.lib.EnergyToDecibels(energy)
    return 10 * math.log(energy^2 / STANDARD_THRESHOLD_OF_HEARING,10)
end

function Sonus.lib.FrequencyResponse(name)
    if Sonus.FrequencyCategories[name] then
        return Sonus.FrequencyCategories[name].response or 0.025
    else
        return 0.025
    end
end

function Sonus.lib.IsFrequency(name,fq)
    if Sonus.FrequencyCategories[name] then
        if Sonus.FrequencyCategories[name].callback then
            return Sonus.FrequencyCategories[name].callback(fq)
        else
            return (fq >= Sonus.FrequencyCategories[name].min) and (fq < Sonus.FrequencyCategories[name].max)
        end
    else
        return false
    end
end

function Sonus.lib.FrequencyFilter(fq,callback)
    for name,data in pairs(Sonus.FrequencyCategories) do
        if data.callback then
            if data.callback(fq) then
                callback(name,0)
            end
        elseif (data.min <= fq) and (data.max > fq) then
            callback(name,fq - data.min)
        end
    end
end

function Sonus.lib.FrequencyExtract(category,tbl)
    local out,lookup = {},{}
    for fq,_ in pairs(tbl) do
        if Sonus.lib.IsFrequency(category,fq) then
            lookup[#lookup+1] = fq
            out[#out+1] = _
        end
    end

    return out,lookup
end

RegisterCategory("SubBass",0.025,0,60)
RegisterCategory("Bass",0.025,60,250)
RegisterCategory("MidRange",0.025,250,2000)
RegisterCategory("HighMids",0,2000,6000)
RegisterCategory("HighFreqs",0.025,6000,20000)

RegisterCategory("VoiceM",0.01,100,900)
RegisterCategory("VoiceF",0.01,250,1100)

RegisterCategory("Hits",0.005,function(fq)
    return (not (Sonus.lib.IsFrequency("VoiceM",fq) or Sonus.lib.IsFrequency("VoiceF",fq))) and Sonus.lib.IsFrequency("MidRange",fq)
end)
