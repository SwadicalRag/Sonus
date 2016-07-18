Sonus.Resolver = {}
Sonus.Resolver.Resolvers = {}

local ResolverMetadataMetatable = {}
ResolverMetadataMetatable.__index = ResolverMetadataMetatable

function ResolverMetadataMetatable:SetName(name)
    self.Name = name
    return self
end

function Sonus.Resolver:AddResolver(id,resolver)
    self.Resolvers[id] = resolver

    resolver.Metadata = setmetatable({},ResolverMetadataMetatable)

    return resolver.Metadata
end

function Sonus.Resolver:ResolveURL(url,callback)
    for k,resolver in pairs(self.Resolvers) do
        Sonus.Log("Trying resolver "..k.."...")
        if resolver:ValidateURL(url) then
            -- print 'a'
            Sonus.Log("Resolver "..k.." works!")
            return resolver:Resolve(url,callback)
        else
            -- print 'b'
        end
    end

    callback {}
end

function Sonus.Player:AutoAddURL(url)
    Sonus.Log("Auto adding url...")
    Sonus.Resolver:ResolveURL(url,function(metadata)
        metadata.url = metadata.url or url
        metadata.title = metadata.title or "Unknown Title"
        metadata.artist = metadata.artist or "Unknown Artist"

        self.Playlist[#self.Playlist + 1] = metadata

        self.event:emit("PlaylistUpdate")
    end)
end

do
    local files,folders = file.Find("sonus/resolvers/*.lua","LUA")
    for i,fileName in ipairs(files) do
        include("sonus/resolvers/"..fileName)
    end
end
