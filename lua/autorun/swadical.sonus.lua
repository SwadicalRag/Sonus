Sonus = {}

local load_sv = include

local function load_sh(...)
    AddCSLuaFile(...)
    return include(...)
end

local function load_cl(...)
    if SERVER then
        AddCSLuaFile(...)
    else
        return include(...)
    end
end

Sonus.lib = {}

load_sh("sonus/config.lua")

load_cl("sonus/processing/peak_detector.lua")
load_cl("sonus/processing/circular_buffer.lua")
load_cl("sonus/processing/eventemitter.lua")
load_cl("sonus/processing/frequencies.lua")
load_cl("sonus/processing/filters.lua")

load_cl("sonus/processing/channel_processor.lua")

load_cl("sonus/soundcloud.lua")

load_cl("sonus/player/audio.lua")
load_cl("sonus/player/visuals.lua")

hook.Add("InitPostEntity","Sonus",function()
    load_cl("sonus/player/ui.lua")
end)

load_sh("sonus/sh_networking.lua")

if SERVER then
    local files,_ = file.Find("lua/sonus/visuals/*.lua","GAME")
    for k,v in pairs(files) do
        AddCSLuaFile("sonus/visuals/"..v)
    end
end
