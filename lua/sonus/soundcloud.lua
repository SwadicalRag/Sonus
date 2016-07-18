Sonus.Soundcloud = {}

local function encode(str)
    str = string.gsub(str,"([^%w %-%_%.%~])",function(c)
        return string.format ("%%%02X", string.byte(c))
    end)
    str = string.gsub (str," ","+")

    return str
end

local function request(url,params,callback)
    if url:sub(-1,-1) ~= "?" then url = url.."?" end
    for k,v in pairs(params) do
        url = url..encode(tostring(k)).."="..encode(tostring(v)).."&"
    end
    url = url:sub(1,-2)

    http.Fetch(url,callback)
end

local soundcloudURLs = {
    "^https?://www.soundcloud.com/([A-Za-z0-9_%-]+/[A-Za-z0-9_%-]+)/?",
    "^https?://soundcloud.com/([A-Za-z0-9_%-]+/[A-Za-z0-9_%-]+)/?",
    "^www.soundcloud.com/([A-Za-z0-9_%-]+/[A-Za-z0-9_%-]+)/?",
    "^soundcloud.com/([A-Za-z0-9_%-]+/[A-Za-z0-9_%-]+)/?"
}

function Sonus.Soundcloud.SearchTracks(query,callback)
    request("https://api.soundcloud.com/tracks.json",{
        client_id = Sonus.Config.soundcloudKey,
        q = query
    },function(data)
        local data = util.JSONToTable(data)
        callback(data)
    end)
end

function Sonus.Soundcloud.GetMetadataInternal(id,callback)
    request("https://api.soundcloud.com/resolve.json",{
        client_id = Sonus.Config.soundcloudKey,
        url = "https://soundcloud.com/"..id
    },function(data)
        local data = util.JSONToTable(data)
        callback(data)
    end)
end

function Sonus.Soundcloud.AppendClientID(str)
    return str.."?client_id="..encode(Sonus.Config.soundcloudKey)
end

function Sonus.Soundcloud.GetMetadata(soundcloudURL,callback)
    for _,pattern in ipairs(soundcloudURLs) do
        if soundcloudURL:match(pattern) then
            Sonus.Soundcloud.GetMetadataInternal(soundcloudURL:match(pattern),callback)
            return true
        end
    end

    return false
end
