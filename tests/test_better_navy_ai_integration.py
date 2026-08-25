import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

OVERWRITTEN_PATHS = {
    "common/ai_equipment/ENG_naval.txt",
    "common/ai_equipment/ENG_planes.txt",
    "common/ai_equipment/GER_naval.txt",
    "common/ai_equipment/GER_planes.txt",
    "common/ai_equipment/JAP_naval.txt",
    "common/ai_equipment/USA_naval.txt",
    "common/ai_equipment/USA_planes.txt",
    "common/ai_equipment/generic_planes.txt",
    "common/ai_strategy/USA.txt",
    "common/characters/USA.txt",
    "common/ideas/navy_spirits.txt",
    "common/technologies/MTG_naval.txt",
    "common/technologies/bba_air_techs.txt",
}

ADDED_STATIC_PATHS = {
    "common/defines/zz_bna_defines.lua",
    "common/modifiers/bna_static_modifiers.txt",
    "common/special_projects/projects/naval_projects.txt",
    "common/units/battlecruiser.txt",
    "common/units/battleship.txt",
    "common/units/carrier.txt",
    "common/units/destroyer.txt",
    "common/units/heavy_cruiser.txt",
    "common/units/light_cruiser.txt",
    "common/units/submarine.txt",
    "common/units/equipment/modules/00_ship_modules.txt",
    "common/units/equipment/ship_hull_carrier.txt",
    "common/units/equipment/ship_hull_cruiser.txt",
    "common/units/equipment/ship_hull_heavy.txt",
    "common/units/equipment/ship_hull_light.txt",
    "common/units/equipment/ship_hull_submarine.txt",
}

STATE_IDS = {
    261,
    *range(357, 373),
    *range(375, 383),
    *range(384, 392),
    *range(394, 397),
    816,
}

CONFLICTING_DEFINES = {
    "NDefines.NCountry.NAVY_USE_HOME_BASE_FOR_RANGE": "false",
    "NDefines.NNavy.MAX_CAPITALS_PER_AUTO_TASK_FORCE": "30",
    "NDefines.NAI.CAPITALS_TO_CARRIER_RATIO": "2",
    "NDefines.NAI.CAPITAL_TASKFORCE_MAX_CAPITAL_COUNT": "16",
    "NDefines.NAI.CARRIER_TASKFORCE_MAX_CARRIER_COUNT": "8",
    "NDefines.NAI.DESIRE_USE_XP_TO_UPGRADE_NAVAL_EQUIPMENT": "2.0",
    "NDefines.NAI.MAX_FUEL_CONSUMPTION_RATIO_FOR_NAVY_TRAINING": "1.00",
    "NDefines.NAI.MAX_SCREEN_TASKFORCES_FOR_MINE_LAYING": "0.05",
    "NDefines.NAI.MAX_SCREEN_TASKFORCES_FOR_MINE_SWEEPING": "0.05",
    "NDefines.NAI.MIN_CAPITALS_FOR_CARRIER_TASKFORCE": "8",
    "NDefines.NAI.REFIT_SHIP_PERCENTAGE_OF_FORCES": "0.01",
    "NDefines.NAI.REFIT_SHIP_RELUCTANCE": "280",
    "NDefines.NAI.REGION_THREAT_LEVEL_TO_BLOCK_REGION": "25 * 1000",
    "NDefines.NAI.SCREENS_TO_CAPITAL_RATIO": "5.0",
    "NDefines.NAI.SCREEN_TASKFORCE_MAX_SHIP_COUNT": "24",
    "NDefines.NAI.SUB_TASKFORCE_MAX_SHIP_COUNT": "16",
}

EXPECTED_DEFINES = {
    **CONFLICTING_DEFINES,
    "NDefines.NProduction.RESOURCE_TO_ENERGY_COEFFICIENT": "12.0",
    "NDefines.NProduction.BASE_FACTORY_SPEED_NAV": "3.0",
    "NDefines.NNavy.FUEL_COST_MULT": "0.05",
}


def integrated_paths():
    paths = {ROOT / path for path in OVERWRITTEN_PATHS | ADDED_STATIC_PATHS}
    paths.update((ROOT / "common/ai_navy").rglob("*.txt"))
    paths.update((ROOT / "common/ai_strategy").glob("bna_*.txt"))

    for state_id in STATE_IDS:
        matches = list((ROOT / "history/states").glob(f"{state_id}-*.txt"))
        if len(matches) == 1:
            paths.add(matches[0])

    return paths


def brace_error(path):
    text = path.read_text(encoding="utf-8-sig")
    depth = 0
    in_string = False
    escaped = False
    in_comment = False

    for line_number, line in enumerate(text.splitlines(), start=1):
        in_comment = False
        for character in line:
            if in_comment:
                continue
            if in_string:
                if escaped:
                    escaped = False
                elif character == "\\":
                    escaped = True
                elif character == '"':
                    in_string = False
                continue
            if character == "#":
                in_comment = True
            elif character == '"':
                in_string = True
            elif character == "{":
                depth += 1
            elif character == "}":
                depth -= 1
                if depth < 0:
                    return f"unexpected closing brace at line {line_number}"

    if in_string:
        return "unterminated string"
    if depth:
        return f"unbalanced braces: depth {depth}"
    return None


def effective_defines():
    assignments = {}
    pattern = re.compile(r"^(NDefines\.[A-Za-z0-9_.]+)\s*=\s*(.*?)\s*(?:--.*)?$")

    define_files = sorted(
        (ROOT / "common/defines").glob("*.lua"), key=lambda path: path.name
    )
    for path in define_files:
        for line in path.read_text(encoding="utf-8-sig").splitlines():
            match = pattern.match(line.strip())
            if match:
                assignments[match.group(1)] = match.group(2).strip()

    return assignments, define_files


def define_names(path):
    pattern = re.compile(r"^(NDefines\.[A-Za-z0-9_.]+)\s*=")
    return {
        match.group(1)
        for line in path.read_text(encoding="utf-8-sig").splitlines()
        if (match := pattern.match(line.strip()))
    }


class BetterNavyAIIntegrationTest(unittest.TestCase):
    def test_complete_functional_inventory_is_present(self):
        ai_navy_files = list((ROOT / "common/ai_navy").rglob("*.txt"))
        strategy_files = list((ROOT / "common/ai_strategy").glob("bna_*.txt"))

        self.assertEqual(15, len(ai_navy_files))
        self.assertEqual(4, len(strategy_files))
        self.assertEqual(37, len(STATE_IDS))
        self.assertEqual(85, len(integrated_paths()))

        missing = [path for path in integrated_paths() if not path.is_file()]
        self.assertEqual([], missing)

    def test_imported_pdxscript_has_balanced_braces(self):
        failures = {}
        for path in integrated_paths():
            if path.suffix != ".txt":
                continue
            error = brace_error(path)
            if error:
                failures[str(path.relative_to(ROOT))] = error

        self.assertEqual({}, failures)

    def test_state_ids_are_unique(self):
        state_paths = list((ROOT / "history/states").glob("*.txt"))
        states_by_id = {}
        for path in state_paths:
            state_id = path.name.partition("-")[0]
            states_by_id.setdefault(state_id, []).append(path.name)

        duplicates = {
            state_id: names
            for state_id, names in states_by_id.items()
            if len(names) > 1
        }
        self.assertEqual({}, duplicates)

    def test_better_navy_ai_defines_have_final_precedence(self):
        assignments, define_files = effective_defines()
        sheep_defines = define_names(ROOT / "common/defines/lsm_defines.lua")
        better_navy_defines = define_names(
            ROOT / "common/defines/zz_bna_defines.lua"
        )

        self.assertEqual("zz_bna_defines.lua", define_files[-1].name)
        self.assertEqual(
            set(CONFLICTING_DEFINES), sheep_defines & better_navy_defines
        )
        for name, expected_value in EXPECTED_DEFINES.items():
            self.assertEqual(expected_value, assignments.get(name), name)

    def test_critical_naval_behaviors_are_present(self):
        usa_naval = (ROOT / "common/ai_equipment/USA_naval.txt").read_text()
        germany = (ROOT / "common/ai_strategy/bna_GER.txt").read_text()
        britain = (ROOT / "common/ai_strategy/bna_ENG.txt").read_text()
        japan = (ROOT / "common/ai_strategy/bna_JAP.txt").read_text()
        carrier = (ROOT / "common/units/carrier.txt").read_text()

        self.assertIn("USA_naval_capital_super_heavy = {", usa_naval)
        self.assertIn("GER_increase_submarine_ratio = {", germany)
        self.assertIn("ENG_naval_role_ratios_anti_submarines = {", britain)
        self.assertIn("JAP_attack_usa_fleet = {", japan)
        self.assertIn("supply_consumption = 0.08", carrier)


if __name__ == "__main__":
    unittest.main()
