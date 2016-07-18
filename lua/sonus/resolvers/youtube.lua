local Resolver = {}

Resolver.URLs = {
    "^https?://[A-Za-z0-9%.%-]*%.?youtu%.be/([A-Za-z0-9_%-]+)",
    "^https?://[A-Za-z0-9%.%-]*%.?youtube%.com/watch%?.*v=([A-Za-z0-9_%-]+)",
    "^https?://[A-Za-z0-9%.%-]*%.?youtube%.com/v/([A-Za-z0-9_%-]+)",
    "^[A-Za-z0-9%.%-]*%.?youtu%.be/([A-Za-z0-9_%-]+)",
    "^[A-Za-z0-9%.%-]*%.?youtube%.com/watch%?.*v=([A-Za-z0-9_%-]+)",
    "^[A-Za-z0-9%.%-]*%.?youtube%.com/v/([A-Za-z0-9_%-]+)"
}

function Resolver:ValidateURL(url)
    for i,templateURL in ipairs(self.URLs) do
        if url:match(templateURL) then
            return url:match(templateURL)
        end
    end

    return false
end

-- https://www.youtube.com/watch?v=dQw4w9WgXcQ
function Resolver:Resolve(url,callback)
    http.Fetch(string.format(Sonus.Config.SwadYTURL,self:ValidateURL(url)),function(data)
        local metadata = util.JSONToTable(data)
        -- metadata.url = string.format(Sonus.Config.SwadYTStreamURL,self:ValidateURL(url))
        callback(metadata)
    end,Sonus.Error)
end

Sonus.Resolver:AddResolver("youtube",Resolver)
    :SetName("YouTube")
