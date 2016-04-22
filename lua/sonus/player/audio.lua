Sonus.Player = Sonus.Player or {}
Sonus.Player.event = Sonus.lib.NewEventEmitter()

function Sonus.Player:PlayURL(url,callback)
    callback = callback or function()end
    sound.PlayURL(url,"noplay noblock",function(station)
        if IsValid(station) then
            self:Stop()
            self.ActiveStation = station
            self.ChannelProcessor = Sonus.lib.NewChannelProcessor(station)
            station:Play()
            Sonus.Player.event:emit("Playing")

            callback(true)
        else
            callback(false)
        end
    end)
end

function Sonus.Player:Pause()
    if IsValid(Sonus.Player.ActiveStation) then
        Sonus.Player.ActiveStation:Pause()
    end
end

function Sonus.Player:Play()
    if IsValid(Sonus.Player.ActiveStation) then
        Sonus.Player.ActiveStation:Play()
    end
end

function Sonus.Player:IsPlaying()
    if IsValid(Sonus.Player.ActiveStation) then
        return Sonus.Player.ActiveStation:GetState() == GMOD_CHANNEL_PLAYING
    end
    return false
end

function Sonus.Player:TogglePlay()
    if self:IsPlaying() then
        self:Pause()
    else
        self:Play()
    end
end

function Sonus.Player:Stop()
    if IsValid(Sonus.Player.ActiveStation) then
        Sonus.Player.ActiveStation:Stop()
    end
end

Sonus.Player.CurrentTrackID = Sonus.Player.CurrentTrackID or 0
Sonus.Player.Playlist = Sonus.Player.Playlist or {}

function Sonus.Player:AddTrack(url,title,artist)
    self.Playlist[#self.Playlist + 1] = {
        url = url,
        title = title,
        artist = artist
    }

    self.event:emit("PlaylistUpdate")
end

function Sonus.Player:RemoveTrack(id)
    table.remove(self.Playlist,id)
    self.event:emit("PlaylistUpdate")
end

function Sonus.Player:PlayID(id,callback)
    local track = self.Playlist[id]

    if track then
        self.CurrentTrackID = id
        self:Pause()
        self.Metadata = {
            Artist = track.artist,
            Title = track.title
        }
        self:PlayURL(track.url,callback or function()end)
    end
end

function Sonus.Player:PlayLastEntry(callback)
    self:PlayID(#self.Playlist,callback)
end

function Sonus.Player:PlayFirstEntry()
    self:PlayID(1)
end

function Sonus.Player:NextTrack()
    self.CurrentTrackID = self.CurrentTrackID + 1
    local track = self.Playlist[self.CurrentTrackID]
    if track then
        self:Pause()
        self.Metadata = {
            Artist = track.artist,
            Title = track.title
        }
        self:PlayURL(track.url,function()end)
    else
        self.CurrentTrackID = self.CurrentTrackID - 1
    end
end

function Sonus.Player:PreviousTrack()
    self.CurrentTrackID = self.CurrentTrackID - 1
    local track = self.Playlist[self.CurrentTrackID]
    if track then
        self:Pause()
        self.Metadata = {
            Artist = track.artist,
            Title = track.title
        }
        self:PlayURL(track.url,function()end)
    else
        self.CurrentTrackID = self.CurrentTrackID + 1
    end
end

Sonus.Player.event:on("Tick",function()
    if IsValid(Sonus.Player.ActiveStation) then
        if Sonus.Player.ActiveStation:GetTime()/Sonus.Player.ActiveStation:GetLength() == 1 then
            Sonus.Player.ActiveStation = nil
            Sonus.Player:NextTrack()
        end
    end
end)

concommand.Add("sonus_stop",function()
    Sonus.Player:Stop()
end)

concommand.Add("sonus_search",function(_,_,_,query)
    Sonus.Soundcloud.SearchTracks(query,function(data)
        if data[1] then
            Sonus.Player:AddTrack(Sonus.Soundcloud.AppendClientID(data[1].stream_url),data[1].title,data[1].user.username)
            Sonus.Player:PlayLastEntry()
        end
    end)
end)
