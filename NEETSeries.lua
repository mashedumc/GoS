--[[ NEET Series Version 0.16
	_____   ___________________________   ________           _____             
	___  | / /__  ____/__  ____/__  __/   __  ___/______________(_)____________
	__   |/ /__  __/  __  __/  __  /      _____ \_  _ \_  ___/_  /_  _ \_  ___/
	_  /|  / _  /___  _  /___  _  /       ____/ //  __/  /   _  / /  __/(__  ) 
	/_/ |_/  /_____/  /_____/  /_/        /____/ \___//_/    /_/  \___//____/  

---------------------------------------]]
NEETSeries_Version = 0.16
local function NEETSeries_Print(text) PrintChat(string.format("<font color=\"#4169E1\"><b>[NEET Series]:</b></font><font color=\"#FFFFFF\"> %s</font>", tostring(text))) end

if not FileExist(COMMON_PATH.."MixLib.lua") then
	NEETSeries_Print("MixLib.lua not found. Please wait...")
	DownloadFileAsync("https://raw.githubusercontent.com/VTNEETS/GoS/master/MixLib.lua", COMMON_PATH.."MixLib.lua", function() NEETSeries_Print("Downloaded MixLib.lua, please 2x F6!") end)
	return
else require('MixLib') end

if not FileExist(COMMON_PATH.."OpenPredict.lua") or not FileExist(COMMON_PATH.."ChallengerCommon.lua") or not FileExist(COMMON_PATH.."DamageLib.lua") or not FileExist(COMMON_PATH.."Analytics.lua") then return end
if not ChallengerCommonLoaded then require('ChallengerCommon') end
if not Analytics then require("Analytics") end

local SupTbl = {"Xerath"}
local Supported = Set(SupTbl)

class "__MinionManager"
function __MinionManager:__init(range1, range2)
	self.range1 = range1*range1
	self.range2 = range2*range2
	self.minion = {}
	self.mob = {}
	self.tminion = {}
	self.tmob = {}
	OnObjectLoad(function(obj) self:CreateObj(obj) end)
	OnCreateObj(function(obj) self:CreateObj(obj) end)
	OnDeleteObj(function(obj) self:DeleteObj(obj) end)
end

function __MinionManager:CreateObj(obj)
	if GetObjectType(obj) == "obj_AI_Minion" and GetTeam(obj) == MINION_ENEMY and GetObjectBaseName(obj):find("Minion_") and IsObjectAlive(obj) then
		self.minion[#self.minion +1] = obj
	elseif GetTeam(obj) == 300 and GetObjectType(obj) == "obj_AI_Minion" and IsObjectAlive(obj) then
		self.mob[#self.mob +1] = obj
	end
end

function __MinionManager:DeleteObj(obj)
	if GetObjectType(obj) ~= "obj_AI_Minion" or GetTeam(obj) == MINION_ALLY then return end
	if GetObjectBaseName(obj):find("Minion_") and GetTeam(obj) ~= 300 then
		for i = 1, #self.minion do
			if self.minion[i] == obj then 
				table.remove(self.minion, i)
				return
			end
		end
	end

	if GetTeam(obj) ~= 300 then return end
	for i = 1, #self.mob do
		if self.mob[i] == obj then
			table.remove(self.mob, i)
			return
		end
	end
end

function __MinionManager:Update()
	self.tminion = {}
	for _, minion in pairs(self.minion) do
		if IsObjectAlive(minion) and GetDistanceSqr(minion) <= self.range1 and GetTeam(minion) == MINION_ENEMY then
			self.tminion[#self.tminion +1] = minion
		end
	end

	self.tmob = {}
	for _, mob in pairs(self.mob) do
		if IsObjectAlive(mob) and GetDistanceSqr(mob) <= self.range2 and GetTeam(mob) == 300 then
			self.tmob[#self.tmob +1] = mob
		end
	end

	table.sort(self.tminion, SORT_HEALTH_ASC)
	table.sort(self.tmob, SORT_MAXHEALTH_DEC)
end

class "PredictSpell"
function PredictSpell:__init(Slot, Delay, Speed, Width, Range, Collision, collNum, Aoe, Type, Name, HitChance, predName, Other)
	local Angle = (Other and Other.angle) and Other.angle or nil
	local Accel = (Other and Other.accel ) and Other.accel or nil
	local Min = (Accel and Other.min) and Other.min or nil
	local Max = (Accel and Other.max) and Other.max or nil
	self.Pred = predName
	self.data = { slot = Slot, name = Name, speed = Speed, delay = Delay, range = Range, width = Width, collision = Collision, col = {"minion", "yasuowall"}, coll = collNum, aoe = Aoe, type = Type, hc = HitChance, angle = Angle, accel = Accel, minSpeed = Miin, maxSpeed = Max }
	self.IPrediction = self.Pred == "IPrediction" and IPrediction.Prediction(self.data)
	self.css2 = (Other and Other.s2) and true or false
end

function PredictSpell:Cast(target, CSS2Range)
	if not IsReady(self.data.slot) or not target then self.hc, self.pos = 0, nil return end
	local HitChance, Pos, CanCast, Name = Mix:Predicting(self.Pred, target, self.data, self.IPrediction)
	if CanCast and ((Name == "OpenPredict" and HitChance >= self.data.hc) or (Name == "IPrediction" and HitChance > 2) or (Name == "GoSPrediction" and HitChance >= 1) or (Name == "GPrediction" and HitChance > 1)) then
		if not self.css2 and GetDistance(Pos) <= self.data.range then
			CastSkillShot(self.data.slot, Pos)
		elseif self.css2 and GetDistance(Pos) <= CSS2Range then
			CastSkillShot2(self.data.slot, Pos)
		end
	end
end

do
	if not Supported[myHero.charName] then NEETSeries_Print("Not Supported For "..myHero.charName) return end
	if not FileExist(COMMON_PATH.."NS_"..myHero.charName..".lua") then
		NEETSeries_Print("Downloading NS_"..myHero.charName..".lua. Please wait...")
		DelayAction(function() DownloadFileAsync("https://raw.githubusercontent.com/VTNEETS/GoS/master/NS_"..myHero.charName..".lua", COMMON_PATH.."NS_"..myHero.charName..".lua", function() NEETSeries_Print("Downloaded plugin NS_"..myHero.charName..".lua, please 2x F6!") return end) end, 1)
		return
	else
		require("NS_"..myHero.charName)
	end
	Analytics("NEETSeries", "Ryzuki", true)
end

OnLoad(function()
	GetWebResultAsync("https://raw.githubusercontent.com/VTNEETS/GoS/master/NEETSeries.version", function(OnlineVer)
		if tonumber(OnlineVer) > NEETSeries_Version then
			NEETSeries_Print("New Version found (v"..OnlineVer.."). Please wait...")
			local check = function(v)
				if v <= 4 and not FileExist(COMMON_PATH.."NS_"..SupTbl[v]..".lua") then check(v + 1) return end
				if v > 4 then NEETSeries_Print("Updated to version "..OnlineVer..". Please F6 x2 to reload.") return end
				DownloadFileAsync("https://raw.githubusercontent.com/VTNEETS/GoS/master/NS_"..SupTbl[v]..".lua", COMMON_PATH.."NS_"..SupTbl[v]..".lua", function() check(v + 1) return end) return
			end
			DownloadFileAsync("https://raw.githubusercontent.com/VTNEETS/GoS/master/NEETSeries.lua", SCRIPT_PATH.."NEETSeries.lua", function() check(1) return end) return
		else
			if Supported[myHero.charName] then
				PrintChat(string.format("<font color=\"#4169E1\"><b>[NEET Series]:</b></font><font color=\"#FFFFFF\"><i> Successfully Loaded</i> (v%s) | Good Luck</font> <font color=\"#C6E2FF\"><u>%s</u></font>", NEETSeries_Version, GetUser())) return
			end
		end
	end)
end)
