if IsValid(Sonus.Player.Panel) then
    Sonus.Player.Panel:Remove()
end

Sonus.Player.Panel = vgui.Create("DFrame")

local Panel = Sonus.Player.Panel

Panel:SetSize(600,430)
Panel:SetPos(ScrW()/2 - 300,ScrH()/2 - 215)
Panel:SetMouseInputEnabled(true)
Panel:SetKeyBoardInputEnabled(false)
Panel:ShowCloseButton(true)
Panel:SetDeleteOnClose(false)
Panel:Hide()
Panel:SetTitle("Sonus")

Panel.lastToggled = SysTime()
concommand.Add("+sonus",function()
    if Panel:IsVisible() then
        Panel:Hide()
    else
        Panel:Show()
        Panel:MakePopup()
        Panel:SetMouseInputEnabled(true)
        Panel:SetKeyBoardInputEnabled(false)
    end

    Panel.lastToggled = SysTime()
end)

concommand.Add("-sonus",function()
    if (SysTime() - Panel.lastToggled) > 0.5 then
        Panel:Hide()
    end
end)

function Panel:Paint(w,h)
    surface.SetDrawColor(Color(255,255,255,220))
    surface.DrawRect(0,0,w,h)

    surface.SetDrawColor(Color(105,155,155,220))
    surface.DrawRect(0,0,w,25)
end

local Playlist = vgui.Create("DListView",Panel)
Playlist:SetPos(10,35)
Playlist:SetSize(380,305)

Playlist:SetMultiSelect(false)
Playlist:AddColumn("ID")
Playlist:AddColumn("Title")
Playlist:AddColumn("Artist")

function Playlist:DoDoubleClick(id,line)
    Sonus.Player:Pause()
    Sonus.Player:PlayID(id)
end

function Playlist:UpdateOrder()
    self:Clear()
    for i,track in pairs(Sonus.Player.Playlist) do
        self:AddLine(i,track.title,track.artist)
    end
    self:SelectItem(self:GetLine(Sonus.Player.CurrentTrackID))
end
Sonus.Player.event:on("PlaylistUpdate",function()
    Playlist:UpdateOrder()
end)
Sonus.Player.event:on("Playing",function()
    Playlist:UpdateOrder()
end)
Playlist:UpdateOrder()

surface.CreateFont("NormalButtonFont",{
	font = "Roboto",
	extended = false,
	size = 22,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
})

local AddURL = vgui.Create("DButton",Panel)
AddURL:SetFont("NormalButtonFont")
AddURL:SetColor(Color(255,255,255))
AddURL:SetText("Add from a URL")
AddURL:SetPos(410,35)
AddURL:SetSize(170,50)
function AddURL:Paint(w,h)
    surface.SetDrawColor(Color(105,155,155,220))
    surface.DrawRect(0,0,w,h)
end

function AddURL:DoClick()
    Derma_StringRequest(
        "Sonus URL Parser",
        "Enter a valid URL to a soundcloud track or direct media file",
        "",
        function(url)
            if not Sonus.Soundcloud.GetMetadata(url,function(data)
                Sonus.Player:AddTrack(Sonus.Soundcloud.AppendClientID(data.stream_url),data.title,data.user.username)
            end) then
                -- notification.AddLegacy("Invalid URL!",NOTIFY_ERROR,5)
                Sonus.Player:AddTrack(url,"Unknown title","Unknown artist")
            end
        end
    )
end

local AddQuery = vgui.Create("DButton",Panel)
AddQuery:SetFont("NormalButtonFont")
AddQuery:SetColor(Color(255,255,255))
AddQuery:SetText("Add from a search")
AddQuery:SetPos(410,95)
AddQuery:SetSize(170,50)
function AddQuery:Paint(w,h)
    surface.SetDrawColor(Color(105,155,155,220))
    surface.DrawRect(0,0,w,h)
end

function AddQuery:DoClick()
    Derma_StringRequest(
        "Sonus URL Parser",
        "Enter your query",
        "",
        function(query)
            Sonus.Soundcloud.SearchTracks(query,function(data)
                if data[1] then
                    Sonus.Player:AddTrack(Sonus.Soundcloud.AppendClientID(data[1].stream_url),data[1].title,data[1].user.username)
                else
                    notification.AddLegacy("No tracks found!",NOTIFY_ERROR,5)
                end
            end)
        end
    )
end

local RemoveEntry = vgui.Create("DButton",Panel)
RemoveEntry:SetFont("NormalButtonFont")
RemoveEntry:SetColor(Color(255,255,255))
RemoveEntry:SetText("Delete track")
RemoveEntry:SetPos(410,215)
RemoveEntry:SetSize(170,50)
function RemoveEntry:Paint(w,h)
    surface.SetDrawColor(Color(105,155,155,220))
    surface.DrawRect(0,0,w,h)
end

function RemoveEntry:DoClick()
    local idx = Playlist:GetSelectedLine()
    Sonus.Player:RemoveTrack(idx)
end

local ShareTrack = vgui.Create("DButton",Panel)
ShareTrack:SetFont("NormalButtonFont")
ShareTrack:SetColor(Color(255,255,255))
ShareTrack:SetText("Share current track")
ShareTrack:SetPos(410,155)
ShareTrack:SetSize(170,50)
function ShareTrack:Paint(w,h)
    surface.SetDrawColor(Color(105,155,155,220))
    surface.DrawRect(0,0,w,h)
end

function ShareTrack:DoClick()
    -- Derma_Message("Unimplemented.","Sonus","ok :'(")
    local track = Sonus.Player.Playlist[#Sonus.Player.Playlist]
    if track and IsValid(Sonus.Player.ActiveStation) then
        local dialog = vgui.Create("DFrame")
        dialog:SetPos(ScrW()/2-250,ScrH()/2-150)
        dialog:SetSize(500,300)
        dialog:MakePopup()
        dialog.Paint = Panel.Paint

        local Playerlist = vgui.Create("DListView",dialog)
        Playerlist:SetPos(10,35)
        Playerlist:SetSize(480,215)

        Playerlist:AddColumn("Nickname")

        local list = player.GetAll()
        for i,ply in ipairs(list) do
            Playerlist:AddLine(ply:Nick()).ply = ply
        end

        local Share = vgui.Create("DButton",dialog)
        Share:SetFont("NormalButtonFont")
        Share:SetColor(Color(255,255,255))
        Share:SetText("Share")
        Share:SetPos(10,260)
        Share:SetSize(480,30)
        function Share:Paint(w,h)
            surface.SetDrawColor(Color(105,155,155,220))
            surface.DrawRect(0,0,w,h)
        end

        function Share:DoClick()
            for i,line in ipairs(Playerlist:GetSelected()) do
                Sonus:ShareTrack(line.ply,track.url,CurTime() - Sonus.Player.ActiveStation:GetTime(),track.artist,track.title)
            end

            dialog:Remove()
        end
    else
        notification.AddLegacy("No track is playing!",NOTIFY_ERROR,5)
    end
end

local Visuals = vgui.Create("DButton",Panel)
Visuals:SetFont("NormalButtonFont")
Visuals:SetColor(Color(255,255,255))
Visuals:SetText("Visualiser")
Visuals:SetPos(410,275)
Visuals:SetSize(170,50)
function Visuals:Paint(w,h)
    surface.SetDrawColor(Color(105,155,155,220))
    surface.DrawRect(0,0,w,h)
end

function Visuals:DoClick()
    Derma_Query(
        "Pick a visualiser",
        "Sonus VIS",
        "None",
        function()
            Sonus.Player:SetActiveVisualiser("none")
        end,
        "Genesis",
        function()
            Sonus.Player:SetActiveVisualiser("genesis")
        end
    )
end

local AudioControl = vgui.Create("DPanel",Panel)
AudioControl:SetPos(0,350)
AudioControl:SetSize(600,80)

function AudioControl:Paint(w,h)
    surface.SetDrawColor(Color(105,155,155,220))
    surface.DrawRect(0,0,w,h)
end

local AudioMetadata = vgui.Create("DLabel",AudioControl)
AudioMetadata:SetPos(160,0)
AudioMetadata:SetSize(310,50)
AudioMetadata:SetFont("DermaLarge")
AudioMetadata:SetColor(Color(255,255,255))
function AudioMetadata:UpdateText()
    if Sonus.Player.Metadata then
        -- self:SetText(Sonus.Player.Metadata.Artist.." - "..Sonus.Player.Metadata.Title)
        self:SetText(Sonus.Player.Metadata.Title or "Unknown title")
    else
        self:SetText("No tracks are playing.")
    end
end
Sonus.Player.event:on("Playing",function()
    AudioMetadata:UpdateText()
end)
AudioMetadata:UpdateText()

surface.CreateFont("TextButtonFont",{
	font = "Roboto",
	extended = false,
	size = 64,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
})

local PrevButton = vgui.Create("DButton",AudioControl)
PrevButton:SetText("")
PrevButton:SetPos(0,0)
PrevButton:SetSize(50,50)
function PrevButton:Paint(w,h)
    surface.SetDrawColor(Color(255,255,255,220))
    surface.DrawRect(0,0,w,h)
    draw.SimpleText("⏪","TextButtonFont",w/2,h/2-6,Color(0,0,0),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
end

function PrevButton:DoClick()
    Sonus.Player:PreviousTrack()
end

local PlayButton = vgui.Create("DButton",AudioControl)
PlayButton:SetText("")
PlayButton:SetPos(50,0)
PlayButton:SetSize(50,50)
function PlayButton:Paint(w,h)
    surface.SetDrawColor(Color(255,255,255,220))
    surface.DrawRect(0,0,w,h)
    if IsValid(Sonus.Player.ActiveStation) and Sonus.Player.ActiveStation:GetState() == GMOD_CHANNEL_PLAYING then
        draw.SimpleText("⏸","TextButtonFont",w/2,h/2-10,Color(0,0,0),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    else
        draw.SimpleText("▶","TextButtonFont",w/2,h/2,Color(0,0,0),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    end
end

function PlayButton:DoClick()
    if IsValid(Sonus.Player.ActiveStation) then
        if Sonus.Player.ActiveStation:GetState() == GMOD_CHANNEL_PLAYING then
            Sonus.Player.ActiveStation:Pause()
        else
            Sonus.Player.ActiveStation:Play()
        end
    end
end

local NextButton = vgui.Create("DButton",AudioControl)
NextButton:SetText("")
NextButton:SetPos(100,0)
NextButton:SetSize(50,50)
function NextButton:Paint(w,h)
    surface.SetDrawColor(Color(255,255,255,220))
    surface.DrawRect(0,0,w,h)
    draw.SimpleText("⏩","TextButtonFont",w/2,h/2-6,Color(0,0,0),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
end

function NextButton:DoClick()
    Sonus.Player:NextTrack()
end

local VolumeSlider = vgui.Create("DNumSlider",AudioControl)
VolumeSlider:SetPos(480,10)
VolumeSlider:SetSize(120,30)
VolumeSlider.TextArea:SetTextColor(Color(255,255,255))
VolumeSlider.TextArea:SetText("100%")
-- VolumeSlider:SetDecimals(1)
VolumeSlider.Slider:SetImageColor(255,255,255)
function VolumeSlider:OnValueChanged(val)
    self.TextArea:SetText(string.format("%02d%%",val*100))

    if self:IsEditing() then
        Sonus.Player:SetVolume(val)
    end
end
function VolumeSlider:PerformLayout()
    self.Label:SetWide(0)
end

VolumeSlider:SetValue(Sonus.Player:GetVolume())
Sonus.Player.event:on("VolumeUpdate",function(vol)
    if not VolumeSlider:IsEditing() then
        VolumeSlider:SetValue(Sonus.Player:GetVolume())
    end
end)

local Scrub = vgui.Create("DNumSlider",AudioControl)
Scrub:SetPos(10,50)
Scrub:SetSize(580,30)
Scrub.TextArea:SetTextColor(Color(255,255,255))
Scrub.TextArea:SetText("0:00")
-- Scrub:SetDecimals(1)
Scrub.Slider:SetImageColor(255,255,255)
function Scrub:OnValueChanged(val)
    self.TextArea:SetText(string.format("%d:%02d",val/60,val%60))

    if IsValid(Sonus.Player.ActiveStation) and self:IsEditing() then
        Sonus.Player.ActiveStation:SetTime(val)
    end
end
function Scrub:PerformLayout()
    self.Label:SetWide(0)
end

timer.Create("sonus.updateUISlider",0.1,0,function()
    if IsValid(Sonus.Player.ActiveStation) and not Scrub:IsEditing() then
        local len = Sonus.Player.ActiveStation:GetLength()
        if len ~= Scrub:GetMax() then
            Scrub:SetMax(len)
        end
        Scrub:SetValue(Sonus.Player.ActiveStation:GetTime())
    end
end)
