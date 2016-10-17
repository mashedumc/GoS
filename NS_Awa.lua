--[[ NS_Awa ver: 0.02
	Cooldown tracker only
--]]

if not DirExists(SPRITE_PATH.."NS_Awa\\") then CreateDir(SPRITE_PATH.."NS_Awa\\") end
if not DirExists(SPRITE_PATH.."NS_Awa\\Spells\\") then CreateDir(SPRITE_PATH.."NS_Awa\\Spells\\") end
if not DirExists(SPRITE_PATH.."NS_Awa\\Hud\\") then CreateDir(SPRITE_PATH.."NS_Awa\\Hud\\") end
local NSAwa_Version = 0.02
local function NSAwa_Print(text) PrintChat(string.format("<font color=\"#D9006C\"><b>[NS Awaraness]:</b></font><font color=\"#FFFFFF\"> %s</font>", tostring(text))) end

local Nothing, c, link, patch, dname, ch = true, 0, { }, { }, { }, { }
local function addDownload(fd, name)
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
local dfcd   = CreateSpriteFromFile("NS_Awa\\Spells\\cd.png", 1)
if hpbar1 == 0 then addDownload("Hud", "HPBar.png") end
if hpbar2 == 0 then addDownload("Hud", "HPBar2.png") end
if dfcd   == 0 then addDownload("Spells", "cd.png") end
local CoolDown = { }
local menu = nil

local sumDF = {
	[1] = { },
	[2] = { }
}

local fixb1 = {
	["Annie"] = { x = 8, y = 7.5 },
	["Jhin"]  = { x = 8, y = 7.5 },
	["Other"] = { x = -3, y = 15 }
}

local fixb2 = {
	["Annie"] = { x = 122, y = -20 },
	["Jhin"]  = { x = 122, y = -20 },
	["Other"] = { x = 130, y = -3 },
}

local function Load()
	OnUnLoad(function()
		ReleaseSprite(hpbar1)
		ReleaseSprite(hpbar2)
		for i, enemy in pairs(GetEnemyHeroes()) do
			ReleaseSprite(sumDF[1][i])
			ReleaseSprite(sumDF[2][i])
		end
	end)

	OnDraw(function()
		for i, enemy in pairs(GetEnemyHeroes()) do
			if not enemy.dead and enemy.visible and menu.cd["cd_"..enemy.charName]:Value() then
				local bar = GetHPBarPos(enemy)
				if bar.x > 0 and bar.y > 0 then
					local posX1 = bar.x + (fixb2[enemy.charName] and fixb2[enemy.charName].x or fixb2.Other.x)
					local posY1 = bar.y + (fixb2[enemy.charName] and fixb2[enemy.charName].y or fixb2.Other.y)
					local posX2 = bar.x + (fixb1[enemy.charName] and fixb1[enemy.charName].x or fixb1.Other.x)
					local posY2 = bar.y + (fixb1[enemy.charName] and fixb1[enemy.charName].y or fixb1.Other.y)
					DrawSprite(hpbar1, posX2, posY2, 0, 1, 107, 10, GoS.White)
					DrawSprite(hpbar2, posX1, posY1, 0, 0, 37, 26, GoS.White)
					DrawSprite(sumDF[1][i], posX1 + 2, posY1 + 2, 0, 0, 14, 14, GoS.White)
					DrawSprite(sumDF[2][i], posX1 + 20, posY1 + 2, 0, 0, 14, 14, GoS.White)
					for slot = 0, 3 do
						if enemy:GetSpellData(slot).currentCd > 0 then
							local fullCD = enemy:GetSpellData(slot).cd*(1 + enemy.cdr)
							DrawText(math.ceil(enemy:GetSpellData(slot).currentCd), 15, posX2 + 2 + 28*slot, posY2 + 7, GoS.White)
							FillRect(posX2 + 5 + 26*slot, posY2+2, (fullCD - enemy:GetSpellData(slot).currentCd) * 21 / fullCD, 4, ARGB(255, 38, 159, 222))
						else
							if enemy:GetSpellData(slot).level > 0 then
								FillRect(posX2 + 5 + 26*slot, posY2+2, 21, 4, GoS.Green)
							end
						end
					end
					for slot = 4, 5 do
						if enemy:GetSpellData(slot).currentCd > 0 then
							local fullCD = enemy:GetSpellData(slot).cd*(1 + enemy.cdr)
							DrawSprite(dfcd, posX1 + 2 + 18*(slot-4), posY1 + 2, 0, 0, 14, 14, GoS.White)
							DrawText(math.ceil(enemy:GetSpellData(slot).currentCd), 13, posX1 - 3 + 24*(slot-4), posY1 + 24, GoS.White)
							FillRect(posX1 + 3 + 18*(slot-4), posY1 + 19, (fullCD - enemy:GetSpellData(slot).currentCd) * 13 / fullCD, 4, ARGB(255, 38, 159, 222))
						else
							if enemy:GetSpellData(slot).level > 0 then
								FillRect(posX1 + 3 + 18*(slot-4), posY1 + 19, 13, 4, GoS.Green)
							end
						end
					end
				end
			end
		end
	end)
end

class "NS_Awaraness"
function NS_Awaraness:__init(Menu)
	menu = Menu
	menu:Menu("cd", "Cooldown Tracker")
	OnLoad(function()
		for i, enemy in pairs(GetEnemyHeroes()) do
			menu.cd:Boolean("cd_"..enemy.charName, "Track "..enemy.charName, true)
			sumDF[1][i] = CreateSpriteFromFile("NS_Awa\\Spells\\"..GetCastName(enemy, 4):lower()..".png", 1)
			sumDF[2][i] = CreateSpriteFromFile("NS_Awa\\Spells\\"..GetCastName(enemy, 5):lower()..".png", 1)
			if sumDF[1][i] == 0 and not ch[GetCastName(enemy, 4)] then
				addDownload("Spells", GetCastName(enemy, 4):lower()..".png")
				ch[GetCastName(enemy, 4)] = true
			end
			if sumDF[2][i] == 0 and not ch[GetCastName(enemy, 5)] then
				addDownload("Spells", GetCastName(enemy, 5):lower()..".png")
				ch[GetCastName(enemy, 5)] = true
			end
		end
		menu:Info("ifo", "[NS Awaraness] Version: "..NSAwa_Version)
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
