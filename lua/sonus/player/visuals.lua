local show = {
    -- SubBass = true,
    -- Bass = true,
    -- MidRange = true,
    -- HighMids = true,
    -- HighFreqs = true,
    -- VoiceM = true,
    -- VoiceF = true,
    -- Hits = true,
}

Sonus.Player.Visualisations = {}

function Sonus.Player:GetActiveVisualiser()
    return self.ActiveVisualiser
end

local VisualiserMetadataMetatable = {}
VisualiserMetadataMetatable.__index = VisualiserMetadataMetatable

function VisualiserMetadataMetatable:SetName(name)
    self.Name = name
    return self
end

function VisualiserMetadataMetatable:SetVersion(version)
    self.Version = Version
    return self
end

function Sonus.Player:RegisterVisualiser(id,VIS)
    self.Visualisations[id] = VIS

    VIS.Metadata = setmetatable({},VisualiserMetadataMetatable)

    return VIS.Metadata
end

function Sonus.Player:SetActiveVisualiser(name)
    assert(self.Visualisations[name],"That visualiser does not exist!")

    self.ActiveVisualiser = self.Visualisations[name]
end

concommand.Add("sonus_vis",function(_,_,_,name)
    Sonus.Player:SetActiveVisualiser(name)
end)

hook.Add("DrawOverlay","SoundVis",function()
    Sonus.Player.event:emit("Tick")
    if not Sonus.Player.ChannelProcessor then return end
    local audioData = Sonus.Player.ChannelProcessor:Process()
    local VIS = Sonus.Player:GetActiveVisualiser()
    Sonus.Player.event:emit("DataTick",audioData)
    Sonus.LastAudioData = audioData

    if audioData then
        if VIS then
            VIS.Channel = Sonus.Player.ActiveStation
            VIS.audioData = audioData
            VIS.Metadata = Sonus.Player.Metadata
        end

        for category,data in pairs(audioData.CategoricalPeaks) do
            if data.peak.recentlyPresent then
                if show[category] then
                    print("PEAK",category)
                end

                if VIS and VIS.event then
                    VIS.event:emit("Peak",category,data.peak.delta)
                    VIS.event:emit(category..".peak",data.peak.delta)
                end

                Sonus.Player.event:emit("VIS.Peak",category,data.peak.delta)
                Sonus.Player.event:emit("VIS."..category..".peak",data.peak.delta)
            elseif data.trough.recentlyPresent then
                if show[category] then
                    print("TROUGH",category)
                end

                if VIS and VIS.event then
                    VIS.event:emit("Trough",category,data.trough.delta)
                end

                Sonus.Player.event:emit("VIS.Trough",category,data.trough.delta)
                Sonus.Player.event:emit("VIS."..category..".trough",data.trough.delta)
            end
        end
    end

    if VIS and VIS.event then
        VIS.event:emit("Draw")
    end
end)

Sonus.Player:RegisterVisualiser("none",{})

do
    local files,folders = file.Find("sonus/visuals/*.lua","LUA")
    for i,fileName in ipairs(files) do
        include("sonus/visuals/"..fileName)
    end
end
