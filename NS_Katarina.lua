--[[ NEETSeries's plugin
	 __   ___       __  ___________   __        _______    __    _____  ___        __      
	|/"| /  ")     /""\("     _   ") /""\      /"      \  |" \  (\"   \|"  \      /""\     
	(: |/   /     /    \)__/  \\__/ /    \    |:        | ||  | |.\\   \    |    /    \    
	|    __/     /' /\  \  \\_ /   /' /\  \   |_____/   ) |:  | |: \.   \\  |   /' /\  \   
	(// _  \    //  __'  \ |.  |  //  __'  \   //      /  |.  | |.  \    \. |  //  __'  \  
	|: | \  \  /   /  \\  \\:  | /   /  \\  \ |:  __   \  /\  |\|    \    \ | /   /  \\  \ 
	(__|  \__)(___/    \___)\__|(___/    \___)|__|  \___)(__\_|_)\___|\____\)(___/    \___)

---------------------------------------]]
local Enemies, C, HPBar = { }, 0, { }
local huge, max, min = math.huge, math.max, math.min
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

--------------------------------------------------------------------------------
local check = { Q = { }, R = false, LastCastTime = 0, wards = { }, cast = true }
local Q = { Range = GetData(_Q).range, Speed = 1500, Delay = 0.25, Damage = function(unit) return CalcDmg(2, unit, 35 + 25*GetData(_Q).level + 0.45*myHero.ap) end, time = { last = 0, unit = { sPos = nil, obj = nil} }}
local W = { Range = GetData(_W).range, Speed = huge, Delay = 0.3,  Damage = function(unit) return CalcDmg(2, unit, 5 + 35*GetData(_W).level + 0.25*myHero.ap + 0.6*myHero.totalDamage) end, Width = 375}
local E = { Range = GetData(_E).range, Damage = function(unit) return CalcDmg(2, unit, 10 + 30*GetData(_E).level + 0.25*myHero.ap) end}
local R = { Range = GetData(_R).range, Damage = function(unit) return CalcDmg(2, unit, 150 + 200*GetData(_R).level + 2.5*myHero.ap + 3.75*myHero.totalDamage) end}
local Cr = __MinionManager(E.Range, E.Range)
local WardCheck, target = Set({"SightWard", "VisionWard", "YellowTrinket"}), nil

local NS_Kata = MenuConfig("NS_Katarina", "[NEET Series] - Katarina")

	--[[ Q Settings ]]--
	AddMenu(NS_Kata, "Q", false, "Q Settings", {true, true, true, true, true, true})
	NS_Kata.Q:Boolean("Ahr", "Auto Q Harass", false)

	--[[ W Settings ]]--
	AddMenu(NS_Kata, "W", false, "W Settings", {true, true, true, true, true, true})
	NS_Kata.W:Slider("h", "W LaneClear if hit Minions >= ", 2, 1, 10, 1)
	NS_Kata.W:Boolean("Ahr", "Auto W Harass", false)

	--[[ E Settings ]]--
	AddMenu(NS_Kata, "E", false, "E Settings", {true, true, true, true, true, true})
	NS_Kata.E:Boolean("Slc", "LaneClear Safe E", true)
	NS_Kata.E:Boolean("Slh", "LastHit Safe E", true)
	OnLoad(function()
		for i = 1, C do
			NS_Kata.E:Boolean("Oncb_"..Enemies[i].charName, "Combo - Use E on "..Enemies[i].charName, true)
			NS_Kata.E:Boolean("Onhr_"..Enemies[i].charName, "Harass - Use E on "..Enemies[i].charName, false)
		end
	end)

	--[[ R Settings ]]--
	NS_Kata:Menu("ult", "R Settings")
		NS_Kata.ult:Boolean("cb", "Use R in Combo", true)
		NS_Kata.ult:DropDown("set", "Set R Mode ", 1, {"Killable Check (recommend)", "If can hit x enemies"})
		NS_Kata.ult:Slider("hitR", "R if can hit enemies >=", 2, 1, 5, 1)
		NS_Kata.ult:Info("info", "Recommend choose \"Killable Check\"")

	--[[ Ignite Settings ]]--
	if Ignite then AddMenu(NS_Kata, "Ignite", false, "Ignite Settings", {false, false, false, false, true, false}) end

	--[[ Drawings Menu ]]--
	NS_Kata:Menu("dw", "Drawings Mode")
		NS_Kata.dw:Menu("DmgInfo", "Draw Damage Info")
			OnLoad(function() for i = 1, C do NS_Kata.dw.DmgInfo:Boolean(Enemies[i].charName, "Enable On "..Enemies[i].charName, true) end end)

	--[[ Misc Menu ]]--
	NS_Kata:Menu("misc", "Misc Mode")
		NS_Kata.misc:Menu("J", "E Jump Setting")
		NS_Kata.misc.J:Boolean("K", "Enable Auto Jump to KS", true)
		NS_Kata.misc.J:KeyBinding("F", "Flee - AutoJump (G)", 71)
		NS_Kata.misc.J:Boolean("Uw", "Use Ward", true)
		NS_Kata.misc.J:Boolean("P", "Put ward at maxRange", true)
		NS_Kata.misc.J:Info("if1", "Jump Priority: Hero -> Minion -> Ward")
	NS_Kata.misc:Menu("D", "Setting Spells Delay")
		NS_Kata.misc.D:Slider("Q", "Q Delay (ms)", 0, 0, 1000, 1)
		NS_Kata.misc.D:Slider("W", "W Delay (ms)", 0, 0, 1000, 1)
		NS_Kata.misc.D:Slider("E", "E Delay (ms)", 100, 0, 1000, 1)
	SetSkin(NS_Kata.misc, {"Classic", "Mercenary", "Red Card", "Bilgewater", "Kitty Cat", "High Command", "Sandstorm", "Slay Belle", "Warring Kingdoms", "PROJECT:", "Disable"})
	PermaShow(NS_Kata.misc.J.F)
-----------------------------------

Q.Draw = DCircle(NS_Kata.dw, "Draw Q Range", Q.Range, ARGB(150, 0, 245, 255))
W.Draw = DCircle(NS_Kata.dw, "Draw W Range", W.Range, ARGB(150, 0, 217, 108))
E.Draw = DCircle(NS_Kata.dw, "Draw E Range", E.Range, ARGB(150, 255, 255, 0))
R.Draw = DCircle(NS_Kata.dw, "Draw R Range", R.Range, ARGB(255, 186, 85, 211))
Target = ChallengerTargetSelector(E.Range, 2, false, nil, false, NS_Kata)
Target.Menu.TargetSelector.TargetingMode.callback = function(id) Target.Mode = id end
-----------------------------------

local function QBuff(unit)
	if IsReady(_Q) or check.Q[unit.networkID] then return CalcDmg(2, unit, 15*GetData(_Q).level + 0.2*myHero.ap) end
		return 0
end

local function DamageCheck(unit)
	local QDmg  = IsReady(_Q) and Q.Damage(unit) or 0
	local WDmg  = IsReady(_W) and W.Damage(unit) or 0
	local EDmg  = IsReady(_E) and E.Damage(unit) or 0
	local QBuff = (IsReady(_Q) or IsReady(_W) or IsReady(_E)) and QBuff(unit) or 0
		return QDmg + WDmg + EDmg + QBuff
end

local function CountCheck()
	local count = 0
	for i = 1, C do
		local enemy = Enemies[i]
		if enemy and ValidTarget(enemy) and GetDistanceSqr(enemy.pos) <= E.Range * E.Range and GetHP2(enemy) + enemy.hpRegen < DamageCheck(enemy) and not enemy.dead then
			count = count + 1
			if count > 1 then return count end
		end
	end
		return count
end

local function KillCheck()
	if (EnemiesAround(myHero.pos, E.Range) == 1 and CountCheck() == 1) or (EnemiesAround(myHero.pos, E.Range) > 1 and CountCheck() > 1) then return true end
		return false
end

local function Updates()
	if check.R and ((NS_Kata.ult.set:Value() == 1 and KillCheck()) or EnemiesAround(myHero.pos, 600) == 0) then Mix:BlockOrb(false) end
	for i = 1, C do
		local enemy = Enemies[i]
		if ValidTarget(enemy, 3000) and HPBar[i] then
			HPBar[i]:SetValue(1, enemy, R.Damage(enemy), IsSReady(_R))
			HPBar[i]:SetValue(2, enemy, Q.Damage(enemy), IsSReady(_Q))
			HPBar[i]:SetValue(3, enemy, W.Damage(enemy), IsSReady(_W))
			HPBar[i]:SetValue(4, enemy, E.Damage(enemy), IsSReady(_E))
			HPBar[i]:CheckValue()
		end
	end
end

local function CastQ(target)
	if not ValidTarget(target, Q.Range) or os.clock() - check.LastCastTime < NS_Kata.misc.D.Q:Value()*0.001 then return end
		CastTargetSpell(target, _Q)
end

local function CastW(target)
	if not ValidTarget(target, W.Range) or os.clock() - check.LastCastTime < NS_Kata.misc.D.W:Value()*0.001 then return end
		CastSpell(_W)
end

local function CastE(target)
	if not ValidTarget(target, E.Range) then return end
	if (target == Q.time.unit.obj and os.clock() - Q.time.last + GetLatency()*0.0005 >= GetDistance(Q.time.unit.sPos, Q.time.unit.obj.pos)/1800) or Q.time.unit.obj ~= target or not Q.time.unit.obj or Q.time.unit.obj.dead then
		if os.clock() - check.LastCastTime > NS_Kata.misc.D.E:Value()*0.001 then CastTargetSpell(target, _E) end
	end
end

local function CastR(target)
	if IsReady(_Q) or IsReady(_W) or IsReady(_E) then return end
	if (NS_Kata.ult.set:Value() == 1 and ValidTarget(target, 470) and GetHP2(target) + target.hpRegen*2.5 < R.Damage(target)) or (NS_Kata.ult.set:Value() == 2 and EnemiesAround(myHero.pos, 500) >= NS_Kata.ult.hitR:Value()) then
		CastSpell(_R)
	end
end

local function GetJump(Objects, Check, Team)
	local mPos, target = Vector(GetMousePos()), nil
	for _, m in pairs(Objects) do
		if (not Team or m.team == Team) and ((Check and GetDistance(mPos, m) <= 130) or not Check) and IsInDistance(m, E.Range) and m.visible and m.health > 0 and (not target or GetDistanceSqr(m, mPos) < GetDistanceSqr(target, mPos)) then
			target = m
		end
	end
		return target
end

local function PutWard(Position)
	local Yellow, Sight, Vision = Mix:GetSlotByName("trinkettotem", 6), Mix:GetSlotByName("ghostward", 6), Mix:GetSlotByName("visionward", 6)
	local Pos = NS_Kata.misc.J.P:Value() and Vector(myHero.pos + Vector(Position - myHero.pos):normalized()*590) or Vector(myHero.pos + Vector(Position - myHero.pos):normalized()*min(GetDistance(Position), 590))
	if Yellow and IsReady(Yellow) then
		CastSkillShot(Yellow, Pos)
	elseif Sight and IsReady(Sight) then
		CastSkillShot(Sight, Pos)
	elseif Vision and IsReady(Vision) then
		CastSkillShot(Vision, Pos)
	end
end

local function GetJumpTarget()
	local mPos = Vector(GetMousePos())
	if EnemiesAround(mPos, 130) > 0 then
		return GetJump(Enemies, true, MINION_ENEMY)
	elseif MinionsAround(mPos, 130, MINION_ENEMY) > 0 then
		return GetJump(minionManager.objects, true, MINION_ENEMY)
	elseif MinionsAround(mPos, 130, 300) > 0 then
		return GetJump(minionManager.objects, true, 300)
	elseif MinionsAround(mPos, 130, MINION_ALLY) > 0 then
		return GetJump(minionManager.objects, true, MINION_ALLY)
	elseif AlliesAround(mPos, 130) > 0 then
		return GetJump(GetAllyHeroes(), true, MINION_ALLY)
	else
		if CountObjectsNearPos(mPos, nil, 130, check.wards) > 0 then
			return GetJump(check.wards)
		elseif CountObjectsNearPos(Vector(myHero), nil, E.Range, check.wards) > 0 and GetDistanceSqr(mPos, GetJump(check.wards)) < GetDistanceSqr(mPos) then
			return GetJump(check.wards)
		elseif CountObjectsNearPos(mPos, nil, 300, check.wards) == 0 and NS_Kata.misc.J.Uw:Value() then
			PutWard(mPos)
		end
	end
		return nil
end

local function WardJumpKill()
	for i = 1, C do
		local enemy = Enemies[i]
		if GetDistanceSqr(enemy.pos) > E.Range*E.Range and ((IsReady(_W) and ValidTarget(enemy, 990) and W.Damage(enemy) + QBuff(enemy) > GetHP2(enemy) + enemy.hpRegen) or (IsReady(_Q) and ValidTarget(enemy, 1265) and Q.Damage(enemy) > GetHP2(enemy) + enemy.hpRegen*(0.2+GetDistance(enemy.pos)/1800))) then
			local jump = GetJumpTarget()
			if jump and ((IsReady(_W) and GetDistanceSqr(jump, enemy) < W.Range*W.Range) or (IsReady(_Q) and GetDistanceSqr(jump, enemy) < Q.Range*Q.Range)) then
				CastTargetSpell(jump, _E)
			end
		end
	end
end

local function UpdateBuff(unit, buff)
	if unit == myHero and buff.Name:lower() == "katarinarsound" then
		check.R = true
		Mix:BlockOrb(true)
	end
	if buff.Name:lower() == "katarinaqmark" and unit.team == MINION_ENEMY and GetDistanceSqr(unit) <= 4000000 then
		check.Q[unit.networkID] = true
	end
end

local function RemoveBuff(unit, buff)
	if unit == myHero and buff.Name:lower() == "katarinarsound" then
		check.R = false
		Mix:BlockOrb(false)
	end
	if buff.Name:lower() == "katarinaqmark" and unit.team == MINION_ENEMY and GetDistanceSqr(unit) <= 4000000 then
		table.remove(check.Q, unit.networkID)
	end
end

local function ProcSpellCast(unit, spell)
	if unit ~= myHero then return end
	if spell.name:lower() == "katarinaq" then
		check.LastCastTime = os.clock() + 0.25
		if spell.target.type == "AIHeroClient" then
			Q.time.last = os.clock()
			Q.time.unit.sPos = spell.startPos
			Q.time.unit.obj = spell.target
		end
		return
	end
	if spell.name:lower() == "katarinaw" then
		check.LastCastTime = os.clock() + 0.2
	end
	if spell.name:lower() == "katarinae" then
		check.LastCastTime = os.clock() + 0.15
	end
	if spell.name:lower() == "katarinar" and not check.R then
		check.R = true
		Mix:BlockOrb(true)
	end
end

local function CreateObj(obj)
	if WardCheck[obj.charName] then check.wards[#check.wards + 1] = obj end
end

local function DeleteObj(obj)
	if not WardCheck[obj.charName] then return end
	for w, ward in pairs(check.wards) do
		if ward == obj then
			table.remove(check.wards, w)
			return
		end
	end
end

local function KillSteal()
	if not target then return end
	if Ignite and IsReady(Ignite) and NS_Kata.Ignite.ks:Value() and ValidTarget(target, 600) then
		local hp, dmg = Mix:HealthPredict(target, 2500, "OW") + target.hpRegen*2.5 + target.shieldAD, 50 + 20*myHero.level
		if hp > 0 and dmg > hp then CastTargetSpell(target, Ignite) end
	end

	if IsReady(_Q) and NS_Kata.Q.ks:Value() and ValidTarget(target, Q.Range) then
		local HP = GetHP2(target) + target.hpRegen*(min(1, 0.2+GetDistance(target.pos)/1800))
		local WDmg = (IsReady(_W) and (IsReady(_E) or ValidTarget(target, W.Range))) and W.Damage(target) or 0
		if HP < WDmg + Q.Damage(target) + QBuff(target) then CastQ(target) end
	end

	if IsReady(_W) and NS_Kata.W.ks:Value()and ValidTarget(target, W.Range) then
		local HP = GetHP2(target) + target.hpRegen
		local QDmg = (IsReady(_Q) and (IsReady(_E) or ValidTarget(target, Q.Range))) and Q.Damage(target) or 0
		if HP < QDmg + W.Damage(target) + QBuff(target) then CastW(target) end
	end

	if IsReady(_E) and NS_Kata.E.ks:Value() then
		local HP = GetHP2(target) + target.hpRegen
		if HP < DamageCheck(target) then CastE(target) end
	end
end

local function LastHit()
	for _, m in pairs(Cr.tminion) do
		if IsReady(_Q) and NS_Kata.Q.lh:Value() and Q.Damage(m) + QBuff(m) > Mix:HealthPredict(m, GetDistance(m)/1.8 + 200, "OW") then
			CastTargetSpell(m, _Q)
		end
		if IsReady(_W) and NS_Kata.W.lh:Value() and ValidTarget(m, W.Range) and W.Damage(m) + QBuff(m) > m.health then
			CastSpell(_W)
		end
		if IsReady(_E) and NS_Kata.E.lh:Value() and m.health < E.Damage(m) + QBuff(m) then
			if NS_Kata.E.Slh:Value() and (EnemiesAround(m.pos, 1000) == 0 or GetDistance(m.pos) < 300) then CastTargetSpell(m, _E)
			elseif not NS_Kata.E.Slh:Value() then CastTargetSpell(m, _E) end
		end
	end
end

local function LaneClear()
	for _, m in pairs(Cr.tminion) do
		if IsReady(_W) and NS_Kata.W.lc:Value() and ValidTarget(m, W.Range) then
			if MinionsAround(myHero.pos, W.Range, MINION_ENEMY) >= NS_Kata.W.h:Value() or m.health < W.Damage(m) then CastSpell(_W) end
		end
		if IsReady(_Q) and NS_Kata.Q.lc:Value() and ValidTarget(m, Q.Range) then
			CastTargetSpell(m, _Q)
		end
		if IsReady(_E) and NS_Kata.E.lc:Value() and m.health < E.Damage(m) + QBuff(m) then
			if NS_Kata.E.Slc:Value() and (EnemiesAround(m.pos, 1000) == 0 or GetDistance(m.pos) < 300) then CastTargetSpell(m, _E)
			elseif not NS_Kata.E.Slc:Value() then CastTargetSpell(m, _E) end
		end
	end
end

local function JungleClear()
	if not Cr.tmob[1] then return end
	local mob = Cr.tmob[1]
	if IsReady(_Q) and NS_Kata.Q.jc:Value() and ValidTarget(mob, Q.Range) then
		CastQ(mob)
	end
	if IsReady(_W) and NS_Kata.W.jc:Value() and ValidTarget(mob, W.Range) then
		CastW(mob)
	end
	if IsReady(_E) and NS_Kata.E.jc:Value() and ValidTarget(mob, E.Range) then
		CastE(mob)
	end
end

local function Flee()
    Mix:Move()
	if not IsReady(_E) then return end
    local jtarget = GetJumpTarget()
    if jtarget then CastTargetSpell(jtarget, _E) end
end

local function DrawRange()
	if IsSReady(_Q) then Q.Draw:Draw(myHero.pos) end
	if IsSReady(_W) then W.Draw:Draw(myHero.pos) end
	if IsSReady(_E) then E.Draw:Draw(myHero.pos) end
	if IsSReady(_R) or check.R then R.Draw:Draw(myHero.pos) end
end

local function DmgHPBar()
	for i = 1, C do
		if ValidTarget(Enemies[i], 3000) and HPBar[i] then
			HPBar[i]:Draw()
		end
	end
end

local function DmgCheck()
	local Draw = function(enemy, text, status)
		if status == 1 then
			DrawText3D(text, enemy.pos.x, enemy.pos.y, enemy.pos.z, 16, GoS.Red, true)
			return
		end
		local QDmg, WDmg, EDmg, RDmg, QBonus = IsReady(_Q) and Q.Damage(enemy) or 0, IsReady(_W) and W.Damage(enemy) or 0, IsReady(_E) and E.Damage(enemy) or 0, (IsSReady(_R) or check.R) and R.Damage(enemy) or 0, QBuff(enemy)
		local dmg = text == "Full Combo + Ignite =" and (QDmg + WDmg + EDmg + RDmg + QBonus + 20*GetLevel(myHero)+50) or (QDmg + WDmg + EDmg + RDmg + QBonus)
		DrawText3D(string.format("%s %.1f%%", text, math.floor(dmg*100/(GetHP2(enemy) + enemy.hpRegen*2))), enemy.pos.x, enemy.pos.y, enemy.pos.z, 16, GoS.White, true)
	end
	for i = 1, C do
		local enemy = Enemies[i]
		if NS_Kata.dw.DmgInfo[enemy.charName]:Value() and ValidTarget(enemy, 3000) then
			local HP, QDmg, WDmg, EDmg, RDmg, Ignitee, QBonus = GetHP2(enemy) + enemy.hpRegen*2, IsReady(_Q) and Q.Damage(enemy) or 0, IsReady(_W) and W.Damage(enemy) or 0, IsReady(_E) and E.Damage(enemy) or 0, (IsSReady(_R) or check.R) and R.Damage(enemy) or 0, 20*GetLevel(myHero)+50 or 0, QBuff(enemy)
			local IgniteCheck = (Ignite and IsReady(Ignite)) and true or false
			if HP < EDmg + QBonus then Draw(enemy, "E = Kill!", 1)
			elseif HP < WDmg + QBonus then Draw(enemy, "W = Kill!", 1)
			elseif HP < QDmg + QBonus then Draw(enemy, "Q = Kill!", 1)
			elseif HP < EDmg + QBonus + WDmg then Draw(enemy, "E + W = Kill!", 1)
			elseif HP < EDmg + QBonus + QDmg then Draw(enemy, "E + Q = Kill!", 1)
			elseif HP < WDmg + QBonus + QDmg then Draw(enemy, "W + Q = Kill!", 1)
			elseif HP < QDmg + QBonus + WDmg + EDmg then Draw(enemy, "Q + W + E = Kill!", 1)
			elseif IgniteCheck and HP < Ignitee then Draw(enemy, "Ignite = Kill!", 1)
			elseif IgniteCheck and HP < Ignitee + QBonus + EDmg then Draw(enemy, "Ignite + E = Kill!", 1)
			elseif IgniteCheck and HP < Ignitee + QBonus + WDmg then Draw(enemy, "Ignite + W = Kill!")
			elseif IgniteCheck and HP < Ignitee + QBonus + QDmg then Draw(enemy, "Ignite + Q = Kill!", 1)
			elseif IgniteCheck and HP < Ignitee + QBonus + EDmg + WDmg then Draw(enemy, "Ignite + E + W = Kill!", 1)
			elseif IgniteCheck and HP < Ignitee + QBonus + EDmg + QDmg then Draw(enemy, "Ignite + E + Q = Kill!", 1)
			elseif IgniteCheck and HP < Ignitee + QBonus + WDmg + QDmg then Draw(enemy, "Ignite + W + Q = Kill!", 1)
			elseif IgniteCheck and HP < Ignitee + QBonus + QDmg + WDmg + EDmg then Draw(enemy, "Ignite + Q + W + E = Kill!", 1)
			elseif HP < RDmg + QBonus then Draw(enemy, "R = Kill!", 1)
			elseif HP < RDmg + QBonus + EDmg then Draw(enemy, "R + E = Kill!", 1)
			elseif HP < RDmg + QBonus + WDmg then Draw(enemy, "R + W = Kill!", 1)
			elseif HP < EDmg + QBonus + QDmg then Draw(enemy, "R + Q = Kill!", 1)
			elseif HP < RDmg + QBonus + EDmg + WDmg then Draw(enemy, "R + E + W = Kill!", 1)
			elseif HP < RDmg + QBonus + EDmg + QDmg then Draw(enemy, "R + E + Q = Kill!", 1)
			elseif HP < RDmg + QBonus + WDmg + QDmg then Draw(enemy, "R + W + Q = Kill!", 1)
			elseif HP < RDmg + QBonus + QDmg + WDmg + EDmg then Draw(enemy, "R + Q + W + E = Kill!", 1)
			elseif IgniteCheck and HP < RDmg + QBonus + Ignitee then Draw(enemy, "R + Ignite = Kill!", 1)
			elseif IgniteCheck and HP < RDmg + QBonus + Ignitee + EDmg then Draw(enemy, "R + Ignite + E = Kill!", 1)
			elseif IgniteCheck and HP < RDmg + QBonus + Ignitee + WDmg then Draw(enemy, "R + Ignite + W = Kill!")
			elseif IgniteCheck and HP < RDmg + QBonus + Ignitee + QDmg then Draw(enemy, "R + Ignite + Q = Kill!", 1)
			elseif IgniteCheck and HP < RDmg + QBonus + Ignitee + EDmg + WDmg then Draw(enemy, "R + Ignite + E + W = Kill!", 1)
			elseif IgniteCheck and HP < RDmg + QBonus + Ignitee + EDmg + QDmg then Draw(enemy, "R + Ignite + E + Q = Kill!", 1)
			elseif IgniteCheck and HP < RDmg + QBonus + Ignitee + WDmg + QDmg then Draw(enemy, "R + Ignite + W + Q = Kill!", 1)
			elseif IgniteCheck and HP < RDmg + QBonus + Ignitee + QDmg + WDmg + EDmg then Draw(enemy, "R + Ignite + Q + W + E = Kill!", 1)
			else
				if IgniteCheck then Draw(enemy, "Full Combo + Ignite =", 0) else Draw(enemy, "Full Combo =", 0) end
			end
		end
	end
end
------------------------------------

local function Tick()
	if myHero.dead or not Enemies[C] then return end
	Updates()
	target = Target:GetTarget()
	local mode = Mix:Mode()
	if mode == "Combo" and target and not check.R then
		if IsReady(_Q) and NS_Kata.Q.cb:Value() then CastQ(target) end
		if IsReady(_W) and NS_Kata.W.cb:Value() then CastW(target) end
		if IsReady(_E) and NS_Kata.E.cb:Value() and NS_Kata.E["Oncb_"..target.charName]:Value() then
			if not IsReady(_Q) and not IsReady(_W) then CastE(target) end
			if (IsReady(_Q) and GetDistance(target.pos) > Q.Range) or (IsReady(_Q) == false and IsReady(_W) and GetDistance(target.pos) > W.Range) then CastE(target) end
		end
		if IsReady(_R) and NS_Kata.ult.cb:Value() then CastR(target) end
	end

	if mode == "Harass" and target and not check.R then
		if IsReady(_Q) and NS_Kata.Q.hr:Value() then CastQ(target) end
		if IsReady(_W) and NS_Kata.W.hr:Value() then CastW(target) end
		if IsReady(_E) and NS_Kata.E.hr:Value() and NS_Kata.E["Onhr_"..target.charName]:Value() then
			if not IsReady(_Q) and not IsReady(_W) then CastE(target) end
			if (IsReady(_Q) and GetDistance(target.pos) > Q.Range) or (IsReady(_Q) == false and IsReady(_W) and GetDistance(target.pos) > W.Range) then CastE(target) end
		end
	end
		if IsReady(_Q) and not check.R and NS_Kata.Q.Ahr:Value() and target then CastQ(target) end
		if IsReady(_W) and not check.R and NS_Kata.W.Ahr:Value() and target then CastW(target) end

	if mode == "LastHit" then
		Cr:Update()
		LastHit()
	end

	if mode == "LaneClear" then
		Cr:Update()
		LaneClear()
		JungleClear()
	end

	if NS_Kata.misc.J.F:Value() then Flee() end

	KillSteal()

	if IsReady(_E) and NS_Kata.misc.J.K:Value() and not check.R and EnemiesAround(myHero.pos, E.Range) == 0 and EnemiesAround(myHero.pos, 1270) > 0 and mode == "Combo" then WardJumpKill() end
end

local function Drawings()
   if myHero.dead or not Enemies[C] then return end
   DrawRange()
   DmgCheck()
   DmgHPBar()
end
------------------------------------

OnLoad(function()
	HPBar = DrawDmgOnHPBar(NS_Kata.dw, {ARGB(200, 89, 0 ,179), ARGB(200, 0, 245, 255), ARGB(200, 186, 85, 211), ARGB(200, 0, 217, 108)}, {"R", "Q", "W", "E"})
	OnProcessSpellCast(ProcSpellCast)
	OnUpdateBuff(UpdateBuff)
	OnRemoveBuff(RemoveBuff)
	OnObjectLoad(CreateObj)
	OnCreateObj(CreateObj)
	OnDeleteObj(DeleteObj)
	OnTick(Tick)
	OnDraw(Drawings)
end)
