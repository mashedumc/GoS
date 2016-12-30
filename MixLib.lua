--[[ Mix Lib Version 0.099 ]]--
if FileExist(COMMON_PATH.."MixLib.lua") then
  require('MixLib')
else
  PrintChat("MixLib not found. Please wait for download.")
  DownloadFileAsync("https://raw.githubusercontent.com/VTNEETS/GoS/master/MixLib.lua", COMMON_PATH.."MixLib.lua", function() PrintChat("Downloaded MixLib. Please 2x F6!") end) return
end 
local MixLibVersion = 0.099
local Reback = {_G.AttackUnit, _G.MoveToXYZ, _G.CastSkillShot, _G.CastSkillShot2, _G.CastSpell, _G.CastTargetSpell}
local QWER, dta = {"_Q", "_W", "_E", "_R"}, {circular = function(unit, data) return GetCircularAOEPrediction(unit, data) end, linear = function(unit, data) return GetLinearAOEPrediction(unit, data) end, cone = function(unit, data) return GetConicAOEPrediction(unit, data) end}
local OW, gw, Check, RIP = mc_cfg_orb.orb:Value(), {"Combo", "Harass", "LaneClear", "LastHit"}, Set {5, 8, 21, 22}, function() end
local attack_check, move_check, fix, Credits = false, false, {["Annie"] = {-7.5, -17}, ["Jhin"]  = {-7, -6}, ["Other"] = {1.5, 0}}, {"Feretorix", "Inspired", "Deftsu", "Platypus", "Icesythe7", "jouzuna", "MeoBeo"}
local fixpos = function(unit) local fx = fix[unit.charName] and fix[unit.charName][1] or fix["Other"][1] local fy = fix[unit.charName] and fix[unit.charName][2] or fix["Other"][2] return { x = fx, y = fy } end
local hpbar = function(unit) return { x = unit.hpBarPos.x + fixpos(unit).x, y = unit.hpBarPos.y + fixpos(unit).y } end
local hpP = function(unit) return (unit.health + unit.shieldAD)*103/(unit.maxHealth + unit.shieldAD) end
local dmgP = function(dmg, unit) return dmg*103/(unit.maxHealth + unit.shieldAD) end
local min, max, saveColor = math.min, math.max, {};
local colors = {{255, 0, 0}, {255, 128, 0}, {255, 255, 0}, {128, 255, 0}, {0, 255, 0}, {0, 255, 128}, {0, 255, 255}, {0, 128, 255}, {0, 0, 255}, {128, 0, 255}, {255, 0, 255}, {255, 255, 255}}
colors[0] = {0, 0, 0}
local Mix_Print = function(text) PrintChat(string.format("<font color=\"#00B359\"><b>[Mix Lib]:</b></font><font color=\"#FFFFFF\"> %s</font>", tostring(text))) end

do
	local FilesCheck = {
		[1] = {
			"ChallengerCommon.lua",
			"GPrediction.lua",
			"Item-Pi-brary.lua",
			"Analytics.lua",
			"Krystralib.lua",
			"ChallengerDLL.dll"
		},

		[2] = {
			"https://raw.githubusercontent.com/D3ftsu/GoS/master/Common/ChallengerCommon.lua",
			"https://raw.githubusercontent.com/KeVuong/GoS/master/Common/GPrediction.lua",
			"https://raw.githubusercontent.com/DefinitelyRiot/PlatyGOS/master/Common/Item-Pi-brary.lua",
			"https://raw.githubusercontent.com/LoggeL/GoS/master/Analytics.lua",
			"https://raw.githubusercontent.com/Lonsemaria/Gos/master/Common/Krystralib.lua",
			"https://raw.githubusercontent.com/D3ftsu/GoS/master/Common/ChallengerDLL.dll"
		}
	}
	local c, t, fp = 0, {}, function(n) local s = n == 1 and "" or "s" Mix_Print(n.." file"..s.." need to be download. Please wait...") end
    
	for i = 1, 6 do
		if not FileExist(COMMON_PATH..FilesCheck[1][i]) then
			c = c + 1
			t[c] = i
		end
	end
	if c > 0 then
		fp(c)
		local ps = function(n) Mix_Print("("..n.."/"..c..") "..FilesCheck[1][t[n]]..". Don't Press F6!") end
		local download = function(n) DownloadFileAsync(FilesCheck[2][t[n]], COMMON_PATH..FilesCheck[1][t[n]], function() ps(n) check(n+1) end) end
		check = function(n) if n > c then Mix_Print("All file need have been downloaded. Please x2F6!") return end DelayAction(function() download(n) end, 1) end
		DelayAction(function() download(1) end, 1)
	end
end

OnUpdateBuff(function(unit, buff)
	if unit == myHero then
		if Check[buff.Type] then _G.AttackUnit, _G.MoveToXYZ, _G.CastSkillShot, _G.CastSkillShot2, _G.CastSpell, _G.CastTargetSpell = RIP, RIP, RIP, RIP, RIP, RIP end
		if buff.Name:lower() == "xeratharcanopulsechargeup" then _G.AttackUnit = RIP end
	end
end)

OnRemoveBuff(function(unit, buff)
	if unit == myHero then
		if Check[buff.Type] then _G.AttackUnit, _G.MoveToXYZ, _G.CastSkillShot, _G.CastSkillShot2, _G.CastSpell, _G.CastTargetSpell = Reback[1], Reback[2], Reback[3], Reback[4], Reback[5], Reback[6] end
		if buff.Name:lower() == "xeratharcanopulsechargeup" then _G.AttackUnit = Reback[1] end
	end
end)
----------------------------[[ { -o- } ]]----------------------------

class "MixLib"
function MixLib:__init()
	self.OW = (OW == 2 and _G.IOW_Loaded) and "IOW" or (OW == 3 and _G.DAC_Loaded) and "DAC" or (OW == 4 and _G.PW_Loaded) and "PW" or (OW == 5 and _G.GoSWalkLoaded) and "GoSWalk" or (OW == 6 and _G.AutoCarry_Loaded) and "DACR" or _G.SLW and "SLW" or "Disabled"
end

function MixLib:PrintCurrOW()
	Mix_Print("Current Orbwalker: "..self.OW)
end

function MixLib:Mode()
	if self.OW == "GoSWalk" and gw[GoSWalk.CurrentMode+1] then return gw[GoSWalk.CurrentMode+1] end
	if self.OW ~= "Disabled" then return _G[self.OW]:Mode() end
		return ""
end

function MixLib:ResetAA()
	if self.OW == "Disabled" then return end
	if self.OW == "GoSWalk" then
		GoSWalk:ResetAttack()
	else
		_G[self.OW]:ResetAA()
	end
end

function MixLib:BlockOrb(boolean)
	self:BlockAttack(boolean)
	self:BlockMovement(boolean)
end

function MixLib:BlockAttack(boolean)
	if attack_check == boolean or self.OW == "Disabled" then return end
	attack_check = boolean
	boolean = not boolean
	if self.OW == "GoSWalk" then
		GoSWalk:EnableAttack(boolean)
	else
		_G[self.OW].attacksEnabled = boolean
	end
end

function MixLib:BlockMovement(boolean)
	if move_check == boolean or self.OW == "Disabled" then return end
	move_check = boolean
	boolean = not boolean
	if self.OW == "GoSWalk" then
		GoSWalk:EnableMovement(boolean)
	else
		_G[self.OW].movementEnabled = boolean
	end
	BlockF7OrbWalk(true)
	BlockF7Dodge(true)
end

function MixLib:HealthPredict(unit, time, hpname) -- time[ms] | name["OW", "OP", "GoS"]
	if hpname == "OP" then
		return GetHealthPrediction(unit, time + GetLatency()*0.5)
	end
	if hpname == "OW" then
		if self.OW == "IOW" then
			return IOW:PredictHealth(unit, time)
		elseif self.OW == "DAC" then
			return DAC:GetPredictedHealth(unit, time*0.001)
		elseif self.OW == "PW" then
			return PW:PredictHealth(unit, time)
		elseif self.OW == "DACR" then
			return DACR:GetHealthPrediction(unit, time*0.001, 0)
		elseif self.OW == "SLW" then
			return SLW:PredictHP(unit, time*0.001 + GetLatency()*0.5)
		end
	end
	return unit.health - GetDamagePrediction(unit, time + GetLatency()*0.5)
end

-- Ignite: "summonerdot"
-- Heal: "summonerheal"
-- Barrier: "summonerbarrier"
-- Cleanse: "summonerboost"
-- Teleport: "summonerteleport"
-- Clarity: "summonermana"
-- Smite: "smite"
-- Flash: "summonerflash"

-- YellowTrinket: "trinkettotem"
-- SightWard: "ghostward"
-- VisionWard: "visionward"
-- BlueTrinket: "trinketorb"

-- Example: local Ignite = Mix:GetSlotByName("summonerdot", 4, 5)

function MixLib:GetSlotByName(NAME, s, e) -- Name, Start, End
	s = s or 0
	e = e or 12
	for i = s, e do
		if myHero:GetSpellData(i).name and myHero:GetSpellData(i).name:lower():find(NAME) then
			return i
		end
	end
		return nil
end

function MixLib:GetCurrentTarget()
	if self.OW == "GoSWalk" then return GoSWalk.CurrentTarget end
	if self.OW ~= "Disabled" then return _G[self.OW]:GetTarget() end
		return nil
end

function MixLib:ForceTarget(target)
	if self.OW == "Disabled" then return end
	if self.OW == "GoSWalk" then
		GoSWalk:ForceTarget(target)
	elseif self.OW ~= "DAC" then
		_G[self.OW].forceTarget = target
	end
end

function MixLib:ForcePos(Pos)
	if self.OW == "Disabled" then return end
	Pos = Pos and Vector(Pos) or nil
	if self.OW == "GoSWalk" then
		GoSWalk:ForceMovePoint(Pos)
	else
		_G[self.OW].forcePos = Pos
	end
end

local lastMove = 0
function MixLib:Move(Pos)
	if lastMove + 0.32 < os.clock() then
		if GetDistanceSqr(Pos) > 10000 then MoveToXYZ(Pos) end
		lastMove = os.clock()
	end
end

function MixLib:Predicting(Pred, unit, data, IPred)
	if Pred == "OpenPredict" then
		if data.collision then
			local Pred = GetPrediction(unit, data)
			local Hitchance, Pos = Pred.hitChance, Pred.castPos
			if not Pred:mCollision(data.coll) then
				return Hitchance, Pos, true, "OpenPredict" else return Hitchance, Pos, false, "OpenPredict"
			end
		else
			local Pred = dta[data.type](unit, data)
			return Pred.hitChance, Pred.castPos, true, "OpenPredict"
		end
	end
	if Pred == "GPrediction" then
		data.type = data.type == "linear" and "line" or data.type
		local Pred = gPred:GetPrediction(unit, myHero, data, data.aoe, data.collision)
		return Pred.HitChance, Pred.CastPosition, true, "GPrediction"
	end
	if Pred == "IPrediction" then
		local Hitchance, Pos = IPred:Predict(unit)
		return Hitchance, Pos, true, "IPrediction"
	end
	if Pred == "GoSPrediction" then
		local Pred = GetPredictionForPlayer(myHero.pos, unit, unit.ms, data.speed, data.delay*1000, data.range, data.width, data.collision, data.aoe)
		return Pred.HitChance, Pred.PredPos, true, "GoSPrediction"
	end
	return -5, nil, false, ""
end

class "DrawDmgHPBar"
function DrawDmgHPBar:__init(Menu, unit, color, Text)
	self.cfg, self.data, self.value, self.c = Menu, { }, { }, #Text
	self.unit = unit
	self.cfg:Boolean("rt", "Enable on this target?", true)
	self.cfg:Info("rc", "    ------------------------------")
	for i = 1, self.c do
		self.value[i] = { x = 0, y = 0, show = false }
		self.data[i] = { fill = 0, pos = 0, check = false }
		self.cfg:Boolean(i, "Draw "..Text[i].." Dmg?", true)
		self.cfg:ColorPick("color_"..i, "Set "..Text[i].." Color", {color[i]["a"], color[i]["r"], color[i]["g"] ,color[i]["b"]})	
	end
end

function DrawDmgHPBar:CheckValue()
	if not self.cfg.rt:Value() then return end
	for i = 1, self.c do
		if not self.cfg[i]:Value() or not self.data[i].check then
			if i == 1 then
				self.data[i].pos = hpP(self.unit)
			else
				self.data[i].pos = self.data[i-1].pos
			end
			self.value[i].show = false
		end
		if self.data[i].pos < 0 then 
			self.data[i].pos = 0
			if i == 1 then
				self.data[i].fill = hpP(self.unit)
			else
				self.data[i].fill = self.data[i-1].pos
			end
			if i < self.c then self.value[i+1].show = false end
		end
	end
end

function DrawDmgHPBar:SetValue(i, damage, boolean)
	if not self.cfg.rt:Value() then return end
	self.data[i].fill = dmgP(damage, self.unit)
	self.data[i].check = boolean
	self.value[i].show = true
	if not boolean or not self.cfg[i]:Value() then return end
	if i == 1 then
		self.data[i].pos = hpP(self.unit) - self.data[i].fill
	else
		self.data[i].pos = self.data[i - 1].pos - self.data[i].fill
	end
end

function DrawDmgHPBar:UpdatePos()
	for i = 1, self.c do
		self.value[i].x = hpbar(self.unit).x + self.data[i].pos
		self.value[i].y = hpbar(self.unit).y
	end
end

function DrawDmgHPBar:Draw()
	if not self.cfg.rt:Value() then return end
	for i = 1, self.c do
		if self.value[i].show and self.value[i].x > 0 and self.value[i].y > 0 then
			FillRect(self.value[i].x, self.value[i].y, self.data[i].fill, 9, self.cfg["color_"..i]:Value())
		end
	end
end

function DrawDmgHPBar:GetPos(i) -- members: x, y, fill[number], show[true/false]
	return { x = self.value[i].x, y = self.value[i].y, fill = self.data[i].fill, show = self.value[i].show }
end

class "DCircle"
function DCircle:__init(Menu, text, range, color, width)
	self.cfg, self.link, self.range, self.width = Menu, "DCircle_"..text, range, width or 1
	self.color = {color["a"], color["r"], color["g"] ,color["b"]}
	self.cfg:Menu(self.link, text)
	self.cfg[self.link]:Boolean("r1",   "Enable Draw?", true)
	self.cfg[self.link]:Slider("r2",    "Circle Quality (%)", 35, 1, 100, 1)
	self.cfg[self.link]:ColorPick("r3", "Circle Color", self.color)
end

function DCircle:Update(what, value)
	if what == "Range" then self.range = value end
	if what == "Width" then self.width = value end
	if what == "Color" then self.cfg[self.link].r3:Value(value) end
end

function DCircle:Draw(Pos, bonusQuality)
	if self.cfg[self.link].r1:Value() and Pos then
		local bQuality, menuQuality = bonusQuality or 0, self.cfg[self.link].r2:Value()*0.01
		DrawCircle3D(Pos.x, Pos.y, Pos.z, self.range, self.width, self.cfg[self.link].r3:Value(), self.range*(20+bQuality)/100*menuQuality)
	end
end

function UpdateColor(color, step)
	local R, G, B = color[1], color[2], color[3]
	if (R == 255 and B == 0) then
		G = min(255, G + step);
	end
	if (G == 255 and B == 0) then
		R = max(0, R - step);
	end
	if (G == 255 and R == 0) then
		B = min(255, B + step)
	end
	if (B == 255 and R == 0) then
		G = max(0, G - step)
	end
	if (B == 255 and G == 0) then
		R = min(255, R + step)
	end
	if (R == 255 and B == 255) then
		G = min(255, G + step)
	end
	if (R > 0 and R == G and G == B) then
		R = max(0, R - step);
		G = max(0, G - step);
		B = max(0, B - step);
	end
	if (G == 0 and B == 0) then
		R = min(255, R + step)
	end
	return {R, G, B}
end

local function DrawLinesColor(t,w,c,a,size,step) --DrawLines2
	for i = 1, size do
		if t[i].x > 0 and t[i].y > 0 and t[i+1].x > 0 and t[i+1].y > 0 then
			DrawLine(t[i].x, t[i].y, t[i+1].x, t[i+1].y, w, ARGB(a, c[i][1], c[i][2], c[i][3]))
			c[i] = UpdateColor(c[i], step);
		end
	end
end

--Example: DrawCircleColor(myHero.pos, myHero.range + myHero.boundingRadius*2, "test")
function DrawCircleColor(pos, radius, id, step, alphaColor, width, quality) -- DrawCircle3D | id for save current color, step: change faster (1->255)
	quality = quality and 2 * math.pi / quality or 2 * math.pi / (radius / 5)
	local points = {}
	local size = 0
	alphaColor  = alphaColor or 255
	step = step or 10	
	local x, y, z = pos.x, pos.y, pos.z
	if not saveColor[id] then saveColor[id] = {} end
	for theta = 0, 2 * math.pi + quality, quality do
		local c = WorldToScreen(0, Vector(x + radius * math.cos(theta), y, z - radius * math.sin(theta)))
		size = size + 1;
		points[size] = Vector(c.x, c.y)
		if not saveColor[id][size] then saveColor[id][size] = colors[size%13] end
	end
	DrawLinesColor(points, width or 1, saveColor[id], alphaColor, size - 1, step)
end

do
	if not _G.Mix then _G.Mix = MixLib() end
	BlockF7OrbWalk(true)
	BlockF7Dodge(true)
end

OnLoad(function()
	GetWebResultAsync("https://raw.githubusercontent.com/VTNEETS/GoS/master/MixLib.version", function(OnlineVer)
		if tonumber(OnlineVer) > MixLibVersion then
			Mix_Print("New Version found (v"..OnlineVer.."). Please wait...")
			DownloadFileAsync("https://raw.githubusercontent.com/VTNEETS/GoS/master/MixLib.lua", COMMON_PATH.."MixLib.lua", function() Mix_Print("Updated to version "..OnlineVer..". Please F6 x2 to reload.") end)
		else
			Mix_Print("Loaded lastest version (v"..MixLibVersion..")")
			Mix:PrintCurrOW()
		end
	end)
end)
