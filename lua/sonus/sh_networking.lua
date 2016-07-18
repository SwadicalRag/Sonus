if SERVER then
    util.AddNetworkString("sonus_share")
    net.Receive("sonus_share",function(_,ply)
        local target = net.ReadEntity()
        local url = net.ReadString()
        local title = net.ReadString()
        local artist = net.ReadString()
        local timeStamp = net.ReadFloat()

        net.Start("sonus_share")
            net.WriteEntity(ply)
            net.WriteString(url)
            net.WriteString(title)
            net.WriteString(artist)
            net.WriteFloat(timeStamp)
        net.Send(target)
    end)
else
    function Sonus:ShareTrack(target,url,timeStamp,artist,title)
        net.Start("sonus_share")
            net.WriteEntity(target)
            net.WriteString(url)
            net.WriteString(title)
            net.WriteString(artist)
            net.WriteFloat(timeStamp)
        net.SendToServer()
    end

    local blocked = {}

    concommand.Add("sonus_clearblocks",function()
        blocked = {}
    end)

    local queue = {}
    local occupied = false

    net.Receive("sonus_share",function()
        local from = net.ReadEntity()
        local url = net.ReadString()
        local title = net.ReadString()
        local artist = net.ReadString()
        local timeStamp = net.ReadFloat()

        if occupied then
            LocalPlayer():ChatPrint("[Sonus] Could not receive a share from "..from:Nick().."!")
        end
        if blocked[from:SteamID()] then return end

        occupied = true
        Derma_Query(
            "Incoming share from "..from:Nick()..": "..artist.." - "..title,
            "Sonus",
            "Accept",
            function()
                Sonus.Player:AddTrack(url,title,artist)
                Sonus.Player:PlayLastEntry(function()
                    timer.Simple(1,function()
                        Sonus.Player.ActiveStation:SetTime(CurTime() - timeStamp)
                    end)
                end)
                occupied = false
            end,
            "Decline",
            function()
                occupied = false
            end,
            "Decline and block",
            function()
                blocked[from:SteamID()] = true
                occupied = false
            end
        )
    end)
end
