if myHero.charName ~= "Swain" then return end

--// requirements
require "Eternal Prediction"

--// spelldata
local Q = { Range = 700, Delay = myHero:GetSpellData(_Q).delay, Speed = myHero:GetSpellData(_Q).speed, Width = myHero:GetSpellData(_Q).width}
local W = { Range = 900, Delay = myHero:GetSpellData(_W).delay, Speed = myHero:GetSpellData(_W).speed, Width = myHero:GetSpellData(_W).width}
local E = { Range = 625, Delay = myHero:GetSpellData(_E).delay, Speed = myHero:GetSpellData(_E).speed, Width = myHero:GetSpellData(_E).width}
local R = { Range = 700, Delay = myHero:GetSpellData(_R).delay, Speed = myHero:GetSpellData(_R).speed, Width = myHero:GetSpellData(_R).width}

local QtoPred = Prediction:SetSpell(Q, TYPE_CIRCULAR, true)
local WtoPred = Prediction:SetSpell(W, TYPE_CIRCULAR, true)
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
    	return CalcMagicalDamage(myHero, target, (50 + 70 * level + 1.20 * myHero.ap))
	end
	return 0
end

local function Wdmg(target)
    local level = myHero:GetSpellData(_W).level
	if Ready(_W) then
    	return CalcMagicalDamage(myHero, target, (40 + 35 * level + 0.70 * myHero.ap))
	end
	return 0
end

local function Edmg(target)
    local level = myHero:GetSpellData(_E).level
	if Ready(_E) then
        return CalcMagicalDamage(myHero, target, (24 + 36 * level + 1.20 * myHero.ap))
	end
	return 0
end

local function Rdmg(target)
    local level = myHero:GetSpellData(_R).level
	if Ready(_R) then
    	return CalcMagicalDamage(myHero, target, (30 + 20 * level + 0.20 * myHero.ap))
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
local Swain = MenuElement({type = MENU, id = "Swain", name = "Swag Swain", leftIcon = "http://ddragon.leagueoflegends.com/cdn/6.24.1/img/champion/Swain.png"})

Swain:MenuElement({type = MENU, id = "C", name = "Combo"})
Swain:MenuElement({type = MENU, id = "H", name = "Harass"})
Swain:MenuElement({type = MENU, id = "LC", name = "LaneClear"})
Swain:MenuElement({type = MENU, id = "JC", name = "JungleClear"})
Swain:MenuElement({type = MENU, id = "KS", name = "KillSteal"})
Swain:MenuElement({type = MENU, id = "MM", name = "Mana Settings"})
Swain:MenuElement({type = MENU, id = "A", name = "Activator Settings"})
Swain:MenuElement({type = MENU, id = "D", name = "Drawings"})
Swain:MenuElement({id = "Author", name = "Author", drop = {"parad0x"}})
Swain:MenuElement({id = "Version", name = "Version", drop = {"v1.0"}})
Swain:MenuElement({id = "Patch", name = "Patch", drop = {"RIOT 7.13"}})

Swain.C:MenuElement({id = "Q", name = "Q: Decrepify", value = true})
Swain.C:MenuElement({id = "W", name = "W: Nevermove", value = true})
Swain.C:MenuElement({id = "E", name = "E: Torment", value = true})
Swain.C:MenuElement({id = "R", name ="R: Ravenous Flock", value = true})
Swain.C:MenuElement({id = "RMin", name = "Min Near Enemies to R", value = 1, min = 0, max = 4, tooltip = "If You Want 1 Enemy Put 0, 2 Enemies Put 1, 3 Enemies put 2 and etc..."})

Swain.H:MenuElement({id = "Q", name = "Q: Decrepify", value = true})
Swain.H:MenuElement({id = "W", name = "W: Nevermove", value = false})
Swain.H:MenuElement({id = "E", name = "E: Torment", value = false})

Swain.LC:MenuElement({id = "Q", name = "Q: Decrepify", value = true})
Swain.LC:MenuElement({id = "QMin", name = "Near minions to Q", value = 3, min = 0, max = 6})
Swain.LC:MenuElement({id = "W", name = "W: Nevermove", value = true})
Swain.LC:MenuElement({id = "WMin", name = "Near minions to W", value = 3, min = 1, max = 7})
Swain.LC:MenuElement({id = "E", name = "E: Torment", value = false})

Swain.JC:MenuElement({id = "Q", name = "Q: Decrepify", value = true})
Swain.JC:MenuElement({id = "W", name = "W: Nevermove", value = true})
Swain.JC:MenuElement({id = "E", name = "E: Torment", value = true})

Swain.KS:MenuElement({id = "Q", name = "Q: Decrepify", value = true})
Swain.KS:MenuElement({id = "W", name = "W: Nevermove", value = true})
Swain.KS:MenuElement({id = "E", name = "E: Torment", value = true})

Swain.MM:MenuElement({id = "C", name = "Mana % to Combo", value = 0, min = 0, max = 100})
Swain.MM:MenuElement({id = "H", name = "Mana % to Harass", value = 60, min = 0, max = 100})
Swain.MM:MenuElement({id = "LC", name = "Mana % to Lane", value = 55, min = 0, max = 100})
Swain.MM:MenuElement({id = "JC", name = "Mana % to Jungle", value = 30, min = 0, max = 100})
Swain.MM:MenuElement({id = "KS", name = "Mana % to KS", value = 0, min = 0, max = 100})

Swain.A:MenuElement({type = MENU, id = "P", name = "Potions"})
Swain.A.P:MenuElement({id = "Pot", name = "All Potions", value = true})
Swain.A.P:MenuElement({id = "HP", name = "Health % to Potion", value = 60, min = 0, max = 100})
Swain.A:MenuElement({type = MENU, id = "I", name = "Items"})
Swain.A.I:MenuElement({id = "RO", name = "Randuin's Omen", value = true})
Swain.A.I:MenuElement({id = "Proto", name = "Hextec Items (all)", value = true})
Swain.A:MenuElement({type = MENU, id = "S", name = "Summoner Spells"})
DelayAction(function()
	if myHero:GetSpellData(SUMMONER_1).name == "SummonerSmite" or myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmitePlayerGanker" or myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmiteDuel"
	or myHero:GetSpellData(SUMMONER_2).name == "SummonerSmite" or myHero:GetSpellData(SUMMONER_2).name == "S5_SummonerSmitePlayerGanker" or myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmiteDuel" then
		Swain.A.S:MenuElement({id = "Smite", name = "Smite in Combo [?]", value = true, tooltip = "If Combo will kill"})
		Swain.A.S:MenuElement({id = "SmiteS", name = "Smite Stacks to Combo", value = 1, min = 1, max = 2})
	end
end, 2)
DelayAction(function()
	if myHero:GetSpellData(SUMMONER_1).name == "SummonerHeal"
	or myHero:GetSpellData(SUMMONER_2).name == "SummonerHeal" then
		Swain.A.S:MenuElement({id = "Heal", name = "Auto Heal", value = true})
		Swain.A.S:MenuElement({id = "HealHP", name = "Health % to Heal", value = 25, min = 0, max = 100})
	end
end, 2)
DelayAction(function()
	if myHero:GetSpellData(SUMMONER_1).name == "SummonerBarrier"
	or myHero:GetSpellData(SUMMONER_2).name == "SummonerBarrier" then
		Swain.A.S:MenuElement({id = "Barrier", name = "Auto Barrier", value = true})
		Swain.A.S:MenuElement({id = "BarrierHP", name = "Health % to Barrier", value = 25, min = 0, max = 100})
	end
end, 2)
DelayAction(function()
	if myHero:GetSpellData(SUMMONER_1).name == "SummonerDot"
	or myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" then
		Swain.A.S:MenuElement({id = "Ignite", name = "Ignite in Combo", value = true})
	end
end, 2)
DelayAction(function()
	if myHero:GetSpellData(SUMMONER_1).name == "SummonerExhaust"
	or myHero:GetSpellData(SUMMONER_2).name == "SummonerExhaust" then
		Swain.A.S:MenuElement({id = "Exh", name = "Exhaust in Combo [?]", value = true, tooltip = "If Combo will kill"})
	end
end, 2)
DelayAction(function()
	if myHero:GetSpellData(SUMMONER_1).name == "SummonerBoost"
	or myHero:GetSpellData(SUMMONER_2).name == "SummonerBoost" then
		Swain.A.S:MenuElement({id = "Cleanse", name = "Auto Cleanse", value = true})
		Swain.A.S:MenuElement({id = "Blind", name = "Blind", value = false})
		Swain.A.S:MenuElement({id = "Charm", name = "Charm", value = true})
		Swain.A.S:MenuElement({id = "Flee", name = "Flee", value = true})
		Swain.A.S:MenuElement({id = "Slow", name = "Slow", value = false})
		Swain.A.S:MenuElement({id = "Root", name = "Root/Snare", value = true})
		Swain.A.S:MenuElement({id = "Poly", name = "Polymorph", value = true})
		Swain.A.S:MenuElement({id = "Silence", name = "Silence", value = true})
		Swain.A.S:MenuElement({id = "Stun", name = "Stun", value = true})
		Swain.A.S:MenuElement({id = "Taunt", name = "Taunt", value = true})
	end
end, 2)
Swain.A.S:MenuElement({type = SPACE, id = "Note", name = "Note: Ghost/TP/Flash is not supported"})

Swain.D:MenuElement({id = "Q", name = "Q: Decrepify", value = true})
Swain.D:MenuElement({id = "W", name = "W: Nevermove", value = true})
Swain.D:MenuElement({id = "E", name = "E: Torment", value = true})
Swain.D:MenuElement({id = "R", name = "R: Ravenous Flock", value = true})
Swain.D:MenuElement({id = "Dmg", name = "Damage HP bar", value = true})

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
        Summoners()
        Activator()
end

function Combo()
    if Swain.MM.C:Value() > PercentMP(myHero) then return end
    local target = GetTarget(1000)
    if target == nil then return end
    if Ready(_Q) and myHero.pos:DistanceTo(target.pos) < 700 then
        if Swain.C.Q:Value() then
            local Qpred = QtoPred:GetPrediction(target, myHero.pos)
            if Qpred and Qpred.hitChance >= 0.25 then
                Control.CastSpell(HK_Q, Qpred.castPos)
            end
        end
    end
    if Ready(_W) and ValidTarget(target, W.Range) then
        if Swain.C.W:Value() then
            local Wpred = WtoPred:GetPrediction(target, myHero.pos)
            if Wpred and Wpred.hitChance >= 0.3 then
                Control.CastSpell(HK_W, Wpred.castPos)
            end
        end
    end
    if Ready(_E) and ValidTarget(target, E.Range) then
        if Swain.C.E:Value() then
                Control.CastSpell(HK_E, target)
        end
    end
    if Ready(_R) and ValidTarget(target, R.Range) then
        if Swain.C.R:Value() then
            if HeroesAround(target.pos, 700, 200) > Swain.C.RMin:Value() and myHero:GetSpellData(_R).toggleState == 1 then
                Control.CastSpell(HK_R)
            elseif Ready(_R) and myHero:GetSpellData(_R).toggleState == 2 and myHero.mana < Swain.MM.C:Value() then
                Control.CastSpell(HK_R)
            end
        end
    end
end

function Lane()
    if Swain.MM.LC:Value() > PercentMP(myHero) then return end
    for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
        if minion and minion.team == 200 then
            if Ready(_Q) and ValidTarget(minion, Q.Range) then
                if Swain.LC.Q:Value() then
                    local BestPos, BestHit = BestCircularPos(Q.Range, 325, 200)
                    if BestPos and BestHit >= Swain.LC.WMin:Value() then
                        Control.CastSpell(HK_Q, BestPos)
                    end
                end
            end
            if Ready(_W) and ValidTarget(minion, W.Range) then
                if Swain.LC.W:Value() then
                    local BestPos, BestHit = BestCircularPos(W.Range, 125, 200)
                    if BestPos and BestHit >= Swain.LC.WMin:Value() then
                        Control.CastSpell(HK_W, BestPos)
                    end
                end
            end
            if Ready(_E) and ValidTarget(minion, E.Range) then
                if Swain.LC.E:Value() then
                        Control.CastSpell(HK_E, minion)
                end
            end
        end
    end
end
function Jungle()
    if Swain.MM.JC:Value() > PercentMP(myHero) then return end
    for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
        if minion and minion.team == 300 then
            if Ready(_Q) and ValidTarget(minion, Q.Range) then
                if Swain.JC.Q:Value() then
                    local Qpred = QtoPred:GetPrediction(minion, myHero.pos)
                    if Qpred and Qpred.hitChance >= 0.25 then
                        Control.CastSpell(HK_Q, Qpred.castPos)
                    end
                end
            end
            if Ready(_W) and ValidTarget(minion, W.Range) then
                if Swain.JC.W:Value() then
                    local Wpred = WtoPred:GetPrediction(minion, myHero.pos)
                    if Wpred and Wpred.hitChance >= 0.25 then
                        Control.CastSpell(HK_W, Wpred.castPos)
                    end
                end
            end
            if Ready(_E) and ValidTarget(minion, E.Range) then
                if Swain.JC.E:Value() then
                    Control.CastSpell(HK_E, minion)
                end
            end
        end
    end
end

function Harass()
    if Swain.MM.H:Value() > PercentMP(myHero) then return end
    local target = GetTarget(1000)
    if target == nil then return end
    if Ready(_Q) and ValidTarget(target, Q.Range) then
        if Swain.H.Q:Value() then
            local Qpred = QtoPred:GetPrediction(target, myHero.pos)
            if Qpred and Qpred.hitChance >= 0.25 then
                Control.CastSpell(HK_Q, Qpred.castPos)
            end
        end
    end
    if Ready(_W) and ValidTarget(target, W.Range) then
        if Swain.H.W:Value() then
            local Wpred = WtoPred:GetPrediction(target, myHero.pos)
            if Wpred and Wpred.hitChance >= 0.25 then
                Control.CastSpell(HK_W, Wpred.castPos)
            end
        end
    end
    if Ready(_E) and ValidTarget(target, E.Range) then
        if Swain.H.E:Value() then
            Control.CastSpell(HK_E, target)
        end
    end 
end

function Killsteal()
    if Swain.MM.KS:Value() > PercentMP(myHero) then return end
    local target = GetTarget(1000)
    if target == nil then return end
    if Ready(_Q) and ValidTarget(target, Q.Range) then
        if Swain.KS.Q:Value() and Qdmg(target) > target.health then
            local Qpred = QtoPred:GetPrediction(target, myHero.pos)
            if Qpred and Qpred.hitChance >= 0.25 then
                Control.CastSpell(HK_Q, Qpred.castPos)
            end
        end
    end
    if Ready(_W) and ValidTarget(target, W.Range) then
        if Swain.KS.W:Value() and Wdmg(target) > target.health then
            local Wpred = WtoPred:GetPrediction(target, myHero.pos)
            if Wpred and Wpred.hitChance >= 0.25 then
                Control.CastSpell(HK_W, Wpred.castPos)
            end
        end
    end
    if Ready(_E) and ValidTarget(target, E.Range) then
        if Swain.KS.E:Value() and Edmg(target) > target.health then
            Control.CastSpell(HK_E, target)
        end
    end
end


function Summoners()
	local target = GetTarget(1500)
    if target == nil then return end
	if GetMode() == "Combo" then
		if myHero:GetSpellData(SUMMONER_1).name == "SummonerSmite" or myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmitePlayerGanker" or myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmiteDuel"
		or myHero:GetSpellData(SUMMONER_2).name == "SummonerSmite" or myHero:GetSpellData(SUMMONER_2).name == "S5_SummonerSmitePlayerGanker" or myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmiteDuel" then
			if Swain.A.S.Smite:Value() then
				local RedDamage = Qdmg(target) + Wdmg(target) + Edmg(target) + Rdmg(target) + RSdmg(target)
				if myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmiteDuel" and Ready(SUMMONER_1) and RedDamage > target.health
				and myHero:GetSpellData(SUMMONER_1).ammo >= Swain.A.S.SmiteS:Value() and myHero.pos:DistanceTo(target.pos) < 500 then
					Control.CastSpell(HK_SUMMONER_1, target)
				elseif myHero:GetSpellData(SUMMONER_2).name == "S5_SummonerSmiteDuel" and Ready(SUMMONER_2) and RedDamage > target.health
				and myHero:GetSpellData(SUMMONER_2).ammo >= Swain.A.S.SmiteS:Value() and myHero.pos:DistanceTo(target.pos) < 500 then
					Control.CastSpell(HK_SUMMONER_2, target)
				end
				local BlueDamage = Qdmg(target) + Wdmg(target) + Edmg(target) + Rdmg(target) + BSdmg(target)
				if myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmitePlayerGanker" and Ready(SUMMONER_1) and BlueDamage > target.health
				and myHero:GetSpellData(SUMMONER_1).ammo >= Swain.A.S.SmiteS:Value() and myHero.pos:DistanceTo(target.pos) < 500 then
					Control.CastSpell(HK_SUMMONER_1, target)
				elseif myHero:GetSpellData(SUMMONER_2).name == "S5_SummonerSmitePlayerGanker" and Ready(SUMMONER_2) and BlueDamage > target.health
				and myHero:GetSpellData(SUMMONER_2).ammo >= Swain.A.S.SmiteS:Value() and myHero.pos:DistanceTo(target.pos) < 500 then
					Control.CastSpell(HK_SUMMONER_2, target)
				end
			end
		end
		if myHero:GetSpellData(SUMMONER_1).name == "SummonerDot"
		or myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" then
			if Swain.A.S.Ignite:Value() then
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
			if Swain.A.S.Exh:Value() then
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
		if Swain.A.S.Heal:Value() then
			if myHero:GetSpellData(SUMMONER_1).name == "SummonerHeal" and Ready(SUMMONER_1) and PercentHP(myHero) < Swain.A.S.HealHP:Value() then
				Control.CastSpell(HK_SUMMONER_1)
			elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerHeal" and Ready(SUMMONER_1) and PercentHP(myHero) < Swain.A.S.HealHP:Value() then
				Control.CastSpell(HK_SUMMONER_2)
			end
		end
	end
	if myHero:GetSpellData(SUMMONER_1).name == "SummonerBarrier"
	or myHero:GetSpellData(SUMMONER_2).name == "SummonerBarrier" then
		if Swain.A.S.Barrier:Value() then
			if myHero:GetSpellData(SUMMONER_1).name == "SummonerBarrier" and Ready(SUMMONER_1) and PercentHP(myHero) < Swain.A.S.BarrierHP:Value() then
				Control.CastSpell(HK_SUMMONER_1)
			elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerBarrier" and Ready(SUMMONER_1) and PercentHP(myHero) < Swain.A.S.BarrierHP:Value() then
				Control.CastSpell(HK_SUMMONER_2)
			end
		end
	end
	if myHero:GetSpellData(SUMMONER_1).name == "SummonerBoost"
	or myHero:GetSpellData(SUMMONER_2).name == "SummonerBoost" then
		if Swain.A.S.Cleanse:Value() then
			for i = 0, myHero.buffCount do
			local buff = myHero:GetBuff(i);
				if buff.count > 0 then
					if ((buff.type == 5 and Swain.A.S.Stun:Value())
					or (buff.type == 7 and  Swain.A.S.Silence:Value())
					or (buff.type == 8 and  Swain.A.S.Taunt:Value())
					or (buff.type == 9 and  Swain.A.S.Poly:Value())
					or (buff.type == 10 and  Swain.A.S.Slow:Value())
					or (buff.type == 11 and  Swain.A.S.Root:Value())
					or (buff.type == 21 and  Swain.A.S.Flee:Value())
					or (buff.type == 22 and  Swain.A.S.Charm:Value())
					or (buff.type == 25 and  Swain.A.S.Blind:Value())
					or (buff.type == 28 and  Swain.A.S.Flee:Value())) then
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
	if Potion and myHero:GetSpellData(Potion).currentCd == 0 and Swain.A.P.Pot:Value() and PercentHP(myHero) < Swain.A.P.HP:Value() and NoPotion() then
		Control.CastSpell(HKITEM[Potion])
	end

	if GetMode() == "Combo" then
		local Randuin = items[3143]
		if Randuin and myHero:GetSpellData(Randuin).currentCd == 0 and Swain.A.I.RO:Value() and myHero.pos:DistanceTo(target.pos) < 500 then
			Control.CastSpell(HKITEM[Randuin])
		end

		local Proto = items[3152] or items[3146] or items[3146] or items[3030]
		if Proto and myHero:GetSpellData(Proto).currentCd == 0 and Swain.A.I.Proto:Value() and myHero.pos:DistanceTo(target.pos) > 550 then
			Control.CastSpell(HKITEM[Proto], target.pos)
		end
	end
end

function Drawings()
    if myHero.dead then return end
	if Swain.D.Q:Value() and Ready(_Q) then Draw.Circle(myHero.pos, Q.Range, 3,  Draw.Color(255, 000, 222, 255)) end
    if Swain.D.W:Value() and Ready(_W) then Draw.Circle(myHero.pos, W.Range, 3,  Draw.Color(255, 255, 200, 000)) end
	if Swain.D.E:Value() and Ready(_E) then Draw.Circle(myHero.pos, E.Range, 3,  Draw.Color(255, 246, 000, 255)) end
	if Swain.D.Dmg:Value() then
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
				local Damage = Qdmg + Wdmg + Edmg
				if Damage < health then
					Draw.Rect(barPos.x + (((health - Qdmg) / maxHealth) * 100), barPos.y, (Qdmg / maxHealth )*100, 10, Draw.Color(170, 000, 222, 255))
					Draw.Rect(barPos.x + (((health - (Qdmg + Wdmg)) / maxHealth) * 100), barPos.y, (Wdmg / maxHealth )*100, 10, Draw.Color(170, 255, 200, 000))
					Draw.Rect(barPos.x + (((health - (Qdmg + Wdmg + Edmg)) / maxHealth) * 100), barPos.y, (Edmg / maxHealth )*100, 10, Draw.Color(170, 246, 000, 255))
				else
    				Draw.Rect(barPos.x, barPos.y, (health / maxHealth ) * 100, 10, Draw.Color(170, 000, 255, 000))
				end
			end
		end
	end
end
