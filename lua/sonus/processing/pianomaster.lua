local frequencyToFile = {
    [32.7032] = "a1",    -- C͵ contra-octave
    [34.6478] = "b1",    -- C♯͵/D♭͵
    [36.7081] = "a2",    -- D͵
    [38.8909] = "b2",    -- D♯͵/E♭͵
    [41.2034] = "a3",    -- E͵
    [43.6535] = "a4",    -- F͵
    [46.2493] = "b3",    -- F♯͵/G♭͵
    [48.9994] = "a5",    -- G͵
    [51.9131] = "b4",    -- G♯͵/A♭͵
    [55.0000] = "a6",    -- A͵
    [58.2705] = "b5",    -- A♯͵/B♭͵
    [61.7354] = "a7",    -- B͵
    [65.4064] = "a8",    -- C great octave
    [69.2957] = "b6",    -- C♯/D♭
    [73.4162] = "a9",    -- D
    [77.7817] = "b7",    -- D♯/E♭
    [82.4069] = "a10",    -- E
    [87.3071] = "a11",    -- F
    [92.4986] = "b8",    -- F♯/G♭
    [97.9989] = "a12",    -- G
    [103.826] = "b9",    -- G♯/A♭
    [110.000] = "a13",    -- A
    [116.541] = "b10",    -- A♯/B♭
    [123.471] = "a14",    -- B
    [130.813] = "a15",    -- c small octave
    [138.591] = "b11",    -- c♯/d♭
    [146.832] = "a16",    -- d
    [155.563] = "b12",    -- d♯/e♭
    [164.814] = "a17",    -- e
    [174.614] = "a18",    -- f
    [184.997] = "b13",    -- f♯/g♭
    [195.998] = "a19",    -- g
    [207.652] = "b14",    -- g♯/a♭
    [220.000] = "a20",    -- a
    [233.082] = "b15",    -- a♯/b♭
    [246.942] = "a21",    -- b
    [261.626] = "a22",    -- c′ 1-line octave
    [277.183] = "b16",    -- c♯′/d♭′
    [293.665] = "a23",    -- d′
    [311.127] = "b17",    -- d♯′/e♭′
    [329.628] = "a24",    -- e′
    [349.228] = "a25",    -- f′
    [369.994] = "b18",    -- f♯′/g♭′
    [391.995] = "a26",    -- g′
    [415.305] = "b19",    -- g♯′/a♭′
    [440.000] = "a27",    -- a′
    [466.164] = "b20",    -- a♯′/b♭′
    [493.883] = "a28",    -- b′
    [523.251] = "a29",    -- c′′ 2-line octave
    [554.365] = "b21",    -- c♯′′/d♭′′
    [587.330] = "a30",    -- d′′
    [622.254] = "b22",    -- d♯′′/e♭′′
    [659.255] = "a31",    -- e′′
    [698.456] = "a32",    -- f′′
    [739.989] = "b23",    -- f♯′′/g♭′′
    [783.991] = "a33",    -- g′′
    [830.609] = "b24",    -- g♯′′/a♭′′
    [880.000] = "a34",    -- a′′
    [932.328] = "b25",    -- a♯′′/b♭′′
    [987.767] = "a35",    -- b′′
    [1046.50] = "a36",    -- c′′′ 3-line octave
}

local INSTNET_USE = 1
local INSTNET_HEAR = 2
local INSTNET_PLAY = 3

local function getClosestKey(desiredFq,whiteOrBlack,targetDiff)
    local diff = math.huge
    local closestKey,closestFq
    for fq,key in pairs(frequencyToFile) do
        if(whiteOrBlack and (key:sub(1,1) == "b")) then
            continue
        elseif((whiteOrBlack == false) and (key:sub(1,1) == "a")) then
            continue
        end
        local keyDiff = math.abs(desiredFq - fq)
        diff = math.min(diff,keyDiff)
        if diff == keyDiff then
            closestKey = key
            closestFq = fq
        end
    end

    if diff > targetDiff then return false end

    --print(closestKey)
    return closestKey,closestFq
end

local playing,requests = {},0
local notesDown = {}

local function canProceed(closestKey)
    if notesDown[closestKey] then return false end

    local newList = {}
    for i,station in ipairs(playing) do
        if IsValid(station.station) then
            if station.dura then
                print((SysTime() - station.sysTime),station.dura)
                if (SysTime() - station.sysTime) >= station.dura then
                    station.station:Stop()
                    continue
                end
            end

            if (station.station:GetState() == GMOD_CHANNEL_PLAYING) then
                newList[#newList+1] = station
                if station.station then
                    notesDown[station.station:GetFileName()] = false
                end
            end
        end
    end
    playing = newList

    return (requests + #newList) <= 32
end

local cached = {}
local function sin(frequency,dura)
    -- local frequency = 2000 -- Hz
    -- if not (frequency > 120 and frequency < 6000) then return end
    dura = dura or 0.5
    local sound_id = "piano_fq_"..frequency.."_"..dura

    if not canProceed(sound_id) then return false end

    notesDown[sound_id] = true
    local samplerate = 44100

    local function data(t)
    	return math.sin(t * math.pi * dura / samplerate * frequency) * 0.05
    end

    timer.Simple(dura,function()
        notesDown[sound_id] = false
        requests = requests - 1
    end)

    if not cached[sound_id] then
        cached[sound_id] = true
        sound.Generate(sound_id,samplerate,dura,data)
    end

    requests = requests + 1
    surface.PlaySound(sound_id)
end

local cached = {}
local function sin2(frequency,dura,vol)
    -- local frequency = 2000 -- Hz
    -- if not (frequency > 120 and frequency < 6000) then return end
    dura = dura or 0.5
    vol = vol or 0.1
    local sound_id = "piano_fq_"..frequency.."_"..dura

    if not canProceed(sound_id) then return false end

    requests = requests + 1
    notesDown[sound_id] = true

    sound.PlayFile("sound/synth/sine_880.wav","",function(station)
        if(IsValid(station)) then
            requests = requests - 1
            playing[#playing+1] = {
                station = station,
                dura = dura,
                sysTime = SysTime()
            }
            station:SetPlaybackRate(frequency/880*1.5)
            -- print(frequency/880*1.5)
            station:EnableLooping(true)
            station:SetVolume(vol)
            station:Play()
        end
    end)
end

local function simulatePlayFrequency(desiredFq,whiteOrBlack,diff)
    local closestKey,closestFq = getClosestKey(desiredFq,whiteOrBlack,diff)
    if not closestKey then return false end

    if not canProceed(closestKey) then return false end
    requests = requests + 1
    notesDown["sound/gmodtower/lobby/instruments/piano/"..closestKey..".wav"] = true

    sound.PlayFile("sound/gmodtower/lobby/instruments/piano/"..closestKey..".wav","",function(station)
        if(IsValid(station)) then
            requests = requests - 1
            playing[#playing+1] = {
                station = station
            }
            station:Play()
        end
    end)
    return true,closestFq
end

local function playFrequency(desiredFq,whiteOrBlack,diff)
    local closestKey,closestFq = getClosestKey(desiredFq,whiteOrBlack,diff)
    if not closestKey then return false end

    local instrument = LocalPlayer().Instrument
    if not IsValid(instrument) then return end

    net.Start("InstrumentNetwork")
        net.WriteEntity(instrument)
        net.WriteInt(INSTNET_PLAY,3)
        net.WriteString(closestKey)
    net.SendToServer()
    simulatePlayFrequency(desiredFq,whiteOrBlack,diff)
    return true,closestFq
end

--gmodtower/lobby/instruments/piano/*.wav

Sonus.PianoMaster = {
    simulate = simulatePlayFrequency,
    play = playFrequency,
    pianoData = frequencyToFile,
    sin = sin,
    sin2 = sin2
}
