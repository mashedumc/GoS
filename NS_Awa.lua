--[[ NS_Awa ver: 0.05
	Cooldown tracker
	Recall tracker
--]]

local NSAwa_Version = 0.05
local function NSAwa_Print(text) PrintChat(string.format("<font color=\"#D9006C\"><b>[NS Awaraness]:</b></font><font color=\"#FFFFFF\"> %s</font>", tostring(text))) end

if not DirExists(SPRITE_PATH.."NS_Awa\\") then CreateDir(SPRITE_PATH.."NS_Awa\\") end
if not DirExists(SPRITE_PATH.."NS_Awa\\Spells\\") then CreateDir(SPRITE_PATH.."NS_Awa\\Spells\\") end
if not DirExists(SPRITE_PATH.."NS_Awa\\Hud\\") then CreateDir(SPRITE_PATH.."NS_Awa\\Hud\\") end

local Nothing, c, link, patch, dname, ch = true, 0, { }, { }, { }, { }
local function addToDownload(fd, name)
	c = c + 1
	link[c] = "https://raw.githubusercontent.com/VTNEETS/GoS/master/NSAwa/"..fd.."/"..name
	patch[c] = SPRITE_PATH.."NS_Awa\\"..fd.."\\"..name
	Nothing = false
	dname[c] = name
end

local function NSdownloadSprites()
	if c > 0 then
		NSAwa_Print(c.." file"..(c > 1 and "s" or "").." need to be download. Please wait...")
		local ps = function(n) NSAwa_Print("("..n.."/"..c..") "..dname[n]..". Don't Press F6!") end
		local download = function(n) DownloadFileAsync(link[n], patch[n], function() ps(n) sc(n+1) end) end
		sc = function(n) if n > c then NSAwa_Print("All file need have been downloaded. Please 2x F6!") return end DelayAction(function() download(n) end, 1) end
		DelayAction(function() download(1) end, 1)
	end
end

local hpbar1 = CreateSpriteFromFile("NS_Awa\\Hud\\HPBar.png", 1)
local hpbar2 = CreateSpriteFromFile("NS_Awa\\Hud\\HPBar2.png", 1)
local rcbar = CreateSpriteFromFile("NS_Awa\\Hud\\Recall.png", 1)
local dfcd = CreateSpriteFromFile("NS_Awa\\Spells\\cd.png", 1)
do
	if hpbar1 == 0 then addToDownload("Hud", "HPBar.png") end
	if hpbar2 == 0 then addToDownload("Hud", "HPBar2.png") end
	if rcbar == 0 then addToDownload("Hud", "Recall.png") end
	if dfcd == 0 then addToDownload("Spells", "cd.png") end
end

local CoolDown, recall = { }, { }
local menu = nil

local sumDF = { { }, { } }
local cMove = false

local fixbar = {
	["Annie"] = { x = 8, y = 7.5, x2 = 122, y2 = -20 },
	["Jhin"]  = { x = 8, y = 7.5, x2 = 122, y2 = -20 },
	["Other"] = { x = -3, y = 15, x2 = 131, y2 = -3 }
}
local rcf = {
	[1] = { 5, 20, 33, 46, 59 },
	[2] = { 18, 34, 48, 61, 76 }
}

local function CoolDownTracker()
	for i, enemy in pairs(GetEnemyHeroes()) do
		if not enemy.dead and enemy.visible and menu.cd.e["cd_"..enemy.charName]:Value() then
			local bar = GetHPBarPos(enemy)
			if bar.x > 0 and bar.y > 0 then
				local posX1 = bar.x + (fixbar[enemy.charName] and fixbar[enemy.charName].x or fixbar.Other.x)
				local posY1 = bar.y + (fixbar[enemy.charName] and fixbar[enemy.charName].y or fixbar.Other.y)
				local posX2 = bar.x + (fixbar[enemy.charName] and fixbar[enemy.charName].x2 or fixbar.Other.x2)
				local posY2 = bar.y + (fixbar[enemy.charName] and fixbar[enemy.charName].y2 or fixbar.Other.y2)
				DrawSprite(hpbar1, posX1, posY1, 0, 1, 107, 10, GoS.White)
				DrawSprite(hpbar2, posX2, posY2, 0, 0, 37, 26, GoS.White)
				DrawSprite(sumDF[enemy:GetSpellData(4).name:lower()], posX2 + 2, posY2 + 2, 0, 0, 14, 14, GoS.White)
				DrawSprite(sumDF[enemy:GetSpellData(5).name:lower()], posX2 + 20, posY2 + 2, 0, 0, 14, 14, GoS.White)
				for slot = 0, 3 do
					if GetGameTimer() < GetSpellData(enemy, slot).cdEndTime then
						local fullCD = GetSpellData(enemy, slot).spellCd
						local time = GetSpellData(enemy, slot).cdEndTime - GetGameTimer()
						DrawText(string.format("%2d", math.ceil(time)), 15, posX1+ 2 + 28*slot, posY1 + 7, GoS.White)
						FillRect(posX1+ 5 + 26*slot, posY1+2, (fullCD - time) * 21 / fullCD, 4, ARGB(255, 38, 159, 222))
					else
						if enemy:GetSpellData(slot).level > 0 then
							FillRect(posX1+ 5 + 26*slot, posY1+2, 21, 4, GoS.Green)
						end
					end
				end
				for slot = 4, 5 do
					if GetGameTimer() < GetSpellData(enemy, slot).cdEndTime then
						local fullCD = GetSpellData(enemy, slot).spellCd
						local time = GetSpellData(enemy, slot).cdEndTime - GetGameTimer()
						DrawSprite(dfcd, posX2 + 2 + 18*(slot-4), posY2 + 2, 0, 0, 14, 14, GoS.White)
						DrawText(string.format("%2d", math.ceil(time)), 13, posX2 - 3 + 24*(slot-4), posY2 + 24, GoS.White)
						FillRect(posX2 + 3 + 18*(slot-4), posY2 + 19, (fullCD - time) * 13 / fullCD, 4, ARGB(255, 38, 159, 222))
					else
						if enemy:GetSpellData(slot).level > 0 then
							FillRect(posX2 + 3 + 18*(slot-4), posY2 + 19, 13, 4, GoS.Green)
						end
					end
				end
			end
		end
	end

	for i, ally in pairs(GetAllyHeroes()) do
		if not ally.dead and menu.cd.a["cd_"..ally.charName]:Value() then
			local bar = GetHPBarPos(ally)
			if bar.x > 0 and bar.y > 0 then
				local posX1 = bar.x + (fixbar[ally.charName] and fixbar[ally.charName].x or fixbar.Other.x)
				local posY1 = bar.y + (fixbar[ally.charName] and fixbar[ally.charName].y or fixbar.Other.y)
				local posX2 = bar.x + (fixbar[ally.charName] and fixbar[ally.charName].x2 or fixbar.Other.x2)
				local posY2 = bar.y + (fixbar[ally.charName] and fixbar[ally.charName].y2 or fixbar.Other.y2)
				DrawSprite(hpbar1, posX1, posY1, 0, 1, 107, 10, GoS.White)
				DrawSprite(hpbar2, posX2, posY2, 0, 0, 37, 26, GoS.White)
				DrawSprite(sumDF[ally:GetSpellData(4).name:lower()], posX2 + 2, posY2 + 2, 0, 0, 14, 14, GoS.White)
				DrawSprite(sumDF[ally:GetSpellData(5).name:lower()], posX2 + 20, posY2 + 2, 0, 0, 14, 14, GoS.White)
				for slot = 0, 3 do
					if GetGameTimer() < GetSpellData(ally, slot).cdEndTime then
						local fullCD = GetSpellData(ally, slot).spellCd
						local time = GetSpellData(ally, slot).cdEndTime - GetGameTimer()
						DrawText(string.format("%2d", math.ceil(time)), 15, posX1+ 2 + 28*slot, posY1 + 7, GoS.White)
						FillRect(posX1+ 5 + 26*slot, posY1+2, (fullCD - time) * 21 / fullCD, 4, ARGB(255, 38, 159, 222))
					else
						if ally:GetSpellData(slot).level > 0 then
							FillRect(posX1+ 5 + 26*slot, posY1+2, 21, 4, GoS.Green)
						end
					end
				end
				for slot = 4, 5 do
					if GetGameTimer() < GetSpellData(ally, slot).cdEndTime then
						local fullCD = GetSpellData(ally, slot).spellCd
						local time = GetSpellData(ally, slot).cdEndTime - GetGameTimer()
						DrawSprite(dfcd, posX2 + 2 + 18*(slot-4), posY2 + 2, 0, 0, 14, 14, GoS.White)
						DrawText(string.format("%2d", math.ceil(time)), 13, posX2 - 3 + 24*(slot-4), posY2 + 24, GoS.White)
						FillRect(posX2 + 3 + 18*(slot-4), posY2 + 19, (fullCD - time) * 13 / fullCD, 4, ARGB(255, 38, 159, 222))
					else
						if ally:GetSpellData(slot).level > 0 then
							FillRect(posX2 + 3 + 18*(slot-4), posY2 + 19, 13, 4, GoS.Green)
						end
					end
				end
			end
		end
	end
end

local function RecallTracker()
	if (#recall > 0 or menu.rc.cm:Value()) and cMove and CursorIsUnder(menu.rc.px:Value()-15, menu.rc.py:Value()-20, 345, 33) then
		menu.rc.px.value = GetCursorPos().x - 330/2
		menu.rc.py.value = GetCursorPos().y
	end
	if #recall > 0 or menu.rc.cm:Value() then DrawSprite(rcbar, menu.rc.px:Value(), menu.rc.py:Value(), 0, 0, 330, 13, GoS.White) end
	for i = 1, #recall do
		recall[i].cTime = (recall[i].fT - os.clock() + recall[i].sT)
		local rec = recall[i]
		if rec.stopT then
			recall[i].cTime = (recall[i].fT - recall[i].stopT + recall[i].sT)
			if os.clock() > rec.stopT + 0.5 then
				table.remove(recall, i)
				break
			end
		end
		FillRect(menu.rc.px:Value() + 3, menu.rc.py:Value() + 1, rec.cTime * 324 / rec.fT, 11, rec.color(i))
		FillRect(menu.rc.px:Value() + 3 + rec.cTime * 324 / rec.fT, menu.rc.py:Value() - rcf[1][i], 1, 12*i, GoS.White)
		DrawText(string.format("%s (%d | %.1f)", rec.unit.charName, math.round(rec.unit.health), rec.cTime), 15, menu.rc.px:Value() + 3 + rec.cTime * 324 / rec.fT, menu.rc.py:Value() - rcf[2][i], GoS.White)
	end
end

local function Load()
	OnUnLoad(function()
		ReleaseSprite(hpbar1)
		ReleaseSprite(hpbar2)
		ReleaseSprite(dfcd)

		for i, enemy in pairs(GetEnemyHeroes()) do
			local NAME = enemy:GetSpellData(4).name:lower()
			if sumDF[NAME] > 0 then
				ReleaseSprite(sumDF[NAME])
				sumDF[NAME] = 0
			end
			local NAME = enemy:GetSpellData(5).name:lower()
			if sumDF[NAME] > 0 then
				ReleaseSprite(sumDF[NAME])
				sumDF[NAME] = 0
			end
		end

		for i, ally in pairs(GetAllyHeroes()) do
			local NAME = ally:GetSpellData(4).name:lower()
			if sumDF[NAME] > 0 then
				ReleaseSprite(sumDF[NAME])
				sumDF[NAME] = 0
			end
			local NAME = ally:GetSpellData(5).name:lower()
			if sumDF[NAME] > 0 then
				ReleaseSprite(sumDF[NAME])
				sumDF[NAME] = 0
			end
		end
	end)

	OnWndMsg(function(msg, key)
		if msg == 513 and key == 0 then
			cMove = true
		elseif msg == 514 and key == 1 then
			cMove = false
		end
	end)

	OnProcessRecall(function(unit, rec)
		if unit.team == myHero.team then return end
		if rec.isStart then
			recall[#recall + 1] = { unit = unit, sT = os.clock(), fT = rec.totalTime*0.001, color = function(i) if rec.totalTime <= 4 then return ARGB(270 - 45*i, 181, 19, 210) end return ARGB(270 - 45*i, 255, 255, 255) end }
		else
			for i = 1, #recall do
				if recall[i].unit.networkID == unit.networkID then
					if rec.isFinish or (rec.totalTime <= 4 and rec.passedTime >= 3940 or rec.passedTime >= 7940) then
						table.remove(recall, i)
					else
						recall[i].stopT = os.clock() + 0.35
						recall[i].color = function(i) if rec.totalTime <= 4 then return ARGB(270 - 45*i, 159, 11, 196) end return ARGB(270 - 45*i, 208, 198, 198) end
					end
					break
				end
			end
		end
	end)

	OnDraw(function()
		CoolDownTracker()
		if menu.rc.on:Value() then RecallTracker() end
	end)
end

class "NS_Awaraness"
function NS_Awaraness:__init(Menu)
	menu = Menu
	menu:Menu("cd", "Cooldown Tracker")
		menu.cd:Menu("e", "Track Enemies")
		menu.cd:Menu("a", "Track Allies")
	menu:Menu("rc", "Recall Tracker")
		menu.rc:Boolean("on", "Enable?", true)
		menu.rc:Boolean("cm", "Move recall bar", false)
		menu.rc:Slider("px", "Horizontal", GetResolution().x/2.8, 1, GetResolution().x, 0.001)
		menu.rc:Slider("py", "Vertical", GetResolution().y/1.5, 1, GetResolution().y, 0.001)
	OnLoad(function()
		for i, enemy in pairs(GetEnemyHeroes()) do
			menu.cd.e:Boolean("cd_"..enemy.charName, "Track "..enemy.charName, true)

			local NAME = enemy:GetSpellData(4).name:lower()
			if not FileExist(SPRITE_PATH.."NS_Awa\\Spells\\"..NAME..".png") then
				if not ch[NAME] then
					addToDownload("Spells", NAME..".png")
					ch[NAME] = true
				end
			else
				if sumDF[NAME] == nil then
					sumDF[NAME] = CreateSpriteFromFile("NS_Awa\\Spells\\"..NAME..".png", 1)
				end
			end

			NAME = enemy:GetSpellData(5).name:lower()
			if not FileExist(SPRITE_PATH.."NS_Awa\\Spells\\"..NAME..".png") then
				if not ch[NAME] then
					addToDownload("Spells", NAME..".png")
					ch[NAME] = true
				end
			else
				if sumDF[NAME] == nil then
					sumDF[NAME] = CreateSpriteFromFile("NS_Awa\\Spells\\"..NAME..".png", 1)
				end
			end
		end

		for i, ally in pairs(GetAllyHeroes()) do
			menu.cd.a:Boolean("cd_"..ally.charName, "Track "..ally.charName, true)

			local NAME = ally:GetSpellData(4).name:lower()
			if not FileExist(SPRITE_PATH.."NS_Awa\\Spells\\"..NAME..".png") then
				if not ch[NAME] then
					addToDownload("Spells", NAME..".png")
					ch[NAME] = true
				end
			else
				if sumDF[NAME] == nil then
					sumDF[NAME] = CreateSpriteFromFile("NS_Awa\\Spells\\"..NAME..".png", 1)
				end
			end

			NAME = ally:GetSpellData(5).name:lower()
			if not FileExist(SPRITE_PATH.."NS_Awa\\Spells\\"..NAME..".png") then
				if not ch[NAME] then
					addToDownload("Spells", NAME..".png")
					ch[NAME] = true
				end
			else
				if sumDF[NAME] == nil then
					sumDF[NAME] = CreateSpriteFromFile("NS_Awa\\Spells\\"..NAME..".png", 1)
				end
			end
		end

		if mapID == 12 then
			if not FileExist(SPRITE_PATH.."NS_Awa\\Spells\\snowballfollowupcast.png") then
				addToDownload("Spells", "snowballfollowupcast.png")
			else
				sumDF["snowballfollowupcast"] = CreateSpriteFromFile("NS_Awa\\Spells\\snowballfollowupcast.png", 1)
			end
		end

		menu:Info("ifo", "[NS Awaraness] - Ver: "..NSAwa_Version)
		NSdownloadSprites()
		if not Nothing then return end
		Load()
	end)
end

OnLoad(function()
	GetWebResultAsync("https://raw.githubusercontent.com/VTNEETS/GoS/master/NS_Awa.version", function(OnlineVer)
		if tonumber(OnlineVer) > NSAwa_Version then
			NSAwa_Print("New Version found (v"..OnlineVer.."). Please wait...")
			DownloadFileAsync("https://raw.githubusercontent.com/VTNEETS/GoS/master/NS_Awa.lua", COMMON_PATH.."NS_Awa.lua", function() NSAwa_Print("Updated to version "..OnlineVer..". Please F6 x2 to reload.") end)
		else
			NSAwa_Print("Loaded Version: "..NSAwa_Version)
		end
	end)
end)
