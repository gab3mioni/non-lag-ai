
NDefines.NCountry.NAVY_USE_HOME_BASE_FOR_RANGE = false			-- If true, will calculate task force range from home base, otherwise will calculate from any friendly naval base 원래 true

NDefines.NProduction.RESOURCE_TO_ENERGY_COEFFICIENT = 12.0		-- How much energy per coal produces 원래 9
NDefines.NProduction.BASE_FACTORY_SPEED_NAV = 3.0 				-- Base factory speed multiplier (how much hoi3 style IC each factory gives). 원래 2.0.
NDefines.NProduction.POWERED_FACTORY_SPEED_NAV = 3.5 			--Powered factory speed multiplier. 원래 2.5

NDefines.NBuildings.NAVALBASE_REPAIR_MULT = 0.5		-- Each level of navalbase building repairs X strength and can repair as many ships as its level 원래 0.05
NDefines.NBuildings.INFRASTRUCTURE_RESOURCE_BONUS = 0.20 -- multiplicative resource bonus for each level of (non damaged) infrastructure 원래 0.15

NDefines.NNavy.MAX_CAPITALS_PER_AUTO_TASK_FORCE = 30 --원래 5							-- maximum number of capital ships the auto-task force creation will put together when designing SurfaceActionGroup
NDefines.NNavy.COMBAT_MIN_DURATION = 24										-- Min combat duration before we can retreat. It's a balancing variable so it's not possible to always run with our weak ships agains big flotillas. 원래 8
NDefines.NNavy.EXPERIENCE_FACTOR_NON_CARRIER_GAIN = 0.08						-- Xp gain by non-carrier ships in the combat 원래 0.04
NDefines.NNavy.EXPERIENCE_FACTOR_CARRIER_GAIN = 0.16							-- Xp gain by carrier ships in the combat 원래 0.08
NDefines.NNavy.NAVAL_INVASION_PREPARE_DAYS = 32								-- base days needed to prepare a naval invasion 원래 60
NDefines.NNavy.NAVAL_INVASION_PLAN_CAP = 3									-- base cap of naval invasions can be planned at the same time 원래 1
NDefines.NNavy.NAVAL_COMBAT_PLANE_MIN_STACKING_PENALTY = 240						-- How many planes flying in a naval combat before penalties are introduced 원래 80
NDefines.NNavy.NAVAL_COMBAT_PLANE_STACKING_PENALTY_EFFECT = 0.002					-- Each plane above the optimal amount decreases the amount of airplanes being able to takeoff by such %. Subject to diminishing returns 원래 0.005
NDefines.NNavy.FUEL_COST_MULT = 0.05 -- fuel multiplier for all naval missions 원래 0.10

NDefines.NNavy.AGGRESSION_SETTINGS_VALUES = { -- ships will use this values while deciding to attack enemies
		0,		-- do not engage
		1.8,	-- low 원래 0.5
		2.4,	-- medium 원래 0.9
		3.2,	-- high 원래 2.0
		10000,	-- I am death incarnate!
}

NDefines.NNavy.AGGRESION_MULTIPLIER_FOR_COMBAT = 3				-- ships are more aggresive in combat 원래 1.2

NDefines.NNavy.BASE_SPOTTING = 5												-- base spotting percentage for navy 원래 1

NDefines.NNavy.HIGHER_SHIP_RATIO_POSITIONING_PENALTY_FACTOR					= 0.25 --원래 0.25 -- if one side has more ships than the other, that side will get this penalty for each +100% ship ratio it has

NDefines.NNavy.MIN_SHIP_COUNT_FOR_TASK_FORCE_ROLE_ASSIGNMENT = 8--원래 4					-- define the minimum number of ship that should be in a task force for it to be considered a patrol or an escort task force (used to the insignia assignment, see TASK_FORCE_ROLE_TO_INSIGNIA)

NDefines.NAI.DESIRE_USE_XP_TO_UPGRADE_NAVAL_EQUIPMENT = 2.0 -- How quickly is desire to update/create naval equipment variants accumulated? 원래 1.0
NDefines.NAI.WANTED_UNITS_MAX_WANTED_CAP = 800	-- Maximum wanted divisions for a country. This can be exceeded by certain hardcoded multipliers, but not by base calculation logic. 원래 500
NDefines.NAI.WANTED_CARRIER_PLANES_PER_CARRIER_CAPACITY_FACTOR = 2					-- Scales how many carrier planes the AI want per carrier deck space. 원래 1.5
NDefines.NAI.WANTED_CARRIER_PLANES_PER_CARRIER_CAPACITY_IN_PRODUCTION_FACTOR = 1.5	-- Scales how many carrier planes the AI want per deck space of carriers in production. 원래 1
NDefines.NAI.REFIT_SHIP_RELUCTANCE = 280							-- How often to consider refitting to new equipment variants for ships in the field 원래 28
NDefines.NAI.REFIT_SHIP_PERCENTAGE_OF_FORCES = 0.01				-- How big part of the navy that should be considered for refitting 원래 0.1
NDefines.NAI.REGION_THREAT_LEVEL_TO_AVOID_REGION = 25 * 500		-- How much threat must be generated in region ( by REGION_THREAT_PER_SUNK_CONVOY ) so the AI will decide to mark the region as avoid 원래 25*10
NDefines.NAI.REGION_THREAT_LEVEL_TO_BLOCK_REGION = 25 * 1000		-- How much threat must be generated in region ( by REGION_THREAT_PER_SUNK_CONVOY ) so the AI will decide to mark the region as avoid 원래 25*100
NDefines.NAI.PRODUCTION_MAX_PROGRESS_TO_SWITCH_NAVAL = 0.05		-- AI will not replace ships being built by newer types if progress is above this 원래 0.1

NDefines.NAI.CARRIER_TASKFORCE_MAX_CARRIER_COUNT = 8 		-- optimum carrier count for carrier taskforces 원래 4
NDefines.NAI.CAPITAL_TASKFORCE_MAX_CAPITAL_COUNT = 16 		-- optimum capital count for capital taskforces 원래 12
NDefines.NAI.SCREEN_TASKFORCE_MAX_SHIP_COUNT = 24			-- optimum screen count for screen taskforces 원래 12
NDefines.NAI.SUB_TASKFORCE_MAX_SHIP_COUNT = 16				-- optimum sub count for sub taskforces 원래 16

NDefines.NAI.MIN_CAPITALS_FOR_CARRIER_TASKFORCE = 8			-- carrier fleets will at least have this amount of capitals 원래 6
NDefines.NAI.CAPITALS_TO_CARRIER_RATIO = 2				-- capital to carrier count in carrier taskfoces 원래 1.5
NDefines.NAI.SCREENS_TO_CAPITAL_RATIO = 5.0					-- screens to capital/carrier count in carrier & capital taskforces 원래 4.0

NDefines.NAI.MAX_SCREEN_TASKFORCES_FOR_MINE_SWEEPING = 0.05 -- maximum ratio of screens forces to be used in mine sweeping 원래 0.10

NDefines.NAI.MAX_SCREEN_TASKFORCES_FOR_MINE_LAYING = 0.05 -- maximum ratio of screens forces to be used in mine laying 원래 0.10

NDefines.NAI.MAX_FUEL_CONSUMPTION_RATIO_FOR_NAVY_TRAINING = 1.00		-- ai will use at most this ratio of affordable fuel for naval training 원래 0.20

NDefines.NAI.MAX_FULLY_TRAINED_SHIP_RATIO_FOR_TRAINING = 0.9			-- ai will not train a taskforce if fully trained ships are above this ratio 원래 0.7
