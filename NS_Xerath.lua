--[[ NEETSeries's plugin
	 ___  ___  _______   _______        __  ___________  __    __   
	|"  \/"  |/"     "| /"      \      /""\("     _   ")/" |  | "\  
	 \   \  /(: ______)|:        |    /    \)__/  \\__/(:  (__)  :) 
	  \\  \/  \/    |  |_____/   )   /' /\  \  \\_ /    \/      \/  
	  /\.  \  // ___)_  //      /   //  __'  \ |.  |    //  __  \\  
	 /  \   \(:      "||:  __   \  /   /  \\  \\:  |   (:  (  )  :) 
	|___/\___|\_______)|__|  \___)(___/    \___)\__|    \__|  |__/  

---------------------------------------]]
local Enemies, C, HPBar, CCast = { }, 0, { }, false
local huge, max, min = math.huge, math.max, math.min
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

local GetLineFarmPosition2 = function (range, width, objects)
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
local EObj, WObj = nil, nil
local Q = { Range = 0, minRange = 750, maxRange = 1460, Range2 = 0,         Speed = huge, Delay = 0.6,   Width = 100, Damage = function(unit) return CalcDmg(2, unit, 40 + 40*GetData(_Q).level + 0.75*myHero.ap) end, Charging = false, LastCastTime = 0}
local W = { Range = GetData(_W).range,                                      Speed = huge, Delay = 0.85,  Width = 220, Damage = function(unit) return CalcDmg(2, unit, 45 + 45*GetData(_W).level + 0.9*myHero.ap) end, LastCastTime = 0}
local E = { Range = GetData(_E).range,                                      Speed = 1500, Delay = 0.25,  Width = 73,  Damage = function(unit) return CalcDmg(2, unit, 50 + 30*GetData(_E).level + 0.45*myHero.ap) end, LastCastTime = 0}
local R = { Range = function() return 2000 + 1200*GetData(_R).level end,    Speed = huge, Delay = 0.72,  Width = 195, Damage = function(unit) return CalcDmg(2, unit, 170 + 30*GetData(_R).level + 0.43*myHero.ap) end, Activating = false, Count = max(3, GetData(_R).level + 2), Delay1 = 0, Delay2 = 0, Delay3 = 0, Delay4 = 0, Delay5 = 0}
if GotBuff(myHero, "xerathlocusofpower2") > 0 then R.Activating = true R.Delay1 = os.clock() end
local Cr = __MinionManager(Q.maxRange, W.Range)
local function CanCast(t, target)
	if (t == "W" and WObj and GetDistanceSqr(myHero, WObj.pos) >= GetDistanceSqr(myHero, target.pos)) then
		return false
	end
	if (t == "E" and WObj and GetDistanceSqr(myHero, EObj.pos) >= GetDistanceSqr(myHero, target.pos)) then
		return false
	end
	return true
end

local NS_Xe = MenuConfig("NS_Xerath", "[NEET Series] - Xerath")

	--[[ Q Settings ]]--
	AddMenu(NS_Xe, "Q", true, "Q Settings", {true, true, true, true, true, false}, 15)
	NS_Xe.Q:Slider("h", "Q LaneClear if hit Minions >= ", 2, 1, 10, 1)
	NS_Xe.Q.Pred.callback = function(v) Q.Prediction.Pred = pred[v] LoadGPred(v) end
	LoadGPred(NS_Xe.Q.Pred:Value())

	--[[ W Settings ]]--
	AddMenu(NS_Xe, "W", true, "W Settings", {true, true, true, true, true, false}, 15)
	NS_Xe.W:Slider("h", "W LaneClear if hit Minions >= ", 2, 1, 10, 1)
	NS_Xe.W.Pred.callback = function(v) W.Prediction.Pred = pred[v] LoadGPred(v) end
	LoadGPred(NS_Xe.W.Pred:Value())

	--[[ E Settings ]]--
	AddMenu(NS_Xe, "E", true, "E Settings", {true, true, false, true, true, false}, 15)
	NS_Xe.E.Pred.callback = function(v) E.Prediction.Pred = pred[v] LoadGPred(v) end
	LoadGPred(NS_Xe.E.Pred:Value())

	--[[ Ignite Settings ]]--
	if Ignite then AddMenu(NS_Xe, "Ignite", false, "Ignite Settings", {false, false, false, false, true, false}) end

	--[[ Ultimate Menu ]]--
	NS_Xe:Menu("ult", "Ultimate Settings")
		NS_Xe.ult:DropDown("Pred", "Choose Prediction:", 1, pred, function(v) R.R1Prediction.Pred = pred[v] R.R2Prediction.Pred = pred[v] R.R3Prediction.Pred = pred[v] LoadGPred(v) end)
		LoadGPred(NS_Xe.ult.Pred:Value())
		NS_Xe.ult:Menu("use", "Active Mode")
			NS_Xe.ult.use:DropDown("mode", "Choose Your Mode:", 1, {"Press R", "Auto Use"}, function(v) if v == 2 then NS_Xe.ult.cast.mode:Value(v) end end)
			NS_Xe.ult.use:Info("if1", "-- Press R: You Must PressR")
			NS_Xe.ult.use:Info("if2", "To enable AutoCasting")
			NS_Xe.ult.use:Info("if3", "-- Auto Use: Auto ActiveR")
			NS_Xe.ult.use:Info("if4", "if find Target Killable")
			NS_Xe.ult.use:Info("if5", "-- Note: It Only Active Ult Not AutoCast")
			NS_Xe.ult.use:Info("if6", "-- Recommend using Press R Mode")
		NS_Xe.ult:Menu("cast", "Casting Mode")
			NS_Xe.ult.cast:DropDown("mode", "Choose Your Mode:", 1, {"Press Key", "Auto Cast", "Target In Mouse Range"})
			NS_Xe.ult.cast:KeyBinding("key", "Seclect Key For PressKey Mode:", 84)
			NS_Xe.ult.cast:Slider("range", "Range for Target NearMouse", 500, 200, 1500, 50, function(value) R.Draw2:Update("Range", value) end)
			NS_Xe.ult.cast:Info("if1", "Press Key: Press a Key everywhere to AutoCast")
			NS_Xe.ult.cast:Info("if2", "Auto Cast: AutoCasting Target")
			NS_Xe.ult.cast:Info("if3", "Mouse: AutoCast Target in Mouse Range")
			NS_Xe.ult.cast:Info("if4", "Recommend using Press Key")

	--[[ Misc Menu ]]--
	NS_Xe:Menu("misc", "Misc Mode")
		NS_Xe.misc:Menu("castCombo", "Combo Casting")
			NS_Xe.misc.castCombo:Info("if", "Only Cast QWE if W or E Ready")
			NS_Xe.misc.castCombo:Boolean("WE", "Enable? (default off)", false)
		NS_Xe.misc:Menu("hc", "Spell HitChance")
			NS_Xe.misc.hc:Slider("Q", "Q Hit-Chance", 25, 1, 100, 1, function(value) Q.Prediction.data.hc = value*0.01 end)
			NS_Xe.misc.hc:Slider("W", "W Hit-Chance", 25, 1, 100, 1, function(value) W.Prediction.data.hc = value*0.01 end)
			NS_Xe.misc.hc:Slider("E", "E Hit-Chance", 30, 1, 100, 1, function(value) E.Prediction.data.hc = value*0.01 end)
			NS_Xe.misc.hc:Slider("R", "R Hit-Chance", 40, 1, 100, 1, function(value) R.R1Prediction.data.hc = value*0.01 R.R2Prediction.data.hc = value*0.01 R.R3Prediction.data.hc = value*0.01 end)
		NS_Xe.misc:Menu("delay", "R Casting Delays")
			NS_Xe.misc.delay:Slider("c1", "Delay CastR 1 (ms)", 230, 0, 1500, 1)
			NS_Xe.misc.delay:Slider("c2", "Delay CastR 2 (ms)", 250, 0, 1500, 1)
			NS_Xe.misc.delay:Slider("c3", "Delay CastR 3 (ms)", 270, 0, 1500, 1)
			NS_Xe.misc.delay:Slider("c4", "Delay CastR 4 (ms)", 290, 0, 1500, 1)
			NS_Xe.misc.delay:Slider("c5", "Delay CastR 5 (ms)", 310, 0, 1500, 1)
		NS_Xe.misc:KeyBinding("E", "Use E in Combo/Harass (Z)", 90, true, function() end, true)
		NS_Xe.misc:KeyBinding("escape", "Escape use W/E (G)", 71)
		SetSkin(NS_Xe.misc, {"Classic", "Runeborn", "Battlecast", "Scorched Earth", "Guardian Of The Sands", "Disable"})

	--[[ Drawings Menu ]]--
	NS_Xe:Menu("dw", "Drawings Mode")
		NS_Xe.dw:Boolean("R", "Draw R Range Minimap", true)
		NS_Xe.dw:Boolean("TK", "Draw Text Target R Killable", true)

	PermaShow(NS_Xe.misc.escape)
	PermaShow(NS_Xe.misc.E)
-----------------------------------

Q.Target = ChallengerTargetSelector(Q.maxRange, 2, false, nil, false, NS_Xe.Q, false, 4)
W.Target = ChallengerTargetSelector(W.Range, 2, false, nil, false, NS_Xe.W, false, 4)
E.Target = ChallengerTargetSelector(E.Range, 2, true, nil, false, NS_Xe.E, false, 7)
Q.Target.Menu.TargetSelector.TargetingMode.callback = function(id) Q.Target.Mode = id end
W.Target.Menu.TargetSelector.TargetingMode.callback = function(id) W.Target.Mode = id end
E.Target.Menu.TargetSelector.TargetingMode.callback = function(id) E.Target.Mode = id end

Q.Draw  = DCircle(NS_Xe.dw, "Draw Q Full Range", Q.maxRange, ARGB(150, 0, 245, 255))
Q.Draw2 = DCircle(NS_Xe.dw, "Draw Q Current Range", Q.minRange, ARGB(150, 0, 245, 255))
W.Draw  = DCircle(NS_Xe.dw, "Draw W Range", W.Range, ARGB(150, 186, 85, 211))
E.Draw  = DCircle(NS_Xe.dw, "Draw E Range", E.Range, ARGB(150, 0, 217, 108))
R.Draw  = DCircle(NS_Xe.dw, "Draw R Range", R.Range(), ARGB(150, 89, 0 ,179))
R.Draw2 = DCircle(NS_Xe.ult.cast, "Draw NearMouse Range", NS_Xe.ult.cast.range:Value(), ARGB(150, 255, 255, 0))

Q.Prediction = PredictSpell(_Q, Q.Delay, Q.Speed, Q.Width, Q.maxRange, false, 0, true, "linear", "Xerath Q", NS_Xe.misc.hc.Q:Value()*0.01, pred[NS_Xe.Q.Pred:Value()], {s2 = true})
W.Prediction = PredictSpell(_W, W.Delay, W.Speed, W.Width, W.Range, false, 0, true, "circular", "Xerath W", NS_Xe.misc.hc.W:Value()*0.01, pred[NS_Xe.W.Pred:Value()])
E.Prediction = PredictSpell(_E, E.Delay, E.Speed, E.Width, E.Range, true, 1, false, "linear", "Xerath E", NS_Xe.misc.hc.E:Value()*0.01, pred[NS_Xe.E.Pred:Value()])
R.R1Prediction = PredictSpell(_R, R.Delay, R.Speed, R.Width, 3200, false, 0, true, "circular", "Xerath R Lv 1", NS_Xe.misc.hc.R:Value()*0.01, pred[NS_Xe.ult.Pred:Value()])
R.R2Prediction = PredictSpell(_R, R.Delay, R.Speed, R.Width, 4400, false, 0, true, "circular", "Xerath R Lv 2", NS_Xe.misc.hc.R:Value()*0.01, pred[NS_Xe.ult.Pred:Value()])
R.R3Prediction = PredictSpell(_R, R.Delay, R.Speed, R.Width, 5600, false, 0, true, "circular", "Xerath R Lv 3", NS_Xe.misc.hc.R:Value()*0.01, pred[NS_Xe.ult.Pred:Value()])

ChallengerAntiGapcloser(NS_Xe.misc, function(o, s) if not ValidTarget(o, E.Range) or not IsReady(_E) or (s.spell.name == "AlphaStrike" and s.endTime - GetTickCount() > 650) or ((s.spell.name == "KatarinaE" or s.spell.name == "RiftWalk" or s.spell.name == "TalonCutThroat") and s.endTime - GetTickCount() > 750) then return end E.Prediction:Cast(o) end)
ChallengerInterrupter(NS_Xe.misc, function(o, s) if not ValidTarget(o, E.Range) or not IsReady(_E) or ((s.spell.name == "VarusQ" or s.spell.name == "Drain") and s.endTime - GetTickCount() > 2400) then return end E.Prediction:Cast(o) end)
-----------------------------------

local function CastR(target)
	if not target or R.Count == 0 then return end
	local RData = {
		[3] = {
			[3] = { delay = R.Delay1, menu = NS_Xe.misc.delay.c1:Value() },
			[2] = { delay = R.Delay2, menu = NS_Xe.misc.delay.c2:Value() },
			[1] = { delay = R.Delay3, menu = NS_Xe.misc.delay.c3:Value() }
		},

		[4] = {
			[4] = { delay = R.Delay1, menu = NS_Xe.misc.delay.c1:Value() },
			[3] = { delay = R.Delay2, menu = NS_Xe.misc.delay.c2:Value() },
			[2] = { delay = R.Delay3, menu = NS_Xe.misc.delay.c3:Value() },
			[1] = { delay = R.Delay4, menu = NS_Xe.misc.delay.c4:Value() },
		},

		[5] = {
			[5] = { delay = R.Delay1, menu = NS_Xe.misc.delay.c1:Value() },
			[4] = { delay = R.Delay2, menu = NS_Xe.misc.delay.c2:Value() },
			[3] = { delay = R.Delay3, menu = NS_Xe.misc.delay.c3:Value() },
			[2] = { delay = R.Delay4, menu = NS_Xe.misc.delay.c4:Value() },
			[1] = { delay = R.Delay5, menu = NS_Xe.misc.delay.c5:Value() },
		}
	}

	if RData[2+GetData(_R).level] and os.clock() - RData[2+GetData(_R).level][R.Count].delay >= RData[2+GetData(_R).level][R.Count].menu/1000 then
		if GetData(_R).level == 1 then
			R.R1Prediction:Cast(target)
		elseif GetData(_R).level == 2 then
			R.R2Prediction:Cast(target)
		elseif GetData(_R).level == 3 then
			R.R3Prediction:Cast(target)
		end
	end
end

local function CastQ(target)
	if not IsReady(_Q) or not ValidTarget(target, Q.maxRange + 80) then return end
	if not Q.Charging then
		if os.clock() - W.LastCastTime > 0.1 and CanCast("W", target) and CanCast("E", target) then CastSkillShot(_Q, GetMousePos()) end
	else
		Q.Prediction:Cast(target, Q.Range2)
	end
end

local function CastW(target)
	if not IsReady(_W) or not ValidTarget(target, W.Range + 80) or not CanCast("E", target) or os.clock() - Q.LastCastTime < 0.2 then return end
		W.Prediction:Cast(target)
end

local function CastE(target)
	if not IsReady(_E) or not ValidTarget(target, E.Range + 50) or not CanCast("W", target) or os.clock() - Q.LastCastTime < 0.2 then return end
		E.Prediction:Cast(target)
end

local function GetRTarget(pos, range)
	local RTarget = nil
	for i = 1, C do
		local enemy = Enemies[i]
		if ValidTarget(enemy, 2000 + 1200*GetData(_R).level) and GetDistanceSqr(pos, enemy.pos) <= range * range then
			if not RTarget or GetHP2(enemy) - R.Damage(enemy) * R.Count < GetHP2(RTarget) - R.Damage(RTarget) * R.Count then
				RTarget = enemy
			end
		end
	end
		return RTarget
end

local function CheckRUsing()
	if not IsReady(_R) then return end
	if NS_Xe.ult.use.mode:Value() == 2 then
		local target = GetRTarget(myHero.pos, R.Range())
		if target and GetHP2(target) < R.Damage(target) * R.Count then
			CastSpell(_R)
			R.Activating = true
		end
	end
end

local function CheckRCasting()
	if not IsReady(_R) then return end
	if NS_Xe.ult.cast.mode:Value() < 3 then
		local target = GetRTarget(myHero.pos, R.Range())
		if NS_Xe.ult.cast.mode:Value() == 1 and NS_Xe.ult.cast.key:Value() then
			CastR(target)
		elseif NS_Xe.ult.cast.mode:Value() == 2 then
			CastR(target)
		end
	else
		local target = GetRTarget(GetMousePos(), NS_Xe.ult.cast.range:Value())
		CastR(target)
	end
end

local function UpdateValues()
	if IsReady(_Q) and Q.Charging then
		Q.Range = min(Q.minRange + (os.clock() - Q.LastCastTime)*500, Q.maxRange)
		Q.Range2 = min(735 + (os.clock() - Q.LastCastTime)*500, Q.maxRange)
	end
	if IsReady(_R) then
		if not R.Activating then
			CheckRUsing()
		else
			CheckRCasting()
			if EnemiesAround(myHero.pos, 1000) == 0 then
				Mix:BlockOrb(true)
			else
				Mix:BlockOrb(false)
			end
		end
	end

	if WObj and os.clock() - W.LastCastTime >= W.Delay then WObj = nil end
	if EObj and os.clock() - E.LastCastTime >= E.Range/E.Speed then EObj = nil end

	for i = 1, C do
		local enemy = Enemies[i]
		if ValidTarget(enemy, R.Range()) and HPBar[i] then
			HPBar[i]:SetValue(1, enemy, R.Damage(enemy)*R.Count, IsSReady(_R))
			HPBar[i]:SetValue(2, enemy, Q.Damage(enemy), IsSReady(_Q))
			HPBar[i]:SetValue(3, enemy, W.Damage(enemy), IsSReady(_W))
			HPBar[i]:SetValue(4, enemy, E.Damage(enemy), IsSReady(_E))
			HPBar[i]:CheckValue()
		end
	end

	if IsReady(_Q) then Q.Draw2:Update("Range", Q.Range) end
	if IsReady(_R) then R.Draw:Update("Range", R.Range()) end

end

local function ProcSpellCast(unit, spell)
	if unit == myHero and not unit.dead then
		if spell.name:lower() == "xeratharcanebarrage2" then
			W.LastCastTime = os.clock() + spell.windUpTime
		elseif spell.name:lower() == "xerathmagespear" then
			E.LastCastTime = os.clock() + 0.3
		end

		if spell.name:lower() ~= "xerathlocuspulse" then return end
		R.Count = R.Count - 1
		local time = os.clock() + 0.8
		local count = 2 + GetData(_R).level
		if count == 3 then
			if R.Count == 2 then
				R.Delay2 = time
			elseif R.Count == 1 then
				R.Delay3 = time
			end
		elseif count == 4 then
			if R.Count == 3 then
				R.Delay2 = time
			elseif R.Count == 2 then
				R.Delay3 = time
			elseif R.Count == 1 then
				R.Delay4 = time
			end
		elseif count == 5 then
			if R.Count == 4 then
				R.Delay2 = time
			elseif R.Count == 3 then
				R.Delay3 = time
			elseif R.Count == 2 then
				R.Delay4 = time
			elseif R.Count == 1 then
				R.Delay5 = time
			end
		end
	end
end

local function UpdateBuff(unit, buff)
	if unit == myHero and not unit.dead then
		if buff.Name:lower() == "xeratharcanopulsechargeup" then
			Q.LastCastTime = os.clock()
			Q.Charging = true
		elseif buff.Name:lower() == "xerathlocusofpower2" then
			R.Count = GetData(_R).level + 2
			R.Delay1 = os.clock()
			R.Activating = true
		end
	end
end

local function RemoveBuff(unit, buff)
	if unit == myHero and not unit.dead then
		if buff.Name:lower() == "xeratharcanopulsechargeup" then
			Q.Charging = false
			Q.Range = Q.minRange
			Q.Range2 = Q.minRange
		elseif buff.Name:lower() == "xerathlocusofpower2" then
			R.Activating = false
			R.Count = GetData(_R).level + 2
			Mix:BlockOrb(false)
		end
	end
end

local function CreateObj(obj)
	if obj.team == myHero.team and obj.name == "Xerath_Base_E_mis.troy" then
		EObj = obj
	end

	if obj.team == myHero.team and obj.name == "Xerath_Base_W_aoe_green.troy" then
		WObj = obj
	end
end

local function DeleteObj(obj)
	if obj.team == myHero.team and obj.name == "Xerath_Base_E_mis.troy" then
		EObj = nil
	end

	if obj.team == myHero.team and obj.name == "Xerath_Base_W_aoe_green.troy" then
		WObj = nil
	end
end


local function KillSteal()
	for i = 1, C do
		local enemy = Enemies[i]
		if Ignite and IsReady(Ignite) and NS_Xe.Ignite.ks:Value() and ValidTarget(enemy, 600) then
			local hp, dmg = Mix:HealthPredict(enemy, 2500, "OW") + enemy.hpRegen*2.5 + enemy.shieldAD, 50 + 20*myHero.level
			if hp > 0 and dmg > hp then CastTargetSpell(enemy, Ignite) end
		end

		local EnemyHP = GetHP2(enemy)
		if IsReady(_E) and NS_Xe.E.ks:Value() and ManaCheck(NS_Xe.E.MPks:Value()) and EnemyHP < E.Damage(enemy) then
			CastE(enemy)
		end

		if IsReady(_W) and NS_Xe.W.ks:Value() and ManaCheck(NS_Xe.W.MPks:Value()) and EnemyHP < W.Damage(enemy) then
			CastW(enemy)
		end

		if IsReady(_Q) and NS_Xe.Q.ks:Value() and (ManaCheck(NS_Xe.Q.MPks:Value()) or Q.Charging) and EnemyHP < Q.Damage(enemy) then
			CastQ(enemy)
		end
	end
end

local function LaneClear()
	if IsReady(_W) and NS_Xe.W.lc:Value() and ManaCheck(NS_Xe.W.MPlc:Value()) then
		local WPos, WHit = GetFarmPosition2(W.Range, W.Width, Cr.tminion)
		if WHit >= NS_Xe.W.h:Value() then CastSkillShot(_W, WPos) end
	end
	if IsReady(_Q) and NS_Xe.Q.lc:Value() and (ManaCheck(NS_Xe.W.MPlc:Value()) or Q.Charging) then
		local QPos, QHit = GetLineFarmPosition2(Q.maxRange, Q.Width, Cr.tminion)
		if not Q.Charging then
			if QHit >= NS_Xe.Q.h:Value() and os.clock() - W.LastCastTime > 0.1 then
				CastSkillShot(_Q, GetMousePos())
			end
		else
			if GetDistance(QPos) <= Q.Range then
				CastSkillShot2(_Q, QPos)
			end
		end
	end
end

local function JungleClear()
	if not Cr.tmob[1] then return end
	local mob = Cr.tmob[1]
	if IsReady(_W) and NS_Xe.W.jc:Value() and ManaCheck(NS_Xe.W.MPjc:Value()) then CastSkillShot(_W, Vector(mob)) end
	if IsReady(_E) and NS_Xe.E.jc:Value() and ManaCheck(NS_Xe.E.MPjc:Value()) and ValidTarget(mob, E.Range) then CastSkillShot(_E, Vector(mob)) end
	if IsReady(_Q) and NS_Xe.Q.jc:Value() and (ManaCheck(NS_Xe.Q.MPjc:Value()) or Q.Charging) then if not Q.Charging then CastSkillShot(_Q, GetMousePos()) elseif ValidTarget(mob, Q.Range) then CastSkillShot2(_Q, Vector(mob)) end end
end

local function Escape(Wtarget, ETarget)
	Mix:Move()
	if (IsReady(_W) and WTarget) then
		CastW(WTarget)
		return
	end
	if (IsReady(_E) and ETarget) then
		CastE(ETarget)
		return
	end
end

local function DrawRange()
	if IsSReady(_Q) then
		Q.Draw:Draw(myHero.pos)
		Q.Draw2:Draw(myHero.pos)
	end
	if IsSReady(_W) then W.Draw:Draw(myHero.pos) end
	if IsSReady(_E) then E.Draw:Draw(myHero.pos) end
	if NS_Xe.ult.cast.mode:Value() == 3 and R.Activating then R.Draw2:Draw(GetMousePos()) end
	if IsSReady(_R) then R.Draw:Draw(myHero.pos) end
end

local function DmgHPBar()
	for i = 1, C do
		if ValidTarget(Enemies[i], R.Range()) and HPBar[i] then
			HPBar[i]:Draw()
		end
	end
end

function RKillable()
	local d = 0
	for i = 1, C do
		local enemy = Enemies[i]
		d = d + 1
		if ValidTarget(enemy, R.Range()) and GetHP2(enemy) < R.Damage(enemy) * R.Count then
			DrawText(enemy.charName.." R Killable", 30, GetResolution().x/80, GetResolution().y/7+d*26, GoS.Red)
		end
	end
end

local function DrawRRange()
	if not IsSReady(_R) then return end
	if NS_Xe.dw.R:Value() then DrawCircleMinimap(myHero.pos, R.Range(), 1, 120, 0x20FFFF00) end
end
------------------------------------

local function Tick()
	if myHero.dead or not Enemies[C] then return end
	UpdateValues()
	if R.Activating then return end
	local QTarget = IsReady(_Q) and Q.Target:GetTarget()
	local WTarget = IsReady(_W) and W.Target:GetTarget()
	local ETarget = IsReady(_E) and E.Target:GetTarget()
	local mode = Mix:Mode()
	if mode == "Combo" and CCast then
		if (NS_Xe.misc.castCombo.WE:Value() and (IsReady(_W) or IsReady(_E))) or not NS_Xe.misc.castCombo.WE:Value() then
			if NS_Xe.E.cb:Value() and NS_Xe.misc.E:Value() and ETarget then CastE(ETarget) end
			if NS_Xe.W.cb:Value() and WTarget then CastW(WTarget) end
			if NS_Xe.Q.cb:Value() and QTarget then CastQ(QTarget) end
		end
	end

	if mode == "Harass" and CCast then
		if NS_Xe.E.hr:Value() and ManaCheck(NS_Xe.E.MPhr:Value()) and NS_Xe.misc.E:Value() and ETarget then CastE(ETarget) end
		if NS_Xe.W.hr:Value() and ManaCheck(NS_Xe.W.MPhr:Value()) and WTarget then CastW(WTarget) end
		if NS_Xe.Q.hr:Value() and ManaCheck(NS_Xe.Q.MPhr:Value()) and QTarget then CastQ(QTarget) end
	end
	if mode == "Harass" and IsReady(_Q) and Q.Charging and QTarget and not R.Activating then CastQ(QTarget) end

	if mode == "LaneClear" then
		Cr:Update()
		if CCast then
			LaneClear()
			JungleClear()
		end
	end

	if EnemiesAround(myHero, Q.maxRange) > 0 then KillSteal() end

	if NS_Xe.misc.escape:Value() then Escape(WTarget, ETarget) end
end

local function Drawings()
	if myHero.dead or not Enemies[C] then return end
	if NS_Xe.dw.TK:Value() and IsSReady(_R) then RKillable() end
	DmgHPBar()
	DrawRange()
end
------------------------------------

OnLoad(function()
	HPBar = DrawDmgOnHPBar(NS_Xe.dw, {ARGB(200, 89, 0 ,179), ARGB(200, 0, 245, 255), ARGB(200, 186, 85, 211), ARGB(200, 0, 217, 108)}, {"R", "Q", "W", "E"})
	OnProcessSpellCast(ProcSpellCast)
	OnUpdateBuff(UpdateBuff)
	OnRemoveBuff(RemoveBuff)
	OnCreateObj(CreateObj)
	OnDeleteObj(DeleteObj)
	OnTick(Tick)
	OnDraw(Drawings)
	OnDrawMinimap(DrawRRange)
end)
