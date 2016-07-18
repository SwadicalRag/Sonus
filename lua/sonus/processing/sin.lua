Sonus.sin = Sonus.sin or {}
local channels = Sonus.sin.channels or {}
Sonus.sin.channels = channels

local base = 880 -- hz

local function stop()
    for i,chanData in ipairs(channels) do
        if IsValid(chanData.station) then
            chanData.station:Stop()
        end
    end

    for i=1,#channels do
        channels[i] = nil
    end
end

local function initialiseChannels(amt)
    stop()
    for i=1,amt or 5 do
        sound.PlayFile("sound/synth/sine_"..base..".wav","",function(station)
            if(IsValid(station)) then
                channels[i] = {
                    station = station
                }

                station:EnableLooping(true)
                station:SetVolume(0)
                station:Play()
            end
        end)
    end
end

local function getChannel(fq)
    if fq then
        for i,chanData in ipairs(channels) do
            if chanData.frequency == fq then
                channels[#channels] = table.remove(channels,i)
                chanData.frequency = fq
                return chanData.station
            end
        end
    end

    local chan = channels[1]

    if not chan then return false end
    if not IsValid(chan.station) then return false end

    channels[#channels] = table.remove(channels,1)

    chan.frequency = fq
    return chan.station
end

local function playFrequency(frequency,duration,volume)
    -- local frequency = 2000 -- Hz
    -- if not (frequency > 120 and frequency < 6000) then return end
    duration = duration or 0.5
    volume = volume or 0.1

    local station = getChannel(frequency)
    if not station then return false end

    local add = 1

    if station:GetState() ~= GMOD_CHANNEL_PLAYING then
        station:Play()
    end

    station:SetPlaybackRate(frequency/base * add)
    station:SetVolume(volume)
end

Sonus.sin.initialiseChannels = initialiseChannels
Sonus.sin.getChannel = getChannel
Sonus.sin.playFrequency = playFrequency
Sonus.sin.stop = stop
