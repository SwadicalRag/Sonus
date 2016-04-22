Sonus.FrequencyCategories = {}

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

function Sonus.lib.FrequencyResponse(name)
    if Sonus.FrequencyCategories[name] then
        return Sonus.FrequencyCategories[name].response or 0.025
    else
        return 0.025
    end
end

function Sonus.lib.IsFrequency(name,fq)
    if Sonus.FrequencyCategories[name] then
        return (fq >= Sonus.FrequencyCategories[name].min) and (fq < Sonus.FrequencyCategories[name].max)
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
