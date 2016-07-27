--[[ NEET Series Version 0.099 ]]--
-- > Added support Annie < --
---------------------------------------
local NEETSeries_Version = 0.099
local Enemies, C = { }, 0
local function NEETSeries_Print(text) PrintChat(string.format("<font color=\"#4169E1\"><b>[NEET Series]:</b></font><font color=\"#FFFFFF\"> %s</font>", tostring(text))) end

if not FileExist(COMMON_PATH.."MixLib.lua") then
    NEETSeries_Print("MixLib.lua not found. Please wait...")
    DownloadFileAsync("https://raw.githubusercontent.com/VTNEETS/NEET-Scripts/master/MixLib.lua", COMMON_PATH.."MixLib.lua", function() NEETSeries_Print("Downloaded MixLib.lua, please 2x F6!") end)
return else require('MixLib') end
if not FileExist(COMMON_PATH.."OpenPredict.lua") or not FileExist(COMMON_PATH.."ChallengerCommon.lua") or not FileExist(COMMON_PATH.."DamageLib.lua") or not FileExist(COMMON_PATH.."Analytics.lua") then return end
if not ChallengerCommonLoaded then require('ChallengerCommon') end
if not Analytics then require("Analytics") end

local huge, max, min = math.huge, math.max, math.min
DelayAction(function() for i = 1, heroManager.iCount do local hero = heroManager:getHero(i) if hero.team == MINION_ENEMY then C = C + 1 Enemies[C] = hero table.sort(Enemies, function(a,b) local t = {a.charName, b.charName} table.sort(t) local s1,_ = table.contains(t, a.charName) local s2,__ = table.contains(t, b.charName) return s1 < s2 end) end end end, 0.001)
local Supported, StrID, StrN = Set {"Xerath", "Katarina", "KogMaw", "Annie"}, {"cb", "hr", "lc", "jc", "ks", "lh"}, {"Combo", "Harass", "LaneClear", "JungleClear", "KillSteal", "LastHit"}
local EnemiesAround, AddCB, QWER, WardCheck = function(pos, range) return CountObjectsNearPos(pos, nil, range, Enemies, MINION_ENEMY) end, Callback.Add, {"Q", "W", "E", "R"}, Set {"SightWard", "VisionWard", "YellowTrinket"}

local ChangeSkin = function(id, n) myHero:Skin(id == n and -1 or id-1) end
local GetData = function(spell) return myHero:GetSpellData(spell) end
local CalcDmg = function(type, target, dmg) local calc = type == 1 and CalcPhysicalDamage or CalcMagicalDamage return calc(myHero, target, dmg) end
local IsSReady = function(spell) return CanUseSpell(myHero, spell) == 0 or CanUseSpell(myHero, spell) == 8 end
local Ignite = Mix:GetOtherSlot("Ignite")
local ManaCheck = function(value) return value <= GetPercentMP(myHero) end
local DrawDmgOnHPBar = function(Menu, Color, Text)
    local Dt = {}
    DelayAction(function()
      for i = 1, C do
        Menu:Menu("HPBar_"..Enemies[i].charName, "Draw Dmg HPBar "..Enemies[i].charName)
        Dt[i] = DrawDmgHPBar(Menu["HPBar_"..Enemies[i].charName], Color, Text)
      end
    end, 1)
        return Dt
end
local AddMenu = function(Menu, ID, Text, Tbl, MP)
    Menu:Menu(ID, Text)
    for i = 1, 6 do
      if Tbl[i] then Menu[ID]:Boolean(StrID[i], "Use in "..StrN[i], true) end
      if MP and i > 1 and Tbl[i] then Menu[ID]:Slider("MP"..StrID[i], "Enable on "..StrN[i].." if %MP >=", MP, 1, 100, 1) end
    end
end
local SetSkin = function(Menu, skintable)
    local maxSkin = #skintable
    Menu:DropDown(myHero.charName.."_SetSkin", myHero.charName.." SkinChanger", 1, skintable, function(id) ChangeSkin(id, maxSkin) NEETSeries_Print("Skin changed to "..skintable[id].." "..myHero.charName) end)
    ChangeSkin(Menu[myHero.charName.."_SetSkin"]:Value(), maxSkin)
end
local GetLineFarmPosition2 = function(range, width, objects)
    local Pos, Hit, mP = nil, 0, Vector(myHero)
    for _, m in pairs(objects) do
      if ValidTarget(m, range) then
        local c = CountObjectsOnLineSegment(mP, Vector(m), width, objects, MINION_ENEMY)
        if not Pos or CountObjectsOnLineSegment(mP, Vector(Pos), width, objects, MINION_ENEMY) < c then
          Pos = Vector(m)
          Hit = c
        end
      end
    end
        return Pos, Hit
end
local GetFarmPosition2 = function(range, width, objects)
    local Pos, Hit = nil, 0
    for _, m in pairs(objects) do
      if ValidTarget(m, range) then
        local c = CountObjectsNearPos(Vector(m), nil, width, objects, MINION_ENEMY)
        if not Pos or CountObjectsNearPos(Vector(Pos), nil, width, objects, MINION_ENEMY) < c then
          Pos = Vector(m)
          Hit = c
        end
      end
    end
        return Pos, Hit
end

class "MinionManager2"
function MinionManager2:__init(range1, range2)
    self.range1 = range1*range1
    self.range2 = range2*range2
    self.minion = {}
    self.mob = {}
    self.tminion = {}
    self.tmob = {}
    AddCB("ObjectLoad", function(obj) self:CreateObj(obj) end)
    AddCB("CreateObj", function(obj) self:CreateObj(obj) end)
    AddCB("DeleteObj", function(obj) self:DeleteObj(obj) end)
end

function MinionManager2:CreateObj(obj)
    if GetObjectType(obj) == "obj_AI_Minion" and GetTeam(obj) == MINION_ENEMY and GetObjectBaseName(obj):find("Minion_") and IsObjectAlive(obj) then
      self.minion[#self.minion +1] = obj
    elseif GetTeam(obj) == 300 and GetObjectType(obj) == "obj_AI_Minion" and IsObjectAlive(obj) then
      self.mob[#self.mob +1] = obj
    end
end

function MinionManager2:DeleteObj(obj)
    for i, minion in pairs(self.minion) do
      if minion == obj then table.remove(self.minion, i) end
    end
    for k, mob in pairs(self.mob) do
      if mob == obj then table.remove(self.mob, k) end
    end
end

function MinionManager2:Update()
    self.tminion = {}
    for _, minion in pairs(self.minion) do
      if IsObjectAlive(minion) and GetDistanceSqr(minion) <= self.range1 and GetTeam(minion) == MINION_ENEMY then
        table.insert(self.tminion, minion)
      end
    end

    self.tmob = {}
    for _, mob in pairs(self.mob) do
      if IsObjectAlive(mob) and GetDistanceSqr(mob) <= self.range2 and GetTeam(mob) == 300 then
        table.insert(self.tmob, mob)
      end
    end

    table.sort(self.tminion, SORT_HEALTH_ASC)
    table.sort(self.tmob, SORT_MAXHEALTH_DEC)
end

--[[-----------Xerath Plugin Load-----------]]--
class "NS_Xerath"
function NS_Xerath:__init()
    self:CreateMenu()
    self:LoadVariables()
    self:ExtraLoad()
    AddCB("Tick", function() self:Tick() end)
    AddCB("Draw", function() self:Drawings() end)
    AddCB("DrawMinimap", function() self:DrawRRange() end)
    AddCB("ProcessSpell", function(unit, spell) self:AutoE(unit, spell) self:GetCastTime(unit, spell) self:GetRCount(unit, spell) end)
    AddCB("UpdateBuff", function(unit, buff) self:UpdateBuff(unit, buff) end)
    AddCB("RemoveBuff", function(unit, buff) self:RemoveBuff(unit, buff) end)
end

function NS_Xerath:LoadVariables()
    self.Q = { Range = 0, minRange = 750, maxRange = 1460, Range2 = 0,         Speed = huge, Delay = 0.6,   Width = 100, Damage = function(unit) return CalcDmg(2, unit, 40 + 40*GetData(_Q).level + 0.75*myHero.ap) end, Charging = false, LastCastTime = 0}
    self.W = { Range = GetData(_W).range,                                      Speed = huge, Delay = 0.85,  Width = 220, Damage = function(unit) return CalcDmg(2, unit, 45 + 45*GetData(_W).level + 0.9*myHero.ap) end, LastCastTime = 0}
    self.E = { Range = GetData(_E).range,                                      Speed = 1500,      Delay = 0.25,  Width = 73,  Damage = function(unit) return CalcDmg(2, unit, 50 + 30*GetData(_E).level + 0.45*myHero.ap) end, LastCastTime = 0}
    self.R = { Range = function() return 2000 + 1200*GetData(_R).level end,    Speed = huge, Delay = 0.72,  Width = 195, Damage = function(unit) return CalcDmg(2, unit, 170 + 30*GetData(_R).level + 0.43*myHero.ap) end, Activating = false, Count = max(3, GetData(_R).level + 2), Delay1 = 0, Delay2 = 0, Delay3 = 0, Delay4 = 0, Delay5 = 0}
    if GotBuff(myHero, "xerathlocusofpower2") > 0 then self.R.Activating = true self.R.Delay1 = os.clock() end
    self.C = MinionManager2(self.Q.maxRange, self.W.Range)
end

function NS_Xerath:CreateMenu()
  self.cfg = MenuConfig("NS_Xerath", "[NEET Series] - Xerath")
    self.cfg:Info("ifo", "Script Version: "..NEETSeries_Version)

    --[[ Q Settings ]]--
    AddMenu(self.cfg, "Q", "Q Settings", {true, true, true, true, true, false}, 15)
    self.cfg.Q:Slider("h", "Q LaneClear if hit Minions >= ", 2, 1, 10, 1)

    --[[ W Settings ]]--
    AddMenu(self.cfg, "W", "W Settings", {true, true, true, true, true, false}, 15)
    self.cfg.W:Slider("h", "W LaneClear if hit Minions >= ", 2, 1, 10, 1)

    --[[ E Settings ]]--
    AddMenu(self.cfg, "E", "E Settings", {true, true, false, true, true, false}, 15)

    --[[ Ignite Settings ]]--
    if Ignite then AddMenu(self.cfg, "Ignite", "Ignite Settings", {false, false, false, false, true, false}) end

    --[[ Ultimate Menu ]]--
    self.cfg:Menu("ult", "Ultimate Settings")
      self.cfg.ult:Menu("use", "Active Mode")
        self.cfg.ult.use:DropDown("mode", "Choose Your Mode:", 1, {"Press R", "Auto Use"}, function(v) if v == 2 then self.cfg.ult.cast.mode:Value(v) end end)
        self.cfg.ult.use:Info("if1", "-- Press R: You Must PressR")
        self.cfg.ult.use:Info("if2", "To enable AutoCasting")
        self.cfg.ult.use:Info("if3", "-- Auto Use: Auto ActiveR")
        self.cfg.ult.use:Info("if4", "if find Target Killable")
        self.cfg.ult.use:Info("if5", "-- Note: It Only Active Ult Not AutoCast")
        self.cfg.ult.use:Info("if6", "-- Recommend using Press R Mode")
      self.cfg.ult:Menu("cast", "Casting Mode")
        self.cfg.ult.cast:DropDown("mode", "Choose Your Mode:", 1, {"Press Key", "Auto Cast", "Target In Mouse Range"})
        self.cfg.ult.cast:KeyBinding("key", "Seclect Key For PressKey Mode:", 84)
        self.cfg.ult.cast:Slider("range", "Range for Target NearMouse", 500, 200, 1500, 50, function(value) self.R.Draw2:Update("Range", value) end)
        self.cfg.ult.cast:Info("if1", "Press Key: Press a Key everywhere to AutoCast")
        self.cfg.ult.cast:Info("if2", "Auto Cast: AutoCasting Target")
        self.cfg.ult.cast:Info("if3", "Mouse: AutoCast Target in Mouse Range")
        self.cfg.ult.cast:Info("if4", "Recommend using Press Key")

    --[[ Misc Menu ]]--
    self.cfg:Menu("misc", "Misc Mode")
      self.cfg.misc:Menu("castCombo", "Combo Casting")
        self.cfg.misc.castCombo:Info("if", "Only Cast QWE if W or E Ready")
        self.cfg.misc.castCombo:Boolean("WE", "Enable? (default off)", false)
      self.cfg.misc:Menu("hc", "Spell HitChance")
        self.cfg.misc.hc:Slider("Q", "Q Hit-Chance", 25, 1, 100, 1, function(value) self.Q.Prediction:SetHitChance(value*0.01) end)
        self.cfg.misc.hc:Slider("W", "W Hit-Chance", 25, 1, 100, 1, function(value) self.W.Prediction:SetHitChance(value*0.01) end)
        self.cfg.misc.hc:Slider("E", "E Hit-Chance", 30, 1, 100, 1, function(value) self.E.Prediction:SetHitChance(value*0.01) end)
        self.cfg.misc.hc:Slider("R", "R Hit-Chance", 40, 1, 100, 1, function(value) self.R.R1Prediction:SetHitChance(value*0.01) self.R.R2Prediction:SetHitChance(value*0.01) self.R.R3Prediction:SetHitChance(value*0.01) end)
		self.cfg.misc:Menu("delay", "R Casting Delays")
        self.cfg.misc.delay:Slider("c1", "Delay CastR 1 (ms)", 230, 0, 1500, 1)
        self.cfg.misc.delay:Slider("c2", "Delay CastR 2 (ms)", 250, 0, 1500, 1)
        self.cfg.misc.delay:Slider("c3", "Delay CastR 3 (ms)", 270, 0, 1500, 1)
        self.cfg.misc.delay:Slider("c4", "Delay CastR 4 (ms)", 290, 0, 1500, 1)
        self.cfg.misc.delay:Slider("c5", "Delay CastR 5 (ms)", 310, 0, 1500, 1)
      self.cfg.misc:KeyBinding("E", "Use E in Combo/Harass (G)", 71, true, function() end, true)
      SetSkin(self.cfg.misc, {"Classic", "Runeborn", "Battlecast", "Scorched Earth", "Guardian Of The Sands", "Disable"})

    --[[ Drawings Menu ]]--
    self.cfg:Menu("dw", "Drawings Mode")
        self.cfg.dw:Boolean("R", "Draw R Range Minimap", true)
		self.cfg.dw:Boolean("TK", "Draw Text Target R Killable", true)

    PermaShow(self.cfg.misc.E)
end

function NS_Xerath:ExtraLoad()
    self.Q.Target = ChallengerTargetSelector(self.Q.maxRange, 2, false, nil, false, self.cfg.Q, false, 4)
    self.W.Target = ChallengerTargetSelector(self.W.Range, 2, false, nil, false, self.cfg.W, false, 4)
    self.E.Target = ChallengerTargetSelector(self.E.Range, 2, true, nil, false, self.cfg.E, false, 7)
    self.Q.Target.Menu.TargetSelector.TargetingMode.callback = function(id) self.Q.Target.Mode = id end
    self.W.Target.Menu.TargetSelector.TargetingMode.callback = function(id) self.W.Target.Mode = id end
    self.E.Target.Menu.TargetSelector.TargetingMode.callback = function(id) self.E.Target.Mode = id end

    self.HPBar   = DrawDmgOnHPBar(self.cfg.dw, {ARGB(200, 89, 0 ,179), ARGB(200, 0, 245, 255), ARGB(200, 186, 85, 211), ARGB(200, 0, 217, 108)}, {"R", "Q", "W", "E"})
    self.Q.Draw  = DCircle(self.cfg.dw, "Draw Q Full Range", self.Q.maxRange, ARGB(150, 0, 245, 255))
    self.Q.Draw2 = DCircle(self.cfg.dw, "Draw Q Current Range", self.Q.minRange, ARGB(150, 0, 245, 255))
    self.W.Draw  = DCircle(self.cfg.dw, "Draw W Range", self.W.Range, ARGB(150, 186, 85, 211))
    self.E.Draw  = DCircle(self.cfg.dw, "Draw E Range", self.E.Range, ARGB(150, 0, 217, 108))
    self.R.Draw  = DCircle(self.cfg.dw, "Draw R Range", self.R.Range(), ARGB(150, 89, 0 ,179))
    self.R.Draw2 = DCircle(self.cfg.ult.cast, "Draw NearMouse Range", self.cfg.ult.cast.range:Value(), ARGB(150, 255, 255, 0))

    self.Q.Prediction = Spells(_Q, self.Q.Delay, self.Q.Speed, self.Q.Width, self.Q.maxRange, false, 0, true, "linear", "Xerath Q", self.cfg.misc.hc.Q:Value()*0.01, nil, true)
    self.W.Prediction = Spells(_W, self.W.Delay, self.W.Speed, self.W.Width, self.W.Range, false, 0, true, "circular", "Xerath W", self.cfg.misc.hc.W:Value()*0.01)
    self.E.Prediction = Spells(_E, self.E.Delay, self.E.Speed, self.E.Width, self.E.Range, true, 1, false, "linear", "Xerath E", self.cfg.misc.hc.E:Value()*0.01)
    self.R.R1Prediction = Spells(_R, self.R.Delay, self.R.Speed, self.R.Width, 3200, false, 0, true, "circular", "Xerath R Lv 1", self.cfg.misc.hc.R:Value()*0.01)
    self.R.R2Prediction = Spells(_R, self.R.Delay, self.R.Speed, self.R.Width, 4400, false, 0, true, "circular", "Xerath R Lv 2", self.cfg.misc.hc.R:Value()*0.01)
    self.R.R3Prediction = Spells(_R, self.R.Delay, self.R.Speed, self.R.Width, 5600, false, 0, true, "circular", "Xerath R Lv 3", self.cfg.misc.hc.R:Value()*0.01)

    AddCB("Load", function()
        ChallengerAntiGapcloser(self.cfg.misc, function(o, s) if not ValidTarget(o, self.E.Range) or not IsReady(_E) or (s.spell.name == "AlphaStrike" and s.endTime - GetTickCount() > 650) or ((s.spell.name == "KatarinaE" or s.spell.name == "RiftWalk" or s.spell.name == "TalonCutThroat") and s.endTime - GetTickCount() > 750) then return end self.E.Prediction:Cast1(o) end)
        ChallengerInterrupter(self.cfg.misc, function(o, s) if not ValidTarget(o, self.E.Range) or not IsReady(_E) or ((s.spell.name == "VarusQ" or s.spell.name == "Drain") and s.endTime - GetTickCount() > 2400) then return end self.E.Prediction:Cast1(o) end)
    end)
end

function NS_Xerath:CastR(target)
    if target == nil or self.R.Count == 0 then return end
    local RData = {
    [3] = {
        [3] = { delay = self.R.Delay1, menu = self.cfg.misc.delay.c1:Value() },
        [2] = { delay = self.R.Delay2, menu = self.cfg.misc.delay.c2:Value() },
        [1] = { delay = self.R.Delay3, menu = self.cfg.misc.delay.c3:Value() }
    },
    [4] = {
        [4] = { delay = self.R.Delay1, menu = self.cfg.misc.delay.c1:Value() },
        [3] = { delay = self.R.Delay2, menu = self.cfg.misc.delay.c2:Value() },
        [2] = { delay = self.R.Delay3, menu = self.cfg.misc.delay.c3:Value() },
        [1] = { delay = self.R.Delay4, menu = self.cfg.misc.delay.c4:Value() },
    },
    [5] = {
        [5] = { delay = self.R.Delay1, menu = self.cfg.misc.delay.c1:Value() },
        [4] = { delay = self.R.Delay2, menu = self.cfg.misc.delay.c2:Value() },
        [3] = { delay = self.R.Delay3, menu = self.cfg.misc.delay.c3:Value() },
        [2] = { delay = self.R.Delay4, menu = self.cfg.misc.delay.c4:Value() },
        [1] = { delay = self.R.Delay5, menu = self.cfg.misc.delay.c5:Value() },
    }
        }

      if RData[2+GetData(_R).level] and os.clock() - RData[2+GetData(_R).level][self.R.Count].delay >= RData[2+GetData(_R).level][self.R.Count].menu/1000 then
        if GetData(_R).level == 1 then
          self.R.R1Prediction:Cast1(target)
        elseif GetData(_R).level == 2 then
          self.R.R2Prediction:Cast1(target)
        elseif GetData(_R).level == 3 then
          self.R.R3Prediction:Cast1(target)
        end
      end
end

function NS_Xerath:CastQ(target)
   if not IsReady(_Q) or not ValidTarget(target, self.Q.maxRange + 80) then return end
    if not self.Q.Charging then
      if os.clock() - self.W.LastCastTime > 0.1 then CastSkillShot(_Q, GetMousePos()) end
    else
      self.Q.Prediction:Cast1(target, self.Q.Range2)
    end
end

function NS_Xerath:CastW(target)
   if not IsReady(_W) or not ValidTarget(target, self.W.Range + 80) then return end
   if (Mix:Mode() == "Combo" or Mix:Mode() == "Harass") and (os.clock() - self.Q.LastCastTime < 0.18 or os.clock() - self.E.LastCastTime < 0.24) then return end
    self.W.Prediction:Cast1(target)
end

function NS_Xerath:CastE(target)
   if not IsReady(_E) or not ValidTarget(target, self.E.Range + 50) then return end
   if (Mix:Mode() == "Combo" or Mix:Mode() == "Harass") and (os.clock() - self.Q.LastCastTime < 0.18 or os.clock() - self.W.LastCastTime < 0.27) then return end
    self.E.Prediction:Cast1(target)
end

function NS_Xerath:UpdateValues()
    if IsReady(_Q) and self.Q.Charging then
      self.Q.Range = min(self.Q.minRange + (os.clock() - self.Q.LastCastTime)*500, self.Q.maxRange)
      self.Q.Range2 = min(735 + (os.clock() - self.Q.LastCastTime)*500, self.Q.maxRange)
    end
    if IsReady(_R) then
     if not self.R.Activating then
       self:CheckRUsing()
     else
       self:CheckRCasting()
       if EnemiesAround(myHero.pos, 1000) == 0 then
        Mix:BlockOrb(true)
       else
        Mix:BlockOrb(false)
       end
     end
    end

    for i = 1, C do
      local enemy = Enemies[i]
      if ValidTarget(enemy, self.R.Range()) and self.HPBar[i] then
        self.HPBar[i]:SetValue(1, enemy, self.R.Damage(enemy)*self.R.Count, IsSReady(_R))
        self.HPBar[i]:SetValue(2, enemy, self.Q.Damage(enemy), IsSReady(_Q))
        self.HPBar[i]:SetValue(3, enemy, self.W.Damage(enemy), IsSReady(_W))
        self.HPBar[i]:SetValue(4, enemy, self.E.Damage(enemy), IsSReady(_E))
        self.HPBar[i]:CheckValue()
      end
    end

    if IsReady(_Q) then self.Q.Draw2:Update("Range",self.Q.Range) end
    if IsReady(_R) then self.R.Draw:Update("Range", self.R.Range()) end
    self.C:Update()
end

function NS_Xerath:Tick()
   if myHero.dead or not Enemies[C] then return end
    self:UpdateValues()
    if self.R.Activating then return end
    local QTarget = IsReady(_Q) and self.Q.Target:GetTarget()
    local WTarget = IsReady(_W) and self.W.Target:GetTarget()
    local ETarget = IsReady(_E) and self.E.Target:GetTarget()
    if Mix:Mode() == "Combo" then
     if (self.cfg.misc.castCombo.WE:Value() and (IsReady(_W) or IsReady(_E))) or not self.cfg.misc.castCombo.WE:Value() then
       if self.cfg.E.cb:Value() and self.cfg.misc.E:Value() and ETarget then self:CastE(ETarget) end
       if self.cfg.W.cb:Value() and WTarget then self:CastW(WTarget) end
       if self.cfg.Q.cb:Value() and QTarget then self:CastQ(QTarget) end
      end
    end

    if Mix:Mode() == "Harass" then
       if self.cfg.E.hr:Value() and ManaCheck(self.cfg.E.MPhr:Value()) and self.cfg.misc.E:Value() and ETarget then self:CastE(ETarget) end
       if self.cfg.W.hr:Value() and ManaCheck(self.cfg.W.MPhr:Value()) and WTarget then self:CastW(WTarget) end
       if self.cfg.Q.hr:Value() and ManaCheck(self.cfg.Q.MPhr:Value()) and QTarget then self:CastQ(QTarget) end
    end
    if Mix:Mode() == "Harass" and IsReady(_Q) and self.Q.Charging and QTarget and not self.R.Activating then self:CastQ(QTarget) end

    if Mix:Mode() == "LaneClear" then
     self:LaneClear()
     self:JungleClear()
    end

    if EnemiesAround(myHero, self.Q.maxRange) > 0 then self:KillSteal() end
end

function NS_Xerath:KillSteal()
    for i = 1, C do
    local enemy = Enemies[i]
     if Ignite and IsReady(Ignite) and self.cfg.Ignite.ks:Value() and ValidTarget(enemy, 600) then
      local hp, dmg = Mix:HealthPredict(enemy, 2500, "OW") + enemy.hpRegen*2.5 + enemy.shieldAD, 50 + 20*myHero.level
      if hp > 0 and dmg > hp then CastTargetSpell(enemy, Ignite) end
     end

     local EnemyHP = GetHP2(enemy)
     if IsReady(_E) and self.cfg.E.ks:Value() and ManaCheck(self.cfg.E.MPks:Value()) and EnemyHP < self.E.Damage(enemy) then
      self:CastE(enemy)
     end

     if IsReady(_W) and self.cfg.W.ks:Value() and ManaCheck(self.cfg.W.MPks:Value()) and EnemyHP < self.W.Damage(enemy) then
      self:CastW(enemy)
     end

     if IsReady(_Q) and self.cfg.Q.ks:Value() and (ManaCheck(self.cfg.Q.MPks:Value()) or self.Q.Charging) and EnemyHP < self.Q.Damage(enemy) then
      self:CastQ(enemy)
     end
    end
end

function NS_Xerath:LaneClear()
    if IsReady(_W) and self.cfg.W.lc:Value() and ManaCheck(self.cfg.W.MPlc:Value()) then
    local WPos, WHit = GetFarmPosition2(self.W.Range, self.W.Width, self.C.tminion)
       if WHit >= self.cfg.W.h:Value() then CastSkillShot(_W, WPos) end
    end
    if IsReady(_Q) and self.cfg.Q.lc:Value() and (ManaCheck(self.cfg.W.MPlc:Value()) or self.Q.Charging) then
    local QPos, QHit = GetLineFarmPosition2(self.Q.maxRange, self.Q.Width, self.C.tminion)
     if not self.Q.Charging then
       if QHit >= self.cfg.Q.h:Value() and os.clock() - self.W.LastCastTime > 0.1 then CastSkillShot(_Q, GetMousePos()) end
     else
      if GetDistance(QPos) <= self.Q.Range then
       CastSkillShot2(_Q, QPos)
      end
     end
    end
end

function NS_Xerath:JungleClear()
    if not self.C.tmob[1] then return end
    local mob = self.C.tmob[1]
    if IsReady(_W) and self.cfg.W.jc:Value() and ManaCheck(self.cfg.W.MPjc:Value()) then CastSkillShot(_W, Vector(mob)) end
    if IsReady(_E) and self.cfg.E.jc:Value() and ManaCheck(self.cfg.E.MPjc:Value()) and ValidTarget(mob, self.E.Range) then CastSkillShot(_E, Vector(mob)) end
    if IsReady(_Q) and self.cfg.Q.jc:Value() and (ManaCheck(self.cfg.Q.MPjc:Value()) or self.Q.Charging) then if not self.Q.Charging then CastSkillShot(_Q, GetMousePos()) elseif ValidTarget(mob, self.Q.Range) then CastSkillShot2(_Q, Vector(mob)) end end
end

function NS_Xerath:CheckRUsing()
   if not IsReady(_R) then return end
    if self.cfg.ult.use.mode:Value() == 2 then
     local target = self:GetRTarget(myHero.pos, self.R.Range())
     if target and GetHP2(target) < self.R.Damage(target) * self.R.Count then
      CastSpell(_R)
      self.R.Activating = true
     end
    end
end

function NS_Xerath:CheckRCasting()
   if not IsReady(_R) then return end
    if self.cfg.ult.cast.mode:Value() < 3 then
    local target = self:GetRTarget(myHero.pos, self.R.Range())
     if self.cfg.ult.cast.mode:Value() == 1 and self.cfg.ult.cast.key:Value() then
      self:CastR(target)
     elseif self.cfg.ult.cast.mode:Value() == 2 then
      self:CastR(target)
     end
    else
    local target = self:GetRTarget(GetMousePos(), self.cfg.ult.cast.range:Value())
      self:CastR(target)
    end
end

function NS_Xerath:AutoE(unit, spell)
    if self.R.Activating or not IsReady(_E) or unit.team == MINION_ALLY or unit.type ~= "AIHeroClient" then return end
      if CHANELLING_SPELLS[spell.name] and ValidTarget(unit, self.E.Range) and unit.charName == CHANELLING_SPELLS[spell.name].Name and self.cfg.misc.Interrupt[unit.charName.."Inter"] and self.cfg.misc.Interrupt[unit.charName.."Inter"]:Value() then
        self.E.Prediction:Cast1(unit)
      end
end

function NS_Xerath:Drawings()
   if myHero.dead or not Enemies[C] then return end
   if self.cfg.dw.TK:Value() and IsSReady(_R) then self:RKillable() end
   self:DmgHPBar()
   self:DrawRange()
end

function NS_Xerath:RKillable()
    local d = 0
    for i = 1, C do
    local enemy = Enemies[i]
     d = d+1
     if ValidTarget(enemy, self.R.Range()) and GetHP2(enemy) < self.R.Damage(enemy) * self.R.Count then
      DrawText(enemy.charName.." R Killable", 30, GetResolution().x/80, GetResolution().y/7+d*26, GoS.Red)
     end
    end
end

function NS_Xerath:DrawRRange()
    if not IsSReady(_R) then return end
    if self.cfg.dw.R:Value() then DrawCircleMinimap(myHero.pos, self.R.Range(), 1, 120, 0x20FFFF00) end
end

function NS_Xerath:DrawRange()
    if IsSReady(_Q) then
      self.Q.Draw:Draw(myHero.pos)
      self.Q.Draw2:Draw(myHero.pos)
    end
    if IsSReady(_W) then self.W.Draw:Draw(myHero.pos) end
    if IsSReady(_E) then self.E.Draw:Draw(myHero.pos) end
    if self.cfg.ult.cast.mode:Value() == 3 and self.R.Activating then self.R.Draw2:Draw(GetMousePos()) end
    if IsSReady(_R) then self.R.Draw:Draw(myHero.pos) end
end

function NS_Xerath:DmgHPBar()
    for i = 1, C do
      if ValidTarget(Enemies[i], self.R.Range()) and self.HPBar[i] then
        self.HPBar[i]:Draw()
     end
    end
end

function NS_Xerath:DelayCheck(time)
    local count = 2 + GetData(_R).level
    if count == 3 then
      if self.R.Count == 2 then
        self.R.Delay2 = time
      elseif self.R.Count == 1 then
        self.R.Delay3 = time
      end
    elseif count == 4 then
      if self.R.Count == 3 then
        self.R.Delay2 = time
      elseif self.R.Count == 2 then
        self.R.Delay3 = time
      elseif self.R.Count == 1 then
        self.R.Delay4 = time
      end
    elseif count == 5 then
      if self.R.Count == 4 then
        self.R.Delay2 = time
      elseif self.R.Count == 3 then
        self.R.Delay3 = time
      elseif self.R.Count == 2 then
        self.R.Delay4 = time
      elseif self.R.Count == 1 then
        self.R.Delay5 = time
      end
    end
end

function NS_Xerath:GetRCount(unit, spell)
    if unit == myHero and unit.dead == false and spell.name:lower() == "xerathlocuspulse" then
      self.R.Count = self.R.Count - 1
      self:DelayCheck(os.clock() + 0.8)
    end
end

function NS_Xerath:GetCastTime(unit, spell)
    if unit == myHero and unit.dead == false then
      if spell.name:lower() == "xeratharcanebarrage2" then
          self.W.LastCastTime = os.clock() + spell.windUpTime
      elseif spell.name:lower() == "xerathmagespear" then
          self.E.LastCastTime = os.clock() + 0.3
      elseif spell.name:lower() == "xeratharcanopulse2" then
          self.Q.LastCastTime = os.clock() + 0.5
      end
    end
end

function NS_Xerath:UpdateBuff(unit, buff)
    if unit == myHero and not unit.dead then
     if buff.Name:lower() == "xeratharcanopulsechargeup" then
      self.Q.LastCastTime = os.clock()
      self.Q.Charging = true
	  Mix:BlockAttack(true)
     elseif buff.Name:lower() == "xerathlocusofpower2" then
      self.R.Count = GetData(_R).level + 2
      self.R.Delay1 = os.clock()
      self.R.Activating = true
     end
    end
end

function NS_Xerath:RemoveBuff(unit, buff)
    if unit == myHero and not unit.dead then
     if buff.Name:lower() == "xeratharcanopulsechargeup" then
      self.Q.Charging = false
	  Mix:BlockAttack(false)
      self.Q.Range = self.Q.minRange
      self.Q.Range2 = self.Q.minRange
     elseif buff.Name:lower() == "xerathlocusofpower2" then
      self.R.Activating = false
      self.R.Count = GetData(_R).level + 2
      Mix:BlockOrb(false)
     end
    end
end

function NS_Xerath:GetRTarget(pos, range)
    local RTarget = nil
      for i = 1, C do
        local enemy = Enemies[i]
        if ValidTarget(enemy, 2000 + 1200*GetData(_R).level) and GetDistanceSqr(pos, enemy.pos) <= range * range then
          if RTarget == nil then
            RTarget = enemy
          elseif GetHP2(enemy) - self.R.Damage(enemy) * self.R.Count < GetHP2(RTarget) - self.R.Damage(RTarget) * self.R.Count then
            RTarget = enemy
          end
        end
      end
    return RTarget
end

--[[-----------Katarina Plugin Load-----------]]--
class "NS_Katarina"
function NS_Katarina:__init()
    self:CreateMenu()
    self:LoadVariables()
    AddCB("Tick", function() self:Tick() end)
    AddCB("Draw", function() self:Drawings() end)
    AddCB("ProcessSpell", function(unit, spell) self:CheckAttack(unit, spell) end)
    AddCB("UpdateBuff", function(unit, buff) self:UpdateBuff(unit, buff) end)
    AddCB("RemoveBuff", function(unit, buff) self:RemoveBuff(unit, buff) end)
    AddCB("ObjectLoad", function(obj) self:CreateObj(obj) end)
    AddCB("CreateObj", function(obj) self:CreateObj(obj) end)
    AddCB("DeleteObj", function(obj) self:DeleteObj(obj) end)
end

function NS_Katarina:LoadVariables()
    self.check = { Q = { }, R = false, LastCastTime = 0, wards = { }, cast = true }
    self.Q = { Range = GetData(_Q).range, Speed = 1500,           Delay = 0.25, Damage = function(unit) return CalcDmg(2, unit, 35 + 25*GetData(_Q).level + 0.45*myHero.ap) end, time = { last = 0, unit = { sPos = nil, obj = nil} }}
    self.W = { Range = GetData(_W).range, Speed = huge,      Delay = 0.3,  Damage = function(unit) return CalcDmg(2, unit, 5 + 35*GetData(_W).level + 0.25*myHero.ap + 0.6*myHero.totalDamage) end, Width = 375}
    self.E = { Range = GetData(_E).range, Damage = function(unit) return CalcDmg(2, unit, 10 + 30*GetData(_E).level + 0.25*myHero.ap) end}
    self.R = { Range = GetData(_R).range, Damage = function(unit) return CalcDmg(2, unit, 150 + 200*GetData(_R).level + 2.5*myHero.ap + 3.75*myHero.totalDamage) end}

    self.HPBar  = DrawDmgOnHPBar(self.cfg.dw, {ARGB(200, 89, 0 ,179), ARGB(200, 0, 245, 255), ARGB(200, 186, 85, 211), ARGB(200, 0, 217, 108)}, {"R", "Q", "W", "E"})
    self.Q.Draw = DCircle(self.cfg.dw, "Draw Q Range", self.Q.Range, ARGB(150, 0, 245, 255))
    self.W.Draw = DCircle(self.cfg.dw, "Draw W Range", self.W.Range, ARGB(150, 0, 217, 108))
    self.E.Draw = DCircle(self.cfg.dw, "Draw E Range", self.E.Range, ARGB(150, 255, 255, 0))
    self.R.Draw = DCircle(self.cfg.dw, "Draw R Range", self.R.Range, ARGB(255, 186, 85, 211))

    self.Target = ChallengerTargetSelector(self.E.Range, 2, false, nil, false, self.cfg)
    self.Target.Menu.TargetSelector.TargetingMode.callback = function(id) self.Target.Mode = id end
    self.C = MinionManager2(self.E.Range, self.E.Range)
end

function NS_Katarina:CreateMenu()
 self.cfg = MenuConfig("NS_Katarina", "[NEET Series] - Katarina")
    self.cfg:Info("info", "Scripts Version: "..NEETSeries_Version)

    --[[ Q Settings ]]--
    AddMenu(self.cfg, "Q", "Q Settings", {true, true, true, true, true, true})
    self.cfg.Q:Boolean("Ahr", "Auto Q Harass", false)

    --[[ W Settings ]]--
    AddMenu(self.cfg, "W", "W Settings", {true, true, true, true, true, true})
    self.cfg.W:Slider("h", "W LaneClear if hit Minions >= ", 2, 1, 10, 1)
    self.cfg.W:Boolean("Ahr", "Auto W Harass", false)

    --[[ E Settings ]]--
    AddMenu(self.cfg, "E", "E Settings", {true, true, true, true, true, true})
    self.cfg.E:Boolean("Slc", "LaneClear Safe E", true)
    self.cfg.E:Boolean("Slh", "LastHit Safe E", true)
    DelayAction(function()
      for i = 1, C do
        self.cfg.E:Boolean("Oncb_"..Enemies[i].charName, "Combo - Use E on "..Enemies[i].charName, true)
        self.cfg.E:Boolean("Onhr_"..Enemies[i].charName, "Harass - Use E on "..Enemies[i].charName, false)
      end
    end, 1)

    --[[ Ignite Settings ]]--
    if Ignite then AddMenu(self.cfg, "Ignite", "Ignite Settings", {false, false, false, false, true, false}) end

    --[[ Ultimate Settings ]]--
    self.cfg:Boolean("R", "Use R in Combo", true)

    --[[ Drawings Menu ]]--
    self.cfg:Menu("dw", "Drawings Mode")
        self.cfg.dw:Boolean("DmgInfo", "Draw Dmg Info", true)

    --[[ Misc Menu ]]--
    self.cfg:Menu("misc", "Misc Mode")
      self.cfg.misc:Menu("J", "E Jump Setting")
        self.cfg.misc.J:Boolean("K", "Enable Auto Jump to KS", true)
        self.cfg.misc.J:KeyBinding("F", "Flee - AutoJump (G)", 71)
        self.cfg.misc.J:Boolean("P", "Put ward at maxRange", true)
        self.cfg.misc.J:Info("if1", "Jump Priority: Minion -> Hero -> Ward")
      self.cfg.misc:Menu("D", "Setting Spells Delay")
        self.cfg.misc.D:Slider("Q", "Q Delay (ms)", 0, 0, 1000, 1)
        self.cfg.misc.D:Slider("W", "W Delay (ms)", 0, 0, 1000, 1)
        self.cfg.misc.D:Slider("E", "E Delay (ms)", 100, 0, 1000, 1)
      SetSkin(self.cfg.misc, {"Classic", "Mercenary", "Red Card", "Bilgewater", "Kitty Cat", "High Command", "Sandstorm", "Slay Belle", "Warring Kingdoms", "Disable"})
    PermaShow(self.cfg.misc.J.F)
end

function NS_Katarina:Checking()
    if self.check.R and (self:KillCheck() or EnemiesAround(myHero.pos, 600) == 0) then Mix:BlockOrb(false) end
    for i = 1, C do
	local enemy = Enemies[i]
      if ValidTarget(enemy, 3000) and self.HPBar[i] then
        self.HPBar[i]:SetValue(1, enemy, self.R.Damage(enemy), IsSReady(_R))
        self.HPBar[i]:SetValue(2, enemy, self.Q.Damage(enemy), IsSReady(_Q))
        self.HPBar[i]:SetValue(3, enemy, self.W.Damage(enemy), IsSReady(_W))
        self.HPBar[i]:SetValue(4, enemy, self.E.Damage(enemy), IsSReady(_E))
        self.HPBar[i]:CheckValue()
      end
    end
end

function NS_Katarina:CastQ(target)
    if not ValidTarget(target, self.Q.Range) or os.clock() - self.check.LastCastTime < self.cfg.misc.D.Q:Value()*0.001 then return end
      CastTargetSpell(target, _Q)
end

function NS_Katarina:CastW(target)
    if not ValidTarget(target, self.W.Range) or os.clock() - self.check.LastCastTime < self.cfg.misc.D.W:Value()*0.001 then return end
      CastSpell(_W)
end

function NS_Katarina:CastE(target)
    if not ValidTarget(target, self.E.Range) then return end
     if (IsReady(_Q) and ValidTarget(target, self.Q.Range) and self.Q.time.unit.obj and target == self.Q.time.unit.obj and os.clock() - self.Q.time.last >= GetDistance(self.Q.time.unit.sPos, self.Q.time.unit.obj.pos)/1800) or IsReady(_Q) == false or GetDistance(target.pos) > self.Q.Range then
      if os.clock() - self.check.LastCastTime > self.cfg.misc.D.E:Value()*0.001 then CastTargetSpell(target, _E) end
     end
end

function NS_Katarina:CastR(target)
    if IsReady(_Q) or IsReady(_W) or IsReady(_E) or not ValidTarget(target, 470) then return end
      if GetHP2(target) + target.hpRegen*2.5 < self.R.Damage(target) then CastSpell(_R) end
end

function NS_Katarina:Tick()
   if myHero.dead or not Enemies[C] then return end
    self:Checking()
    local target = self.Target:GetTarget()
    if Mix:Mode() == "Combo" and target and not self.check.R then
      if IsReady(_Q) and self.cfg.Q.cb:Value() then self:CastQ(target) end
      if IsReady(_W) and self.cfg.W.cb:Value() then self:CastW(target) end
      if IsReady(_E) and self.cfg.E.cb:Value() and self.cfg.E["Oncb_"..target.charName]:Value() then
        if not IsReady(_Q) and not IsReady(_W) then self:CastE(target) end
        if (IsReady(_Q) or IsReady(_W)) and GetDistance(target.pos) > 500 then self:CastE(target) end
      end
      if IsReady(_R) and self.cfg.R:Value() then self:CastR(target) end
    end

    if Mix:Mode() == "Harass" and target and not self.check.R then
      if IsReady(_Q) and self.cfg.Q.hr:Value() then self:CastQ(target) end
      if IsReady(_W) and self.cfg.W.hr:Value() then self:CastW(target) end
      if IsReady(_E) and self.cfg.E.hr:Value() and self.cfg.E["Onhr_"..target.charName]:Value() then
        if not IsReady(_Q) and not IsReady(_W) then self:CastE(target) end
        if (IsReady(_Q) or IsReady(_W)) and GetDistance(target.pos) > 500 then self:CastE(target) end
      end
    end
      if IsReady(_Q) and not self.check.R and self.cfg.Q.Ahr:Value() and target then self:CastQ(target) end
      if IsReady(_W) and not self.check.R and self.cfg.W.Ahr:Value() and target then self:CastW(target) end

    if Mix:Mode() == "LastHit" then
       self.C:Update()
       self:LastHit()
    end

    if Mix:Mode() == "LaneClear" then
      self.C:Update()
      self:LaneClear()
      self:JungleClear()
    end

    if self.cfg.misc.J.F:Value() then self:Flee() end
    self:KillSteal()
    if IsReady(_E) and self.cfg.misc.J.K:Value() and not self.check.R and EnemiesAround(myHero.pos, self.E.Range) == 0 and EnemiesAround(myHero.pos, 1270) > 0 and Mix:Mode() == "Combo" then self:WardJumpKill() end
end

function NS_Katarina:Flee()
    Mix:Move()
    if IsReady(_E) and self:GetJumpTarget() then CastTargetSpell(self:GetJumpTarget(), _E) end
end

function NS_Katarina:WardJumpKill()
    for i = 1, C do
    local enemy = Enemies[i]
      if GetDistance(enemy.pos) > self.E.Range and ((IsReady(_W) and ValidTarget(enemy, 990) and self.W.Damage(enemy) + self:QBuff(enemy) > GetHP2(enemy) + enemy.hpRegen) or (IsReady(_Q) and ValidTarget(enemy, 1265) and self.Q.Damage(enemy) > GetHP2(enemy) + enemy.hpRegen*(0.2+GetDistance(enemy.pos)/1800))) then
        local jump = self:GetJumpTarget()
        if jump and ((IsReady(_W) and GetDistance(jump, target) < self.W.Range) or (IsReady(_Q) and GetDistance(jump, target) < self.Q.Range)) then
          CastTargetSpell(jump, _E)
        end
      end
    end
end

function NS_Katarina:KillSteal()
    local enemy = self.Target:GetTarget()
	if not enemy then return end
     if Ignite and IsReady(Ignite) and self.cfg.Ignite.ks:Value() and ValidTarget(enemy, 600) then
      local hp, dmg = Mix:HealthPredict(enemy, 2500, "OW") + enemy.hpRegen*2.5 + enemy.shieldAD, 50 + 20*myHero.level
      if hp > 0 and dmg > hp then CastTargetSpell(enemy, Ignite) end
     end

     if IsReady(_Q) and self.cfg.Q.ks:Value() and ValidTarget(enemy, self.Q.Range) then
       local HP = GetHP2(enemy) + enemy.hpRegen*(min(1, 0.2+GetDistance(enemy.pos)/1800))
       local WDmg = (IsReady(_W) and (IsReady(_E) or ValidTarget(enemy, self.W.Range))) and self.W.Damage(enemy) or 0
        if HP < WDmg + self.Q.Damage(enemy) + self:QBuff(enemy) then self:CastQ(enemy) end
     end

     if IsReady(_W) and self.cfg.W.ks:Value()and ValidTarget(enemy, self.W.Range) then
       local HP = GetHP2(enemy) + enemy.hpRegen
       local QDmg = (IsReady(_Q) and (IsReady(_E) or ValidTarget(enemy, self.Q.Range))) and self.Q.Damage(enemy) or 0
        if HP < QDmg + self.W.Damage(enemy) + self:QBuff(enemy) then self:CastW(enemy) end
     end

     if IsReady(_E) and self.cfg.E.ks:Value() then
       local HP = GetHP2(enemy) + enemy.hpRegen
        if HP < self:DamageCheck(enemy) then self:CastE(enemy) end
     end
end

function NS_Katarina:LastHit()
    for _, m in pairs(self.C.tminion) do
      if IsReady(_Q) and self.cfg.Q.lh:Value() and self.Q.Damage(m) + self:QBuff(m) > Mix:HealthPredict(m, GetDistance(m)/1.8 + 200, "OW") then
        CastTargetSpell(m, _Q)
      end
      if IsReady(_W) and self.cfg.W.lh:Value() and ValidTarget(m, self.W.Range) and self.W.Damage(m) + self:QBuff(m) > m.health then
        CastSpell(_W)
      end
      if IsReady(_E) and self.cfg.E.lh:Value() and m.health < self.E.Damage(m) + self:QBuff(m) then
        if self.cfg.E.Slh:Value() and (EnemiesAround(m.pos, 1000) == 0 or GetDistance(m.pos) < 300) then CastTargetSpell(m, _E)
        elseif not self.cfg.E.Slh:Value() then CastTargetSpell(m, _E) end
      end
    end
end

function NS_Katarina:LaneClear()
    for _, m in pairs(self.C.tminion) do
      if IsReady(_W) and self.cfg.W.lc:Value() and ValidTarget(m, self.W.Range) then
        if MinionsAround(myHero.pos, self.W.Range, MINION_ENEMY) >= self.cfg.W.h:Value() or m.health < self.W.Damage(m) then CastSpell(_W) end
      end
      if IsReady(_Q) and self.cfg.Q.lc:Value() and ValidTarget(m, self.Q.Range) then
        CastTargetSpell(m, _Q)
      end
      if IsReady(_E) and self.cfg.E.lc:Value() and m.health < self.E.Damage(m) + self:QBuff(m) then
        if self.cfg.E.Slc:Value() and (EnemiesAround(m.pos, 1000) == 0 or GetDistance(m.pos) < 300) then CastTargetSpell(m, _E)
        elseif not self.cfg.E.Slc:Value() then CastTargetSpell(m, _E) end
      end
    end
end

function NS_Katarina:JungleClear()
    if not self.C.tmob[1] then return end
    local mob = self.C.tmob[1]
    if IsReady(_Q) and self.cfg.Q.jc:Value() and ValidTarget(mob, self.Q.Range) then
      self:CastQ(mob)
    end
    if IsReady(_W) and self.cfg.W.jc:Value() and ValidTarget(mob, self.W.Range) then
      self:CastW(mob)
    end
    if IsReady(_E) and self.cfg.E.jc:Value() and ValidTarget(mob, self.E.Range) then
      self:CastE(mob)
    end
end

function NS_Katarina:Drawings()
   if myHero.dead or not Enemies[C] then return end
   self:DrawRange()
   if self.cfg.dw.DmgInfo:Value() then self:DmgCheck() end
   self:DmgHPBar()
end

function NS_Katarina:DrawRange()
    if IsSReady(_Q) then self.Q.Draw:Draw(myHero.pos) end
    if IsSReady(_W) then self.W.Draw:Draw(myHero.pos) end
    if IsSReady(_E) then self.E.Draw:Draw(myHero.pos) end
    if IsSReady(_R) or self.check.R then self.R.Draw:Draw(myHero.pos) end
end

function NS_Katarina:DmgHPBar()
    for i = 1, C do
      if ValidTarget(Enemies[i], 3000) and self.HPBar[i] then
        self.HPBar[i]:Draw()
     end
    end
end

function NS_Katarina:DmgCheck()
    local Draw = function(target, text, status)
      if status == "KILL" then
        DrawText3D(text, target.pos.x, target.pos.y, target.pos.z, 16, GoS.Red, true)
        DrawText3D(text, target.pos.x, target.pos.y, target.pos.z, 16, GoS.White, true)
      elseif status == "Can't Kill" then
        local QDmg, WDmg, EDmg, RDmg, QBonus = IsReady(_Q) and self.Q.Damage(target) or 0, IsReady(_W) and self.W.Damage(target) or 0, IsReady(_E) and self.E.Damage(target) or 0, (IsSReady(_R) or self.check.R) and self.R.Damage(target) or 0, self:QBuff(target)
        local dmg = text == "Full Combo + Ignite =" and (QDmg + WDmg + EDmg + RDmg + QBonus + 20*GetLevel(myHero)+50) or (QDmg + WDmg + EDmg + RDmg + QBonus)
        DrawText3D(string.format("%s %.1f%s", text, math.floor(dmg*100/(GetHP2(target) + target.hpRegen*2)), '%'), target.pos.x, target.pos.y, target.pos.z, 16, GoS.White, true)
      end
    end
    for i = 1, C do
    local enemy = Enemies[i]
      if ValidTarget(enemy, 3000) then
       local HP, QDmg, WDmg, EDmg, RDmg, Ignitee, QBonus = GetHP2(enemy) + enemy.hpRegen*2, IsReady(_Q) and self.Q.Damage(enemy) or 0, IsReady(_W) and self.W.Damage(enemy) or 0, IsReady(_E) and self.E.Damage(enemy) or 0, (IsSReady(_R) or self.check.R) and self.R.Damage(enemy) or 0, 20*GetLevel(myHero)+50 or 0, self:QBuff(enemy)
       local IgniteCheck = (Ignite and IsReady(Ignite)) and true or false
        if HP < EDmg + QBonus then Draw(enemy, "E = Kill!", "KILL")
        elseif HP < WDmg + QBonus then Draw(enemy, "W = Kill!", "KILL")
        elseif HP < QDmg + QBonus then Draw(enemy, "Q = Kill!", "KILL")
        elseif HP < EDmg + QBonus + WDmg then Draw(enemy, "E + W = Kill!", "KILL")
        elseif HP < EDmg + QBonus + QDmg then Draw(enemy, "E + Q = Kill!", "KILL")
        elseif HP < WDmg + QBonus + QDmg then Draw(enemy, "W + Q = Kill!", "KILL")
        elseif HP < QDmg + QBonus + WDmg + EDmg then Draw(enemy, "Q + W + E = Kill!", "KILL")
        elseif IgniteCheck and HP < Ignitee then Draw(enemy, "Ignite = Kill!", "KILL")
        elseif IgniteCheck and HP < Ignitee + QBonus + EDmg then Draw(enemy, "Ignite + E = Kill!", "KILL")
        elseif IgniteCheck and HP < Ignitee + QBonus + WDmg then Draw(enemy, "Ignite + W = Kill!")
        elseif IgniteCheck and HP < Ignitee + QBonus + QDmg then Draw(enemy, "Ignite + Q = Kill!", "KILL")
        elseif IgniteCheck and HP < Ignitee + QBonus + EDmg + WDmg then Draw(enemy, "Ignite + E + W = Kill!", "KILL")
        elseif IgniteCheck and HP < Ignitee + QBonus + EDmg + QDmg then Draw(enemy, "Ignite + E + Q = Kill!", "KILL")
        elseif IgniteCheck and HP < Ignitee + QBonus + WDmg + QDmg then Draw(enemy, "Ignite + W + Q = Kill!", "KILL")
        elseif IgniteCheck and HP < Ignitee + QBonus + QDmg + WDmg + EDmg then Draw(enemy, "Ignite + Q + W + E = Kill!", "KILL")
        elseif HP < RDmg + QBonus then Draw(enemy, "R = Kill!", "KILL")
        elseif HP < RDmg + QBonus + EDmg then Draw(enemy, "R + E = Kill!", "KILL")
        elseif HP < RDmg + QBonus + WDmg then Draw(enemy, "R + W = Kill!", "KILL")
        elseif HP < EDmg + QBonus + QDmg then Draw(enemy, "R + Q = Kill!", "KILL")
        elseif HP < RDmg + QBonus + EDmg + WDmg then Draw(enemy, "R + E + W = Kill!", "KILL")
        elseif HP < RDmg + QBonus + EDmg + QDmg then Draw(enemy, "R + E + Q = Kill!", "KILL")
        elseif HP < RDmg + QBonus + WDmg + QDmg then Draw(enemy, "R + W + Q = Kill!", "KILL")
        elseif HP < RDmg + QBonus + QDmg + WDmg + EDmg then Draw(enemy, "R + Q + W + E = Kill!", "KILL")
        elseif IgniteCheck and HP < RDmg + QBonus + Ignitee then Draw(enemy, "R + Ignite = Kill!", "KILL")
        elseif IgniteCheck and HP < RDmg + QBonus + Ignitee + EDmg then Draw(enemy, "R + Ignite + E = Kill!", "KILL")
        elseif IgniteCheck and HP < RDmg + QBonus + Ignitee + WDmg then Draw(enemy, "R + Ignite + W = Kill!")
        elseif IgniteCheck and HP < RDmg + QBonus + Ignitee + QDmg then Draw(enemy, "R + Ignite + Q = Kill!", "KILL")
        elseif IgniteCheck and HP < RDmg + QBonus + Ignitee + EDmg + WDmg then Draw(enemy, "R + Ignite + E + W = Kill!", "KILL")
        elseif IgniteCheck and HP < RDmg + QBonus + Ignitee + EDmg + QDmg then Draw(enemy, "R + Ignite + E + Q = Kill!", "KILL")
        elseif IgniteCheck and HP < RDmg + QBonus + Ignitee + WDmg + QDmg then Draw(enemy, "R + Ignite + W + Q = Kill!", "KILL")
        elseif IgniteCheck and HP < RDmg + QBonus + Ignitee + QDmg + WDmg + EDmg then Draw(enemy, "R + Ignite + Q + W + E = Kill!", "KILL")
        else
         if IgniteCheck then Draw(enemy, "Full Combo + Ignite =", "Can't Kill") else Draw(enemy, "Full Combo =", "Can't Kill") end
        end
      end
    end
end

function NS_Katarina:QBuff(unit)
    if IsReady(_Q) or self.check.Q[unit.networkID] then return CalcDmg(2, unit, 15*GetData(_Q).level + 0.2*myHero.ap) end
    return 0
end

function NS_Katarina:DamageCheck(unit)
    local QDmg = IsReady(_Q) and self.Q.Damage(unit) or 0
    local WDmg = IsReady(_W) and self.W.Damage(unit) or 0
    local EDmg = IsReady(_E) and self.E.Damage(unit) or 0
      return QDmg + WDmg + EDmg + self:QBuff(unit)
end

function NS_Katarina:CountCheck()
    local count = 0
    for i = 1, C do
    local enemy = Enemies[i]
      if enemy and ValidTarget(enemy) and GetDistanceSqr(enemy.pos) <= self.E.Range * self.E.Range and GetHP2(enemy) + enemy.hpRegen < self:DamageCheck(enemy) and not enemy.dead then
          count = count + 1
      end
    end
        return count
end

function NS_Katarina:KillCheck()
    if (EnemiesAround(myHero.pos, self.E.Range) == 1 and self:CountCheck() == 1) or (EnemiesAround(myHero.pos, self.E.Range) > 1 and self:CountCheck() > 1) then return true end
        return false
end

function NS_Katarina:GetJumpTarget()
    local mPos = Vector(GetMousePos())
      if MinionsAround(mPos, 130, MINION_ENEMY) > 0 then
        return self:GetJump(minionManager.objects, MINION_ENEMY)
      elseif MinionsAround(mPos, 120, 300) > 0 then
        return self:GetJump(minionManager.objects, 300)
      elseif EnemiesAround(mPos, 130) > 0 then
        return self:GetJump(Enemies, MINION_ENEMY)
      elseif MinionsAround(mPos, 130, MINION_ALLY) > 0 then
        return self:GetJump(minionManager.objects, MINION_ALLY)
      elseif AlliesAround(mPos, 130) > 0 then
        return self:GetJump(GetAllyHeroes(), MINION_ALLY)
      else
        if CountObjectsNearPos(mPos, nil, 130, self.check.wards) > 0 then return self:GetJump(self.check.wards)
        elseif CountObjectsNearPos(Vector(myHero), nil, self.E.Range, self.check.wards) > 0 and GetDistanceSqr(mPos, self:GetJump(self.check.wards)) < GetDistanceSqr(mPos) then return self:GetJump(self.check.wards)
        elseif CountObjectsNearPos(mPos, nil, 300, self.check.wards) == 0 then self:PutWard(mPos)
        end
      end
        return nil
end

function NS_Katarina:GetJump(Objects, Team)
    local mPos, target = Vector(GetMousePos()), nil
    for _, m in pairs(Objects) do
      if (not Team or m.team == Team) and IsInDistance(m, self.E.Range) and m.visible and m.health > 0 and (not target or GetDistanceSqr(m, mPos) < GetDistanceSqr(target, mPos)) then
        target = m
      end
    end
        return target
end

function NS_Katarina:PutWard(Position)
    local Yellow, Sight, Vision = Mix:GetWardSlot("Yellow"), Mix:GetWardSlot("Sight"), Mix:GetWardSlot("Vision")
    local Pos = self.cfg.misc.J.P:Value() and Vector(myHero.pos + Vector(Position - myHero.pos):normalized()*590) or Vector(myHero.pos + Vector(Position - myHero.pos):normalized()*min(GetDistance(Position), 590))
    if Yellow and IsReady(Yellow) then
      CastSkillShot(Yellow, Pos)
    elseif Sight and IsReady(Sight) then
      CastSkillShot(Sight, Pos)
    elseif Vision and IsReady(Vision) then
      CastSkillShot(Vision, Pos)
    end
end

function NS_Katarina:UpdateBuff(unit, buff)
    if unit == myHero and buff.Name:lower() == "katarinarsound" then
      self.check.R = true
      Mix:BlockOrb(true)
    end
    if buff.Name:lower() == "katarinaqmark" and unit.team == MINION_ENEMY and ValidTarget(unit, 1500) then
      self.check.Q[unit.networkID] = true
    end
end

function NS_Katarina:RemoveBuff(unit, buff)
    if unit == myHero and buff.Name:lower() == "katarinarsound" then
      self.check.R = false
      Mix:BlockOrb(false)
    end
    if buff.Name:lower() == "katarinaqmark" and unit.team == MINION_ENEMY and ValidTarget(unit, 1500) then
      table.remove(self.check.Q, unit.networkID)
    end
end

function NS_Katarina:CheckAttack(unit, spell)
    if unit.networkID == myHero.networkID and unit.dead == false then
      if spell.name:lower() == "katarinaq" then
        self.check.LastCastTime = os.clock() + 0.25
        self.Q.time.last = os.clock()
        self.Q.time.unit.sPos = spell.startPos
        self.Q.time.unit.obj = spell.target
      elseif spell.name:lower() == "katarinaw" then
        self.check.LastCastTime = os.clock() + 0.2
      elseif spell.name:lower() == "katarinae" then
        self.check.LastCastTime = os.clock() + 0.15
      elseif spell.name:lower() == "katarinar" and not self.check.R then
        self.check.R = true
        Mix:BlockOrb(true)
      end
    end
end

function NS_Katarina:CreateObj(obj)
    if WardCheck[obj.charName] then self.check.wards[#self.check.wards + 1] = obj end
end

function NS_Katarina:DeleteObj(obj)
    if WardCheck[obj.charName] then
      for w, ward in pairs(self.check.wards) do
        if ward == obj then table.remove(self.check.wards, w) end
      end
    end
end

--[[-----------Kog'Maw Plugin Load-----------]]--
class "NS_KogMaw"
function NS_KogMaw:__init()
    self:CreateMenu()
    self:LoadVariables()
    self:ExtraLoad()
    AddCB("Tick", function() self:Tick() end)
    AddCB("Draw", function() self:Drawings() end)
    AddCB("ProcessSpellComplete", function(unit, spell) self:CheckAttack(unit, spell) end)
    AddCB("UpdateBuff", function(unit, buff) self:UpdateBuff(unit, buff) end)
    AddCB("RemoveBuff", function(unit, buff) self:RemoveBuff(unit, buff) end)
end

function NS_KogMaw:LoadVariables()
    self.Q = { Range = GetData(_Q).range,                                 Speed = 1450,      Delay = 0.25, Width = 80,  Damage = function(unit) return CalcDmg(2, unit, 30 + 50*GetData(_Q).level + 0.5*myHero.ap) end}
    self.E = { Range = GetData(_E).range,                                 Speed = 1100,      Delay = 0.25, Width = 120, Damage = function(unit) return CalcDmg(2, unit, 10 + 50*GetData(_E).level + 0.7*myHero.ap) end}
    self.R = { Range = function() return 900 + 300*GetData(_R).level end, Speed = huge, Delay = 1, Width = 235, Damage = function(unit) local bonus = GetPercentHP(unit) < 25 and 3 or (GetPercentHP(unit) >= 25 and GetPercentHP(unit) < 50) and 2 or 1 return CalcDmg(2, unit, bonus*(30 + 40*GetData(_R).level + 0.25*myHero.ap)) end, Count = 1}
    self.C = MinionManager2(self.E.Range, self.E.Range)
    self.D = {CanCast = true, WBuff = GotBuff(myHero, "KogMawBioArcaneBarrage") > 0}
end

function NS_KogMaw:CreateMenu()
  self.cfg = MenuConfig("NS_KogMaw", "[NEET Series] - Kog'Maw")
    self.cfg:Info("info", "Scripts Version: "..NEETSeries_Version)

    --[[ Q Settings ]]--
    AddMenu(self.cfg, "Q", "Q Settings", {true, true, false, true, true, false}, 15)

    --[[ W Settings ]]--
    AddMenu(self.cfg, "W", "W Settings", {true, false, false, false, false, false})

    --[[ E Settings ]]--
    AddMenu(self.cfg, "E", "E Settings", {true, true, true, true, true, false}, 15)
    self.cfg.E:Slider("h", "LaneClear if hit minions >=", 3, 1, 10, 1)

    --[[ Ignite Settings ]]--
    if Ignite then AddMenu(self.cfg, "Ignite", "Ignite Settings", {false, false, false, false, true, false}) end

    --[[ R Settings ]]--
    AddMenu(self.cfg, "R", "R Settings", {true, true, false, true, false, false}, 15)
    self.cfg.R:Boolean("lc", "Use in LaneClear", false)
    self.cfg.R:Slider("MPlc", "Enable on LaneClear if %MP >=", 15, 1, 100, 1)
    self.cfg.R:Slider("h", "Use R if hit Minions >=", 3, 1, 10, 1)
    self.cfg.R:Boolean("ec", "R LaneClear if no enemy in 1200 range", true)
    self.cfg.R:Boolean("ks", "Use in KillSteal", true)

    --[[ Drawings Menu ]]--
    self.cfg:Menu("dw", "Drawings Mode")

    --[[ Misc Menu ]]--
    self.cfg:Menu("misc", "Misc Mode")
      self.cfg.misc:Menu("rc", "Request Casting R")
        self.cfg.misc.rc:Boolean("R1", "R but save mana for W", true)
        self.cfg.misc.rc:Slider("R2", "Cast R if Stacks < x", 5, 1, 10, 1)
      self.cfg.misc:Menu("hc", "Spell HitChance")
        self.cfg.misc.hc:Slider("Q", "Q Hit-Chance", 25, 1, 100, 1, function(value) self.Q.Prediction:SetHitChance(value*0.01) end)
		self.cfg.misc.hc:Slider("E", "E Hit-Chance", 25, 1, 100, 1, function(value) self.E.Prediction:SetHitChance(value*0.01) end)
		self.cfg.misc.hc:Slider("R", "R Hit-Chance", 40, 1, 100, 1, function(value) self.R.R1Prediction:SetHitChance(value*0.01) self.R.R2Prediction:SetHitChance(value*0.01) self.R.R3Prediction:SetHitChance(value*0.01) end)
      self.cfg.misc:Menu("sme", "Block Move (depend on as)")
        self.cfg.misc.sme:Info("ifo1", "Dangerous: if distance to enemy <= 300")
        self.cfg.misc.sme:Info("ifo2", "Kite: if distance to enemy > 600")
        self.cfg.misc.sme:Info("ifo3", "BlockMove: Other case")
        self.cfg.misc.sme:Boolean("b1", "Enable block move check", true)
        self.cfg.misc.sme:Slider("b2", "Enable if AttackSpeed >=", 2.7, 2.5, 6, 0.1)
      self.cfg.misc:Boolean("sc", "Cast Spell after attack", true)
      SetSkin(self.cfg.misc, {"Classic", "Caterpillar", "Sonoran", "Monarch", "Reindeer", "Lion Dance", "Deep Sea", "Jurassic", "Battlecast", "Disable"})
end

function NS_KogMaw:ExtraLoad()
    self.Target = ChallengerTargetSelector(600, 1, true, nil, false, self.cfg)
    self.Target.Menu.TargetSelector.TargetingMode.callback = function(id) self.Target.Mode = id end

    self.HPBar  = DrawDmgOnHPBar(self.cfg.dw, {ARGB(200, 89, 0 ,179), ARGB(200, 0, 245, 255), ARGB(200, 0, 217, 108)}, {"R", "Q", "E"})
    self.Q.Draw = DCircle(self.cfg.dw, "Draw Q Range", self.Q.Range, ARGB(150, 0, 245, 255))
    self.WDraw  = DCircle(self.cfg.dw, "Draw W Range", 625 + 30*GetData(_W).level, ARGB(150, 186, 85, 211))
    self.E.Draw = DCircle(self.cfg.dw, "Draw E Range", self.E.Range, ARGB(150, 0, 217, 108))
    self.R.Draw = DCircle(self.cfg.dw, "Draw R Range", self.R.Range(), ARGB(150, 89, 0 ,179))

    self.Q.Prediction = Spells(_Q, self.Q.Delay, self.Q.Speed, self.Q.Width, self.Q.Range, true, 1, false, "linear", "Kog'Maw Q", self.cfg.misc.hc.Q:Value()*0.01)
    self.E.Prediction = Spells(_E, self.E.Delay, self.E.Speed, self.E.Width, self.E.Range, false, 0, true, "linear", "Kog'Maw E", self.cfg.misc.hc.E:Value()*0.01)
    self.R.R1Prediction = Spells(_R, self.R.Delay, self.R.Speed, self.R.Width, 1200, false, 0, true, "circular", "Kog'Maw RLvl1", self.cfg.misc.hc.R:Value()*0.01)
    self.R.R2Prediction = Spells(_R, self.R.Delay, self.R.Speed, self.R.Width, 1500, false, 0, true, "circular", "Kog'Maw RLvl2", self.cfg.misc.hc.R:Value()*0.01)
    self.R.R3Prediction = Spells(_R, self.R.Delay, self.R.Speed, self.R.Width, 1800, false, 0, true, "circular", "Kog'Maw RLvl3", self.cfg.misc.hc.R:Value()*0.01)
end

function NS_KogMaw:Updating()
    self.D.WRange = 625 + 30*GetData(_W).level
    if EnemiesAround(myHero.pos, self.D.WRange) == 0 then self.D.CanCast = true end
    for i = 1, C do
    local enemy = Enemies[i]
      if ValidTarget(enemy, 2000) and self.HPBar[i] then
        self.HPBar[i]:SetValue(1, enemy, self.R.Damage(enemy), IsSReady(_R))
        self.HPBar[i]:SetValue(2, enemy, self.Q.Damage(enemy), IsSReady(_Q))
        self.HPBar[i]:SetValue(3, enemy, self.E.Damage(enemy), IsSReady(_E))
        self.HPBar[i]:CheckValue()
      end
    end
    if ((IsReady(_W) and EnemiesAround(myHero.pos, self.D.WRange) == 0) or (IsReady(_W) == false and EnemiesAround(myHero.pos, 565) == 0)) then self.Target.range = self.E.Range end
    if IsReady(_R) then self.R.Draw:Update("Range", self.R.Range()) end
    if IsReady(_W) then self.WDraw:Update("Range", self.D.WRange) end
    Mix:ForceTarget(self.Target:GetTarget())
    if self.D.WBuff then
      self.Q.Prediction:UpdateValue("Delay", 0.125)
      self.E.Prediction:UpdateValue("Delay", 0.125)
      self.R.R1Prediction:UpdateValue("Delay", 0.875)
      self.R.R2Prediction:UpdateValue("Delay", 0.875)
      self.R.R3Prediction:UpdateValue("Delay", 0.875)
    else
      self.Q.Prediction:UpdateValue("Delay", 0.25)
      self.E.Prediction:UpdateValue("Delay", 0.25)
      self.R.R1Prediction:UpdateValue("Delay", 1)
      self.R.R2Prediction:UpdateValue("Delay", 1)
      self.R.R3Prediction:UpdateValue("Delay", 1)
    end
end

function NS_KogMaw:CastR(target)
   if not ValidTarget(target, self.R.Range()) then return end
    if GetData(_R).level == 1 then
     self.R.R1Prediction:Cast1(target)
    elseif GetData(_R).level == 2 then
     self.R.R2Prediction:Cast1(target)
    elseif GetData(_R).level == 3 then
     self.R.R3Prediction:Cast1(target)
    end
end

function NS_KogMaw:CastE(target)
   if not ValidTarget(target, self.E.Range) then return end
    self.E.Prediction:Cast1(target)
end

function NS_KogMaw:CastW()
    if (IsReady(_E) and EnemiesAround(myHero.pos, self.D.WRange) > 0) or (IsReady(_E) == false and EnemiesAround(myHero.pos, 600 + 25*GetData(_W).level) > 0) then CastSpell(_W) end
end

function NS_KogMaw:CastQ(target)
   if not ValidTarget(target, self.Q.Range) then return end
    self.Q.Prediction:Cast1(target)
end

function NS_KogMaw:Tick()
    if myHero.dead or not Enemies[C] then return end
    self:Updating()
    local target = self.Target:GetTarget()

    if target and self.cfg.misc.sme.b1:Value() and 0.625*myHero.attackSpeed >= self.cfg.misc.sme.b2:Value() and GetDistance(target) >= 300 and GetDistance(target) <= myHero.range - 85 then Mix:BlockMovement(true) else Mix:BlockMovement(false) end

    if Mix:Mode() == "Combo" and self.D.CanCast then
       if IsReady(_E) and self.cfg.E.cb:Value() then self:CastE(target) end
       if IsReady(_W) and self.cfg.W.cb:Value() then self:CastW() end
       if IsReady(_Q) and self.cfg.Q.cb:Value() then self:CastQ(target) end
       if IsReady(_R) and self.cfg.R.cb:Value() and self.cfg.misc.rc.R2:Value() > self.R.Count and ((self.cfg.misc.rc.R1:Value() and myHero.mana - 50*self.R.Count >= 40) or not self.cfg.misc.rc.R1:Value()) and self:GetRTarget() then self:CastR(self:GetRTarget()) end
    end

    if Mix:Mode() == "Harass" and self.D.CanCast then
       if IsReady(_E) and self.cfg.E.hr:Value() and ManaCheck(self.cfg.E.MPhr:Value()) then self:CastE(target) end
       if IsReady(_Q) and self.cfg.Q.hr:Value() and ManaCheck(self.cfg.Q.MPhr:Value()) then self:CastE(target) end
       if IsReady(_R) and self.cfg.R.hr:Value() and ManaCheck(self.cfg.R.MPhr:Value()) and self.cfg.misc.rc.R2:Value() > self.R.Count and ((self.cfg.misc.rc.R1:Value() and myHero.mana - 50*self.R.Count >= 40) or not self.cfg.misc.rc.R1:Value()) and self:GetRTarget() then self:CastR(self:GetRTarget()) end
    end

    if Mix:Mode() == "LaneClear" then
      self.C:Update()
      self:LaneClear()
      self:JungleClear()
    end

    self:KillSteal()
end

function NS_KogMaw:KillSteal()
    for i = 1, C do
    local enemy = Enemies[i]
     if Ignite and IsReady(Ignite) and self.cfg.Ignite.ks:Value() and ValidTarget(enemy, 600) then
      local hp, dmg = Mix:HealthPredict(enemy, 2500, "OW") + enemy.hpRegen*2.5 + enemy.shieldAD, 50 + 20*myHero.level
      if hp > 0 and dmg > hp then CastTargetSpell(enemy, Ignite) end
     end

     if IsReady(_Q) and self.cfg.Q.ks:Value() and ManaCheck(self.cfg.Q.MPks:Value()) and GetHP2(enemy) < self.Q.Damage(enemy) then
      self:CastQ(enemy)
     end

     if IsReady(_R) and self.cfg.R.ks:Value() and GetHP2(enemy) < self.R.Damage(enemy) then
      self:CastR(enemy)
     end

     if IsReady(_E) and self.cfg.E.ks:Value() and ManaCheck(self.cfg.E.MPks:Value()) and GetHP2(enemy) < self.E.Damage(enemy) then
      self:CastE(enemy)
     end
    end
end

function NS_KogMaw:LaneClear()
    if IsReady(_R) and self.cfg.R.lc:Value() and ManaCheck(self.cfg.R.MPlc:Value()) then
    if self.cfg.misc.rc.R2:Value() <= self.R.Count then return end
    if self.cfg.R.ec:Value() and EnemiesAround(myHero.pos, 1200) > 0 then return end
    if self.cfg.misc.rc.R1:Value() and myHero.mana - 50*self.R.Count < 40 then return end
    local RPos, RHit = GetFarmPosition2(self.R.Range(), self.R.Width, self.C.tminion)
       if RHit >= self.cfg.R.h:Value() then CastSkillShot(_R, RPos) end
    end
    if IsReady(_E) and self.cfg.E.lc:Value() and ManaCheck(self.cfg.E.MPlc:Value()) then
    local EPos, EHit = GetLineFarmPosition2(self.E.Range, self.E.Width, self.C.tminion)
       if EHit >= self.cfg.E.h:Value() then CastSkillShot(_E, EPos) end
    end
end

function NS_KogMaw:JungleClear()
    if not self.C.tmob[1] then return end
    local mob = self.C.tmob[1]
    if IsReady(_Q) and self.cfg.Q.jc:Value() and ManaCheck(self.cfg.Q.MPjc:Value()) and ValidTarget(mob, self.Q.Range) then
      CastSkillShot(_Q, Vector(mob))
    end
    if IsReady(_E) and self.cfg.E.jc:Value() and ManaCheck(self.cfg.E.MPjc:Value()) then
      CastSkillShot(_E, Vector(mob))
    end
    if IsReady(_R) and self.cfg.R.jc:Value() and ManaCheck(self.cfg.R.MPjc:Value()) and ValidTarget(mob, self.R.Range()) and self.cfg.misc.rc.R2:Value() > self.R.Count and ((self.cfg.misc.rc.R1:Value() and myHero.mana - 50*self.R.Count > 40) or not self.cfg.misc.rc.R1:Value()) then
      CastSkillShot(_R, Vector(mob))
    end
end

function NS_KogMaw:Drawings()
    if myHero.dead or not Enemies[C] then return end
    self:DmgHPBar()
    self:DrawRange()
end

function NS_KogMaw:DrawRange()
    local myPos = Vector(myHero)
    if IsSReady(_Q) then self.Q.Draw:Draw(myPos) end
    if IsSReady(_W) then self.WDraw:Draw(myPos) end
    if IsSReady(_E) then self.E.Draw:Draw(myPos) end
    if IsSReady(_R) then self.R.Draw:Draw(myPos) end
end

function NS_KogMaw:DmgHPBar()
    for i = 1, C do
      if ValidTarget(Enemies[i], self.R.Range()) and self.HPBar[i] then
        self.HPBar[i]:Draw()
     end
    end
end

function NS_KogMaw:GetRTarget()
    local RTarget = nil
      for i = 1, C do
        local enemy = Enemies[i]
        if ValidTarget(enemy, 900 + 300*myHero:GetSpellData(_R).level) and GetDistanceSqr(enemy.pos) <= self.R.Range() * self.R.Range() then
          if RTarget == nil then
            RTarget = enemy
          elseif GetHP2(enemy) - self.R.Damage(enemy) < GetHP2(RTarget) - self.R.Damage(RTarget) then
            RTarget = enemy
          end
        end
      end
    return RTarget
end

function NS_KogMaw:CheckAttack(unit, spell)
    if self.cfg.misc.sc:Value() and unit == myHero and spell.name:lower():find("attack") then
        self.D.CanCast = true
        DelayAction(function() self.D.CanCast = false end, 0.1)
    end
end

function NS_KogMaw:UpdateBuff(unit, buff)
    if unit == myHero then
      if buff.Name:lower() == "kogmawlivingartillerycost" then self.R.Count = buff.Count end
      if buff.Name:lower() == "kogmawbioarcanebarrage" then self.D.WBuff = true self.Target.range = self.D.WRange end
    end
end

function NS_KogMaw:RemoveBuff(unit, buff)
    if unit == myHero then
      if buff.Name:lower() == "kogmawlivingartillerycost" then self.R.Count = 1 end
      if buff.Name:lower() == "kogmawbioarcanebarrage" then self.D.WBuff = false self.Target.range = 600 end
    end
end

--[[-----------Annie Plugin Load-----------]]--
class "NS_Annie"
function NS_Annie:__init()
    self:LoadVariables()
    self:CreateMenu()
    self:ExtraLoad()
    AddCB("Tick", function() self:Tick() end)
    AddCB("Draw", function() self:Drawings() end)
    AddCB("ProcessSpell", function(unit, spell) self:CheckSpell(unit, spell) end)
    AddCB("ProcessSpellComplete", function(unit, spell) self:UseE(unit, spell) end)
    AddCB("UpdateBuff", function(unit, buff) self:UpdateBuff(unit, buff) end)
    AddCB("RemoveBuff", function(unit, buff) self:RemoveBuff(unit, buff) end)
end

function NS_Annie:LoadVariables()
    self.Q = { Range = GetData(_Q).range, Speed = 1500, Delay = 0.25, Damage = function(unit) return CalcDmg(2, unit, 45 + 35*GetData(_Q).level + 0.8*myHero.ap) end }
    self.W = { Range = GetData(_W).range, Speed = huge, Delay = 0.25, Width = 80,  Damage = function(unit) return CalcDmg(2, unit, 25 + 45*GetData(_W).level + 0.85*myHero.ap) end }
    self.R = { Range = GetData(_R).range, Speed = huge, Delay = 0.25, Width = 250, Damage = function(unit) return CalcDmg(2, unit, 25 + 130*GetData(_R).level + 0.7*myHero.ap) end }
    self.D = { Flash = Mix:GetOtherSlot("Flash"), passive = GotBuff(myHero, "pyromania"), stun = GotBuff(myHero, "pyromania_particle") > 0}
    self.C = MinionManager2(self.Q.Range, self.Q.Range)
end

function NS_Annie:CreateMenu()
  self.cfg = MenuConfig("NS_Annie", "[NEET Series] - Annie")
    self.cfg:Info("info", "Scripts Version: "..NEETSeries_Version)

    --[[ Q Settings ]]--
    AddMenu(self.cfg, "Q", "Q Settings", {true, true, true, true, true, true}, 15)
    self.cfg.Q:DropDown("c", "LaneClear Mode:", 1, {"LastHit", "Always Cast"})
    self.cfg.Q:Boolean("s1", "Harass but save stun", true)
    self.cfg.Q:Boolean("s2", "LaneClear but save stun", true)
    self.cfg.Q:Boolean("s3", "LastHit but save stun", false)

    --[[ W Settings ]]--
    AddMenu(self.cfg, "W", "W Settings", {true, true, true, true, true, false}, 15)
    self.cfg.W:Slider("h", "LaneClear if hit minions >=", 3, 1, 10, 1)
    self.cfg.W:Boolean("s", "Harass/LC but save stun", true)	

    --[[ E Settings ]]--
    AddMenu(self.cfg, "E", "E Settings", {true, false, false, false, false, false})

    --[[ Ignite Settings ]]--
    if Ignite then AddMenu(self.cfg, "Ignite", "Ignite Settings", {false, false, false, false, true, false}) end

    --[[ Ultimate Menu ]]--
    self.cfg:Menu("ult", "Ultimate Settings")
      self.cfg.ult:DropDown("u1", "Casting Mode", 1, {"If Killable", "If can stun x enemies"})
      self.cfg.ult:Slider("u2", "R if can stun enemies >=", 2, 1, 5, 1)
      self.cfg.ult:KeyBinding("u3", "Use R if Combo Active (G)", 71, true)
      if self.D.Flash ~= nil then
        self.cfg.ult:Menu("fult", "Flash and Ultimate")
        self.cfg.ult.fult:Boolean("eb1", "Enable?", false)
        self.cfg.ult.fult:DropDown("eb2", "Active Mode: ", 1, {"Use when Combo Active", "Auto Use"})
        self.cfg.ult.fult:Slider("x1", "If can stun x enemy", 3, 1, 5, 1)
        self.cfg.ult.fult:Slider("x2", "If ally around >=", 1, 0, 5, 1)
      end

    --[[ Drawings Menu ]]--
    self.cfg:Menu("dw", "Drawings Mode")
      self.cfg.dw:Menu("lh", "Draw Q LastHit Circle")
        self.cfg.dw.lh:Boolean("e", "Enable", true)
        self.cfg.dw.lh:ColorPick("c1", "Color if QDmg*2.5 can kill", {200, 255, 191, 0})
        self.cfg.dw.lh:ColorPick("c2", "Color if QDmg can kill", {200, 255, 0, 0})

    --[[ Misc Menu ]]--
    self.cfg:Menu("misc", "Misc Mode")  
      self.cfg.misc:Menu("E", "E Setting")
        self.cfg.misc.E:Boolean("eb1", "Auto E to update stacks", false)
        self.cfg.misc.E:Slider("eb2", "Auto E if %MP > ", 50, 1, 100, 1)
        self.cfg.misc.E:Boolean("eb3", "Auto E if need 1 stack to stun", true)
      self.cfg.misc:Menu("hc", "Spell HitChance")
        self.cfg.misc.hc:Slider("W", "W Hit-Chance", 25, 1, 100, 1, function(value) self.W.Prediction:SetHitChance(value*0.01) end)
        self.cfg.misc.hc:Slider("R", "R Hit-Chance", 40, 1, 100, 1, function(value) self.R.Prediction:SetHitChance(value*0.01) end)
      SetSkin(self.cfg.misc, {"Classic", "Goth", "Red Riding", "Wonderland", "Prom Queen", "Frostfire", "Reverse", "FrankenTibbers", "Panda", "Sweetheart", "Hextech"})
    PermaShow(self.cfg.ult.u3)
end

function NS_Annie:ExtraLoad()
    self.Q.Target = ChallengerTargetSelector(self.Q.Range, 2, false, nil, false, self.cfg.Q)
    self.W.Target = ChallengerTargetSelector(self.W.Range, 2, false, nil, false, self.cfg.W)
    self.R.Target = ChallengerTargetSelector(self.R.Range, 2, false, nil, false, self.cfg.ult)
    self.Q.Target.Menu.TargetSelector.TargetingMode.callback = function(id) self.Q.Target.Mode = id end
    self.W.Target.Menu.TargetSelector.TargetingMode.callback = function(id) self.W.Target.Mode = id end
    self.R.Target.Menu.TargetSelector.TargetingMode.callback = function(id) self.R.Target.Mode = id end

    self.HPBar  = DrawDmgOnHPBar(self.cfg.dw, {ARGB(200, 89, 0 ,179), ARGB(200, 0, 245, 255), ARGB(200, 0, 217, 108)}, {"R", "Q", "W"})
    self.Q.Draw = DCircle(self.cfg.dw, "Draw Q Range", self.Q.Range, ARGB(150, 0, 245, 255))
    self.W.Draw = DCircle(self.cfg.dw, "Draw W Range", self.W.Range, ARGB(150, 186, 85, 211))
    self.R.Draw = DCircle(self.cfg.dw, "Draw R Range", self.R.Range, ARGB(150, 89, 0 ,179))

    self.W.Prediction = Spells(_W, self.W.Delay, self.W.Speed, self.W.Width, self.W.Range, false, 0, true, "cone", "Annie W", self.cfg.misc.hc.W:Value()*0.01, {angle = 50})
    self.R.Prediction = Spells(_R, self.R.Delay, self.R.Speed, self.R.Width, self.R.Range, false, 0, true, "circular", "Annie R", self.cfg.misc.hc.R:Value()*0.01)

    AddCB("Load", function()
        ChallengerInterrupter(self.cfg.misc, function(o, s) if not self.D.stun or ((s.spell.name == "VarusQ" or s.spell.name == "Drain") and s.endTime - GetTickCount() > 2400) then return end if ValidTarget(o, self.W.Range) and IsReady(_W) then self.W.Prediction:Cast1(o) elseif ValidTarget(o, self.Q.Range) and IsReady(_Q) then CastTargetSpell(o, _Q) end end)
    end)
end

function NS_Annie:CastR(target)
   if not ValidTarget(target, self.R.Range) then return end
    self.R.Prediction:Cast1(target)
end

function NS_Annie:CastQ(target)
   if not ValidTarget(target, self.Q.Range) then return end
     CastTargetSpell(target, _Q)
end

function NS_Annie:CastW(target)
   if not ValidTarget(target, self.W.Range) then return end
    self.W.Prediction:Cast1(target)
end

function NS_Annie:FlashR()
    if EnemiesAround(myHero.pos, self.R.Range) == 0 and EnemiesAround(myHero.pos, self.R.Range + 420) > 0 and AlliesAround(myHero.pos, self.R.Range) >= self.cfg.ult.fult.x2:Value() then
      local pos, hit = GetFarmPosition2(self.R.Width, self.R.Range + 420, Enemies)
      if hit >= self.cfg.ult.fult.x1:Value() then
        CastSkillShot(self.D.Flash, pos)
        if GetDistance(pos) <= self.R.Range then CastSkillShot(_R, pos) end
      end
    end
end

function NS_Annie:CheckR()
    if self.cfg.ult.u1:Value() == 1 then
      local target = self.R.Target:GetTarget()
      if ValidTarget(target, self.R.Range) and GetHP2(target) < self.R.Damage(target) and (IsReady(_Q) == false or (IsReady(_Q) and ValidTarget(target, self.Q.Range) and GetHP2(target) > self.Q.Damage(target))) and (IsReady(_W) == false or (IsReady(_W) and ValidTarget(target, self.W.Range) and GetHP2(target) > self.W.Damage(target))) then self:CastR(target) end
    elseif self.cfg.ult.u1:Value() == 2 then
      local pos, hit = GetFarmPosition2(self.R.Width, self.R.Range, Enemies)
      if hit >= self.cfg.ult.u2:Value() then CastSkillShot(_R, pos) end
    end
end

function NS_Annie:Updating()
    for i = 1, C do
    local enemy = Enemies[i]
      if ValidTarget(enemy, 1500) and self.HPBar[i] then
        self.HPBar[i]:SetValue(1, enemy, self.R.Damage(enemy), IsSReady(_R))
        self.HPBar[i]:SetValue(2, enemy, self.Q.Damage(enemy), IsSReady(_Q))
        self.HPBar[i]:SetValue(3, enemy, self.W.Damage(enemy), IsSReady(_W))
        self.HPBar[i]:CheckValue()
      end
    end

    if Mix:Mode() == "LaneClear" or Mix:Mode() == "LastHit" then self.C:Update() end
end

function NS_Annie:Tick()
   if myHero.dead or not Enemies[C] then return end
    self:Updating()
    local QTarget = IsReady(_Q) and self.Q.Target:GetTarget()
    local WTarget = IsReady(_W) and self.W.Target:GetTarget()
    if Mix:Mode() == "Combo" then
      if IsReady(_Q) and self.cfg.Q.cb:Value() then self:CastQ(QTarget) end
      if IsReady(_W) and self.cfg.W.cb:Value() then self:CastW(WTarget) end
    end

    if IsReady(_R) then
      if (self.cfg.ult.u3:Value() and Mix:Mode() == "Combo") or not self.cfg.ult.u3:Value() then self:CheckR() end
      if self.D.Flash and IsReady(self.D.Flash) and IsReady(_R) and self.cfg.ult.fult.eb1:Value() and ((self.cfg.ult.fult.eb2:Value() == 1 and Mix:Mode() == "Combo") or self.cfg.ult.fult.eb2:Value() == 2) then self:FlashR() end
    end

    if IsReady(_E) and self.cfg.misc.E.eb1:Value() and ManaCheck(self.cfg.misc.E.eb2:Value()) and EnemiesAround(myHero.pos, 1500) == 0 and not self.D.stun then CastSpell(_E) end

    if Mix:Mode() == "Harass" then
      if IsReady(_Q) and self.cfg.Q.hr:Value() and ManaCheck(self.cfg.Q.MPhr:Value()) and ((self.cfg.Q.s1:Value() and not self.D.stun) or not self.cfg.Q.s1:Value()) then self:CastQ(QTarget) end
      if IsReady(_W) and self.cfg.W.hr:Value() and ManaCheck(self.cfg.W.MPhr:Value()) and ((self.cfg.W.s:Value() and not self.D.stun) or not self.cfg.W.s:Value()) then self:CastW(WTarget) end
    end

    if Mix:Mode() == "LaneClear" then
      self:LaneClear()
	  self:JungleClear()
    end

    if Mix:Mode() == "LastHit" and IsReady(_Q) and ManaCheck(self.cfg.Q.MPlh:Value()) and ((self.cfg.Q.s3:Value() and not self.D.stun) or not self.cfg.Q.s3:Value()) then
      for _, minion in pairs(self.C.tminion) do
        self:QLastHit(minion)
      end
    end

    self:KillSteal()
end

function NS_Annie:KillSteal()
    for i = 1, C do
    local enemy = Enemies[i]
     if Ignite and IsReady(Ignite) and self.cfg.Ignite.ks:Value() and ValidTarget(enemy, 600) then
      local hp, dmg = Mix:HealthPredict(enemy, 2500, "OW") + enemy.hpRegen*2.5 + enemy.shieldAD, 50 + 20*myHero.level
      if hp > 0 and dmg > hp then CastTargetSpell(enemy, Ignite) end
     end

     if IsReady(_W) and self.cfg.W.ks:Value() and ManaCheck(self.cfg.W.MPks:Value()) and ValidTarget(enemy, self.W.Range) and GetHP2(enemy) < self.W.Damage(enemy) then 
       self:CastW(enemy)

     elseif IsReady(_Q) and self.cfg.Q.ks:Value() and ManaCheck(self.cfg.Q.MPks:Value()) and ValidTarget(enemy, self.Q.Range) and GetHP2(enemy) < self.Q.Damage(enemy) then 
       self:CastQ(enemy)
     end
    end
end

function NS_Annie:QLastHit(minion)
    if Mix:HealthPredict(minion, 1000*(self.Q.Delay + GetDistance(minion)/self.Q.Speed), "OW") > 0 and self.Q.Damage(minion) > Mix:HealthPredict(minion, 1000*(self.Q.Delay + GetDistance(minion)/self.Q.Speed), "OW") then
      CastTargetSpell(minion, _Q)
    end
end

function NS_Annie:LaneClear()
    for _, minion in pairs(self.C.tminion) do
      if ManaCheck(self.cfg.Q.MPlc:Value()) and ((self.cfg.Q.s2:Value() and not self.D.stun) or not self.cfg.Q.s2:Value()) then
        if self.cfg.Q.c:Value() == 1 then self:QLastHit(minion) else CastTargetSpell(minion, _Q) end
      end
    end
      if ManaCheck(self.cfg.W.MPlc:Value()) and ((self.cfg.W.s:Value() and not self.D.stun) or not self.cfg.W.s:Value()) then
        local pos, hit = GetFarmPosition2(self.W.Range, 180, self.C.tminion)
        if hit >= self.cfg.W.h:Value() then CastSkillShot(_W, pos) end
      end
end

function NS_Annie:JungleClear()
    if not self.C.tmob[1] then return end
    local mob = self.C.tmob[1]
      if IsReady(_W) and self.cfg.W.jc:Value() and ManaCheck(self.cfg.W.MPjc:Value()) and ValidTarget(mob, self.W.Range) then
        CastSkillShot(_W, Vector(mob))
      end
      if IsReady(_Q) and self.cfg.Q.jc:Value() and ManaCheck(self.cfg.Q.MPjc:Value()) and ValidTarget(mob, self.Q.Range) then
        CastTargetSpell(mob, _Q)
      end
end

function NS_Annie:Drawings()
    if myHero.dead or not Enemies[C] then return end
    self:DmgHPBar()
    self:DrawRange()
    if self.cfg.dw.lh.e:Value() and IsReady(_Q) and (Mix:Mode() == "LaneClear" or Mix:Mode() == "LastHit") then self:DrawQLastHit() end
end

function NS_Annie:DrawQLastHit()
    for _, minion in pairs(self.C.tminion) do
      local HPPred = Mix:HealthPredict(minion, 1000*(self.Q.Delay + GetDistance(minion)/self.Q.Speed), "OW")
      local Pos = Vector(minion)      
	  if self.Q.Damage(minion) > HPPred then
        DrawCircle3D(Pos.x, Pos.y, Pos.z, 50, 1, self.cfg.dw.lh.c2:Value(), 20)
	  elseif self.Q.Damage(minion)*2.5 > minion.health then
        DrawCircle3D(Pos.x, Pos.y, Pos.z, 50, 1, self.cfg.dw.lh.c1:Value(), 20)
      end
    end
end

function NS_Annie:DrawRange()
    local myPos = Vector(myHero)
    if IsSReady(_Q) then self.Q.Draw:Draw(myPos) end
    if IsSReady(_W) then self.W.Draw:Draw(myPos) end
    if IsSReady(_R) then self.R.Draw:Draw(myPos) end
end

function NS_Annie:DmgHPBar()
    for i = 1, C do
      if ValidTarget(Enemies[i], 1500) and self.HPBar[i] then
        self.HPBar[i]:Draw()
     end
    end
end

function NS_Annie:UseE(unit, spell)
    if Mix:Mode() == "Combo" and self.cfg.E.cb:Value() and unit.type == "AIHeroClient" and unit.team == MINION_ENEMY then
      if spell.name:lower():find("attack") and spell.target == myHero and IsReady(_E) then
        CastSpell(_E)
      end
    end
end

function NS_Annie:CheckSpell(unit, spell)
    if unit == myHero and spell.name:lower() == "disintegrate" and self.D.passive == 3 and spell.target.type == "AIHeroClient" and IsReady(_E) then
      CastSpell(_E)
    end  
end

function NS_Annie:UpdateBuff(unit, buff)
    if unit == myHero then
      if buff.Name == "pyromania" then self.D.passive = buff.Count end
      if buff.Name == "pyromania_particle" then self.D.stun = true end
    end
end

function NS_Annie:RemoveBuff(unit, buff)
    if unit == myHero then
      if buff.Name == "pyromania" then self.D.passive = 0 end
      if buff.Name == "pyromania_particle" then self.D.stun = false end
    end
end

----------------[[ Script Load ]]------------------------
do
    if not Supported[myHero.charName] then NEETSeries_Print("Not Supported For "..myHero.charName) return end
    _G["NS_"..myHero.charName]()
    Analytics("NEETSeries", "Ryzuki")
end

GetWebResultAsync("https://raw.githubusercontent.com/VTNEETS/GoS/master/NEETSeries.version", function(OnlineVer)
    if tonumber(OnlineVer) > NEETSeries_Version then
      NEETSeries_Print("New Version found (v"..OnlineVer.."). Please wait...")
      DownloadFileAsync("https://raw.githubusercontent.com/VTNEETS/GoS/master/NEETSeries.lua", SCRIPT_PATH.."NEETSeries.lua", function() NEETSeries_Print("Updated to version "..v..". Please F6 x2 to reload.") end)
    else
      if Supported[myHero.charName] then PrintChat(string.format("<font color=\"#4169E1\"><b>[NEET Series]:</b></font><font color=\"#FFFFFF\"><i> Successfully Loaded</i> (v%s) | Good Luck</font> <font color=\"#C6E2FF\"><u>%s</u></font>", NEETSeries_Version, GetUser())) end
    end
end)
