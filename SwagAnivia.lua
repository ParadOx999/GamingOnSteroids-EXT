if myHero.charName ~= "Anivia" then return end

--// requirements
require "DamageLib"

--// spelldata
local Q = { Range = 1075, Delay = 0.25, Width = 125, Radius = 225, Speed = 850}
local W = { Range = 1000, Delay = myHero:GetSpellData(_W).delay, Width = myHero:GetSpellData(_W).width, Speed = myHero:GetSpellData(_W).speed}
local E = { Range = 650, Delay = myHero:GetSpellData(_E).delay, Width = myHero:GetSpellData(_E).width, Speed = 1600}
local R = { Range = 750, Delay = myHero:GetSpellData(_R).delay, Width = myHero:GetSpellData(_W).width, Radius = 400}

--// needs
local _EnemyHeroes
local function GetEnemyHeroes()
	if _EnemyHeroes then return _EnemyHeroes end
	_EnemyHeroes = {}
	for i = 1, Game.HeroCount() do
		local unit = Game.Hero(i)
		if unit.isEnemy then
			table.insert(_EnemyHeroes, unit)
		end
	end
	return _EnemyHeroes
end

local function Ready(spell)
	return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana and Game.CanUseSpell(spell) == 0 
end

function ValidTarget(target, range)
	range = range and range or math.huge
	return target ~= nil and target.valid and target.visible and not target.dead and target.distance <= range
end

local function IsImmobileTarget(unit)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24 or buff.name == "recall") and buff.count > 0 then
			return true
		end
	end
	return false	
end

function PercentHP(target)
    return 100 * target.health / target.maxHealth
end

function PercentMP(target)
    return 100 * target.mana / target.maxMana
end

local function OnScreen(unit)
	return unit.pos:To2D().onScreen;
end

local function GetTarget(range)
	local target = nil
	if _G.SDK and _G.SDK.Orbwalker then
		target = _G.SDK.TargetSelector:GetTarget(range)
	else
		target = GOS:GetTarget(range)
	end
	return target
end

local function GetMode()
	if _G.SDK and _G.SDK.Orbwalker then
		if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
			return "Combo"
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] then
			return "Harass"	
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR] or _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR] then
			return "Clear"
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LASTHIT] then
			return "Lasthit"
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_FLEE] then
			return "Flee"
		end
	else
		return GOS.GetMode()
	end
end

function HeroesAround(pos, range, team)
	local Count = 0
	for i = 1, Game.HeroCount() do
		local minion = Game.Hero(i)
		if minion and minion.team == team and not minion.dead and pos:DistanceTo(minion.pos) <= range then
			Count = Count + 1
		end
	end
	return Count
end

function MinionsAround(pos, range, team)
	local Count = 0
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if minion and minion.team == team and not minion.dead and pos:DistanceTo(minion.pos) <= range then
			Count = Count + 1
		end
	end
	return Count
end

function BestCircularPos(range, radius, team)
	local BestPos = nil
	local MostHit = 0
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if minion and minion.isEnemy and not minion.dead and myHero.pos:DistanceTo(minion.pos) <= range then
			local Count = MinionsAround(minion.pos, radius, team)
			if Count > MostHit then
				MostHit = Count
				BestPos = minion.pos
			end
		end
	end
	return BestPos, MostHit
end

local HKITEM = {
	[ITEM_1] = HK_ITEM_1,
	[ITEM_2] = HK_ITEM_2,
	[ITEM_3] = HK_ITEM_3,
	[ITEM_4] = HK_ITEM_4,
	[ITEM_5] = HK_ITEM_5,
	[ITEM_6] = HK_ITEM_6,
	[ITEM_7] = HK_ITEM_7,
}

--// damages
local function Qdmg(target)
    local level = myHero:GetSpellData(_Q).level
	if Ready(_Q) then
    	return CalcMagicalDamage(myHero, target, (70 + 50 * level + 0.80 * myHero.ap))
	end
	return 0
end

local function Edmg(target)
    local level = myHero:GetSpellData(_E).level
	if Ready(_E) then
        for i = 0, target.buffCount do
        local buff = target:GetBuff(i);
            if buff.count > 0 then
                if buff.name == "aniviaiced" then
                    return CalcMagicalDamage(myHero, target, (25 + 25 * level + 0.5 * myHero.ap)) * 2
                end
            end
        end
            return CalcMagicalDamage(myHero, target, (25 + 25 * level + 0.5 * myHero.ap))
	end
	return 0
end

local function Idmg(target)
	if (myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and Ready(SUMMONER_1))
	or (myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and Ready(SUMMONER_2)) then
		return 50 + 20 * myHero.levelData.lvl
	end
	return 0
end

local function BSdmg(target)
	if (myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmiteDuel" and Ready(SUMMONER_1))
	or (myHero:GetSpellData(SUMMONER_2).name == "S5_SummonerSmiteDuel" and Ready(SUMMONER_2)) then
		return 20 + 8 * myHero.levelData.lvl
	end
	return 0
end

local function RSdmg(target)
	if (myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmitePlayerGanker" and Ready(SUMMONER_1))
	or (myHero:GetSpellData(SUMMONER_2).name == "S5_SummonerSmitePlayerGanker" and Ready(SUMMONER_2)) then
		return 54 + 6 * myHero.levelData.lvl
	end
	return 0
end

local function NoPotion()
	for i = 0, 63 do 
	local buff = myHero:GetBuff(i)
		if buff.type == 13 and Game.Timer() < buff.expireTime then 
			return false
		end
	end
	return true
end

local sqrt = math.sqrt

local function GetDistanceSqr(p1, p2)
    local dx = p1.x - p2.x
    local dz = p1.z - p2.z
    return (dx * dx + dz * dz)
end

local function GetDistance(p1, p2)
    return sqrt(GetDistanceSqr(p1, p2))
end

local function GetDistance2D(p1,p2)
    return sqrt((p2.x - p1.x)*(p2.x - p1.x) + (p2.y - p1.y)*(p2.y - p1.y))
end

--// Menu
local Anivia = MenuElement({type = MENU, id = "Anivia", name = "Swag Anivia", leftIcon = "http://ddragon.leagueoflegends.com/cdn/6.24.1/img/champion/Anivia.png"})
Anivia:MenuElement({type = MENU, id = "C", name = "Combo Menu"})
Anivia:MenuElement({type = MENU, id = "LC", name = "Lane Menu"})
Anivia:MenuElement({type = MENU, id = "JC", name = "Jungle Menu"})
Anivia:MenuElement({type = MENU, id = "S", name = "Auto Q2 Menu"})
Anivia:MenuElement({type = MENU, id = "H", name = "Harass Menu"})
Anivia:MenuElement({type = MENU, id = "F", name = "Flee Menu"})
Anivia:MenuElement({type = MENU, id = "KS", name = "Killsteal Menu"})
Anivia:MenuElement({type = MENU, id = "A", name = "Activator Menu"})
Anivia:MenuElement({type = MENU, id = "D", name = "Drawings Menu"})
Anivia:MenuElement({id = "Author", name = "Author", drop = {"parad0x"}})
Anivia:MenuElement({id = "Version", name = "Version", drop = {"v1.3"}})
Anivia:MenuElement({id = "Patch", name = "Patch", drop = {"RIOT 7.14"}})

Anivia.C:MenuElement({name = "Flash Frost", drop = {"Q"}, leftIcon = "http://ddragon.leagueoflegends.com/cdn/6.24.1/img/spell/FlashFrost.png"})
Anivia.C:MenuElement({id = "Q", name = "Enable", value = true})
Anivia.C:MenuElement({id = "Qm", name = "Mana %", value = 0, min = 0, max = 100})
Anivia.C:MenuElement({name = "Crystallize", drop = {"W"}, leftIcon = "http://ddragon.leagueoflegends.com/cdn/6.24.1/img/spell/Crystallize.png"})
Anivia.C:MenuElement({id = "Wa", name = "Toggle: W ON/OFF", key = string.byte("M"), toggle = true})
Anivia.C:MenuElement({id = "W", name = "Enable", drop = {'Pull','Push'}})
Anivia.C:MenuElement({id = "NoPull", name = "Dont Pull if HP below %", value = 40, min = 0, max = 100})
Anivia.C:MenuElement({id = "Wm", name = "Mana %", value = 0, min = 0, max = 100})
Anivia.C:MenuElement({name = "Frostbite", drop = {"E"}, leftIcon = "http://ddragon.leagueoflegends.com/cdn/6.24.1/img/spell/Frostbite.png"})
Anivia.C:MenuElement({id = "E", name = "Toggle: E Mode Key", key = string.byte("T"), toggle = true})
Anivia.C:MenuElement({id = "Em", name = "Mana %", value = 0, min = 0, max = 100})
Anivia.C:MenuElement({name = "Glacial Storm", drop = {"R"}, leftIcon = "http://ddragon.leagueoflegends.com/cdn/6.24.1/img/spell/GlacialStorm.png"})
Anivia.C:MenuElement({id = "R", name = "Enable", value = true})
Anivia.C:MenuElement({id = "Rm", name = "Mana %", value = 25, min = 0, max = 100})

Anivia.LC:MenuElement({name = "Frostbite", drop = {"E"}, leftIcon = "http://ddragon.leagueoflegends.com/cdn/6.24.1/img/spell/Frostbite.png"})
Anivia.LC:MenuElement({id = "E", name = "Enable", value = true})
Anivia.LC:MenuElement({id = "Em", name = "Mana %", value = 65, min = 0, max = 100})
Anivia.LC:MenuElement({name = "Glacial Storm", drop = {"R"}, leftIcon = "http://ddragon.leagueoflegends.com/cdn/6.24.1/img/spell/GlacialStorm.png"})
Anivia.LC:MenuElement({id = "R", name = "Enable", value = true})
Anivia.LC:MenuElement({id = "MinR", name = "Min Minions", value = 6, min = 1, max = 7})
Anivia.LC:MenuElement({id = "Rm", name = "Mana %", value = 65, min = 0, max = 100})

Anivia.JC:MenuElement({name = "Frostbite", drop = {"E"}, leftIcon = "http://ddragon.leagueoflegends.com/cdn/6.24.1/img/spell/Frostbite.png"})
Anivia.JC:MenuElement({id = "E", name = "Enable", value = true})
Anivia.JC:MenuElement({id = "Em", name = "Mana %", value = 40, min = 0, max = 100})
Anivia.JC:MenuElement({name = "Glacial Storm", drop = {"R"}, leftIcon = "http://ddragon.leagueoflegends.com/cdn/6.24.1/img/spell/GlacialStorm.png"})
Anivia.JC:MenuElement({id = "R", name = "Enable", value = true})
Anivia.JC:MenuElement({id = "MinR", name = "Min Minions", value = 2, min = 1, max = 7})
Anivia.JC:MenuElement({id = "Rm", name = "Mana %", value = 40, min = 0, max = 100})

Anivia.S:MenuElement({name = "Flash Frost", drop = {"Q"}, leftIcon = "http://ddragon.leagueoflegends.com/cdn/6.24.1/img/spell/FlashFrost.png"})
Anivia.S:MenuElement({id = "Q", name = "Auto Stun Q2", value = true})

Anivia.H:MenuElement({name = "Flash Frost", drop = {"Q"}, leftIcon = "http://ddragon.leagueoflegends.com/cdn/6.24.1/img/spell/FlashFrost.png"})
Anivia.H:MenuElement({id = "Q", name = "Enable", value = true})
Anivia.H:MenuElement({id = "Qm", name = "Mana %", value = 50, min = 0, max = 100})
Anivia.H:MenuElement({name = "Frostbite", drop = {"E"}, leftIcon = "http://ddragon.leagueoflegends.com/cdn/6.24.1/img/spell/Frostbite.png"})
Anivia.H:MenuElement({id = "E", name = "Enable", drop = {'Enhanced','Normal','Disabled'}})
Anivia.H:MenuElement({id = "Em", name = "Mana %", value = 30, min = 0, max = 100})

Anivia.F:MenuElement({name = "Flash Frost", drop = {"Q"}, leftIcon = "http://ddragon.leagueoflegends.com/cdn/6.24.1/img/spell/FlashFrost.png"})
Anivia.F:MenuElement({id = "Q", name = "Enable", value = true})
Anivia.F:MenuElement({id = "Qm", name = "Mana %", value = 15, min = 0, max = 100})
Anivia.F:MenuElement({name = "Crystallize", drop = {"W"}, leftIcon = "http://ddragon.leagueoflegends.com/cdn/6.24.1/img/spell/Crystallize.png"})
Anivia.F:MenuElement({id = "W", name = "Enable", value = true})
Anivia.F:MenuElement({id = "Wm", name = "Mana %", value = 15, min = 0, max = 100})

Anivia.KS:MenuElement({name = "Flash Frost", drop = {"Q"}, leftIcon = "http://ddragon.leagueoflegends.com/cdn/6.24.1/img/spell/FlashFrost.png"})
Anivia.KS:MenuElement({id = "Q", name = "Enable", value = true})
Anivia.KS:MenuElement({id = "Qm", name = "Mana %", value = 0, min = 0, max = 100})
Anivia.KS:MenuElement({name = "Frostbite", drop = {"E"}, leftIcon = "http://ddragon.leagueoflegends.com/cdn/6.24.1/img/spell/Frostbite.png"})
Anivia.KS:MenuElement({id = "E", name = "Enable", value = true})
Anivia.KS:MenuElement({id = "Em", name = "Mana %", value = 0, min = 0, max = 100})

Anivia.D:MenuElement({name = "Flash Frost", drop = {"Q"}, leftIcon = "http://ddragon.leagueoflegends.com/cdn/6.24.1/img/spell/FlashFrost.png"})
Anivia.D:MenuElement({id = "Q", name = "Draw Range", value = true})
Anivia.D:MenuElement({name = "Crystallize", drop = {"W"}, leftIcon = "http://ddragon.leagueoflegends.com/cdn/6.24.1/img/spell/Crystallize.png"})
Anivia.D:MenuElement({id = "W", name = "Draw Range", value = true})
Anivia.D:MenuElement({id = "Wa", name = "Toggle Mode", value = true})
Anivia.D:MenuElement({name = "Frostbite", drop = {"E"}, leftIcon = "http://ddragon.leagueoflegends.com/cdn/6.24.1/img/spell/Frostbite.png"})
Anivia.D:MenuElement({id = "E", name = "Draw Range", value = true})
Anivia.D:MenuElement({id = "Emode", name = "Toggle Mode", value = true})
Anivia.D:MenuElement({name = "Glacial Storm", drop = {"R"}, leftIcon = "http://ddragon.leagueoflegends.com/cdn/6.24.1/img/spell/GlacialStorm.png"})
Anivia.D:MenuElement({id = "R", name = "Draw Range", value = true})
Anivia.D:MenuElement({name = "Draw Damage", drop = {"Q + E"}, leftIcon = "http://ddragon.leagueoflegends.com/cdn/6.24.1/img/champion/Anivia.png"})
Anivia.D:MenuElement({id = "Dmg", name = "Draw Dmg", value = true})

Anivia.A:MenuElement({type = MENU, id = "P", name = "Potions"})
Anivia.A.P:MenuElement({id = "Pot", name = "All Potions", value = true})
Anivia.A.P:MenuElement({id = "HP", name = "Health % to Potion", value = 40, min = 0, max = 100})
Anivia.A:MenuElement({type = MENU, id = "I", name = "Items"})
Anivia.A.I:MenuElement({id = "RO", name = "Randuin's Omen", value = true})
Anivia.A.I:MenuElement({id = "Proto", name = "Hextec Items (all)", value = true})
Anivia.A:MenuElement({type = MENU, id = "S", name = "Summoner Spells"})
DelayAction(function()
	if myHero:GetSpellData(SUMMONER_1).name == "SummonerSmite" or myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmitePlayerGanker" or myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmiteDuel"
	or myHero:GetSpellData(SUMMONER_2).name == "SummonerSmite" or myHero:GetSpellData(SUMMONER_2).name == "S5_SummonerSmitePlayerGanker" or myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmiteDuel" then
		Anivia.A.S:MenuElement({id = "Smite", name = "Smite in Combo [?]", value = true, tooltip = "If Combo will kill"})
		Anivia.A.S:MenuElement({id = "SmiteS", name = "Smite Stacks to Combo", value = 1, min = 1, max = 2})
	end
end, 2)
DelayAction(function()
	if myHero:GetSpellData(SUMMONER_1).name == "SummonerHeal"
	or myHero:GetSpellData(SUMMONER_2).name == "SummonerHeal" then
		Anivia.A.S:MenuElement({id = "Heal", name = "Auto Heal", value = true})
		Anivia.A.S:MenuElement({id = "HealHP", name = "Health % to Heal", value = 25, min = 0, max = 100})
	end
end, 2)
DelayAction(function()
	if myHero:GetSpellData(SUMMONER_1).name == "SummonerBarrier"
	or myHero:GetSpellData(SUMMONER_2).name == "SummonerBarrier" then
		Anivia.A.S:MenuElement({id = "Barrier", name = "Auto Barrier", value = true})
		Anivia.A.S:MenuElement({id = "BarrierHP", name = "Health % to Barrier", value = 25, min = 0, max = 100})
	end
end, 2)
DelayAction(function()
	if myHero:GetSpellData(SUMMONER_1).name == "SummonerDot"
	or myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" then
		Anivia.A.S:MenuElement({id = "Ignite", name = "Ignite in Combo", value = true})
	end
end, 2)
DelayAction(function()
	if myHero:GetSpellData(SUMMONER_1).name == "SummonerExhaust"
	or myHero:GetSpellData(SUMMONER_2).name == "SummonerExhaust" then
		Anivia.A.S:MenuElement({id = "Exh", name = "Exhaust in Combo [?]", value = true, tooltip = "If Combo will kill"})
	end
end, 2)
DelayAction(function()
	if myHero:GetSpellData(SUMMONER_1).name == "SummonerBoost"
	or myHero:GetSpellData(SUMMONER_2).name == "SummonerBoost" then
		Anivia.A.S:MenuElement({id = "Cleanse", name = "Auto Cleanse", value = true})
		Anivia.A.S:MenuElement({id = "Blind", name = "Blind", value = false})
		Anivia.A.S:MenuElement({id = "Charm", name = "Charm", value = true})
		Anivia.A.S:MenuElement({id = "Flee", name = "Flee", value = true})
		Anivia.A.S:MenuElement({id = "Slow", name = "Slow", value = false})
		Anivia.A.S:MenuElement({id = "Root", name = "Root/Snare", value = true})
		Anivia.A.S:MenuElement({id = "Poly", name = "Polymorph", value = true})
		Anivia.A.S:MenuElement({id = "Silence", name = "Silence", value = true})
		Anivia.A.S:MenuElement({id = "Stun", name = "Stun", value = true})
		Anivia.A.S:MenuElement({id = "Taunt", name = "Taunt", value = true})
	end
end, 2)
Anivia.A.S:MenuElement({type = SPACE, id = "Note", name = "Note: Ghost/TP/Flash is not supported"})

local _OnVision = {}
function OnVision(unit)
	if _OnVision[unit.networkID] == nil then _OnVision[unit.networkID] = {state = unit.visible , tick = GetTickCount(), pos = unit.pos} end
	if _OnVision[unit.networkID].state == true and not unit.visible then _OnVision[unit.networkID].state = false _OnVision[unit.networkID].tick = GetTickCount() end
	if _OnVision[unit.networkID].state == false and unit.visible then _OnVision[unit.networkID].state = true _OnVision[unit.networkID].tick = GetTickCount() end
	return _OnVision[unit.networkID]
end

--// script
Callback.Add("Tick", function() OnVisionF() Tick() end)
Callback.Add("Draw", function() Drawings() end)

local visionTick = GetTickCount()
function OnVisionF()
	if GetTickCount() - visionTick > 100 then
		for i,v in pairs(GetEnemyHeroes()) do
			OnVision(v)
		end
	end
end

local _OnWaypoint = {}
function OnWaypoint(unit)
	if _OnWaypoint[unit.networkID] == nil then _OnWaypoint[unit.networkID] = {pos = unit.posTo , speed = unit.ms, time = Game.Timer()} end
	if _OnWaypoint[unit.networkID].pos ~= unit.posTo then 
		_OnWaypoint[unit.networkID] = {startPos = unit.pos, pos = unit.posTo , speed = unit.ms, time = Game.Timer()}
			DelayAction(function()
				local time = (Game.Timer() - _OnWaypoint[unit.networkID].time)
				local speed = GetDistance2D(_OnWaypoint[unit.networkID].startPos,unit.pos)/(Game.Timer() - _OnWaypoint[unit.networkID].time)
				if speed > 1250 and time > 0 and unit.posTo == _OnWaypoint[unit.networkID].pos and GetDistance(unit.pos,_OnWaypoint[unit.networkID].pos) > 200 then
					_OnWaypoint[unit.networkID].speed = GetDistance2D(_OnWaypoint[unit.networkID].startPos,unit.pos)/(Game.Timer() - _OnWaypoint[unit.networkID].time)
				end
			end,0.05)
	end
	return _OnWaypoint[unit.networkID]
end

local function EnableOrb(bool)
	if Orb == 1 then
		EOW:SetMovements(bool)
		EOW:SetAttacks(bool)
	elseif Orb == 2 then
		_G.SDK.Orbwalker:SetMovement(bool)
		_G.SDK.Orbwalker:SetAttack(bool)
	else
		GOS.BlockMovement = not bool
		GOS.BlockAttack = not bool
	end
end

local function GetPred(unit, speed, delay)
	local speed = speed or math.huge
	local delay = delay or 0.25
	local unitSpeed = unit.ms
	if OnWaypoint(unit).speed > unitSpeed then unitSpeed = OnWaypoint(unit).speed end
	if OnVision(unit).state == false then
		local unitPos = unit.pos + Vector(unit.pos,unit.posTo):Normalized() * ((GetTickCount() - OnVision(unit).tick)/1000 * unitSpeed)
		local predPos = unitPos + Vector(unit.pos,unit.posTo):Normalized() * (unitSpeed * (delay + (GetDistance(myHero.pos,unitPos)/speed)))
		if GetDistance(unit.pos,predPos) > GetDistance(unit.pos,unit.posTo) then predPos = unit.posTo end
		return predPos
	else
		if unitSpeed > unit.ms then
			local predPos = unit.pos + Vector(OnWaypoint(unit).startPos,unit.posTo):Normalized() * (unitSpeed * (delay + (GetDistance(myHero.pos,unit.pos)/speed)))
			if GetDistance(unit.pos,predPos) > GetDistance(unit.pos,unit.posTo) then predPos = unit.posTo end
			return predPos
		elseif IsImmobileTarget(unit) then
			return unit.pos
		else
			return unit:GetPrediction(speed,delay)
		end
	end
end

local castSpell = {state = 0, tick = GetTickCount(), casting = GetTickCount() - 1000, mouse = mousePos}

local function CustomCast(spell, pos, delay)
	if pos == nil then return end
	if _G.EOWLoaded or _G.SDK then
		Control.CastSpell(spell, pos)
	elseif _G.GOS then
		local ticker = GetTickCount()
		if castSpell.state == 0 and ticker - castSpell.casting > delay + Game.Latency() and pos:ToScreen().onScreen then
			castSpell.state = 1
			castSpell.mouse = mousePos
			castSpell.tick = ticker
		end
		if castSpell.state == 1 then
			if ticker - castSpell.tick < Game.Latency() then
				Control.SetCursorPos(pos)
				Control.KeyDown(spell)
				Control.KeyUp(spell)
				castSpell.casting = ticker + delay
				DelayAction(function()
					if castSpell.state == 1 then
						Control.SetCursorPos(castSpell.mouse)
						castSpell.state = 0
					end
				end, Game.Latency()/1000)
			end
			if ticker - castSpell.casting > Game.Latency() then
				Control.SetCursorPos(castSpell.mouse)
				castSpell.state = 0
			end
		end
	end
end

function Tick()
    local Mode = GetMode()
	if Mode == "Combo" then
		Combo()
	elseif Mode == "Clear" then
		Lane()
        Jungle()
	elseif Mode == "Harass" then
		Harass()
    elseif Mode == "Flee" then
        Flee()
	end
        Killsteal()
		StunQ()
        Summoners()
        Activator()
end

function Combo()
    local target = GetTarget(1200)
	if target == nil or target == myHero.team then return end
	if target ~= myHero.team then
    if Ready(_R) and myHero.pos:DistanceTo(target.pos) < 650 then
        if Anivia.C.Rm:Value() > PercentMP(myHero) then return end
        if Anivia.C.R:Value() then
            if myHero:GetSpellData(_R).toggleState == 1 then
                local pos = GetPred(target, R.Speed, 0.25 + (Game.Latency()/1000))
                EnableOrb(false)
                CustomCast(HK_R, pos, 250)
                EnableOrb(true)
            elseif myHero:GetSpellData(_R).toggleState == 2 then
                for i = 0, Game.ParticleCount() do
					local particle = Game.Particle(i)
					if particle.name == "Anivia_Base_R_AOE_Green.troy" then
						if target and target.pos:DistanceTo(particle.pos) > 400 then
							Control.CastSpell(HK_R)
						end
					end
				end
            end
        end
    end
    if Ready(_E) and myHero.pos:DistanceTo(target.pos) < 650 then
        if Anivia.C.Em:Value() > PercentMP(myHero) then return end
        if Anivia.C.E:Value() == false then
            Control.CastSpell(HK_E, target)
        elseif Anivia.C.E:Value() == true then
            for i = 0, target.buffCount do
            local buff = target:GetBuff(i);
                if buff.count > 0 then
                    if buff.name == "aniviaiced" then
                        Control.CastSpell(HK_E, target)
                    end
                end
            end
        end
    end
    if Ready(_W) and ValidTarget(target, W.Range + 50) then
        if Anivia.C.Wm:Value() > PercentMP(myHero) then return end
        if Anivia.C.Wa:Value() then
            if Anivia.C.W:Value() == 1 and PercentHP(myHero) > Anivia.C.NoPull:Value() and myHero.pos:DistanceTo(target.pos) < W.Range - 50 then
                local pull = Vector(myHero.pos) + Vector(Vector(target.pos) - Vector(myHero.pos)):Normalized() * (myHero.pos:DistanceTo(target.pos) + 88)
                EnableOrb(false)
                Control.CastSpell(HK_W, pull)
                EnableOrb(true)
            elseif Anivia.C.W:Value() == 2 or PercentHP(myHero) < Anivia.C.NoPull:Value() then
                local push = Vector(myHero.pos) + Vector(Vector(target.pos) - Vector(myHero.pos)):Normalized() * (myHero.pos:DistanceTo(target.pos) - 100)
                EnableOrb(false)
                Control.CastSpell(HK_W, push)
                EnableOrb(true)
            end
        end
    end
    if Ready(_Q) and ValidTarget(target, Q.Range) then
        if Anivia.C.Qm:Value() > PercentMP(myHero) then return end
        if Anivia.C.Q:Value() and myHero:GetSpellData(_Q).toggleState == 1 then
            local pos = GetPred(target, Q.Speed, 0.25 + (Game.Latency()/1000))
            EnableOrb(false)
            CustomCast(HK_Q, pos, 250)
            EnableOrb(true)
        elseif myHero:GetSpellData(_Q).toggleState == 2 then
            for i = 0, Game.ParticleCount() do
            	local particle = Game.Particle(i)
                if particle.name == "Anivia_Base_Q_AOE_Mis.troy" then
                    if target and target.pos:DistanceTo(particle.pos) < 225 then
                            Control.CastSpell(HK_Q)
                    end
                end
            end
        end
    end
	end
end

function Lane()
    for i = 1, Game.MinionCount() do
        local minion = Game.Minion(i)
        if minion and minion.team ~= myHero.team then
            if Ready(_E) and ValidTarget(minion, E.Range) then
                if Anivia.LC.Em:Value() > PercentMP(myHero) then return end
                if Anivia.LC.E:Value() then
                    Control.CastSpell(HK_E, minion)
                end
            end
        end
    end
    for i = 1, Game.MinionCount() do
        local minion = Game.Minion(i)
        if minion and minion.team ~= myHero.team then  
            if Ready(_R) and ValidTarget(minion, R.Range) then
                if Anivia.LC.Rm:Value() > PercentMP(myHero) then return end
                if Anivia.LC.R:Value() then
                    if Anivia.LC.MinR:Value() and myHero:GetSpellData(_R).toggleState == 1  then
                        Control.CastSpell(HK_R, minion.pos)
                    elseif Ready(_R) and myHero:GetSpellData(_R).toggleState == 2 and PercentMP(myHero) < Anivia.LC.Rm:Value() then
                        Control.CastSpell(HK_R)   
                    end
                end
            end
        end
    end
end

function Jungle()
    for i = 1, Game.MinionCount() do
        local minion = Game.Minion(i)
        if minion and minion.team == 300 then
            if Ready(_E) and ValidTarget(minion, E.Range) then
                if Anivia.LC.Em:Value() > PercentMP(myHero) then return end
                if Anivia.LC.E:Value() then
                    Control.CastSpell(HK_E, minion)
                end
            end
        end
    end
    for i = 1, Game.MinionCount() do
        local minion = Game.Minion(i)
        if minion and minion.team == 300 then  
            if Ready(_R) and ValidTarget(minion, R.Range) then
                if Anivia.LC.Rm:Value() > PercentMP(myHero) then return end
                if Anivia.LC.R:Value() then
                    if Anivia.LC.MinR:Value() and myHero:GetSpellData(_R).toggleState == 1  then
                        Control.CastSpell(HK_R, minion.pos)
                    elseif Ready(_R) and myHero:GetSpellData(_R).toggleState == 2 and PercentMP(myHero) < Anivia.LC.Rm:Value() then
                        Control.CastSpell(HK_R)   
                    end
                end
            end
        end
    end
end

function Harass()
    local target = GetTarget(Q.Range)
    if target == nil or target == myHero.team then return end
    if Ready(_Q) and ValidTarget(target, Q.Range) then
        if Anivia.H.Qm:Value() > PercentMP(myHero) then return end
        if Anivia.H.Q:Value() and myHero:GetSpellData(_Q).toggleState == 1 then
            local pos = GetPred(target, Q.Speed, 0.25 + (Game.Latency()/1000))
            CustomCast(HK_Q, pos, 250)
        elseif myHero:GetSpellData(_Q).toggleState == 2 then
            for i = 0, Game.ParticleCount() do
            	local particle = Game.Particle(i)
                if particle.name == "Anivia_Base_Q_AOE_Mis.troy" then
                    if target and target.pos:DistanceTo(particle.pos) < Q.Radius then
                            Control.CastSpell(HK_Q)
                    end
                end
            end
        end
    end
    if Ready(_E) and ValidTarget(target, E.Range) then
        if Anivia.H.Em:Value() > PercentMP(myHero) then return end
        if Anivia.H.E:Value() ~= 3 then
            if Anivia.H.E:Value() == 2 then
                Control.CastSpell(HK_E, target)
            elseif Anivia.H.E:Value() == 1 then
                for i = 0, target.buffCount do
                local buff = target:GetBuff(i);
                    if buff.count > 0 then
                        if buff.name == "aniviaiced" then
                            Control.CastSpell(HK_E, target)
                        end
                    end
                end
            end
        end
    end
end

function Flee()
    local target = GetTarget(Q.Range)
    if target == nil then return end
    if Ready(_Q) and ValidTarget(target, Q.Range) then
        if Anivia.F.Qm:Value() > PercentMP(myHero) then return end
        if Anivia.F.Q:Value() and myHero:GetSpellData(_Q).toggleState == 1 then
            local pos = GetPred(target, Q.Speed, 0.25 + (Game.Latency()/1000))
            CustomCast(HK_Q, pos, 250)
        elseif myHero:GetSpellData(_Q).toggleState == 2 then
            for i = 0, Game.ParticleCount() do
            	local particle = Game.Particle(i)
                if particle.name == "Anivia_Base_Q_AOE_Mis.troy" then
                    if target and target.pos:DistanceTo(particle.pos) < Q.Radius then
                            Control.CastSpell(HK_Q)
                    end
                end
            end
        end
    end
    if Ready(_W) and ValidTarget(target, W.Range) then
        if Anivia.F.Wm:Value() > PercentMP(myHero) then return end
        if Anivia.F.W:Value() then
            local push = Vector(myHero.pos) + Vector(Vector(target.pos) - Vector(myHero.pos)):Normalized() * (myHero.pos:DistanceTo(target.pos) - 100)
            Control.CastSpell(HK_W, push)
        end
    end
end

function Killsteal()
    local target = GetTarget(E.Range)
	if target == nil or target == myHero.team then return end
    if Ready(_Q) and ValidTarget(target, Q.Range) then
        if Anivia.F.Qm:Value() > PercentMP(myHero) then return end
        if Anivia.KS.Q:Value() and Qdmg(target) > target.health then
            if Anivia.KS.Q:Value() and myHero:GetSpellData(_Q).toggleState == 1 then
                local pos = GetPred(target, Q.Speed, 0.25 + (Game.Latency()/1000))
                CustomCast(HK_Q, pos, 250)
            elseif myHero:GetSpellData(_Q).toggleState == 2 then
                for i = 0, Game.ParticleCount() do
            	    local particle = Game.Particle(i)
                    if particle.name == "Anivia_Base_Q_AOE_Mis.troy" then
                        if target and target.pos:DistanceTo(particle.pos) < Q.Radius then
                                Control.CastSpell(HK_Q)
                        end
                    end
                end
            end
        end
    end

    if Ready(_E) and ValidTarget(target, E.Range) then
        if Anivia.F.Qm:Value() > PercentMP(myHero) then return end
        if Anivia.KS.E:Value() and Edmg(target) > target.health then
            Control.CastSpell(HK_E, target)
        end
    end
end

function StunQ()
    local target = GetTarget(2500)
    if target == nil or target == myHero.team then return end
	if Anivia.S.Q:Value() == false then return end
    for i = 0, Game.ParticleCount() do
        local particle = Game.Particle(i)
        if particle.name == "Anivia_Base_Q_AOE_Mis.troy" then
            if target and target.pos:DistanceTo(particle.pos) < 225 then
            	Control.CastSpell(HK_Q)
			end
        end
    end
end

function Summoners()
	local target = GetTarget(1500)
    if target == nil or target == myHero.team then return end
	if GetMode() == "Combo" then
		if myHero:GetSpellData(SUMMONER_1).name == "SummonerSmite" or myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmitePlayerGanker" or myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmiteDuel"
		or myHero:GetSpellData(SUMMONER_2).name == "SummonerSmite" or myHero:GetSpellData(SUMMONER_2).name == "S5_SummonerSmitePlayerGanker" or myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmiteDuel" then
			if Anivia.A.S.Smite:Value() then
				local RedDamage = Qdmg(target) + Wdmg(target) + Edmg(target) + Rdmg(target) + RSdmg(target)
				if myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmiteDuel" and Ready(SUMMONER_1) and RedDamage > target.health
				and myHero:GetSpellData(SUMMONER_1).ammo >= Anivia.A.S.SmiteS:Value() and myHero.pos:DistanceTo(target.pos) < 500 then
					Control.CastSpell(HK_SUMMONER_1, target)
				elseif myHero:GetSpellData(SUMMONER_2).name == "S5_SummonerSmiteDuel" and Ready(SUMMONER_2) and RedDamage > target.health
				and myHero:GetSpellData(SUMMONER_2).ammo >= Anivia.A.S.SmiteS:Value() and myHero.pos:DistanceTo(target.pos) < 500 then
					Control.CastSpell(HK_SUMMONER_2, target)
				end
				local BlueDamage = Qdmg(target) + Wdmg(target) + Edmg(target) + Rdmg(target) + BSdmg(target)
				if myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmitePlayerGanker" and Ready(SUMMONER_1) and BlueDamage > target.health
				and myHero:GetSpellData(SUMMONER_1).ammo >= Anivia.A.S.SmiteS:Value() and myHero.pos:DistanceTo(target.pos) < 500 then
					Control.CastSpell(HK_SUMMONER_1, target)
				elseif myHero:GetSpellData(SUMMONER_2).name == "S5_SummonerSmitePlayerGanker" and Ready(SUMMONER_2) and BlueDamage > target.health
				and myHero:GetSpellData(SUMMONER_2).ammo >= Anivia.A.S.SmiteS:Value() and myHero.pos:DistanceTo(target.pos) < 500 then
					Control.CastSpell(HK_SUMMONER_2, target)
				end
			end
		end
		if myHero:GetSpellData(SUMMONER_1).name == "SummonerDot"
		or myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" then
			if Anivia.A.S.Ignite:Value() then
				local IgDamage = Qdmg(target) + Edmg(target) + Idmg(target)
				if myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and Ready(SUMMONER_1) and IgDamage > target.health
				and myHero.pos:DistanceTo(target.pos) < 600 then
					Control.CastSpell(HK_SUMMONER_1, target)
				elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and Ready(SUMMONER_1) and IgDamage > target.health
				and myHero.pos:DistanceTo(target.pos) < 600 then
					Control.CastSpell(HK_SUMMONER_2, target)
				end
			end
		end
		if myHero:GetSpellData(SUMMONER_1).name == "SummonerExhaust"
		or myHero:GetSpellData(SUMMONER_2).name == "SummonerExhaust" then
			if Anivia.A.S.Exh:Value() then
				local Damage = Qdmg(target) + Wdmg(target) + Edmg(target) + Rdmg(target)
				if myHero:GetSpellData(SUMMONER_1).name == "SummonerExhaust" and Ready(SUMMONER_1) and Damage > target.health
				and myHero.pos:DistanceTo(target.pos) < 650 then
					Control.CastSpell(HK_SUMMONER_1, target)
				elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerExhaust" and Ready(SUMMONER_1) and Damage > target.health
				and myHero.pos:DistanceTo(target.pos) < 650 then
					Control.CastSpell(HK_SUMMONER_2, target)
				end
			end
		end
	end
	if myHero:GetSpellData(SUMMONER_1).name == "SummonerHeal"
	or myHero:GetSpellData(SUMMONER_2).name == "SummonerHeal" then
		if Anivia.A.S.Heal:Value() then
			if myHero:GetSpellData(SUMMONER_1).name == "SummonerHeal" and Ready(SUMMONER_1) and PercentHP(myHero) < Anivia.A.S.HealHP:Value() then
				Control.CastSpell(HK_SUMMONER_1)
			elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerHeal" and Ready(SUMMONER_1) and PercentHP(myHero) < Anivia.A.S.HealHP:Value() then
				Control.CastSpell(HK_SUMMONER_2)
			end
		end
	end
	if myHero:GetSpellData(SUMMONER_1).name == "SummonerBarrier"
	or myHero:GetSpellData(SUMMONER_2).name == "SummonerBarrier" then
		if Anivia.A.S.Barrier:Value() then
			if myHero:GetSpellData(SUMMONER_1).name == "SummonerBarrier" and Ready(SUMMONER_1) and PercentHP(myHero) < Anivia.A.S.BarrierHP:Value() then
				Control.CastSpell(HK_SUMMONER_1)
			elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerBarrier" and Ready(SUMMONER_1) and PercentHP(myHero) < Anivia.A.S.BarrierHP:Value() then
				Control.CastSpell(HK_SUMMONER_2)
			end
		end
	end
	if myHero:GetSpellData(SUMMONER_1).name == "SummonerBoost"
	or myHero:GetSpellData(SUMMONER_2).name == "SummonerBoost" then
		if Anivia.A.S.Cleanse:Value() then
			for i = 0, myHero.buffCount do
			local buff = myHero:GetBuff(i);
				if buff.count > 0 then
					if ((buff.type == 5 and Anivia.A.S.Stun:Value())
					or (buff.type == 7 and  Anivia.A.S.Silence:Value())
					or (buff.type == 8 and  Anivia.A.S.Taunt:Value())
					or (buff.type == 9 and  Anivia.A.S.Poly:Value())
					or (buff.type == 10 and  Anivia.A.S.Slow:Value())
					or (buff.type == 11 and  Anivia.A.S.Root:Value())
					or (buff.type == 21 and  Anivia.A.S.Flee:Value())
					or (buff.type == 22 and  Anivia.A.S.Charm:Value())
					or (buff.type == 25 and  Anivia.A.S.Blind:Value())
					or (buff.type == 28 and  Anivia.A.S.Flee:Value())) then
						if myHero:GetSpellData(SUMMONER_1).name == "SummonerBoost" and Ready(SUMMONER_1) then
							Control.CastSpell(HK_SUMMONER_1)
						elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerBoost" and Ready(SUMMONER_2) then
							Control.CastSpell(HK_SUMMONER_2)
						end
					end
				end
			end
		end
	end
end

function Activator()
	local target = GetTarget(900)
    if target == nil then return end
	local items = {}
	for slot = ITEM_1,ITEM_6 do
		local id = myHero:GetItemData(slot).itemID 
		if id > 0 then
			items[id] = slot
		end
	end

	local Potion = items[2003] or items[2010] or items[2031] or items[2032] or items[2033]
	if Potion and myHero:GetSpellData(Potion).currentCd == 0 and Anivia.A.P.Pot:Value() and PercentHP(myHero) < Anivia.A.P.HP:Value() and NoPotion() then
		Control.CastSpell(HKITEM[Potion])
	end

	if GetMode() == "Combo" then
		local Randuin = items[3143]
		if Randuin and myHero:GetSpellData(Randuin).currentCd == 0 and Anivia.A.I.RO:Value() and myHero.pos:DistanceTo(target.pos) < 500 then
			Control.CastSpell(HKITEM[Randuin])
		end

		local Proto = items[3152] or items[3146] or items[3146] or items[3030]
		if Proto and myHero:GetSpellData(Proto).currentCd == 0 and Anivia.A.I.Proto:Value() and myHero.pos:DistanceTo(target.pos) > 550 then
			Control.CastSpell(HKITEM[Proto], target.pos)
		end
	end
end

function Drawings()
    if myHero.dead then return end
	if Anivia.D.Q:Value() and Ready(_Q) then Draw.Circle(myHero.pos, Q.Range, 3,  Draw.Color(255, 000, 222, 255)) end
    if Anivia.D.W:Value() and Ready(_W) then Draw.Circle(myHero.pos, W.Range, 3,  Draw.Color(255, 255, 200, 000)) end
	if Anivia.D.E:Value() and Ready(_E) then Draw.Circle(myHero.pos, E.Range, 3,  Draw.Color(255, 246, 000, 255)) end
    if Anivia.D.R:Value() and Ready(_R) then Draw.Circle(myHero.pos, R.Range, 3,  Draw.Color(255, 000, 043, 255)) end
	if Anivia.D.Dmg:Value() then
		for i = 1, Game.HeroCount() do
			local enemy = Game.Hero(i)
			if enemy and enemy.isEnemy and not enemy.dead and enemy.visible then
				local barPos = enemy.hpBar
				local health = enemy.health
				local maxHealth = enemy.maxHealth
				local Qdmg = Qdmg(enemy)
				local Edmg = Edmg(enemy)
				local Damage = Qdmg + Edmg
				if Damage < health then
					Draw.Rect(barPos.x + (((health - Qdmg) / maxHealth) * 100), barPos.y, (Qdmg / maxHealth )*100, 10, Draw.Color(170, 000, 222, 255))
					Draw.Rect(barPos.x + (((health - (Qdmg + Edmg)) / maxHealth) * 100), barPos.y, (Edmg / maxHealth )*100, 10, Draw.Color(170, 255, 200, 000))
				else
    				Draw.Rect(barPos.x, barPos.y, (health / maxHealth ) * 100, 10, Draw.Color(170, 000, 255, 000))
				end
			end
		end
	end
--toggle
	if Anivia.D.Emode:Value() then
		local textPos = myHero.pos:To2D()
		if Anivia.C.E:Value() then
			Draw.Text("E Mode: ENHANCED", 20, textPos.x - 33, textPos.y + 60, Draw.Color(255, 000, 255, 000))
		else
			Draw.Text("E Mode: NORMAL", 20, textPos.x - 33, textPos.y + 60, Draw.Color(255, 000, 255, 000))
		end
	end
	if Anivia.D.Wa:Value() then
		local textPos = myHero.pos:To2D()
		if Anivia.C.Wa:Value() then
			Draw.Text("Toggle: Wall ON", 20, textPos.x - 33, textPos.y + 40, Draw.Color(255, 000, 255, 000))
		else
			Draw.Text("Toggle: Wall OFF", 20, textPos.x - 33, textPos.y + 40, Draw.Color(255, 225, 000, 000))
		end
	end
end
