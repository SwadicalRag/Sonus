local CProc = {}
CProc.__index = CProc

STANDARD_THRESHOLD_OF_HEARING = 10^(-12)

function CProc:AnalyseDFT(DFT)
    local sampleRate = self.Channel:GetSamplingRate()
    local N = #DFT

    local totalEnergy = 0

    local fqLookup = {}
    local energies,energiesArray = {},{}
    local decibels = {}

    for k=1,#DFT/2 do
        local bin = DFT[k]
        local frequency = (k-1) / N * sampleRate

        local energy = bin^2

        energiesArray[#energiesArray + 1] = energy

        decibels[frequency] = 10 * math.log(bin^2 / STANDARD_THRESHOLD_OF_HEARING,10)
        energies[frequency] = energy

        fqLookup[#fqLookup + 1] = frequency

        totalEnergy = totalEnergy + energy
    end

    return fqLookup,energies,energiesArray,decibels,totalEnergy,10 * math.log(totalEnergy / STANDARD_THRESHOLD_OF_HEARING,10)
end

function CProc:GetEnergyBuffer(category)
    self.EnergyBuffers[category] = self.EnergyBuffers[category] or Sonus.lib.NewCircularBuffer(25)
    return self.EnergyBuffers[category]
end

function CProc:PerformCategoricalAnalysis(data)
    data.CategoricalEnergies = {}
    for fq,energy in pairs(data.Energies) do
        Sonus.lib.FrequencyFilter(fq,function(category,deviation)
            data.CategoricalEnergies[category] = data.CategoricalEnergies[category] or 0
            data.CategoricalEnergies[category] = data.CategoricalEnergies[category] + energy
        end)
    end

    data.CategoricalPeaks = {}

    for category,totalEnergy in pairs(data.CategoricalEnergies) do
        local buffer = self:GetEnergyBuffer(category)
        buffer:insert(totalEnergy)

        local hasPeak,p_idx,p_delta = Sonus.lib.PeakDetect(buffer,Sonus.lib.FrequencyResponse(category) or 0.025)
        local hasTrough,t_idx,t_delta = Sonus.lib.TroughDetect(buffer,Sonus.lib.FrequencyResponse(category) or 0.025)

        local recency = 3

        data.CategoricalPeaks[category] = {
            peak = {
                present = hasPeak,
                recentlyPresent = hasPeak and (p_idx > (#buffer - recency)),
                idx = p_idx,
                delta = p_delta
            },
            trough = {
                present = hasTrough,
                recentlyPresent = hasTrough and (t_idx > (#buffer - recency)),
                idx = t_idx,
                delta = t_delta
            }
        }
    end
end

function CProc:Process(sampleSize)
    if not IsValid(self.Channel) then return false end

    local data = {}

    data.RawDFT = {}
    self.Channel:FFT(data.RawDFT,sampleSize or FFT_16384)

    data.DataLength = #data.RawDFT/2

    data.FqLookup,data.Energies,data.EnergiesArray,data.Decibels,data.TotalEnergy,data.TotalDecibels = self:AnalyseDFT(data.RawDFT)

    data.LeftLevel,data.RightLevel = self.Channel:GetLevel()
    data.AverageLevel = (data.LeftLevel + data.RightLevel) / 2

    self:PerformCategoricalAnalysis(data)

    return data
end

function Sonus.lib.NewChannelProcessor(IGModAudioChannel)
    local instance = setmetatable({},CProc)

    instance.EnergyBuffers = {}
    instance.Channel = IGModAudioChannel

    return instance
end
