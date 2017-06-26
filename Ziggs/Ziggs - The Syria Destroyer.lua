if myHero.charName ~= "Ziggs" then return end

--// requirements
require "Eternal Prediction"

--// spelldata
local Q = { Range = myHero:GetSpellData(_Q).range, Delay = myHero:GetSpellData(_Q).delay, Speed = myHero:GetSpellData(_Q).speed, Width = myHero:GetSpellData(_Q).width}
local W = { Range = myHero:GetSpellData(_W).range, Delay = myHero:GetSpellData(_W).delay, Speed = myHero:GetSpellData(_W).speed, Width = myHero:GetSpellData(_W).width}
local E = { Range = myHero:GetSpellData(_E).range, Delay = myHero:GetSpellData(_E).delay, Speed = myHero:GetSpellData(_E).speed, Width = myHero:GetSpellData(_E).width}
local R = { Range = myHero:GetSpellData(_R).range, Delay = myHero:GetSpellData(_R).delay, Speed = myHero:GetSpellData(_R).speed, Width = myHero:GetSpellData(_R).width}

local QtoPred = Prediction:SetSpell(Q, TYPE_LINE, true)
local EtoPred = Prediction:SetSpell(E, TYPE_CIRCULAR, true)
local RtoPred = Prediction:SetSpell(R, TYPE_CIRCULAR, true)
--// needs
local function Ready(spell)
	return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana and Game.CanUseSpell(spell) == 0 
end

function ValidTarget(target, range)
	range = range and range or math.huge
	return target ~= nil and target.valid and target.visible and not target.dead and target.distance <= range
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
	if _G.EOWLoaded then
		target = EOW:GetTarget(range)
	elseif _G.SDK and _G.SDK.Orbwalker then
		target = _G.SDK.TargetSelector:GetTarget(range)
	else
		target = GOS:GetTarget(range)
	end
	return target
end

local function GetMode()
	if _G.EOWLoaded then
		if EOW.CurrentMode == 1 then
			return "Combo"
		elseif EOW.CurrentMode == 2 then
			return "Harass"
		elseif EOW.CurrentMode == 3 then
			return "Lasthit"
		elseif EOW.CurrentMode == 4 then
			return "Clear"
		end
	elseif _G.SDK and _G.SDK.Orbwalker then
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
    	return CalcMagicalDamage(myHero, target, (30 + 45 * level + 0.65 * myHero.ap))
	end
	return 0
end

local function Wdmg(target)
    local level = myHero:GetSpellData(_W).level
	if Ready(_W) then
    	return CalcMagicalDamage(myHero, target, (35 + 35 * level + 0.35 * myHero.ap))
	end
	return 0
end

local function Edmg(target)
    local level = myHero:GetSpellData(_E).level
	if Ready(_E) then
        local firstmine = CalcMagicalDamage(myHero, target, (15 + 25 * level + 0.3 * myHero.ap))
    	return firstmine + (firstmine * 0.4) * 2
	end
	return 0
end

local function Rdmg(target)
    local level = myHero:GetSpellData(_R).level
	if Ready(_R) then
    	return CalcMagicalDamage(myHero, target, (100 + 100 * level + 0.733 * myHero.ap))
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

--// Menu
local Ziggs = MenuElement({type = MENU, id = "Ziggs", name = "Ziggs - The Syria Destroyer", leftIcon = "https://raw.githubusercontent.com/ParadOx999/GamingOnSteroids-EXT/master/Ziggs/Ziggs.png"})

Ziggs:MenuElement({type = MENU, id = "C", name = "Combo"})
Ziggs:MenuElement({type = MENU, id = "H", name = "Harass"})
Ziggs:MenuElement({type = MENU, id = "LC", name = "LaneClear"})
Ziggs:MenuElement({type = MENU, id = "JC", name = "JungleClear"})
Ziggs:MenuElement({type = MENU, id = "M", name = "Misc"})
Ziggs:MenuElement({type = MENU, id = "F", name = "Flee"})
Ziggs:MenuElement({type = MENU, id = "KS", name = "KillSteal"})
Ziggs:MenuElement({type = MENU, id = "MM", name = "Mana Settings"})
Ziggs:MenuElement({type = MENU, id = "A", name = "Activator Settings"})
Ziggs:MenuElement({type = MENU, id = "D", name = "Drawings"})
Ziggs:MenuElement({id = "Author", name = "Author", drop = {"parad0x"}})
Ziggs:MenuElement({id = "Version", name = "Version", drop = {"Alpha v1"}})
Ziggs:MenuElement({id = "Patch", name = "Patch", drop = {"RIOT 7.12"}})

Ziggs.C:MenuElement({id = "Q", name = "Q: Bouncing Bomb", value = true})
Ziggs.C:MenuElement({id = "W", name = "W: Satchel Charge", drop = {'Pull','Push','Disabled'}})
Ziggs.C:MenuElement({id = "NoPull", name = "Dont Pull if HP below %", value = 40, min = 0, max = 100})
Ziggs.C:MenuElement({id = "E", name = "E: Hexplosive Minefield", value = true})
Ziggs.C:MenuElement({id = "R", name ="R: Mega Inferno Bomb", value = true})
Ziggs.C:MenuElement({id = "RMin", name = "Min Near Enemies to R", value = 2, min = 0, max = 4})

Ziggs.H:MenuElement({id = "Q", name = "Q: Bouncing Bomb", value = true})

Ziggs.LC:MenuElement({id = "Q", name = "Q: Boucing Bomb", value = true})
Ziggs.LC:MenuElement({id = "QMin", name = "Near minions to Q", value = 3, min = 0, max = 6})
Ziggs.LC:MenuElement({id = "W", name = "W: Satchel Charge", drop = {'Turret','Laneclear','Both','Disabled'}})
Ziggs.LC:MenuElement({id = "WMin", name = "Near minions to W", value = 3, min = 1, max = 7})
Ziggs.LC:MenuElement({id = "E", name = "E: Hexplosive Minefield", value = true})
Ziggs.LC:MenuElement({id = "EMin", name = "Minions to E", value = 5, min = 1, max = 7})

Ziggs.JC:MenuElement({id = "Q", name = "Q: Bouncing Bomb", value = true})
Ziggs.JC:MenuElement({id = "W", name = "W: Satchel Charge", value = true})
Ziggs.JC:MenuElement({id = "E", name = "E: Hexplosive Minefield", value = true})

Ziggs.M:MenuElement({id = "Q", name = "Auto Last Hit Q if out of AA range", value = true})

Ziggs.F:MenuElement({id = "W", name = "W: Satchel Charge", value = true})
Ziggs.F:MenuElement({id = "E", name = "E: Hexplosive Minefield", value = true})

Ziggs.KS:MenuElement({id = "Q", name = "Q: Bouncing Bomb", value = true})
Ziggs.KS:MenuElement({id = "W", name = "W: Satchel Charge", value = true})
Ziggs.KS:MenuElement({id = "E", name = "E: Hexplosive Minefield", value = true})
Ziggs.KS:MenuElement({id = "R", name ="Mega Inferno Bomb", value = true})

Ziggs.MM:MenuElement({id = "C", name = "Mana % to Combo", value = 0, min = 0, max = 100})
Ziggs.MM:MenuElement({id = "H", name = "Mana % to Harass", value = 60, min = 0, max = 100})
Ziggs.MM:MenuElement({id = "LC", name = "Mana % to Lane", value = 55, min = 0, max = 100})
Ziggs.MM:MenuElement({id = "JC", name = "Mana % to Jungle", value = 30, min = 0, max = 100})
Ziggs.MM:MenuElement({id = "M", name = "Mana % to Auto Q", value = 65, min = 0, max = 100})
Ziggs.MM:MenuElement({id = "F", name = "Mana % to Flee", value = 5, min = 0, max = 100})
Ziggs.MM:MenuElement({id = "KS", name = "Mana % to KS", value = 0, min = 0, max = 100})

Ziggs.A:MenuElement({type = MENU, id = "P", name = "Potions"})
Ziggs.A.P:MenuElement({id = "Pot", name = "All Potions", value = true})
Ziggs.A.P:MenuElement({id = "HP", name = "Health % to Potion", value = 60, min = 0, max = 100})
Ziggs.A:MenuElement({type = MENU, id = "I", name = "Items"})
Ziggs.A.I:MenuElement({id = "RO", name = "Randuin's Omen", value = true})
Ziggs.A.I:MenuElement({id = "Proto", name = "Hextec Items (all)", value = true})
Ziggs.A:MenuElement({type = MENU, id = "S", name = "Summoner Spells"})
DelayAction(function()
	if myHero:GetSpellData(SUMMONER_1).name == "SummonerSmite" or myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmitePlayerGanker" or myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmiteDuel"
	or myHero:GetSpellData(SUMMONER_2).name == "SummonerSmite" or myHero:GetSpellData(SUMMONER_2).name == "S5_SummonerSmitePlayerGanker" or myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmiteDuel" then
		Ziggs.A.S:MenuElement({id = "Smite", name = "Smite in Combo [?]", value = true, tooltip = "If Combo will kill"})
		Ziggs.A.S:MenuElement({id = "SmiteS", name = "Smite Stacks to Combo", value = 1, min = 1, max = 2})
	end
end, 2)
DelayAction(function()
	if myHero:GetSpellData(SUMMONER_1).name == "SummonerHeal"
	or myHero:GetSpellData(SUMMONER_2).name == "SummonerHeal" then
		Ziggs.A.S:MenuElement({id = "Heal", name = "Auto Heal", value = true})
		Ziggs.A.S:MenuElement({id = "HealHP", name = "Health % to Heal", value = 25, min = 0, max = 100})
	end
end, 2)
DelayAction(function()
	if myHero:GetSpellData(SUMMONER_1).name == "SummonerBarrier"
	or myHero:GetSpellData(SUMMONER_2).name == "SummonerBarrier" then
		Ziggs.A.S:MenuElement({id = "Barrier", name = "Auto Barrier", value = true})
		Ziggs.A.S:MenuElement({id = "BarrierHP", name = "Health % to Barrier", value = 25, min = 0, max = 100})
	end
end, 2)
DelayAction(function()
	if myHero:GetSpellData(SUMMONER_1).name == "SummonerDot"
	or myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" then
		Ziggs.A.S:MenuElement({id = "Ignite", name = "Ignite in Combo", value = true})
	end
end, 2)
DelayAction(function()
	if myHero:GetSpellData(SUMMONER_1).name == "SummonerExhaust"
	or myHero:GetSpellData(SUMMONER_2).name == "SummonerExhaust" then
		Ziggs.A.S:MenuElement({id = "Exh", name = "Exhaust in Combo [?]", value = true, tooltip = "If Combo will kill"})
	end
end, 2)
DelayAction(function()
	if myHero:GetSpellData(SUMMONER_1).name == "SummonerBoost"
	or myHero:GetSpellData(SUMMONER_2).name == "SummonerBoost" then
		Ziggs.A.S:MenuElement({id = "Cleanse", name = "Auto Cleanse", value = true})
		Ziggs.A.S:MenuElement({id = "Blind", name = "Blind", value = false})
		Ziggs.A.S:MenuElement({id = "Charm", name = "Charm", value = true})
		Ziggs.A.S:MenuElement({id = "Flee", name = "Flee", value = true})
		Ziggs.A.S:MenuElement({id = "Slow", name = "Slow", value = false})
		Ziggs.A.S:MenuElement({id = "Root", name = "Root/Snare", value = true})
		Ziggs.A.S:MenuElement({id = "Poly", name = "Polymorph", value = true})
		Ziggs.A.S:MenuElement({id = "Silence", name = "Silence", value = true})
		Ziggs.A.S:MenuElement({id = "Stun", name = "Stun", value = true})
		Ziggs.A.S:MenuElement({id = "Taunt", name = "Taunt", value = true})
	end
end, 2)
Ziggs.A.S:MenuElement({type = SPACE, id = "Note", name = "Note: Ghost/TP/Flash is not supported"})

Ziggs.D:MenuElement({id = "Q", name = "Q: Boucing Bomb", value = true})
Ziggs.D:MenuElement({id = "W", name = "W: Satchel Charge", value = true})
Ziggs.D:MenuElement({id = "E", name = "E: Hexplosive Minefield", value = true})
Ziggs.D:MenuElement({id = "R", name = "R: Mega Inferno Bomb(Minimap) ", value = true})
Ziggs.D:MenuElement({id = "Dmg", name = "Damage HP bar", value = true})

--// script
Callback.Add("Tick", function() Tick() end)
Callback.Add("Draw", function() Drawings() end)

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
        Lasthit()
        Summoners()
        Activator()
end

function Combo()
    if Ziggs.MM.C:Value() > PercentMP(myHero) then return end
    local target = GetTarget(R.Range)
    if target == nil then return end
    if Ready(_Q) and ValidTarget(target, Q.Range) then
        if Ziggs.C.Q:Value() then
            local Qpred = QtoPred:GetPrediction(target, myHero.pos)
            if Qpred and Qpred.hitChance >= 0.25 and Qpred:mCollision() == 0 then
                Control.CastSpell(HK_Q, Qpred.castPos)
            end
        end
    end
    if Ready(_W) and ValidTarget(target, W.Range + 100) then
        if Ziggs.C.W:Value() ~= 3 then
            if Ziggs.C.W:Value() == 1 and PercentHP(myHero) > Ziggs.C.NoPull:Value() and myHero.pos:DistanceTo(target.pos) < W.Range - 100 then
                local pull = Vector(myHero.pos) + Vector(Vector(target.pos) - Vector(myHero.pos)):Normalized() * (myHero.pos:DistanceTo(target.pos) + 100)
                Control.CastSpell(HK_W, pull)
            elseif Ziggs.C.W:Value() == 2 or PercentHP(myHero) < Ziggs.C.NoPull:Value() then
                local push = Vector(myHero.pos) + Vector(Vector(target.pos) - Vector(myHero.pos)):Normalized() * (myHero.pos:DistanceTo(target.pos) - 100)
                Control.CastSpell(HK_W, push)
            end
        end
    end
    if Ready(_E) and ValidTarget(target, E.Range) then
        if Ziggs.C.E:Value() then
            local Epred = EtoPred:GetPrediction(target, myHero.pos)
            if Epred and Epred.hitChance >= 0.25 then
                Control.CastSpell(HK_E, Epred.castPos)
            end
        end
    end
    if Ready(_R) and ValidTarget(target, R.Range) then
        if Ziggs.C.R:Value() then
            if HeroesAround(target.pos, 475, 200) > Ziggs.C.RMin:Value() then
                local Rpred = RtoPred:GetPrediction(target, myHero.pos)
                if Rpred and Rpred.hitChance >= 0.25 then
                   if OnScreen(target) then
                        Control.CastSpell(HK_R, Rpred.castPos)
                    else
                        Control.CastSpell(HK_R, Rpred.castPos:ToMM())
                    end
                end
            end
        end
    end
end

function Lane()
    if Ziggs.MM.LC:Value() > PercentMP(myHero) then return end
    for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
        if minion and minion.team == 200 then
            if Ready(_Q) and ValidTarget(minion, Q.Range) then
                if Ziggs.LC.Q:Value() then
                    if MinionsAround(minion.pos, 180, 200) > Ziggs.LC.QMin:Value() then
                        local Qpred = QtoPred:GetPrediction(minion, myHero.pos)
                        if Qpred and Qpred.hitChance >= 0.25 then
                            Control.CastSpell(HK_Q, Qpred.castPos)
                        end
                    end
                end
            end
            if Ready(_W) and ValidTarget(minion, W.Range) then
                if Ziggs.LC.W:Value() == 2 or Ziggs.LC.W:Value() == 3 then
                    local BestPos, BestHit = BestCircularPos(W.Range, 325, 200)
                    if BestPos and BestHit >= Ziggs.LC.WMin:Value() then
                        Control.CastSpell(HK_W, BestPos)
                    end
                end
            end
            if Ready(_E) and ValidTarget(minion, E.Range) then
                if Ziggs.LC.E:Value() then
                    local BestPos, BestHit = BestCircularPos(E.Range, 325, 200)
                    if BestPos and BestHit >= Ziggs.LC.EMin:Value() then
                        Control.CastSpell(HK_E, BestPos)
                    end
                end
            end
        end
    end
    for i = 1, Game.TurretCount() do
		local turret = Game.Turret(i)
        if turret and turret.team ~= myHero.team then
            if Ready(_W) and ValidTarget(turret, W.Range) then
                if Ziggs.LC.W:Value() == 1 or Ziggs.LC.W:Value() == 3 then
                    local level = myHero:GetSpellData(_W).level
                    local demolition = 22.25 + 2.5 * level
                    if PercentHP(turret) < demolition then
                        Control.CastSpell(HK_W, turret.pos)
                    end
                end
            end
        end
    end
end

function Jungle()
    if Ziggs.MM.JC:Value() > PercentMP(myHero) then return end
    for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
        if minion and minion.team == 300 then
            if Ready(_Q) and ValidTarget(minion, Q.Range) then
                if Ziggs.JC.Q:Value() then
                    local Qpred = QtoPred:GetPrediction(minion, myHero.pos)
                    if Qpred and Qpred.hitChance >= 0.25 then
                        Control.CastSpell(HK_Q, Qpred.castPos)
                    end
                end
            end
            if Ready(_W) and ValidTarget(minion, W.Range) then
                if Ziggs.JC.W:Value() then
                    Control.CastSpell(HK_W, minion.pos)
                end
            end
            if Ready(_E) and ValidTarget(minion, E.Range) then
                if Ziggs.JC.E:Value() then
                    Control.CastSpell(HK_E, minion.pos)
                end
            end
        end
    end
end

function Harass()
    if Ziggs.MM.H:Value() > PercentMP(myHero) then return end
    local target = GetTarget(Q.Range)
    if target == nil then return end
    if Ready(_Q) and ValidTarget(target, Q.Range) then
        if Ziggs.H.Q:Value() then
            local Qpred = QtoPred:GetPrediction(target, myHero.pos)
            if Qpred and Qpred.hitChance >= 0.25 and Qpred:mCollision() == 0 then
                Control.CastSpell(HK_Q, Qpred.castPos)
            end
        end
    end
end

function Flee()
    if Ziggs.MM.F:Value() > PercentMP(myHero) then return end
    local target = GetTarget(W.Range)
    if target == nil then return end
    if Ready(_W) and ValidTarget(target, W.Range) then
        if Ziggs.F.W:Value() then
            local push = Vector(myHero.pos) + Vector(Vector(target.pos) - Vector(myHero.pos)):Normalized() * (myHero.pos:DistanceTo(target.pos) - 100)
            Control.CastSpell(HK_W, push)
        end
    end
    if Ready(_E) and ValidTarget(target, E.Range) then
        if Ziggs.F.E:Value() then
            local Epred = EtoPred:GetPrediction(target, myHero.pos)
            if Epred and Epred.hitChance >= 0.25 then
                Control.CastSpell(HK_E, Epred.castPos)
            end
        end
    end
end

function Killsteal()
    if Ziggs.MM.KS:Value() > PercentMP(myHero) then return end
    local target = GetTarget(R.Range)
    if target == nil then return end
    if Ready(_Q) and ValidTarget(target, Q.Range) then
        if Ziggs.KS.Q:Value() and Qdmg(target) > target.health then
            local Qpred = QtoPred:GetPrediction(target, myHero.pos)
            if Qpred and Qpred.hitChance >= 0.25 and Qpred:mCollision() == 0 then
                Control.CastSpell(HK_Q, Qpred.castPos)
            end
        end
    end
    if Ready(_W) and ValidTarget(target, W.Range) then
        if Ziggs.KS.W:Value() then
            if Wdmg(target) > target.health then
                Control.CastSpell(HK_W, target.pos)
            end
        end
    end
    if Ready(_E) and ValidTarget(target, E.Range) then
        if Ziggs.KS.E:Value() and Edmg(target) > target.health then
            local Epred = EtoPred:GetPrediction(target, myHero.pos)
            if Epred and Epred.hitChance >= 0.25 then
                Control.CastSpell(HK_E, Epred.castPos)
            end
        end
    end
    if Ready(_R) and ValidTarget(target, R.Range) then
        if Ziggs.KS.R:Value() and Rdmg(target) > target.health then
            local Rpred = RtoPred:GetPrediction(target, myHero.pos)
            if Rpred and Rpred.hitChance >= 0.25 then
                if OnScreen(target) then
                    Control.CastSpell(HK_R, Rpred.castPos)
                else
                    Control.CastSpell(HK_R, Rpred.castPos:ToMM())
                end
            end
        end
    end
end

function Lasthit()
    if Ziggs.M.Q:Value() == false then return end
    if Ziggs.MM.M:Value() > PercentMP(myHero) then return end
    for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
        if minion and minion.team == 200 then
            if Ready(_Q) and ValidTarget(minion, Q.Range) then
                if Ziggs.M.Q:Value() and Qdmg(minion) > minion.health and myHero.pos:DistanceTo(minion.pos) > 550 then
                    local Qpred = QtoPred:GetPrediction(minion, myHero.pos)
                    if Qpred and Qpred.hitChance >= 0.25 then
                        Control.CastSpell(HK_Q, Qpred.castPos)
                    end
                end
            end
        end
    end
end


function Summoners()
	local target = GetTarget(1500)
    if target == nil then return end
	if GetMode() == "Combo" then
		if myHero:GetSpellData(SUMMONER_1).name == "SummonerSmite" or myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmitePlayerGanker" or myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmiteDuel"
		or myHero:GetSpellData(SUMMONER_2).name == "SummonerSmite" or myHero:GetSpellData(SUMMONER_2).name == "S5_SummonerSmitePlayerGanker" or myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmiteDuel" then
			if Ziggs.A.S.Smite:Value() then
				local RedDamage = Qdmg(target) + Wdmg(target) + Edmg(target) + Rdmg(target) + RSdmg(target)
				if myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmiteDuel" and Ready(SUMMONER_1) and RedDamage > target.health
				and myHero:GetSpellData(SUMMONER_1).ammo >= Ziggs.A.S.SmiteS:Value() and myHero.pos:DistanceTo(target.pos) < 500 then
					Control.CastSpell(HK_SUMMONER_1, target)
				elseif myHero:GetSpellData(SUMMONER_2).name == "S5_SummonerSmiteDuel" and Ready(SUMMONER_2) and RedDamage > target.health
				and myHero:GetSpellData(SUMMONER_2).ammo >= Ziggs.A.S.SmiteS:Value() and myHero.pos:DistanceTo(target.pos) < 500 then
					Control.CastSpell(HK_SUMMONER_2, target)
				end
				local BlueDamage = Qdmg(target) + Wdmg(target) + Edmg(target) + Rdmg(target) + BSdmg(target)
				if myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmitePlayerGanker" and Ready(SUMMONER_1) and BlueDamage > target.health
				and myHero:GetSpellData(SUMMONER_1).ammo >= Ziggs.A.S.SmiteS:Value() and myHero.pos:DistanceTo(target.pos) < 500 then
					Control.CastSpell(HK_SUMMONER_1, target)
				elseif myHero:GetSpellData(SUMMONER_2).name == "S5_SummonerSmitePlayerGanker" and Ready(SUMMONER_2) and BlueDamage > target.health
				and myHero:GetSpellData(SUMMONER_2).ammo >= Ziggs.A.S.SmiteS:Value() and myHero.pos:DistanceTo(target.pos) < 500 then
					Control.CastSpell(HK_SUMMONER_2, target)
				end
			end
		end
		if myHero:GetSpellData(SUMMONER_1).name == "SummonerDot"
		or myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" then
			if Ziggs.A.S.Ignite:Value() then
				local IgDamage = Qdmg(target) + Wdmg(target) + Edmg(target) + Rdmg(target) + Idmg(target)
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
			if Ziggs.A.S.Exh:Value() then
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
		if Ziggs.A.S.Heal:Value() then
			if myHero:GetSpellData(SUMMONER_1).name == "SummonerHeal" and Ready(SUMMONER_1) and HP100(myHero) < Ziggs.A.S.HealHP:Value() then
				Control.CastSpell(HK_SUMMONER_1)
			elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerHeal" and Ready(SUMMONER_1) and HP100(myHero) < Ziggs.A.S.HealHP:Value() then
				Control.CastSpell(HK_SUMMONER_2)
			end
		end
	end
	if myHero:GetSpellData(SUMMONER_1).name == "SummonerBarrier"
	or myHero:GetSpellData(SUMMONER_2).name == "SummonerBarrier" then
		if Ziggs.A.S.Barrier:Value() then
			if myHero:GetSpellData(SUMMONER_1).name == "SummonerBarrier" and Ready(SUMMONER_1) and HP100(myHero) < Ziggs.A.S.BarrierHP:Value() then
				Control.CastSpell(HK_SUMMONER_1)
			elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerBarrier" and Ready(SUMMONER_1) and HP100(myHero) < Ziggs.A.S.BarrierHP:Value() then
				Control.CastSpell(HK_SUMMONER_2)
			end
		end
	end
	if myHero:GetSpellData(SUMMONER_1).name == "SummonerBoost"
	or myHero:GetSpellData(SUMMONER_2).name == "SummonerBoost" then
		if Ziggs.A.S.Cleanse:Value() then
			for i = 0, myHero.buffCount do
			local buff = myHero:GetBuff(i);
				if buff.count > 0 then
					if ((buff.type == 5 and Ziggs.A.S.Stun:Value())
					or (buff.type == 7 and  Ziggs.A.S.Silence:Value())
					or (buff.type == 8 and  Ziggs.A.S.Taunt:Value())
					or (buff.type == 9 and  Ziggs.A.S.Poly:Value())
					or (buff.type == 10 and  Ziggs.A.S.Slow:Value())
					or (buff.type == 11 and  Ziggs.A.S.Root:Value())
					or (buff.type == 21 and  Ziggs.A.S.Flee:Value())
					or (buff.type == 22 and  Ziggs.A.S.Charm:Value())
					or (buff.type == 25 and  Ziggs.A.S.Blind:Value())
					or (buff.type == 28 and  Ziggs.A.S.Flee:Value())) then
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
	if Potion and myHero:GetSpellData(Potion).currentCd == 0 and Ziggs.A.P.Pot:Value() and PercentHP(myHero) < Ziggs.A.P.HP:Value() and NoPotion() then
		Control.CastSpell(HKITEM[Potion])
	end

	if GetMode() == "Combo" then
		local Randuin = items[3143]
		if Randuin and myHero:GetSpellData(Randuin).currentCd == 0 and Ziggs.A.I.RO:Value() and myHero.pos:DistanceTo(target.pos) < 500 then
			Control.CastSpell(HKITEM[Randuin])
		end

		local Proto = items[3152] or items[3146] or items[3146] or items[3030]
		if Proto and myHero:GetSpellData(Proto).currentCd == 0 and Ziggs.A.I.Proto:Value() and myHero.pos:DistanceTo(target.pos) > 550 then
			Control.CastSpell(HKITEM[Proto], target.pos)
		end
	end
end

function Drawings()
    if myHero.dead then return end
	if Ziggs.D.Q:Value() and Ready(_Q) then Draw.Circle(myHero.pos, 1400, 3,  Draw.Color(255, 000, 222, 255)) end
    if Ziggs.D.W:Value() and Ready(_W) then Draw.Circle(myHero.pos, W.Range, 3,  Draw.Color(255, 255, 200, 000)) end
	if Ziggs.D.E:Value() and Ready(_E) then Draw.Circle(myHero.pos, E.Range, 3,  Draw.Color(255, 246, 000, 255)) end
	if Ziggs.D.R:Value() and Ready(_R) then Draw.CircleMinimap(myHero.pos, R.Range, 3,  Draw.Color(255, 000, 043, 255)) end
	if Ziggs.D.Dmg:Value() then
		for i = 1, Game.HeroCount() do
			local enemy = Game.Hero(i)
			if enemy and enemy.isEnemy and not enemy.dead and enemy.visible then
				local barPos = enemy.hpBar
				local health = enemy.health
				local maxHealth = enemy.maxHealth
				local Qdmg = Qdmg(enemy)
				local Wdmg = Wdmg(enemy)
				local Edmg = Edmg(enemy)
				local Rdmg = Rdmg(enemy)
				local Damage = Qdmg + Wdmg + Edmg + Rdmg
				if Damage < health then
					Draw.Rect(barPos.x + (((health - Qdmg) / maxHealth) * 100), barPos.y, (Qdmg / maxHealth )*100, 10, Draw.Color(170, 000, 222, 255))
					Draw.Rect(barPos.x + (((health - (Qdmg + Wdmg)) / maxHealth) * 100), barPos.y, (Wdmg / maxHealth )*100, 10, Draw.Color(170, 255, 200, 000))
					Draw.Rect(barPos.x + (((health - (Qdmg + Wdmg + Edmg)) / maxHealth) * 100), barPos.y, (Edmg / maxHealth )*100, 10, Draw.Color(170, 246, 000, 255))
					Draw.Rect(barPos.x + (((health - (Qdmg + Wdmg + Edmg + Rdmg)) / maxHealth) * 100), barPos.y, (Rdmg / maxHealth )*100, 10, Draw.Color(170, 000, 043, 255))
				else
    				Draw.Rect(barPos.x, barPos.y, (health / maxHealth ) * 100, 10, Draw.Color(170, 000, 255, 000))
				end
			end
		end
	end
end