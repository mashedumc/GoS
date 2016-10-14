--[[ NEETSeries's plugin
	      __      _____  ___   _____  ___    __     _______  
	     /""\    (\"   \|"  \ (\"   \|"  \  |" \   /"     "| 
	    /    \   |.\\   \    ||.\\   \    | ||  | (: ______) 
	   /' /\  \  |: \.   \\  ||: \.   \\  | |:  |  \/    |   
	  //  __'  \ |.  \    \. ||.  \    \. | |.  |  // ___)_  
	 /   /  \\  \|    \    \ ||    \    \ | /\  |\(:      "| 
	(___/    \___)\___|\____\) \___|\____\)(__\_|_)\_______) 

---------------------------------------]]
local Enemies, C, HPBar, CCast = { }, 0, { }, false
local huge, max, min = math.huge, math.max, math.min
local Check = Set {"Run", "Idle1", "Channel_WNDUP"}
local Ignite = Mix:GetSlotByName("summonerdot", 4, 5)
local pred, StrID, StrN = {"OpenPredict", "GPrediction", "GosPrediction"}, {"cb", "hr", "lc", "jc", "ks", "lh"}, {"Combo", "Harass", "LaneClear", "JungleClear", "KillSteal", "LastHit"}
local function GetData(spell) return myHero:GetSpellData(spell) end
local function CalcDmg(type, target, dmg) local calc = type == 1 and CalcPhysicalDamage or CalcMagicalDamage return calc(myHero, target, dmg) end
local function IsSReady(spell) return CanUseSpell(myHero, spell) == 0 or CanUseSpell(myHero, spell) == 8 end
local function ManaCheck(value) return value <= GetPercentMP(myHero) end
local function EnemiesAround(pos, range) return CountObjectsNearPos(pos, nil, range, Enemies, MINION_ENEMY) end
local function LoadGPred(value) if (value == 2 and not gPred) then require('GPrediction') end end

local function AddMenu(Menu, ID, Pred, Text, Tbl, MP)
	Menu:Menu(ID, Text)
	if Pred then Menu[ID]:DropDown("Pred", "Choose Prediction:", 1, pred) end
	for i = 1, 6 do
		if Tbl[i] then Menu[ID]:Boolean(StrID[i], "Use in "..StrN[i], true) end
		if MP and i > 1 and Tbl[i] then Menu[ID]:Slider("MP"..StrID[i], "Enable in "..StrN[i].." if %MP >=", MP, 1, 100, 1) end
	end
end

local function SetSkin(Menu, skintable)
	local ChangeSkin = function(id) myHero:Skin(id == #skintable and -1 or id-1) end
	Menu:DropDown(myHero.charName.."_SetSkin", myHero.charName.." SkinChanger", #skintable, skintable, function(id) ChangeSkin(id) end)
	if (Menu[myHero.charName.."_SetSkin"]:Value() ~= #skintable) then ChangeSkin(Menu[myHero.charName.."_SetSkin"]:Value()) end
end

local function DrawDmgOnHPBar(Menu, Color, Text)
	local Dt = {}
	for i = 1, C do
		Menu:Menu("HPBar_"..Enemies[i].charName, "Draw Dmg HPBar "..Enemies[i].charName)
		Dt[i] = DrawDmgHPBar(Menu["HPBar_"..Enemies[i].charName], Color, Text)
	end
		return Dt
end

local GetLineFarmPosition2 = function(range, width, objects)
	local Pos, Hit = nil, 0
	for _, m in pairs(objects) do
		if ValidTarget(m, range) then
			local count = CountObjectsOnLineSegment(Vector(myHero), Vector(m), width, objects, MINION_ENEMY)
			if not Pos or CountObjectsOnLineSegment(Vector(myHero), Vector(Pos), width, objects, MINION_ENEMY) < count then
				Pos = Vector(m)
				Hit = count
			end
		end
	end
		return Pos, Hit
end

local GetFarmPosition2 = function(range, width, objects)
	local Pos, Hit = nil, 0
	for _, m in pairs(objects) do
		if ValidTarget(m, range) then
			local count = CountObjectsNearPos(Vector(m), nil, width, objects, MINION_ENEMY)
			if not Pos or CountObjectsNearPos(Vector(Pos), nil, width, objects, MINION_ENEMY) < count then
				Pos = Vector(m)
				Hit = count
			end
		end
	end
		return Pos, Hit
end

OnLoad(function()
	for i = 1, heroManager.iCount do
		local hero = heroManager:getHero(i)
		if hero.team == MINION_ENEMY then
			C = C + 1
			Enemies[C] = hero
		end
	end
	table.sort(Enemies, function(a, b) return a.charName < b.charName end)
end)

OnAnimation(function(u, a)
	if (u ~= myHero or u.dead) then return end
	if (Check[a]) then CCast = true return end
	if (a:lower():find("attack")) then CCast = false return end
end)

OnProcessSpellAttack(function(u, a)
	if (u ~= myHero or u.dead) then return end
	if (a.name:lower():find("attack")) then CCast = false return end
end)

OnProcessSpellComplete(function(u, a)
	if (u ~= myHero or u.dead) then return end
	if (a.name:lower():find("attack")) then CCast = true return end
end)

--------------------------------------------------------------------------------
local Q = { Range = GetData(_Q).range, Speed = 1500, Delay = 0.25, Damage = function(unit) return CalcDmg(2, unit, 45 + 35*GetData(_Q).level + 0.8*myHero.ap) end }
local W = { Range = GetData(_W).range, Speed = huge, Delay = 0.25, Width = 80,  Damage = function(unit) return CalcDmg(2, unit, 25 + 45*GetData(_W).level + 0.85*myHero.ap) end }
local R = { Range = GetData(_R).range, Speed = huge, Delay = 0.25, Width = 250, Damage = function(unit) return CalcDmg(2, unit, 25 + 130*GetData(_R).level + 0.7*myHero.ap) end, Teddy = GotBuff(myHero, "infernalguardiantimer") > 0 and true or false}
local D = { Flash = MixLib:GetSlotByName("summonerflash", 4, 5), passive = GotBuff(myHero, "pyromania"), stun = GotBuff(myHero, "pyromania_particle") > 0 }
local Cr = __MinionManager(Q.Range, Q.Range)

local NS_Annie = MenuConfig("NS_Annie", "[NEET Series] - Annie")
NS_Annie:Info("info", "Scripts Version: "..NEETSeries_Version)

	--[[ Q Settings ]]--
	AddMenu(NS_Annie, "Q", false, "Q Settings", {true, true, true, true, true, true}, 15)
	NS_Annie.Q:DropDown("c", "LaneClear Mode:", 1, {"LastHit", "Always Cast"})
	NS_Annie.Q:Boolean("s1", "Harass but save stun", true)
	NS_Annie.Q:Boolean("s2", "LaneClear but save stun", true)
	NS_Annie.Q:Boolean("s3", "LastHit but save stun", false)

	--[[ W Settings ]]--
	AddMenu(NS_Annie, "W", true, "W Settings", {true, true, true, true, true, false}, 15)
	NS_Annie.W:Slider("h", "LaneClear if hit minions >=", 3, 1, 10, 1)
	NS_Annie.W:Boolean("s", "Harass/LC but save stun", true)	
	NS_Annie.W.Pred.callback = function(v) W.Prediction.Pred = pred[v] LoadGPred(v) end
	LoadGPred(NS_Annie.W.Pred:Value())

	--[[ E Settings ]]--
	AddMenu(NS_Annie, "E", false, "E Settings", {true, false, false, false, false, false})

	--[[ Ignite Settings ]]--
	if Ignite then AddMenu(NS_Annie, "Ignite", false, "Ignite Settings", {false, false, false, false, true, false}) end

	--[[ Ultimate Menu ]]--
	NS_Annie:Menu("ult", "Ultimate Settings")
		NS_Annie.ult:DropDown("Pred", "Choose Prediction:", 1, pred, function(v) R.Prediction.Pred = pred[v] LoadGPred(v) end)
		LoadGPred(NS_Annie.ult.Pred:Value())
		NS_Annie.ult:DropDown("u1", "Casting Mode", 1, {"If Killable", "If can stun x enemies"})
		NS_Annie.ult:Slider("u2", "R if can stun enemies >=", 2, 1, 5, 1)
		NS_Annie.ult:KeyBinding("u3", "Use R if Combo Active (G)", 71, true)
	if D.Flash ~= nil then
		NS_Annie.ult:Menu("fult", "Flash and Ultimate")
			NS_Annie.ult.fult:Boolean("eb1", "Enable?", false)
			NS_Annie.ult.fult:DropDown("eb2", "Active Mode: ", 1, {"Use when Combo Active", "Auto Use"})
			NS_Annie.ult.fult:Slider("x1", "If can stun x enemy", 3, 1, 5, 1)
			NS_Annie.ult.fult:Slider("x2", "If ally around >=", 1, 0, 5, 1)
	end

	--[[ Drawings Menu ]]--
	NS_Annie:Menu("dw", "Drawings Mode")
		NS_Annie.dw:Menu("lh", "Draw Q LastHit Circle")
		NS_Annie.dw.lh:Boolean("e", "Enable", true)
		NS_Annie.dw.lh:ColorPick("c1", "Color if QDmg*2.5 can kill", {200, 255, 191, 0})
		NS_Annie.dw.lh:ColorPick("c2", "Color if QDmg can kill", {200, 255, 0, 0})

	--[[ Misc Menu ]]--
	NS_Annie:Menu("misc", "Misc Mode")  
		NS_Annie.misc:Menu("E", "E Setting")
		NS_Annie.misc.E:KeyBinding("eb1", "Auto E for update stacks", 90, true)
		NS_Annie.misc.E:Slider("eb2", "Auto E if %MP > ", 50, 1, 100, 1)
		NS_Annie.misc.E:Boolean("eb3", "Auto E if need 1 stack to stun", true)
		NS_Annie.misc:Menu("hc", "Spell HitChance")
			NS_Annie.misc.hc:Slider("W", "W Hit-Chance", 25, 1, 100, 1, function(value) W.Prediction.data.hc = value*0.01 end)
			NS_Annie.misc.hc:Slider("R", "R Hit-Chance", 40, 1, 100, 1, function(value) R.Prediction.data.hc = value*0.01 end)
	SetSkin(NS_Annie.misc, {"Classic", "Goth", "Red Riding", "Wonderland", "Prom Queen", "Frostfire", "Reverse", "FrankenTibbers", "Panda", "Sweetheart", "Hextech", "Disable"})
	PermaShow(NS_Annie.ult.u3)
	PermaShow(NS_Annie.misc.E.eb1)
-----------------------------------

Q.Target = ChallengerTargetSelector(Q.Range, 2, false, nil, false, NS_Annie.Q)
W.Target = ChallengerTargetSelector(W.Range, 2, false, nil, false, NS_Annie.W)
R.Target = ChallengerTargetSelector(R.Range, 2, false, nil, false, NS_Annie.ult)
Q.Target.Menu.TargetSelector.TargetingMode.callback = function(id) Q.Target.Mode = id end
W.Target.Menu.TargetSelector.TargetingMode.callback = function(id) W.Target.Mode = id end
R.Target.Menu.TargetSelector.TargetingMode.callback = function(id) R.Target.Mode = id end

Q.Draw = DCircle(NS_Annie.dw, "Draw Q Range", Q.Range, ARGB(150, 0, 245, 255))
W.Draw = DCircle(NS_Annie.dw, "Draw W Range", W.Range, ARGB(150, 186, 85, 211))
R.Draw = DCircle(NS_Annie.dw, "Draw R Range", R.Range, ARGB(150, 89, 0 ,179))

W.Prediction = PredictSpell(_W, W.Delay, W.Speed, W.Width, W.Range, false, 0, true, "cone", "Annie W", NS_Annie.misc.hc.W:Value()*0.01, pred[NS_Annie.W.Pred:Value()], {angle = 50})
R.Prediction = PredictSpell(_R, R.Delay, R.Speed, R.Width, R.Range, false, 0, true, "circular", "Annie R", NS_Annie.misc.hc.R:Value()*0.01, pred[NS_Annie.ult.Pred:Value()])

ChallengerAntiGapcloser(NS_Annie.misc, function(o, s) if not D.stun or (s.spell.name == "AlphaStrike" and s.endTime - GetTickCount() > 650) or ((s.spell.name == "KatarinaE" or s.spell.name == "RiftWalk" or s.spell.name == "TalonCutThroat") and s.endTime - GetTickCount() > 750) then return end if ValidTarget(o, W.Range) and IsReady(_W) then W.Prediction:Cast(o) elseif ValidTarget(o, Q.Range) and IsReady(_Q) then CastTargetSpell(o, _Q) end end)
ChallengerInterrupter(NS_Annie.misc, function(o, s) if not D.stun or ((s.spell.name == "VarusQ" or s.spell.name == "Drain") and s.endTime - GetTickCount() > 2400) then return end if ValidTarget(o, W.Range) and IsReady(_W) then W.Prediction:Cast(o) elseif ValidTarget(o, Q.Range) and IsReady(_Q) then CastTargetSpell(o, _Q) end end)
-----------------------------------

local function CastR(target)
	if not ValidTarget(target, R.Range) then return end
		R.Prediction:Cast(target)
end

local function CastQ(target)
		if not ValidTarget(target, Q.Range) then return end
		CastTargetSpell(target, _Q)
end

local function CastW(target)
	if not ValidTarget(target, W.Range) then return end
		W.Prediction:Cast(target)
end

local function FlashR()
	if EnemiesAround(myHero.pos, R.Range) == 0 and EnemiesAround(myHero.pos, R.Range + 420) > 0 and AlliesAround(myHero.pos, R.Range) >= NS_Annie.ult.fult.x2:Value() then
		local pos, hit = GetFarmPosition2(R.Width, R.Range + 420, Enemies)
		if hit >= NS_Annie.ult.fult.x1:Value() then
			CastSkillShot(D.Flash, pos)
			if GetDistance(pos) <= R.Range then CastSkillShot(_R, pos) end
		end
	end
end

local function CheckR()
	if NS_Annie.ult.u1:Value() == 1 then
		local target = R.Target:GetTarget()
		if ValidTarget(target, R.Range) and GetHP2(target) < R.Damage(target) and (not IsReady(_Q) or (IsReady(_Q) and ValidTarget(target, Q.Range) and GetHP2(target) > Q.Damage(target))) and (not IsReady(_W) or (IsReady(_W) and ValidTarget(target, W.Range) and GetHP2(target) > W.Damage(target))) then CastR(target) end
	elseif NS_Annie.ult.u1:Value() == 2 then
		local pos, hit = GetFarmPosition2(R.Width, R.Range, Enemies)
		if hit >= NS_Annie.ult.u2:Value() then CastSkillShot(_R, pos) end
	end
end
local function KillSteal()
	for i = 1, C do
		local enemy = Enemies[i]
		if Ignite and IsReady(Ignite) and NS_Annie.Ignite.ks:Value() and ValidTarget(enemy, 600) then
			local hp, dmg = Mix:HealthPredict(enemy, 2500, "OW") + enemy.hpRegen*2.5 + enemy.shieldAD, 50 + 20*myHero.level
			if hp > 0 and dmg > hp then CastTargetSpell(enemy, Ignite) end
		end

		if IsReady(_W) and NS_Annie.W.ks:Value() and ManaCheck(NS_Annie.W.MPks:Value()) and ValidTarget(enemy, W.Range) and GetHP2(enemy) < W.Damage(enemy) then 
			CastW(enemy)

		elseif IsReady(_Q) and NS_Annie.Q.ks:Value() and ManaCheck(NS_Annie.Q.MPks:Value()) and ValidTarget(enemy, Q.Range) and GetHP2(enemy) < Q.Damage(enemy) then 
			CastQ(enemy)
		end
	end
end

local function QLastHit(minion)
	local Health = Mix:HealthPredict(minion, 1000*(Q.Delay + GetDistance(minion)/Q.Speed), "OW")
	if Health > 0 and Q.Damage(minion) > Health then
		CastTargetSpell(minion, _Q)
	end
end

local function LaneClear()
	if ManaCheck(NS_Annie.Q.MPlc:Value()) and ((NS_Annie.Q.s2:Value() and not D.stun) or not NS_Annie.Q.s2:Value()) then
		for _, minion in pairs(Cr.tminion) do
			if NS_Annie.Q.c:Value() == 1 then QLastHit(minion) else CastTargetSpell(minion, _Q) end
    	end
    end
	if ManaCheck(NS_Annie.W.MPlc:Value()) and ((NS_Annie.W.s:Value() and not D.stun) or not NS_Annie.W.s:Value()) then
		local pos, hit = GetFarmPosition2(W.Range, 180, Cr.tminion)
		if hit >= NS_Annie.W.h:Value() then CastSkillShot(_W, pos) end
	end
end

local function JungleClear()
	if not Cr.tmob[1] then return end
	local mob = Cr.tmob[1]
	if IsReady(_W) and NS_Annie.W.jc:Value() and ManaCheck(NS_Annie.W.MPjc:Value()) and ValidTarget(mob, W.Range) then
		CastSkillShot(_W, Vector(mob))
	end
	if IsReady(_Q) and NS_Annie.Q.jc:Value() and ManaCheck(NS_Annie.Q.MPjc:Value()) and ValidTarget(mob, Q.Range) then
		CastTargetSpell(mob, _Q)
	end
end

local function DrawQLastHit()
	for _, minion in pairs(Cr.tminion) do
		local HPPred = Mix:HealthPredict(minion, 1000*(Q.Delay + GetDistance(minion)/Q.Speed), "OW")
		local Pos = Vector(minion)
		if Q.Damage(minion) > HPPred then
			DrawCircle3D(Pos.x, Pos.y, Pos.z, 50, 1, NS_Annie.dw.lh.c2:Value(), 20)
		elseif Q.Damage(minion)*2.5 > minion.health then
			DrawCircle3D(Pos.x, Pos.y, Pos.z, 50, 1, NS_Annie.dw.lh.c1:Value(), 20)
		end
	end
end

local function DrawRange()
	local myPos = Vector(myHero)
	if IsSReady(_Q) then Q.Draw:Draw(myPos) end
	if IsSReady(_W) then W.Draw:Draw(myPos) end
	if IsSReady(_R) then R.Draw:Draw(myPos) end
end

local function DmgHPBar()
	for i = 1, C do
		if ValidTarget(Enemies[i], 1500) and HPBar[i] then
			HPBar[i]:Draw()
		end
	end
end

local function UseE(unit, spell)
	if Mix:Mode() == "Combo" and NS_Annie.E.cb:Value() and unit.type == "AIHeroClient" and unit.team == MINION_ENEMY then
		if spell.name:lower():find("attack") and spell.target == myHero and IsReady(_E) then
			CastSpell(_E)
		end
	end
end

local function CheckSpell(unit, spell)
	if unit == myHero and spell.name:lower() == "disintegrate" and D.passive == 3 and spell.target.type == "AIHeroClient" and IsReady(_E) then
		CastSpell(_E)
	end  
end

local function UpdateBuff(unit, buff)
	if unit == myHero then
		if buff.Name == "pyromania" then D.passive = buff.Count end
		if buff.Name == "pyromania_particle" then D.stun = true end
		if buff.Name == "infernalguardiantimer" then R.Teddy = true end
	end
end

local function RemoveBuff(unit, buff)
	if unit == myHero then
		if buff.Name == "pyromania" then D.passive = 0 end
		if buff.Name == "pyromania_particle" then D.stun = false end
		if buff.Name == "infernalguardiantimer" then R.Teddy = false end
	end
end
------------------------------------

local function Tick()
	if myHero.dead or not Enemies[C] then return end
	local QTarget = IsReady(_Q) and Q.Target:GetTarget()
	local WTarget = IsReady(_W) and W.Target:GetTarget()
	local mode = Mix:Mode()
	if mode == "Combo" and CCast then
		if IsReady(_Q) and NS_Annie.Q.cb:Value() then CastQ(QTarget) end
		if IsReady(_W) and NS_Annie.W.cb:Value() then CastW(WTarget) end
    end

    if IsReady(_R) and not R.Teddy then
		if (NS_Annie.ult.u3:Value() and mode == "Combo" and CCast) or not NS_Annie.ult.u3:Value() then CheckR() end
		if D.Flash and IsReady(D.Flash) and IsReady(_R) and NS_Annie.ult.fult.eb1:Value() and ((NS_Annie.ult.fult.eb2:Value() == 1 and mode == "Combo") or NS_Annie.ult.fult.eb2:Value() == 2) then FlashR() end
    end

    if IsReady(_E) and NS_Annie.misc.E.eb1:Value() and ManaCheck(NS_Annie.misc.E.eb2:Value()) and EnemiesAround(myHero.pos, 1500) == 0 and not D.stun then CastSpell(_E) end

    if mode == "Harass" and CCast then
		if IsReady(_Q) and NS_Annie.Q.hr:Value() and ManaCheck(NS_Annie.Q.MPhr:Value()) and ((NS_Annie.Q.s1:Value() and not D.stun) or not NS_Annie.Q.s1:Value()) then CastQ(QTarget) end
		if IsReady(_W) and NS_Annie.W.hr:Value() and ManaCheck(NS_Annie.W.MPhr:Value()) and ((NS_Annie.W.s:Value() and not D.stun) or not NS_Annie.W.s:Value()) then CastW(WTarget) end
    end

    if mode == "LaneClear" and CCast then
    	Cr:Update()
		LaneClear()
		JungleClear()
    end

    if mode == "LastHit" and CCast and IsReady(_Q) and ManaCheck(NS_Annie.Q.MPlh:Value()) and ((NS_Annie.Q.s3:Value() and not D.stun) or not NS_Annie.Q.s3:Value()) then
		for _, minion in pairs(Cr.tminion) do
			QLastHit(minion)
		end
    end

	KillSteal()

	for i = 1, C do
		local enemy = Enemies[i]
		if ValidTarget(enemy, 1500) and HPBar[i] then
			HPBar[i]:SetValue(1, enemy, R.Damage(enemy), IsSReady(_R))
			HPBar[i]:SetValue(2, enemy, Q.Damage(enemy), IsSReady(_Q))
			HPBar[i]:SetValue(3, enemy, W.Damage(enemy), IsSReady(_W))
			HPBar[i]:CheckValue()
		end
	end
end

local function Drawings()
	if myHero.dead or not Enemies[C] then return end
	DmgHPBar()
	DrawRange()
	if NS_Annie.dw.lh.e:Value() and IsReady(_Q) and (Mix:Mode() == "LaneClear" or Mix:Mode() == "LastHit") then DrawQLastHit() end
end
------------------------------------

OnLoad(function()
	HPBar = DrawDmgOnHPBar(NS_Annie.dw, {ARGB(200, 89, 0 ,179), ARGB(200, 0, 245, 255), ARGB(200, 0, 217, 108)}, {"R", "Q", "W"})
	OnProcessSpellCast(CheckSpell)
	OnProcessSpellComplete(UseE)
	OnUpdateBuff(UpdateBuff)
	OnRemoveBuff(RemoveBuff)
	OnTick(Tick)
	OnDraw(Drawings)
end)
