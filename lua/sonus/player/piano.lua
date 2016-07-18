Sonus.Player.IS_PIANO = Sonus.Player.IS_PIANO or false
local TYPE = "RoughPeak"

local freqHistory = {}
local SIN = true
local skip = {
    VoiceM = true,
    VoiceF = true
}

hook.Add("InitPostEntity","Sonus.piano",function()

end)

Sonus.Player.event:on("VIS.Peak","PianoPeak",function(category,delta)
    if not Sonus.Player.IS_PIANO then return end
    if TYPE ~= "RoughPeak" then return end

    if skip[category] then return end

    -- print(category)
    local data,lookup = Sonus.lib.FrequencyExtract(category,Sonus.LastAudioData.Energies)

    -- local hasPeak,p_idx,p_delta = Sonus.lib.PeakDetect(data,0.0125)
    --
    -- if hasPeak then
    --     local fq = lookup[p_idx]
    --     if SIN then
    --         print(("PLAY OK %dHz"):format(fq))
    --         Sonus.PianoMaster.sin(fq)
    --     else
    --         if Sonus.PianoMaster.simulate(fq,nil,20) then
    --             print(("PLAY OK %dHz"):format(fq))
    --         else
    --             print(("PLAY NOT OK %dHz"):format(fq))
    --         end
    --     end
    -- end

    local avgEnergy = Sonus.LastAudioData.TotalEnergy / Sonus.LastAudioData.DataLength
    Sonus.lib.PeakDetectEx(data,function(type,delta,p_idx,total_delta)
        if type ~= DELTA_PEAK then return end
        -- if not ((data[p_idx] >= avgEnergy*2.5) or (data[p_idx] >= 0.00004)) then return end
        -- if (not (data[p_idx] >= 0.0004)) then return end
        -- if (not (total_delta >= 0.0000075)) then return end
        -- if (not (total_delta >= avgEnergy*0.75)) then return end

        local fq = lookup[p_idx]

        if not Sonus.lib.IsAudible(fq,data[p_idx]) then return end
        if not Sonus.lib.IsAudible(fq,total_delta) then return end

        if SIN then
            print(("PLAY OK %dHz"):format(fq))
            -- Sonus.PianoMaster.sin(fq)
            Sonus.sin.playFrequency(fq)
        else
            if Sonus.PianoMaster.simulate(fq,nil,20) then
                print(("PLAY OK %dHz"):format(fq))
            else
                print(("PLAY NOT OK %dHz"):format(fq))
            end
        end
    end)
end)

Sonus.Player.event:on("DataTick","PianoBFDataTick",function(data)
    if not Sonus.Player.IS_PIANO then return end
    if TYPE ~= "BruteForce" then return end

    local data = Sonus.LastAudioData

    local peaks,lookup_peaks,troughs,lookup_troughs = Sonus.lib.PeakDetectAll(data.EnergiesArray,0.000001)

    for i,el in ipairs(peaks) do
        el.fq = data.FqLookup[i]
        el.energy = data.EnergiesArray[i]
    end

    table.sort(peaks,function(e1,e2)
        return e1.energy < e2.energy
    end)

    for i=1,math.min(#peaks,3) do
        local fq = peaks[i].fq

        if SIN then
            print(("PLAY OK %dHz"):format(fq))
            Sonus.sin.playFrequency(fq)
        else
            if Sonus.PianoMaster.simulate(fq,nil,20) then
                print(("PLAY OK %dHz"):format(fq))
            else
                print(("PLAY NOT OK %dHz"):format(fq))
            end
        end
    end
end)

Sonus.Player.event:on("DataTick","PianoDataTick",function(data)
    if not Sonus.Player.IS_PIANO then return end
    if TYPE ~= "Peak" then return end

    for fq,energy in pairs(data.Energies) do
        freqHistory[fq] = freqHistory[fq] or Sonus.lib.NewCircularBuffer(15)
        local buffer = freqHistory[fq]

        buffer:insert(energy)

        local hasPeak,p_idx,p_delta = Sonus.lib.PeakDetect(buffer,0.03)

        if hasPeak then
            if SIN then
                print(("PLAY OK %dHz"):format(fq))
                Sonus.sin.playFrequency(fq)
            else
                if Sonus.PianoMaster.simulate(fq,nil,20) then
                    print(("PLAY OK %dHz"):format(fq))
                else
                    print(("PLAY NOT OK %dHz"):format(fq))
                end
            end
        end
    end
end)

concommand.Add("sonus_piano",function()
    Sonus.Player.IS_PIANO = not Sonus.Player.IS_PIANO

    print(Sonus.Player.IS_PIANO and "piano on" or "piano off")

    if IsValid(Sonus.Player.ActiveStation) then
        if Sonus.Player.IS_PIANO then
            Sonus.Player.ActiveStation:SetVolume(0.1)
            freqHistory = {}
        else
            Sonus.Player.ActiveStation:SetVolume(1)
        end
    end
end)

Sonus.Player.event:on("Pause","Piano",function(category,delta)
    Sonus.sin.stop()
end)

Sonus.Player.event:on("Stop","Piano",function(category,delta)
    Sonus.sin.stop()
end)

Sonus.Player.event:on("Play","Piano",function(category,delta)
    if true then return end
    Sonus.sin.initialiseChannels(8)
end)

if IsValid(Sonus.Player.ActiveStation) then
    if true then return end
    Sonus.sin.initialiseChannels(8)
    if Sonus.Player.IS_PIANO then
        Sonus.Player:SetVolume(0.025)
        freqHistory = {}
    else
        Sonus.Player:SetVolume(1)
    end
end
