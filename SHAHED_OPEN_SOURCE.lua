local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer

local ASSET_ID = 120141614672192
local ENGINE_ID = "rbxassetid://86747216998490"
local TARGET_SIZE = 15
local START_SPEED = 60
local SPEED = 198
local MAX_KMH = 200
local ACCEL_TIME = 50
local STOP_SMOOTH = 0.45
local STEER_SMOOTH = 4
local FORWARD_DEADZONE = 0.2
local PLAYER_HIT_RADIUS = 4
local MODEL_YAW = 180
local TURN_TIME = 0.8
local MAX_BANK = 40
local GRACE_TIME = 0.5
local BLACKOUT_TIME = 5
local CRASH_RADIUS = 2
local FADE_IN_TIME = 3
local ENGINE_VOLUME = 1
local BLAST_RADIUS = 14
local BLAST_FORCE = 90
local MAX_DEBRIS = 60
local MAX_PART_SIZE = 60
local DEBRIS_LIFETIME = 7
local WEAK_POINT = 0.4
local COLLAPSE_MIN_HEIGHT = 12
local MAX_COLLAPSE_PARTS = 300
local COLLAPSE_PUSH = 28
local COLLAPSE_LIFETIME = 20
local EXPLOSION_SOUND = "rbxasset://sounds/impact_explosion_03.mp3"
local SIGNAL_SOUND = "rbxasset://sounds/electronicpingshort.wav"

local function makeGui(name, order)
	local g = Instance.new("ScreenGui")
	g.Name = name
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	if order then g.DisplayOrder = order end
	pcall(function() g.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
	if not g.Parent then g.Parent = player:WaitForChild("PlayerGui") end
	return g
end

local gui = makeGui("ShahedGui")
gui.IgnoreGuiInset = false

local blackGui = makeGui("ShahedBlackout", 2147483646)
blackGui.Enabled = false

local flashGui = makeGui("ShahedFlash", 2147483647)
flashGui.Enabled = false

local black = Instance.new("Frame")
black.Size = UDim2.new(1, 0, 1, 0)
black.BackgroundColor3 = Color3.new(0, 0, 0)
black.BorderSizePixel = 0
black.Active = true
black.ZIndex = 100
black.Parent = blackGui

local noSignal = Instance.new("TextLabel")
noSignal.Size = UDim2.new(1, 0, 0, 60)
noSignal.AnchorPoint = Vector2.new(0.5, 0.5)
noSignal.Position = UDim2.new(0.5, 0, 0.5, 0)
noSignal.BackgroundTransparency = 1
noSignal.Text = "NO SIGNAL..."
noSignal.TextColor3 = Color3.new(1, 1, 1)
noSignal.Font = Enum.Font.Code
noSignal.TextSize = 40
noSignal.ZIndex = 101
noSignal.Parent = black

local flash = Instance.new("Frame")
flash.Size = UDim2.new(1, 0, 1, 0)
flash.BackgroundColor3 = Color3.new(1, 1, 1)
flash.BorderSizePixel = 0
flash.ZIndex = 200
flash.Parent = flashGui

local shock = Instance.new("Frame")
shock.AnchorPoint = Vector2.new(0.5, 0.5)
shock.Position = UDim2.new(0.5, 0, 0.5, 0)
shock.Size = UDim2.new(0, 0, 0, 0)
shock.BackgroundTransparency = 1
shock.ZIndex = 201
shock.Parent = flashGui
Instance.new("UICorner", shock).CornerRadius = UDim.new(1, 0)
local shockStroke = Instance.new("UIStroke", shock)
shockStroke.Color = Color3.fromRGB(255, 150, 40)
shockStroke.Thickness = 14

local explosionSound = Instance.new("Sound")
explosionSound.SoundId = EXPLOSION_SOUND
explosionSound.Volume = 2
explosionSound.Parent = SoundService

local signalSound = Instance.new("Sound")
signalSound.SoundId = SIGNAL_SOUND
signalSound.Volume = 1.5
signalSound.Looped = true
signalSound.PlaybackSpeed = 0.5
signalSound.Parent = SoundService

local engineSound = Instance.new("Sound")
engineSound.SoundId = ENGINE_ID
engineSound.Volume = 0
engineSound.Looped = true
engineSound.Parent = SoundService

local engineTween

local function startEngine()
	if engineTween then engineTween:Cancel() end
	engineSound.Volume = 0
	engineSound.TimePosition = 0
	pcall(function() engineSound:Play() end)
	engineTween = TweenService:Create(engineSound, TweenInfo.new(FADE_IN_TIME, Enum.EasingStyle.Sine), {Volume = ENGINE_VOLUME})
	engineTween:Play()
end

local function stopEngine(fade)
	if engineTween then engineTween:Cancel() end
	if fade then
		engineTween = TweenService:Create(engineSound, TweenInfo.new(1.5, Enum.EasingStyle.Sine), {Volume = 0})
		engineTween:Play()
		task.delay(1.6, function()
			if engineSound.Volume <= 0.01 then pcall(function() engineSound:Stop() end) end
		end)
	else
		engineSound.Volume = 0
		pcall(function() engineSound:Stop() end)
	end
end

local function playFlash()
	flashGui.Enabled = true
	flash.BackgroundColor3 = Color3.new(1, 1, 1)
	flash.BackgroundTransparency = 0
	shock.Size = UDim2.new(0, 0, 0, 0)
	shockStroke.Transparency = 0
	TweenService:Create(flash, TweenInfo.new(0.9), {
		BackgroundTransparency = 1,
		BackgroundColor3 = Color3.fromRGB(255, 140, 30),
	}):Play()
	TweenService:Create(shock, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 3000, 0, 3000),
	}):Play()
	TweenService:Create(shockStroke, TweenInfo.new(0.9), {Transparency = 1}):Play()
	task.delay(1, function() flashGui.Enabled = false end)
end

local badgeGui = makeGui("ShahedBadge", 2147483645)

local badge = Instance.new("Frame")
badge.Size = UDim2.new(0, 300, 0, 130)
badge.AnchorPoint = Vector2.new(0, 0.5)
badge.Position = UDim2.new(1, 20, 0.4, 0)
badge.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
badge.BackgroundTransparency = 0.1
badge.BorderSizePixel = 0
badge.Parent = badgeGui
Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 10)
local badgeStroke = Instance.new("UIStroke", badge)
badgeStroke.Color = Color3.fromRGB(150, 150, 150)
badgeStroke.Thickness = 1.5

local badgeIcon = Instance.new("Frame")
badgeIcon.Size = UDim2.new(0, 46, 0, 46)
badgeIcon.Position = UDim2.new(0, 10, 0, 10)
badgeIcon.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
badgeIcon.BorderSizePixel = 0
badgeIcon.Parent = badge
Instance.new("UICorner", badgeIcon).CornerRadius = UDim.new(1, 0)
local iconStroke = Instance.new("UIStroke", badgeIcon)
iconStroke.Color = Color3.fromRGB(220, 220, 220)
iconStroke.Thickness = 2

local badgeStar = Instance.new("TextLabel")
badgeStar.Size = UDim2.new(1, 0, 1, 0)
badgeStar.BackgroundTransparency = 1
badgeStar.Text = "★"
badgeStar.TextColor3 = Color3.fromRGB(235, 235, 235)
badgeStar.Font = Enum.Font.Code
badgeStar.TextSize = 24
badgeStar.Parent = badgeIcon

local badgeTitle = Instance.new("TextLabel")
badgeTitle.Size = UDim2.new(0, 226, 0, 18)
badgeTitle.Position = UDim2.new(0, 66, 0, 6)
badgeTitle.BackgroundTransparency = 1
badgeTitle.Text = "Badge Awarded"
badgeTitle.TextColor3 = Color3.new(1, 1, 1)
badgeTitle.TextXAlignment = Enum.TextXAlignment.Left
badgeTitle.Font = Enum.Font.Code
badgeTitle.TextSize = 15
badgeTitle.Parent = badge

local badgeText = Instance.new("TextLabel")
badgeText.Size = UDim2.new(0, 226, 0, 100)
badgeText.Position = UDim2.new(0, 66, 0, 26)
badgeText.BackgroundTransparency = 1
badgeText.Text = "Привет пока шахед делает людей невидимыми и без колизии когда в них врезаешься в будущем зделаю Fling\n\nМожете врезаться в блоки они разлетятся"
badgeText.TextColor3 = Color3.fromRGB(190, 190, 190)
badgeText.TextXAlignment = Enum.TextXAlignment.Left
badgeText.TextYAlignment = Enum.TextYAlignment.Top
badgeText.TextWrapped = true
badgeText.Font = Enum.Font.Code
badgeText.TextSize = 12
badgeText.Parent = badge

local function showBadge()
	TweenService:Create(badge, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(1, -320, 0.4, 0),
	}):Play()
	task.delay(10, function()
		TweenService:Create(badge, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(1, 20, 0.4, 0),
		}):Play()
	end)
end

task.delay(1, showBadge)

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 230, 0, 105)
frame.Position = UDim2.new(0, 20, 0.5, -50)
frame.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
frame.BackgroundTransparency = 0.3
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local grayGradient = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(225, 225, 225)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(130, 130, 130)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 70, 70)),
})

local stroke = Instance.new("UIStroke", frame)
stroke.Thickness = 1.5
stroke.Color = Color3.new(1, 1, 1)
Instance.new("UIGradient", stroke).Color = grayGradient

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 28)
title.Position = UDim2.new(0, 0, 0, 4)
title.BackgroundTransparency = 1
title.Text = "SHAHED V1"
title.TextColor3 = Color3.fromRGB(230, 230, 230)
title.Font = Enum.Font.Code
title.TextSize = 20
title.Parent = frame

local line = Instance.new("Frame")
line.Size = UDim2.new(0.85, 0, 0, 2)
line.Position = UDim2.new(0.075, 0, 0, 38)
line.BackgroundColor3 = Color3.new(1, 1, 1)
line.BorderSizePixel = 0
line.Parent = frame
Instance.new("UIGradient", line).Color = grayGradient

local button = Instance.new("TextButton")
button.Size = UDim2.new(0.85, 0, 0, 34)
button.Position = UDim2.new(0.075, 0, 1, -44)
button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
button.BackgroundTransparency = 0.3
button.Text = "SHADED"
button.TextColor3 = Color3.new(1, 1, 1)
button.Font = Enum.Font.Code
button.TextSize = 16
button.Parent = frame
Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)
local bStroke = Instance.new("UIStroke", button)
bStroke.Color = Color3.fromRGB(190, 190, 190)
bStroke.Thickness = 1

local dragging, dragStart, startPos
frame.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		dragging, dragStart, startPos = true, i.Position, frame.Position
		i.Changed:Connect(function()
			if i.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)
UserInputService.InputChanged:Connect(function(i)
	if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
		local d = i.Position - dragStart
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
end)

local JOY_R = 65
local joyBase = Instance.new("Frame")
joyBase.Size = UDim2.new(0, JOY_R * 2, 0, JOY_R * 2)
joyBase.Position = UDim2.new(0, 40, 1, -(JOY_R * 2) - 40)
joyBase.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
joyBase.BackgroundTransparency = 0.4
joyBase.Visible = false
joyBase.Active = true
joyBase.Parent = gui
Instance.new("UICorner", joyBase).CornerRadius = UDim.new(1, 0)
local jStroke = Instance.new("UIStroke", joyBase)
jStroke.Color = Color3.fromRGB(190, 190, 190)
jStroke.Thickness = 2

local knob = Instance.new("Frame")
knob.Size = UDim2.new(0, 50, 0, 50)
knob.AnchorPoint = Vector2.new(0.5, 0.5)
knob.Position = UDim2.new(0.5, 0, 0.5, 0)
knob.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
knob.BackgroundTransparency = 0.15
knob.Parent = joyBase
Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
local kStroke = Instance.new("UIStroke", knob)
kStroke.Color = Color3.fromRGB(235, 235, 235)
kStroke.Thickness = 2

local joyVec = Vector2.zero
local joyInput

local function updateJoy(pos)
	local center = joyBase.AbsolutePosition + joyBase.AbsoluteSize / 2
	local d = Vector2.new(pos.X, pos.Y) - center
	if d.Magnitude > JOY_R then d = d.Unit * JOY_R end
	knob.Position = UDim2.new(0.5, d.X, 0.5, d.Y)
	joyVec = Vector2.new(d.X / JOY_R, -d.Y / JOY_R)
end

local function resetJoy()
	joyInput = nil
	joyVec = Vector2.zero
	knob.Position = UDim2.new(0.5, 0, 0.5, 0)
end

joyBase.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
		joyInput = i
		updateJoy(i.Position)
	end
end)
UserInputService.InputChanged:Connect(function(i)
	if i == joyInput then updateJoy(i.Position) end
end)
UserInputService.InputEnded:Connect(function(i)
	if i == joyInput then resetJoy() end
end)

local gauge = Instance.new("Frame")
gauge.AnchorPoint = Vector2.new(0.5, 1)
gauge.Position = UDim2.new(0.5, 0, 1, -8)
gauge.Size = UDim2.new(0, 230, 0, 118)
gauge.BackgroundTransparency = 1
gauge.ClipsDescendants = true
gauge.Visible = false
gauge.Parent = gui

local ring = Instance.new("Frame")
ring.Size = UDim2.new(0, 210, 0, 210)
ring.Position = UDim2.new(0, 10, 0, 13)
ring.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
ring.BackgroundTransparency = 0.35
ring.BorderSizePixel = 0
ring.Parent = gauge
Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
local ringStroke = Instance.new("UIStroke", ring)
ringStroke.Thickness = 2
ringStroke.Color = Color3.new(1, 1, 1)
Instance.new("UIGradient", ringStroke).Color = grayGradient

for i = 0, 8 do
	local holder = Instance.new("Frame")
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.new(0.5, 0, 1, 0)
	holder.Size = UDim2.new(0, 210, 0, 210)
	holder.BackgroundTransparency = 1
	holder.Rotation = -90 + i * 22.5
	holder.Parent = gauge
	local major = (i % 4 == 0)
	local tk = Instance.new("Frame")
	tk.AnchorPoint = Vector2.new(0.5, 0)
	tk.Position = UDim2.new(0.5, 0, 0, 5)
	tk.Size = UDim2.new(0, major and 3 or 2, 0, major and 12 or 7)
	tk.BackgroundColor3 = major and Color3.fromRGB(235, 235, 235) or Color3.fromRGB(140, 140, 140)
	tk.BorderSizePixel = 0
	tk.Parent = holder
end

local needleHolder = Instance.new("Frame")
needleHolder.AnchorPoint = Vector2.new(0.5, 0.5)
needleHolder.Position = UDim2.new(0.5, 0, 1, 0)
needleHolder.Size = UDim2.new(0, 210, 0, 210)
needleHolder.BackgroundTransparency = 1
needleHolder.Rotation = -90
needleHolder.Parent = gauge

local needle = Instance.new("Frame")
needle.AnchorPoint = Vector2.new(0.5, 0)
needle.Position = UDim2.new(0.5, 0, 0, 22)
needle.Size = UDim2.new(0, 3, 0, 83)
needle.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
needle.BorderSizePixel = 0
needle.Parent = needleHolder

local hub = Instance.new("Frame")
hub.AnchorPoint = Vector2.new(0.5, 0.5)
hub.Position = UDim2.new(0.5, 0, 1, 0)
hub.Size = UDim2.new(0, 16, 0, 16)
hub.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
hub.BorderSizePixel = 0
hub.Parent = gauge
Instance.new("UICorner", hub).CornerRadius = UDim.new(1, 0)

local speedLabel = Instance.new("TextLabel")
speedLabel.AnchorPoint = Vector2.new(0.5, 1)
speedLabel.Position = UDim2.new(0.5, 0, 1, -16)
speedLabel.Size = UDim2.new(0, 110, 0, 24)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "0 km/h"
speedLabel.TextColor3 = Color3.fromRGB(235, 235, 235)
speedLabel.Font = Enum.Font.Code
speedLabel.TextSize = 18
speedLabel.Parent = gauge

local minLabel = Instance.new("TextLabel")
minLabel.AnchorPoint = Vector2.new(0, 1)
minLabel.Position = UDim2.new(0, 14, 1, -2)
minLabel.Size = UDim2.new(0, 30, 0, 16)
minLabel.BackgroundTransparency = 1
minLabel.Text = "0"
minLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
minLabel.Font = Enum.Font.Code
minLabel.TextSize = 13
minLabel.Parent = gauge

local maxLabel = Instance.new("TextLabel")
maxLabel.AnchorPoint = Vector2.new(1, 1)
maxLabel.Position = UDim2.new(1, -14, 1, -2)
maxLabel.Size = UDim2.new(0, 36, 0, 16)
maxLabel.BackgroundTransparency = 1
maxLabel.Text = tostring(MAX_KMH)
maxLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
maxLabel.Font = Enum.Font.Code
maxLabel.TextSize = 13
maxLabel.Parent = gauge

local active = false
local returnCFrame
local shahedModel
local hidden, collideBackup = {}, {}
local bv, bg, steppedConn
local onCrash
local ghostedPlayers = {}

local function isCrashPart(p)
	local model = p:FindFirstAncestorOfClass("Model")
	if model and Players:GetPlayerFromCharacter(model) then
		return false
	end
	return p.CanCollide and p.Transparency < 1
end

local function applyGhost(char)
	for _, v in ipairs(char:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Transparency = 1
			v.CanCollide = false
		elseif v:IsA("Decal") or v:IsA("Texture") then
			v.Transparency = 1
		elseif v:IsA("BillboardGui") then
			v.Enabled = false
		end
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
end

local function ghostPlayer(pl)
	if ghostedPlayers[pl] then return end
	ghostedPlayers[pl] = true
	if pl.Character then applyGhost(pl.Character) end
end

local ghostTimer = 0
RunService.Heartbeat:Connect(function(dt)
	ghostTimer = ghostTimer + dt
	if ghostTimer < 0.4 then return end
	ghostTimer = 0
	for pl in pairs(ghostedPlayers) do
		if pl.Parent and pl.Character then
			applyGhost(pl.Character)
		elseif not pl.Parent then
			ghostedPlayers[pl] = nil
		end
	end
end)

local function checkPlayerContact(lastPos, pos)
	local hit = false
	local seg = pos - lastPos
	local segLen2 = seg:Dot(seg)
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl ~= player and not ghostedPlayers[pl] and pl.Character then
			local torso = pl.Character:FindFirstChild("UpperTorso") or pl.Character:FindFirstChild("Torso") or pl.Character:FindFirstChild("HumanoidRootPart")
			if torso then
				local t = 0
				if segLen2 > 0.0001 then
					t = math.clamp((torso.Position - lastPos):Dot(seg) / segLen2, 0, 1)
				end
				local closest = lastPos + seg * t
				if (torso.Position - closest).Magnitude <= PLAYER_HIT_RADIUS then
					ghostPlayer(pl)
					hit = true
				end
			end
		end
	end
	return hit
end

local function sweepHit(char, origin, vec, rp)
	local ex = {char}
	local result = false
	for _ = 1, 5 do
		rp.FilterDescendantsInstances = ex
		local r = workspace:Spherecast(origin, 2, vec, rp)
		if not r then break end
		if isCrashPart(r.Instance) then result = true break end
		table.insert(ex, r.Instance)
	end
	rp.FilterDescendantsInstances = {char}
	return result
end

local function isPlayerPart(p)
	local model = p:FindFirstAncestorOfClass("Model")
	return model and Players:GetPlayerFromCharacter(model) ~= nil
end

local function spawnDebris(p, velocity, burning, life)
	local debris = p:Clone()
	debris:ClearAllChildren()
	debris.Anchored = false
	debris.CanCollide = true
	debris.CanTouch = false
	debris.Massless = false
	debris.Parent = workspace
	debris.AssemblyLinearVelocity = velocity
	debris.AssemblyAngularVelocity = Vector3.new(math.random(-6, 6), math.random(-6, 6), math.random(-6, 6))
	if burning then
		local s = p.Size
		local fire = Instance.new("Fire")
		fire.Heat = 12
		fire.Size = math.clamp(math.max(s.X, s.Y, s.Z) * 0.8, 3, 14)
		fire.Color = Color3.fromRGB(255, 120, 20)
		fire.SecondaryColor = Color3.fromRGB(255, 220, 60)
		fire.Parent = debris
		TweenService:Create(debris, TweenInfo.new(life * 0.6, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, life * 0.4), {
			Color = Color3.fromRGB(25, 20, 20),
		}):Play()
	end
	Debris:AddItem(debris, life)
	p.Transparency = 1
	p.CanCollide = false
end

local function findBuilding(center, char)
	local op = OverlapParams.new()
	op.FilterType = Enum.RaycastFilterType.Exclude
	op.FilterDescendantsInstances = {char}
	local near = workspace:GetPartBoundsInRadius(center, 8, op)
	local best, bestDist
	for _, p in ipairs(near) do
		if p:IsA("BasePart") and not p:IsA("Terrain") and p.Transparency < 1 and not isPlayerPart(p) then
			local d = (p.Position - center).Magnitude
			if not bestDist or d < bestDist then
				best, bestDist = p, d
			end
		end
	end
	if not best then return nil end
	local top = best
	while top.Parent and top.Parent ~= workspace do
		top = top.Parent
	end
	if top:IsA("Model") then return top end
	return nil
end

local function collapseBuilding(model, center)
	local cf, size = model:GetBoundingBox()
	if size.Y < COLLAPSE_MIN_HEIGHT then return false end
	local baseY = cf.Position.Y - size.Y / 2
	local rel = (center.Y - baseY) / size.Y
	if rel > WEAK_POINT then return false end

	local count = 0
	for _, p in ipairs(model:GetDescendants()) do
		if count >= MAX_COLLAPSE_PARTS then break end
		if p:IsA("BasePart") and p.Transparency < 1 then
			count = count + 1
			local away = Vector3.new(p.Position.X - center.X, 0, p.Position.Z - center.Z)
			if away.Magnitude < 0.5 then away = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5) end
			local h = math.clamp((p.Position.Y - baseY) / size.Y, 0, 1)
			local vel = away.Unit * COLLAPSE_PUSH * h * (0.6 + math.random() * 0.6)
			local burning = (p.Position - center).Magnitude <= BLAST_RADIUS
			spawnDebris(p, vel, burning, COLLAPSE_LIFETIME)
		end
	end
	return true
end

local function explodeBlocks(center, char)
	local model = findBuilding(center, char)
	if model then pcall(collapseBuilding, model, center) end

	local op = OverlapParams.new()
	op.FilterType = Enum.RaycastFilterType.Exclude
	op.FilterDescendantsInstances = {char}
	local parts = workspace:GetPartBoundsInRadius(center, BLAST_RADIUS, op)
	local count = 0
	for _, p in ipairs(parts) do
		if count >= MAX_DEBRIS then break end
		if p:IsA("BasePart") and not p:IsA("Terrain") and p.Transparency < 1 and not isPlayerPart(p) then
			local s = p.Size
			if math.max(s.X, s.Y, s.Z) <= MAX_PART_SIZE then
				count = count + 1
				local away = p.Position - center
				if away.Magnitude < 0.1 then away = Vector3.new(0, 1, 0) end
				local dir = (away.Unit + Vector3.new(0, 0.6, 0)).Unit
				spawnDebris(p, dir * BLAST_FORCE * (0.6 + math.random() * 0.8), true, DEBRIS_LIFETIME)
			end
		end
	end
end

local function setControls(enabled)
	pcall(function()
		local controls = require(player.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
		if enabled then controls:Enable() else controls:Disable() end
	end)
end

local function setInvisible(char, state)
	for _, v in ipairs(char:GetDescendants()) do
		if shahedModel and v:IsDescendantOf(shahedModel) then continue end
		if (v:IsA("BasePart") or v:IsA("Decal")) and v.Name ~= "HumanoidRootPart" then
			if state then
				if hidden[v] == nil then hidden[v] = v.Transparency end
				v.Transparency = 1
			elseif hidden[v] ~= nil then
				v.Transparency = hidden[v]
			end
		end
	end
	if not state then table.clear(hidden) end
end

local function startFlight(char, hrp)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then hum.PlatformStand = true end

	bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	bv.Velocity = Vector3.zero
	bv.Parent = hrp

	bg = Instance.new("BodyGyro")
	bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
	bg.P = 20000
	bg.D = 600
	bg.CFrame = hrp.CFrame
	bg.Parent = hrp

	for _, p in ipairs(char:GetDescendants()) do
		if p:IsA("BasePart") and not p:IsDescendantOf(shahedModel) then
			collideBackup[p] = p.CanCollide
		end
	end

	local facing = hrp.CFrame.Rotation
	local roll = 0
	local curSpeed = 0
	local curDir = hrp.CFrame.LookVector
	local startTime = tick()
	local lastPos = hrp.Position

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {char}
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {char}

	steppedConn = RunService.Stepped:Connect(function(_, dt)
		for p in pairs(collideBackup) do
			if p.Parent then p.CanCollide = false end
		end
		local cam = workspace.CurrentCamera
		if not cam or not hrp.Parent then return end

		local look = cam.CFrame.LookVector
		local input = look * joyVec.Y + cam.CFrame.RightVector * joyVec.X
		local pushing = input.Magnitude > 0.05

		if pushing then
			if joyVec.Y > 0 and math.abs(joyVec.X) < FORWARD_DEADZONE then
				curDir = look
			else
				local blend = 1 - math.exp(-dt * STEER_SMOOTH)
				local mixed = curDir:Lerp(input.Unit, blend)
				if mixed.Magnitude > 0.01 then curDir = mixed.Unit end
			end
			if curSpeed < START_SPEED then
				curSpeed = math.min(START_SPEED, curSpeed + 30 * dt)
			else
				curSpeed = math.min(SPEED, curSpeed + ((SPEED - START_SPEED) / ACCEL_TIME) * dt)
			end
		else
			curSpeed = curSpeed * math.exp(-dt * STOP_SMOOTH)
			if curSpeed < 0.5 then curSpeed = 0 end
		end

		bv.Velocity = curDir * curSpeed

		local target = CFrame.lookAt(Vector3.zero, look)
		facing = facing:Lerp(target, 1 - math.exp(-dt * 3 / TURN_TIME))

		local bankInput = math.abs(joyVec.X) < FORWARD_DEADZONE and 0 or joyVec.X
		local targetRoll = -bankInput * math.rad(MAX_BANK)
		roll = roll + (targetRoll - roll) * (1 - math.exp(-dt * 4))
		bg.CFrame = facing * CFrame.Angles(0, 0, roll)

		local ratio = curSpeed / SPEED
		needleHolder.Rotation = -90 + ratio * 180
		speedLabel.Text = math.floor(ratio * MAX_KMH + 0.5) .. " km/h"

		local pos = hrp.Position
		if checkPlayerContact(lastPos, pos) then
			onCrash()
			return
		end

		if curSpeed > 1 and tick() - startTime > GRACE_TIME then
			local hit = false

			local parts = workspace:GetPartBoundsInRadius(pos, CRASH_RADIUS, params)
			for _, p in ipairs(parts) do
				if isCrashPart(p) then hit = true break end
			end

			if not hit then
				hit = sweepHit(char, pos, curDir * (CRASH_RADIUS + curSpeed * dt * 3), rayParams)
			end

			if not hit then
				local travel = pos - lastPos
				if travel.Magnitude > 0.01 then
					hit = sweepHit(char, lastPos, travel + travel.Unit * CRASH_RADIUS, rayParams)
				end
			end

			if hit then onCrash() end
		end
		lastPos = hrp.Position
	end)
end

local function stopFlight(char)
	if steppedConn then steppedConn:Disconnect() steppedConn = nil end
	if bv then bv:Destroy() bv = nil end
	if bg then bg:Destroy() bg = nil end
	for p, c in pairs(collideBackup) do
		if p.Parent then p.CanCollide = c end
	end
	table.clear(collideBackup)
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then hum.PlatformStand = false end
end

local function equipShahed()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	returnCFrame = hrp.CFrame

	local ok, result = pcall(function() return game:GetObjects("rbxassetid://" .. ASSET_ID) end)
	if not ok or not result or not result[1] then
		warn("Не удалось загрузить модель")
		return false
	end

	local obj = result[1]
	if not obj:IsA("Model") then
		local m = Instance.new("Model")
		obj.Parent = m
		obj = m
	end
	shahedModel = obj
	shahedModel.Name = "ShahedModel"
	shahedModel.Parent = char

	local size = shahedModel:GetExtentsSize()
	local biggest = math.max(size.X, size.Y, size.Z)
	if biggest > 0 then shahedModel:ScaleTo(TARGET_SIZE / biggest) end

	shahedModel:PivotTo(hrp.CFrame * CFrame.Angles(0, math.rad(MODEL_YAW), 0))

	for _, v in ipairs(shahedModel:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Anchored = false
			v.CanCollide = false
			v.CanTouch = false
			v.CanQuery = false
			v.Massless = true
			local w = Instance.new("WeldConstraint")
			w.Part0 = hrp
			w.Part1 = v
			w.Parent = v
		end
	end

	setInvisible(char, true)
	startFlight(char, hrp)
	return true
end

local function removeShahed()
	local char = player.Character
	stopFlight(char)
	if shahedModel then shahedModel:Destroy() shahedModel = nil end
	if char then setInvisible(char, false) end
end

local function turnOff(crash)
	removeShahed()
	stopEngine(not crash)
	active = false
	button.Text = "SHADED"
	joyBase.Visible = false
	gauge.Visible = false
	needleHolder.Rotation = -90
	speedLabel.Text = "0 km/h"
	resetJoy()
	setControls(true)
end

local crashing = false
onCrash = function()
	if crashing or not active then return end
	crashing = true
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local impact = hrp and hrp.Position
	blackGui.Enabled = true
	playFlash()
	pcall(function() explosionSound:Play() end)
	pcall(function() signalSound:Play() end)
	if impact then pcall(explodeBlocks, impact, char) end
	turnOff(true)
	local newHrp = char and char:FindFirstChild("HumanoidRootPart")
	if newHrp and returnCFrame then
		newHrp.AssemblyLinearVelocity = Vector3.zero
		newHrp.CFrame = returnCFrame
	end
	task.delay(BLACKOUT_TIME, function()
		blackGui.Enabled = false
		pcall(function() signalSound:Stop() end)
		crashing = false
	end)
end

button.MouseButton1Click:Connect(function()
	if crashing then return end
	if not active then
		if equipShahed() then
			active = true
			button.Text = "SHADED: ON"
			joyBase.Visible = true
			gauge.Visible = true
			setControls(false)
			startEngine()
		end
	else
		turnOff(false)
	end
end)

player.CharacterAdded:Connect(function()
	if steppedConn then steppedConn:Disconnect() steppedConn = nil end
	active = false
	shahedModel = nil
	bv, bg = nil, nil
	table.clear(hidden)
	table.clear(collideBackup)
	stopEngine(false)
	button.Text = "SHADED"
	joyBase.Visible = false
	gauge.Visible = false
	resetJoy()
	setControls(true)
end)