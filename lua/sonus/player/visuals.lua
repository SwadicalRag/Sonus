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

Sonus.Player.Visualisations = {
    genesis = true
}

function Sonus.Player:GetActiveVisualiser()
    return self.ActiveVisualiser
end

function Sonus.Player:SetActiveVisualiser(name)
    if name == "none" then self.ActiveVisualiser = {} return end

    assert(self.Visualisations[name],"That visualiser does not exist!")

    VIS = {}
    VIS.event = Sonus.lib.NewEventEmitter()
    CompileFile("sonus/visuals/"..name..".lua")()
    self.ActiveVisualiser = VIS
    VIS = nil
end

concommand.Add("sonus_vis",function(_,_,_,name)
    Sonus.Player:SetActiveVisualiser(name)
end)

hook.Add("DrawOverlay","SoundVis",function()
    Sonus.Player.event:emit("Tick")
    if not Sonus.Player.ChannelProcessor then return end
    local audioData = Sonus.Player.ChannelProcessor:Process()
    VIS = Sonus.Player:GetActiveVisualiser()

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
            elseif data.trough.recentlyPresent then
                if show[category] then
                    print("TROUGH",category)
                end

                if VIS and VIS.event then
                    VIS.event:emit("Trough",category,data.trough.delta)
                    VIS.event:emit(category..".trough",data.trough.delta)
                end
            end
        end
    end

    if VIS and VIS.event then
        VIS.event:emit("Draw")
    end

    VIS = nil
end)
