--[[ Mix Lib Version 0.09 ]]--
local MixLibVersion = 0.09
local Reback = {_G.AttackUnit, _G.MoveToXYZ, _G.CastSkillShot, _G.CastSkillShot2, _G.CastSpell, _G.CastTargetSpell}
local QWER, dta = {"_Q", "_W", "_E", "_R"}, {circular = function(unit, data) return GetCircularAOEPrediction(unit, data) end, linear = function(unit, data) return GetLinearAOEPrediction(unit, data) end, cone = function(unit, data) return GetConicAOEPrediction(unit, data) end}
local Prediction, OW, gw, Check, RIP = {"OpenPredict", "GPrediction", "GoSPrediction", "IPrediction"}, mc_cfg_orb.orb:Value(), {"Combo", "Harass", "LaneClear", "LastHit"}, Set {5, 8, 21, 22}, function() end
local Block = function(unit, buff) if unit == myHero then if Check[buff.Type] then _G.AttackUnit, _G.MoveToXYZ, _G.CastSkillShot, _G.CastSkillShot2, _G.CastSpell, _G.CastTargetSpell = RIP, RIP, RIP, RIP, RIP, RIP end if buff.Name:lower() == "xeratharcanopulsechargeup" then _G.AttackUnit = RIP end end end
local Allow = function(unit, buff) if unit == myHero then if Check[buff.Type] then _G.AttackUnit, _G.MoveToXYZ, _G.CastSkillShot, _G.CastSkillShot2, _G.CastSpell, _G.CastTargetSpell = Reback[1], Reback[2], Reback[3], Reback[4], Reback[5], Reback[6] end if buff.Name:lower() == "xeratharcanopulsechargeup" then _G.AttackUnit = Reback[1] end end end
local attack_check, move_check, fix, Credits = false, false, {["Annie"] = {-7.5, -17}, ["Jhin"]  = {-7, -6}, ["Other"] = {1.5, 0}}, {"Feretorix", "Inspired", "Deftsu", "Platypus", "Icesythe7", "jouzuna", "MeoBeo"}
local fixpos = function(unit) local fx = fix[unit.charName] and fix[unit.charName][1] or fix["Other"][1] local fy = fix[unit.charName] and fix[unit.charName][2] or fix["Other"][2] return { x = fx, y = fy } end
local hpbar = function(unit) return { x = unit.hpBarPos.x + fixpos(unit).x, y = unit.hpBarPos.y + fixpos(unit).y } end
local hpP = function(unit) return (unit.health + unit.shieldAD)*103/(unit.maxHealth + unit.shieldAD) end
local dmgP = function(dmg, unit) return dmg*103/(unit.maxHealth + unit.shieldAD) end
local Mix_Print = function(text) PrintChat(string.format("<font color=\"#00B359\"><b>[Mix Lib]:</b></font><font color=\"#FFFFFF\"> %s</font>",tostring(text))) end
local Mix_ChangePred = function(id) Mix_Print("Prediction was changed to "..Prediction[id]..". Press x2F6 to aplly!") end

do
    local FilesCheck = {
        {"ChallengerCommon.lua", "GPrediction.lua", "Item-Pi-brary.lua", "Analytics.lua", "Krystralib.lua", "ChallengerDLL.dll"},
      {
        "https://raw.githubusercontent.com/D3ftsu/GoS/master/Common/ChallengerCommon.lua",
        "https://raw.githubusercontent.com/KeVuong/GoS/master/Common/GPrediction.lua",
        "https://raw.githubusercontent.com/DefinitelyRiot/PlatyGOS/master/Common/Item-Pi-brary.lua",
        "https://raw.githubusercontent.com/LoggeL/GoS/master/Analytics.lua",
        "https://raw.githubusercontent.com/Lonsemaria/Gos/master/Common/Krystralib.lua",
        "https://github.com/D3ftsu/GoS/raw/master/ChallengerDLL.dll"
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
      check = function(n) if n > c then Mix_Print("All file need have been downloaded. Please x2F6!") return end DelayAction(function() download(n) end, 1.5) end
      DelayAction(function() download(1) end, 1.5)
    end
end

Callback.Add("UpdateBuff", Block)
Callback.Add("RemoveBuff", Allow)
----------------------------[[ { -o- } ]]----------------------------
class "MixLib"
function MixLib:__init()
    self.Menu = MenuConfig("MixLib", "MixLib (Library Collection)")
    self.Menu:DropDown("predict", "Choose Prediction:", 1, Prediction, function(PredId) Mix_ChangePred(PredId) end)
	self.Menu:Menu("ifo", "Some Information")
    self.Menu.ifo:Info("info1", "Your LoL Version: "..GetGameVersion():sub(1, 13))
    self.Menu.ifo:Info("info2", "Lib Version: "..MixLibVersion)
   for i = 1, 7 do
    self.Menu.ifo:Info("credit_"..i, "Credit --> "..Credits[i])
   end
    Callback.Add("Load", function() self:CheckOtherScript() end)
end

function MixLib:CheckOtherScript()
    self.Predict = Prediction[self.Menu.predict:Value()] or nil
    self.OW = (OW == 2 and _G.IOW_Loaded) and "IOW" or (OW == 3 and _G.DAC_Loaded) and "DAC" or (OW == 4 and _G.PW_Loaded == true) and "PW" or (OW == 5 and _G.GoSWalkLoaded) and "GoSWalk" or (OW == 6 and _G.AutoCarry_Loaded) and "DACR" or _G.SLW and "SLW" or "Disabled"
end

function MixLib:PrintCurrPredOW()
    Mix_Print("Current Pred: "..self.Predict.." | Orbwalker: "..self.OW)
end

function MixLib:LoadPred()
    if self.Predict == "OpenPredict" and FileExist(COMMON_PATH.."OpenPredict.lua") and not _G.OpenPredict_Version then require('OpenPredict') end
    if self.Predict == "GPrediction" and FileExist(COMMON_PATH.."GPrediction.lua") and not _G.gPred then require('GPrediction') end
    if self.Predict == "IPrediction" and FileExist(COMMON_PATH.."IPrediction.lua") and not _G.IPrediction then require('IPrediction') end
end

function MixLib:Mode()
    if self.OW == "IOW" and IOW:Mode() then
      return IOW:Mode()
    elseif self.OW == "DAC" and DAC:Mode() then
      return DAC:Mode()
    elseif self.OW == "PW" and PW:Mode() then
      return PW:Mode()
    elseif self.OW == "DACR" and DACR:Mode() then
      return DACR:Mode()
    elseif self.OW == "GoSWalk" and GoSWalk.CurrentMode and gw[GoSWalk.CurrentMode+1] then
      return gw[GoSWalk.CurrentMode+1]
    elseif self.OW == "SLW" and SLW:Mode() then
      return SLW:Mode()
    end
        return ""
end

function MixLib:ResetAA()
    if self.OW == "IOW" then IOW:ResetAA()
    elseif self.OW == "DAC" then DAC:ResetAA()
    elseif self.OW == "PW" then PW:ResetAA()
    elseif self.OW == "GoSWalk" then GoSWalk:ResetAttack()
    elseif self.OW == "DACR" then DACR:ResetAA()
    elseif self.OW == "SLW" then SLW:ResetAA()
    end
end

function MixLib:BlockOrb(boolean)
    self:BlockAttack(boolean)
    self:BlockMovement(boolean)
end

function MixLib:BlockAttack(boolean)
    if attack_check == boolean then return end
    local cb = not boolean
      if self.OW == "IOW" then
        IOW.attacksEnabled = cb
      elseif self.OW == "DAC" then
        DAC:AttacksEnabled(cb)
      elseif self.OW == "PW" then
        PW.attacksEnabled = cb
      elseif self.OW == "GoSWalk" then
        GoSWalk:EnableAttack(cb)
      elseif self.OW == "DACR" then
        DACR.attacksEnabled = cb
      elseif self.OW == "SLW" then
        SLW.attacksEnabled = cb
      end
    attack_check = boolean
end

function MixLib:BlockMovement(boolean)
    if move_check == boolean then return end
    local cb = not boolean
      if self.OW == "IOW" then
        IOW.movementEnabled = cb
      elseif self.OW == "DAC" then
        DAC:MovementEnabled(cb)
      elseif self.OW == "PW" then
        PW.movementEnabled = cb
      elseif self.OW == "GoSWalk" then
        GoSWalk:EnableMovement(cb)
      elseif self.OW == "DACR" then
        DACR.movementEnabled = cb
      elseif self.OW == "SLW" then
        SLW.movementEnabled = cb
      end
      if _G.GoSEvade then _G.Evading = cb end
      BlockF7OrbWalk(true)
      BlockF7Dodge(true)
    move_check = boolean
end

function MixLib:HealthPredict(unit, time, hpname)
    if hpname == "GoS" then
        return unit.health - GetDamagePrediction(unit, time + GetLatency()*0.5)
    elseif hpname == "OP" then
        return GetHealthPrediction(unit, time + GetLatency()*0.5)
    elseif hpname == "OW" then
      if self.OW == "IOW" then
        return IOW:PredictHealth(unit, time)
      elseif self.OW == "DAC" then
        return DAC:GetPredictedHealth(unit, time*0.001)
      elseif self.OW == "PW" then
        return PW:PredictHealth(unit, time)
      elseif self.OW == "GoSWalk" then
        return unit.health - GetDamagePrediction(unit, time + GetLatency()*0.5)
      elseif self.OW == "DACR" then
        return DACR:GetHealthPrediction(unit, time*0.001, 0)
      elseif self.OW == "SLW" then
        return SLW:PredictHP(unit, time*0.001 + GetLatency()*0.5)
      end
    end
end

function MixLib:GetSlotByName(NAME)
    for i = 0, 12 do
      if myHero:GetSpellData(i).name ~= nil and myHero:GetSpellData(i).name:lower():find(NAME) then
        return i
      end
    end
        return nil
end

function MixLib:GetOtherSlot(what)
   local spell = nil
    if what == "Ignite" then spell = self:GetSlotByName("summonerdot") end
    if what == "Heal" then spell = self:GetSlotByName("summonerheal") end
    if what == "Barrier" then spell = self:GetSlotByName("summonerbarrier") end
    if what == "Cleanse" then spell = self:GetSlotByName("summonerboost") end
    if what == "Teleport" then spell = self:GetSlotByName("summonerteleport") end
    if what == "Clarity" then spell = self:GetSlotByName("summonermana") end
    if what == "Smite" then spell = self:GetSlotByName("smite") end
    if what == "Flash" then spell = self:GetSlotByName("summonerflash") end
        return spell
end

function MixLib:GetWardSlot(whatward)
    local ward = nil
    if whatward == "Yellow" then ward = self:GetSlotByName("trinkettotem") end
    if whatward == "Sight" then ward = self:GetSlotByName("ghostward") end
    if whatward == "Vision" then ward = self:GetSlotByName("visionward") end
    if whatward == "Blue" then ward = self:GetSlotByName("trinketorb") end
        return ward
end

function MixLib:GetCurrentTarget()
    if self.OW == "IOW" then return IOW:GetTarget()
      elseif self.OW == "DAC" then return DAC:GetTarget()
      elseif self.OW == "PW" then return PW:GetTarget()
      elseif self.OW == "GoSWalk" then return GoSWalk.CurrentTarget
      elseif self.OW == "DACR" then return DACR:GetTarget()
      elseif self.OW == "SLW" then return SLW:GetTarget()
    end
    return nil
end

function MixLib:ForceTarget(target)
    if self.OW == "IOW" then IOW.forceTarget = target
    elseif self.OW == "DAC" then DAC.forcePos = Vector(target)
    elseif self.OW == "PW" then PW.forceTarget = target
    elseif self.OW == "GoSWalk" then GoSWalk:ForceTarget(target)
    elseif self.OW == "DACR" then DACR.forceTarget = target
    elseif self.OW == "SLW" then SLW.forceTarget = target
    end	
end

function MixLib:ForcePos(Pos)
    if self.OW == "IOW" then IOW.forcePos = Vector(Pos)
    elseif self.OW == "DAC" then DAC.forcePos = Vector(Pos)
    elseif self.OW == "PW" then PW.forcePos = Vector(Pos)
    elseif self.OW == "GoSWalk" then GoSWalk:ForceMovePoint(Vector(Pos))
    elseif self.OW == "DACR" then DACR.forcePos = Vector(Pos)
    elseif self.OW == "SLW" then SLW.forcePos = Vector(Pos)
    end
end


function MixLib:Move(Pos)
   local mPos, lastMove = Pos or GetMousePos(), 0
    if lastMove + 0.35 < os.clock() then
      if GetDistance(mPos) > 100 then
        local POS = Vector(myHero.pos + Vector(mPos - myHero.pos):normalized()*math.min(GetDistance(mPos),400))
        MoveToXYZ(POS)
      end
      lastMove = os.clock()
    end
end

function MixLib:Predicting(unit, data, IPred)
    if self.Predict == "OpenPredict" then
      if data.collision then
        local Pred = GetPrediction(unit, data)
        local Hitchance, Pos = Pred.hitChance, Pred.castPos
        if not Pred:mCollision(data.coll) then return Hitchance, Pos, true, "OpenPredict" else return Hitchance, Pos, false, "OpenPredict" end
      else
        local Pred = dta[data.type](unit, data)
        return Pred.hitChance, Pred.castPos, true, "OpenPredict"
      end
    elseif self.Predict == "GPrediction" then
      data.type, data.radius = data.type == "linear" and "line" or data.type, data.width*0.5
      local Pred = gPred:GetPrediction(unit, myHero, data, data.aoe, data.collision)
        return Pred.HitChance, Pred.CastPosition, true, "GPrediction"
    elseif self.Predict == "IPrediction" then
      local Hitchance, Pos = IPred:Predict(unit)
        return Hitchance, Pos, true, "IPrediction"
    elseif self.Predict == "GoSPrediction" then
	  local Pred = GetPredictionForPlayer(myHero.pos, unit, unit.ms, data.speed, data.delay*1000, data.range, data.width, data.collision, data.aoe)
        return Pred.HitChance, Pred.PredPos, true, "GoSPrediction"
    end
        return -5, nil, false, ""
end

class "Spells"
function Spells:__init(Slot, Delay, Speed, Width, Range, Collision, collNum, Aoe, Type, Name, HitChance, Other, CSS2)
    Mix:LoadPred()
	local Angle = (Other ~= nil and Other.angle ~= nil) and Other.angle or nil
    local Accel = (Other ~= nil and Other.accel ~= nil) and Other.accel or nil
    local min = (Accel ~= nil and Other.minSp ~= nil) and Other.minSp or nil
    local max = (Accel ~= nil and Other.maxSp ~= nil) and Other.maxSp or nil
    self.data = { slot = Slot, name = Name, speed = Speed, delay = Delay, range = Range, width = Width, collision = Collision, col = {"minion", "yasuowall"}, coll = collNum, aoe = Aoe, type = Type, hc = HitChance, angle = Angle, accel = Accel, minSpeed = min, maxSpeed = max }
    self.IPrediction = Mix.Predict == "IPrediction" and IPrediction.Prediction(self.data)
    self.css2 = CSS2 or false
end

function Spells:SetHitChance(hitChance)
    self.data.hc = hitChance
end

function Spells:UpdateValue(what, value)
    if what == "Delay" then self.data.delay = value end
    if what == "Speed" then self.data.speed = value end
    if what == "Width" then self.data.width = value end
    if what == "Range" then self.data.range = value end
    if what == "CollNum" then self.data.coll = value end
    if what == "Angle" and self.data.angle then self.data.angle = value end
    if what == "Accel" and self.data.accel then self.data.accel = value end
    if what == "minSpeed" and self.data.minSpeed then self.data.minSpeed = value end
    if what == "maxSpeed" and self.data.minSpeed then self.data.minSpeed = value end
end

function Spells:Cast1(target, CSS2Range)
    if not IsReady(self.data.slot) or not target then self.hc, self.pos = 0, nil return end
    local HitChance, Pos, CanCast, Name = Mix:Predicting(target, self.data, self.IPrediction)
    if CanCast and ((Name == "OpenPredict" and HitChance >= self.data.hc) or (Name == "IPrediction" and HitChance > 2) or (Name == "GoSPrediction" and HitChance >= 1) or (Name == "GPrediction" and HitChance > 1)) then
      if not self.css2 and GetDistance(Pos) <= self.data.range then
        CastSkillShot(self.data.slot, Pos)
      elseif self.css2 and GetDistance(Pos) <= CSS2Range then
        CastSkillShot2(self.data.slot, Pos)
      end
    end
end

class "DrawDmgHPBar"
function DrawDmgHPBar:__init(Menu, color, Text)
    self.cfg, self.data, self.c = Menu, { }, #color
     self.cfg:Boolean("rt", "Enable on this target?", true)
     self.cfg:Info("rc", "    ------------------------------")
    for i = 1, self.c do
     self.data[i] = { fill = 0, pos = nil }
     self.cfg:Boolean("r1_"..i, "Draw "..Text[i].." Dmg?", true)
     self.cfg:ColorPick("r2_"..i, "Set "..Text[i].." Color", {color[i]["a"], color[i]["r"], color[i]["g"] ,color[i]["b"]})	
    end
end

function DrawDmgHPBar:CheckValue()
    if not self.cfg.rt:Value() then return end
    for i = 1, self.c do
      if not self.cfg["r1_"..i]:Value() or not self.data[i].check then
        if i == 1 then
          self.data[i].pos = hpP(self.data[i].unit)
        else
          self.data[i].pos = self.data[i-1].pos
        end
      end
      if self.data[i].pos and self.data[i].pos < 0 then
        self.data[i].pos = 0
        if i == 1 then self.data[i].fill = hpP(self.data[i].unit) else self.data[i].fill = self.data[i-1].pos end
      end
    end
end

function DrawDmgHPBar:SetValue(value, target, damage, boolean)
    if not self.cfg.rt:Value() then return end
    self.data[value].unit = target
    self.data[value].fill = dmgP(damage, self.data[value].unit)
    self.data[value].check = boolean
    if not boolean or not self.cfg["r1_"..value]:Value() then return end
    if value == 1 then
      self.data[value].pos = hpP(self.data[value].unit) - self.data[value].fill
    else
      if self.data[value - 1].pos then self.data[value].pos = self.data[value - 1].pos - self.data[value].fill end
    end
end

function DrawDmgHPBar:Draw()
    if not self.cfg.rt:Value() then return end
    for i = 1, self.c do
      if self.cfg["r1_"..i]:Value() and self.data[i].check and self.data[i].pos and hpbar(self.data[i].unit).x + self.data[i].pos > 0 and hpbar(self.data[i].unit).y > 0 then
        FillRect(hpbar(self.data[i].unit).x + self.data[i].pos, hpbar(self.data[i].unit).y, self.data[i].fill, 9, self.cfg["r2_"..i]:Value())
      end
	end
end

function DrawDmgHPBar:GetPos()
    local result = { }
    for i = 1, self.c, 1 do
      result[i] = { x = self.data[i].pos.x, y = self.data[i].y, fill = self.data[i].fill }
    end
        return result
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
        local bQuality, menuQuality = bonusQuality or 0, self.cfg[self.link].r2:Value()/100
        DrawCircle3D(Pos.x, Pos.y, Pos.z, self.range, self.width, self.cfg[self.link].r3:Value(), self.range*(20+bQuality)/100*menuQuality)
    end    
end

do
    local function MixLibLoaded()
      if not _G.Mix then _G.Mix = MixLib() end
      BlockF7OrbWalk(true)
      BlockF7Dodge(true)
    end
      MixLibLoaded()
end

GetWebResultAsync("https://raw.githubusercontent.com/VTNEETS/GoS/master/MixLib.version", function(OnlineVer)
    if tonumber(OnlineVer) > MixLibVersion then
      Mix_Print("New Version found (v"..OnlineVer.."). Please wait...")
      DownloadFileAsync("https://raw.githubusercontent.com/VTNEETS/GoS/master/MixLib.lua", COMMON_PATH.."MixLib.lua", function() Mix_Print("Updated to version "..v..". Please F6 x2 to reload.") end)
    else
      Mix_Print("You are using lastest version (v"..MixLibVersion..")") Mix:PrintCurrPredOW()
    end
end)
