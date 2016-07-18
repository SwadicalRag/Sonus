local Resolver = {}

Resolver.URLs = {
    "^https?://www.soundcloud.com/([A-Za-z0-9_%-]+/[A-Za-z0-9_%-]+)/?",
    "^https?://soundcloud.com/([A-Za-z0-9_%-]+/[A-Za-z0-9_%-]+)/?",
    "^www.soundcloud.com/([A-Za-z0-9_%-]+/[A-Za-z0-9_%-]+)/?",
    "^soundcloud.com/([A-Za-z0-9_%-]+/[A-Za-z0-9_%-]+)/?"
}

function Resolver:ValidateURL(url)
    for i,templateURL in ipairs(self.URLs) do
        print(url,templateURL,url:match(templateURL))
        if url:match(templateURL) then
            return true
        end
    end

    return false
end

function Resolver:Resolve(url,callback)
    Sonus.Soundcloud.GetMetadata(url,function(rawMetadata)
        callback {
            url = Sonus.Soundcloud.AppendClientID(rawMetadata.stream_url),
            artist = rawMetadata.user.username,
            title = rawMetadata.title,
            raw = rawMetadata
        }
    end,Sonus.Error)
end

Sonus.Resolver:AddResolver("soundcloud",Resolver)
    :SetName("SoundCloud")
