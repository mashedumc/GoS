--[[ NEETSeries's plugin
	 __   ___   ______    _______   ____  ___      ___       __       __   __  ___ 
	|/"| /  ") /    " \  /" _   "| ))_ ")|"  \    /"  |     /""\     |"  |/  \|  "|
	(: |/   / // ____  \(: ( \___)(____(  \   \  //   |    /    \    |'  /    \:  |
	|    __/ /  /    ) :)\/ \             /\\  \/.    |   /' /\  \   |: /'        |
	(// _  \(: (____/ // //  \ ___       |: \.        |  //  __'  \   \//  /\'    |
	|: | \  \\        / (:   _(  _|      |.  \    /:  | /   /  \\  \  /   /  \\   |
	(__|  \__)\"_____/   \_______)       |___|\__/|___|(___/    \___)|___/    \___|

---------------------------------------]]
local Enemies, C, HPBar, CCast = { }, 0, { }, true
local huge, min = math.huge, math.min
local Check = Set {"Run", "Idle1", "Channel_WNDUP"}
local Ignite = Mix:GetSlotByName("summonerdot", 4, 5)
local pred, StrID, StrN = {"OpenPredict", "GPrediction", "GosPrediction"}, {"cb", "hr", "lc", "jc", "ks", "lh"}, {"Combo", "Harass", "LaneClear", "JungleClear", "KillSteal", "LastHit"}
local function GetData(spell) return myHero:GetSpellData(spell) end
local function CalcDmg(type, target, dmg) if type == 1 then return CalcPhysicalDamage(myHero, target, dmg) end return CalcMagicalDamage(myHero, target, dmg) end
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
	if u ~= myHero or u.dead then return end
	if Check[a] then CCast = true return end
	if a:lower():find("attack") then CCast = false return end
end)

OnProcessSpellAttack(function(u, a)
	if u ~= myHero or u.dead then return end
	if a.name:lower():find("attack") then CCast = false return end
end)

OnProcessSpellComplete(function(u, a)
	if u ~= myHero or u.dead then return end
	if a.name:lower():find("attack") then CCast = true return end
end)

--------------------------------------------------------------------------------
local Q = { Range = GetData(_Q).range,                                 Speed = 1450,      Delay = 0.25, Width = 80,  Damage = function(unit) return CalcDmg(2, unit, 30 + 50*GetData(_Q).level + 0.5*myHero.ap) end}
local E = { Range = GetData(_E).range,                                 Speed = 1100,      Delay = 0.25, Width = 120, Damage = function(unit) return CalcDmg(2, unit, 10 + 50*GetData(_E).level + 0.7*myHero.ap) end}
local R = { Range = function() return 900 + 300*GetData(_R).level end, Speed = huge,      Delay = 1,    Width = 235, Damage = function(unit) local bonus = GetPercentHP(unit) < 40 and 2 or (1 + min(0.5, (100 - GetPercentHP(unit))*0.0083)) return CalcDmg(2, unit, bonus*(60 + 40*GetData(_R).level + 0.25*myHero.ap + 0.65*myHero.totalDamage)) end, Count = 1}
local Cr, target, WRange = __MinionManager(E.Range, E.Range), nil, 0
local function UpdateDelay(v)
	if v then
		Q.Prediction.data.hc = 0.125
		E.Prediction.data.hc = 0.125
		R.R1Prediction.data.hc = 0.875
		R.R2Prediction.data.hc = 0.875
		R.R3Prediction.data.hc = 0.875
		return
	end
	Q.Prediction.data.hc = 0.25
	E.Prediction.data.hc = 0.25
	R.R1Prediction.data.hc = 1
	R.R2Prediction.data.hc = 1
	R.R3Prediction.data.hc = 1
end

local NS_Kog = MenuConfig("NS_KogMaw", "[NEET Series] - Kog'Maw")

	--[[ Q Settings ]]--
	AddMenu(NS_Kog, "Q", true, "Q Settings", {true, true, false, true, true, false}, 15)
	NS_Kog.Q.Pred.callback = function(v) Q.Prediction.Pred = pred[v] LoadGPred(v) end
	LoadGPred(NS_Kog.Q.Pred:Value())

	--[[ W Settings ]]--
	AddMenu(NS_Kog, "W", false, "W Settings", {true, false, false, false, false, false})

	--[[ E Settings ]]--
	AddMenu(NS_Kog, "E", true, "E Settings", {true, true, true, true, true, false}, 15)
	NS_Kog.E:Slider("h", "LaneClear if hit minions >=", 3, 1, 10, 1)
	NS_Kog.E.Pred.callback = function(v) E.Prediction.Pred = pred[v] LoadGPred(v) end
	LoadGPred(NS_Kog.E.Pred:Value())

	--[[ Ignite Settings ]]--
	if Ignite then AddMenu(NS_Kog, "Ignite", false, "Ignite Settings", {false, false, false, false, true, false}) end

		--[[ R Settings ]]--
	AddMenu(NS_Kog, "R", true, "R Settings", {true, true, false, true, false, false}, 15)
	NS_Kog.R:Boolean("lc", "Use in LaneClear", false)
	NS_Kog.R:Slider("MPlc", "Enable on LaneClear if %MP >=", 15, 1, 100, 1)
	NS_Kog.R:Slider("h", "Use R if hit Minions >=", 3, 1, 10, 1)
	NS_Kog.R:Boolean("ec", "R LaneClear if no enemy in 1200 range", true)
	NS_Kog.R:Boolean("ks", "Use in KillSteal", true)
	LoadGPred(NS_Kog.R.Pred:Value())
	NS_Kog.R.Pred.callback = function(v)
		R.R1Prediction.Pred = pred[v]
		R.R2Prediction.Pred = pred[v]
		R.R3Prediction.Pred = pred[v]
		LoadGPred(v)
	end

	--[[ Drawings Menu ]]--
	NS_Kog:Menu("dw", "Drawings Mode")

	--[[ Misc Menu ]]--
	NS_Kog:Menu("misc", "Misc Mode")
		NS_Kog.misc:Menu("rc", "Request Casting R")
			NS_Kog.misc.rc:Boolean("R1", "R but save mana for W", true)
			NS_Kog.misc.rc:Slider("R2", "Cast R if Stacks < x", 5, 1, 10, 1)
			NS_Kog.misc.rc:Slider("R3", "R in Combo if %MP >= ", 10, 1, 100, 1)
		NS_Kog.misc:Menu("hc", "Spell HitChance")
			NS_Kog.misc.hc:Slider("Q", "Q Hit-Chance", 25, 1, 100, 1, function(value) Q.Prediction.data.hc = value*0.01 end)
			NS_Kog.misc.hc:Slider("E", "E Hit-Chance", 25, 1, 100, 1, function(value) E.Prediction.data.hc = value*0.01 end)
			NS_Kog.misc.hc:Slider("R", "R Hit-Chance", 40, 1, 100, 1, function(value) R.R1Prediction.data.hc = value*0.01 R.R2Prediction.data.hc = value*0.01 R.R3Prediction.data.hc = value*0.01 end)
		NS_Kog.misc:Menu("sme", "Block Move (depend on as)")
			NS_Kog.misc.sme:Info("ifo1", "Dangerous: if distance to enemy <= 300")
			NS_Kog.misc.sme:Info("ifo2", "Kite: if distance to enemy > 600")
			NS_Kog.misc.sme:Info("ifo3", "BlockMove: Other case")
        	NS_Kog.misc.sme:Boolean("b1", "Enable block move check", true)
        	NS_Kog.misc.sme:Slider("b2", "Enable if AttackSpeed >=", 1.7, 1.2, 2.5, 0.1)
		SetSkin(NS_Kog.misc, {"Classic", "Caterpillar", "Sonoran", "Monarch", "Reindeer", "Lion Dance", "Deep Sea", "Jurassic", "Battlecast", "Disable"})
-----------------------------------

local Target = ChallengerTargetSelector(600, 1, true, nil, false, NS_Kog)
Target.Menu.TargetSelector.TargetingMode.callback = function(id) Target.Mode = id end

Q.Draw = DCircle(NS_Kog.dw, "Draw Q Range", Q.Range, ARGB(150, 0, 245, 255))
WDraw  = DCircle(NS_Kog.dw, "Draw W Range", 625 + 30*GetData(_W).level, ARGB(150, 186, 85, 211))
E.Draw = DCircle(NS_Kog.dw, "Draw E Range", E.Range, ARGB(150, 0, 217, 108))
R.Draw = DCircle(NS_Kog.dw, "Draw R Range", R.Range(), ARGB(150, 89, 0 ,179))

Q.Prediction = PredictSpell(_Q, Q.Delay, Q.Speed, Q.Width, Q.Range, true, 1, false, "linear", "Kog'Maw Q", NS_Kog.misc.hc.Q:Value()*0.01, pred[NS_Kog.Q.Pred:Value()])
E.Prediction = PredictSpell(_E, E.Delay, E.Speed, E.Width, E.Range, false, 0, true, "linear", "Kog'Maw E", NS_Kog.misc.hc.E:Value()*0.01, pred[NS_Kog.E.Pred:Value()])
R.R1Prediction = PredictSpell(_R, R.Delay, R.Speed, R.Width, 1200, false, 0, true, "circular", "Kog'Maw RLvl1", NS_Kog.misc.hc.R:Value()*0.01, pred[NS_Kog.R.Pred:Value()])
R.R2Prediction = PredictSpell(_R, R.Delay, R.Speed, R.Width, 1500, false, 0, true, "circular", "Kog'Maw RLvl2", NS_Kog.misc.hc.R:Value()*0.01, pred[NS_Kog.R.Pred:Value()])
R.R3Prediction = PredictSpell(_R, R.Delay, R.Speed, R.Width, 1800, false, 0, true, "circular", "Kog'Maw RLvl3", NS_Kog.misc.hc.R:Value()*0.01, pred[NS_Kog.R.Pred:Value()])
UpdateDelay(GotBuff(myHero, "KogMawBioArcaneBarrage") > 0 and true or false)
-----------------------------------

local function CastR(target)
	if not ValidTarget(target, R.Range()) then return end
	if GetData(_R).level == 1 then
		R.R1Prediction:Cast(target)
	elseif GetData(_R).level == 2 then
		R.R2Prediction:Cast(target)
	elseif GetData(_R).level == 3 then
		R.R3Prediction:Cast(target)
	end
end

local function CastE(target)
	if not ValidTarget(target, E.Range) then return end
		E.Prediction:Cast(target)
end

local function CastW()
	if not target then return end
	if (IsReady(_E) and ValidTarget(target, WRange)) or (not IsReady(_E) and ValidTarget(target, 600 + 25*GetData(_W).level)) then CastSpell(_W) end
end

local function CastQ(target)
	if not ValidTarget(target, Q.Range) then return end
		Q.Prediction:Cast(target)
end

local function KillSteal()
	for i = 1, C do
		local enemy = Enemies[i]
		if Ignite and IsReady(Ignite) and NS_Kog.Ignite.ks:Value() and ValidTarget(enemy, 600) then
			local hp, dmg = Mix:HealthPredict(enemy, 2500, "OW") + enemy.hpRegen*2.5 + enemy.shieldAD, 50 + 20*myHero.level
			if hp > 0 and dmg > hp then CastTargetSpell(enemy, Ignite) end
		end

		if IsReady(_Q) and NS_Kog.Q.ks:Value() and ManaCheck(NS_Kog.Q.MPks:Value()) and GetHP2(enemy) < Q.Damage(enemy) then
			CastQ(enemy)
		end

		if IsReady(_R) and NS_Kog.R.ks:Value() and GetHP2(enemy) < R.Damage(enemy) then
			CastR(enemy)
		end

		if IsReady(_E) and NS_Kog.E.ks:Value() and ManaCheck(NS_Kog.E.MPks:Value()) and GetHP2(enemy) < E.Damage(enemy) then
			CastE(enemy)
		end
	end
end

local function LaneClear()
	if IsReady(_R) and NS_Kog.R.lc:Value() and ManaCheck(NS_Kog.R.MPlc:Value()) then
		if NS_Kog.misc.rc.R2:Value() <= R.Count then return end
		if NS_Kog.R.ec:Value() and EnemiesAround(myHero.pos, 1200) > 0 then return end
		if NS_Kog.misc.rc.R1:Value() and myHero.mana - 40*R.Count < 40 then return end
		local RPos, RHit = GetFarmPosition2(R.Range(), R.Width, Cr.tminion)
		if RHit >= NS_Kog.R.h:Value() then CastSkillShot(_R, RPos) end
    end
    if IsReady(_E) and NS_Kog.E.lc:Value() and ManaCheck(NS_Kog.E.MPlc:Value()) then
    	local EPos, EHit = GetLineFarmPosition2(E.Range, E.Width, Cr.tminion)
		if EHit >= NS_Kog.E.h:Value() then CastSkillShot(_E, EPos) end
	end
end

local function JungleClear()
	if not Cr.tmob[1] then return end
	local mob = Cr.tmob[1]
	if IsReady(_Q) and NS_Kog.Q.jc:Value() and ManaCheck(NS_Kog.Q.MPjc:Value()) and ValidTarget(mob, Q.Range) then
		CastSkillShot(_Q, Vector(mob))
	end
	if IsReady(_E) and NS_Kog.E.jc:Value() and ManaCheck(NS_Kog.E.MPjc:Value()) then
		CastSkillShot(_E, Vector(mob))
	end
	if IsReady(_R) and NS_Kog.R.jc:Value() and ManaCheck(NS_Kog.R.MPjc:Value()) and ValidTarget(mob, R.Range()) and NS_Kog.misc.rc.R2:Value() > R.Count and ((NS_Kog.misc.rc.R1:Value() and myHero.mana - 40*R.Count > 40) or not NS_Kog.misc.rc.R1:Value()) then
		CastSkillShot(_R, Vector(mob))
	end
end

local function DrawRange()
	local myPos = Vector(myHero)
	if IsSReady(_Q) then Q.Draw:Draw(myPos) end
	if IsSReady(_W) then WDraw:Draw(myPos) end
	if IsSReady(_E) then E.Draw:Draw(myPos) end
	if IsSReady(_R) then R.Draw:Draw(myPos) end
end

local function DmgHPBar()
	for i = 1, C do
		if ValidTarget(Enemies[i], R.Range()*2) and HPBar[i] then
			HPBar[i]:Draw()
		end
	end
end

local function Updating()
	WRange = 625 + 30*GetData(_W).level
	for i = 1, C do
		local enemy = Enemies[i]
		if ValidTarget(enemy, R.Range()*2) and HPBar[i] then
			HPBar[i]:SetValue(1, enemy, R.Damage(enemy), IsSReady(_R))
			HPBar[i]:SetValue(2, enemy, Q.Damage(enemy), IsSReady(_Q))
			HPBar[i]:SetValue(3, enemy, E.Damage(enemy), IsSReady(_E))
			HPBar[i]:CheckValue()
		end
	end
	if ((IsReady(_W) and EnemiesAround(myHero.pos, WRange) == 0) or (not IsReady(_W) and EnemiesAround(myHero.pos, 565) == 0)) then Target.range = E.Range end
	if IsReady(_R) then R.Draw:Update("Range", R.Range()) end
	if IsReady(_W) then WDraw:Update("Range", WRange) end
	Mix:ForceTarget(target)
end

local function GetRTarget()
	local RTarget = nil
	for i = 1, C do
		local enemy = Enemies[i]
		if ValidTarget(enemy, R.Range()) then
			if not RTarget or GetHP2(enemy) - R.Damage(enemy) < GetHP2(RTarget) - R.Damage(RTarget) then
				RTarget = enemy
			end
		end
	end
		return RTarget
end

local function UpdateBuff(unit, buff)
	if unit == myHero then
		if buff.Name:lower() == "kogmawlivingartillerycost" then R.Count = buff.Count end
		if buff.Name:lower() == "kogmawbioarcanebarrage" then
			UpdateDelay(true)
			Target.range = WRange
		end
	end
end

local function RemoveBuff(unit, buff)
	if unit == myHero then
		if buff.Name:lower() == "kogmawlivingartillerycost" then R.Count = 1 end
		if buff.Name:lower() == "kogmawbioarcanebarrage" then
			UpdateDelay(false)
			Target.range = 600
		end
    end
end

---------------------------------------------
local function Tick()
	if myHero.dead or not Enemies[C] then return end
	Updating()
	target = Target:GetTarget()
	local mode = Mix:Mode()

	if target and mode == "Combo" and NS_Kog.misc.sme.b1:Value() and 0.625*myHero.attackSpeed >= NS_Kog.misc.sme.b2:Value() then
		if EnemiesAround(myHero.pos, 300) > 0 or (GetDistance(target) >= 300 and GetDistance(target) <= myHero.range - 85) then
			Mix:BlockMovement(true)
		else
			Mix:BlockMovement(false)
		end
	else
		Mix:BlockMovement(false)
	end

	if mode == "Combo" and CCast then
		if IsReady(_E) and NS_Kog.E.cb:Value() then CastE(target) end
		if IsReady(_W) and NS_Kog.W.cb:Value() then CastW() end
		if IsReady(_Q) and NS_Kog.Q.cb:Value() then CastQ(target) end
		if IsReady(_R) and NS_Kog.R.cb:Value() and ManaCheck(NS_Kog.misc.rc.R3:Value()) and NS_Kog.misc.rc.R2:Value() > R.Count and ((NS_Kog.misc.rc.R1:Value() and myHero.mana - 40*R.Count >= 40) or not NS_Kog.misc.rc.R1:Value()) then CastR(GetRTarget()) end
	end

    if mode == "Harass" and CCast then
		if IsReady(_E) and NS_Kog.E.hr:Value() and ManaCheck(NS_Kog.E.MPhr:Value()) then CastE(target) end
		if IsReady(_Q) and NS_Kog.Q.hr:Value() and ManaCheck(NS_Kog.Q.MPhr:Value()) then CastE(target) end
		if IsReady(_R) and NS_Kog.R.hr:Value() and ManaCheck(NS_Kog.R.MPhr:Value()) and NS_Kog.misc.rc.R2:Value() > R.Count and ((NS_Kog.misc.rc.R1:Value() and myHero.mana - 40*R.Count >= 40) or not NS_Kog.misc.rc.R1:Value()) then CastR(GetRTarget()) end
	end

	if mode == "LaneClear" then
		Cr:Update()
		if CCast then
			LaneClear()
			JungleClear()
		end
	end

	KillSteal()
end

local function Drawings()
	if myHero.dead or not Enemies[C] then return end
	DmgHPBar()
	DrawRange()
end
------------------------------------

OnLoad(function()
	HPBar = DrawDmgOnHPBar(NS_Kog.dw, {ARGB(200, 89, 0 ,179), ARGB(200, 0, 245, 255), ARGB(200, 0, 217, 108)}, {"R", "Q", "E"})
	OnUpdateBuff(UpdateBuff)
	OnRemoveBuff(RemoveBuff)
	OnTick(Tick)
	OnDraw(Drawings)
end)
