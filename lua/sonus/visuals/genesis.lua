VIS.items = {}
VIS.itemSize = 20
VIS.itemAccel = 0

VIS.bars = 320
VIS.memeFactor = 0
VIS.memeCrement = 41 -- prime
VIS.actualMemeFactor = 0

VIS.rectAng = 0

local canShake = CreateClientConVar("sonus_genesis_shake",1,true,false,"Enable screenshakes")
local shakeMagnitude = CreateClientConVar("sonus_genesis_shake_magnitude",10,true,false,"Screenshake magnitude")
local shakeSensitivity = CreateClientConVar("sonus_genesis_shake_sensitivity",10,true,false,"Screenshake magnitude")
local rotatyBox = CreateClientConVar("sonus_genesis_rotatybox",1,true,false,"Enable rotating box")

function VIS:AddItem()
    local right = math.random(0,1) == 0
    self.items[#self.items+1] = {
        x = right and ScrW() or -self.itemSize,
        -- y = math.random(ScrH()/4,ScrH()),
        y = math.sin(CurTime()) * ScrH()*3/8 + ScrH() * 5/8,
        vel_x = (right and -1 or 1) * math.random(50,350),
        vel_y = -math.random(0,300),
        col = HSVToColor((self.audioData.TotalEnergy*720+60) % 360,0.75,1)
    }

    self.items[#self.items].col.a = self.audioData.TotalEnergy * 120 + 50
end

function VIS:DrawItems()
    local items = {}
    for i,item in ipairs(self.items) do
        surface.SetDrawColor(item.col)
        surface.DrawRect(item.x,item.y,self.itemSize,self.itemSize)

        item.x = item.x + (item.vel_x * (RealFrameTime() + self.itemAccel))
        item.y = item.y + item.vel_y * (RealFrameTime() + self.itemAccel)

        item.vel_y = item.vel_y + 250 * (RealFrameTime() + self.itemAccel) + self.audioData.TotalEnergy * 0.001

        if (item.x >= -self.itemSize) and (item.x <= ScrW()) and (item.y >= -self.itemSize) and (item.y <= ScrH()) then
            items[#items+1] = item
        end
    end

    self.items = items
end

VIS.event:on("Bass.peak",function(...)
    for i=1,10 do
        VIS:AddItem()
    end
    VIS.itemAccel = VIS.itemAccel + 0.1
    VIS.memeFactor = VIS.memeFactor + VIS.memeCrement
end)

VIS.event:on("Peak",function(...)
    VIS.memeFactor = VIS.memeFactor + VIS.memeCrement
end)

function draw.RotatedBox(x,y,w,h,ang,color)
    draw.NoTexture()
	surface.SetDrawColor(color or Color(255,255,255))
	surface.DrawTexturedRectRotated(x,y,w,h,ang)
end

function VIS:DrawBars(amount,start)
    local lp = Sonus.lib.LowPassFilter(self.audioData.EnergiesArray,self.bars,amount,start)
    Sonus.lib.Smooth(lp,5)

    local width = math.floor(ScrW()/self.bars)

    for i,energy in ipairs(lp) do
        local height = math.floor(energy^0.5 * 10^3.75)
        surface.DrawRect(ScrW() * 0.5 + (i - self.bars/2 - 1) * width,ScrH() - height,width,height)
    end
end

function VIS:GetPowerColor(a,offset)
    local powerColor = HSVToColor((self.actualMemeFactor + offset) % 360,1,1)
    powerColor.a = a

    return powerColor
end

VIS.event:on("Draw",function()
    VIS.itemAccel = VIS.itemAccel - VIS.itemAccel / 8
    VIS:DrawItems()

    VIS.actualMemeFactor = 0.2 * VIS.memeFactor + 0.8 * VIS.actualMemeFactor -- exponential smoothing

    VIS.rectAng = VIS.rectAng + VIS.audioData.TotalEnergy^2 * 50
    if rotatyBox:GetBool() then
        draw.RotatedBox(ScrW()/2,ScrH()/4,100,100,VIS.rectAng,VIS:GetPowerColor(150,0))

        draw.SimpleText(string.format("%.3f W/m^2",VIS.audioData.TotalEnergy),"DermaDefault",ScrW()/2,ScrH()/4,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    end

    if IsValid(VIS.Channel) then
        local elapsed = VIS.Channel:GetTime()
        local frac = (elapsed / VIS.Channel:GetLength())

        surface.SetDrawColor(10,10,10,150)
        surface.DrawRect(0,0,ScrW(),8)
        surface.SetDrawColor(250,250,250,150)
        surface.DrawRect(0,0,ScrW() * frac,8)

        if elapsed <= 10 then
            if VIS.Metadata and VIS.Metadata.Title then
                draw.SimpleText(VIS.Metadata.Title,"DermaLarge",elapsed/7.5*ScrW(),ScrH()/4 + 10,Color(255,255,255,150),TEXT_ALIGN_RIGHT,TEXT_ALIGN_CENTER)
                draw.SimpleText(VIS.Metadata.Artist,"DermaLarge",(1-elapsed/7.5)*ScrW(),ScrH()*3/4 + 10,Color(255,255,255,150),TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
            end
        end
    end

    surface.SetDrawColor(VIS:GetPowerColor(100,45))
    VIS:DrawBars(#VIS.audioData.EnergiesArray/4,#VIS.audioData.EnergiesArray*3/4+1)

    surface.SetDrawColor(VIS:GetPowerColor(150,30))
    VIS:DrawBars(#VIS.audioData.EnergiesArray/4,#VIS.audioData.EnergiesArray/2+1)

    surface.SetDrawColor(VIS:GetPowerColor(150,15))
    VIS:DrawBars(#VIS.audioData.EnergiesArray/4,#VIS.audioData.EnergiesArray/4+1)

    surface.SetDrawColor(VIS:GetPowerColor(150,0))
    VIS:DrawBars(#VIS.audioData.EnergiesArray/4,1)

    if canShake:GetBool() and (VIS.audioData.TotalEnergy^2*50) > shakeSensitivity:GetFloat() then
        util.ScreenShake(LocalPlayer():GetPos(),5,1,0.1,shakeMagnitude:GetFloat())
    end
end)
