import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def extract_effect(source: str, effect_name: str) -> str:
    marker = f"{effect_name} = {{"
    start = source.index(marker)
    brace_start = source.index("{", start)
    depth = 0

    for position in range(brace_start, len(source)):
        character = source[position]
        if character == "{":
            depth += 1
        elif character == "}":
            depth -= 1
            if depth == 0:
                return source[start : position + 1]

    raise AssertionError(f"Unclosed scripted effect: {effect_name}")


class StartupDifficultyPresetTest(unittest.TestCase):
    def setUp(self):
        self.difficulty_on_actions = (
            ROOT / "common/on_actions/lsm_on_actions_difficulties.txt"
        ).read_text(encoding="utf-8-sig")
        self.preset_effects = (
            ROOT / "common/scripted_effects/lsm_startup_preset_effects.txt"
        ).read_text(encoding="utf-8-sig")

    def test_each_difficulty_applies_one_deterministic_soviet_preset(self):
        presets = (
            "LSM_apply_sov_very_easy_preset",
            "LSM_apply_sov_easy_preset",
            "LSM_apply_sov_normal_preset",
            "LSM_apply_sov_hard_preset",
            "LSM_apply_sov_very_hard_preset",
        )

        for preset in presets:
            with self.subTest(preset=preset):
                self.assertEqual(
                    1,
                    self.difficulty_on_actions.count(f"{preset} = yes"),
                )

        self.assertNotIn("set_global_flag = random_difficulty", self.difficulty_on_actions)

    def test_soviet_presets_have_exclusive_doctrine_build_and_economy(self):
        expected = {
            "LSM_apply_sov_very_easy_preset": (
                "superior_firepower",
                "superior_firepower_low",
                "civ_3",
            ),
            "LSM_apply_sov_easy_preset": (
                "superior_firepower",
                "superior_firepower_high",
                "civ_2",
            ),
            "LSM_apply_sov_normal_preset": (
                "mass_assault",
                "mass_assault_standard",
                "civ_1",
            ),
            "LSM_apply_sov_hard_preset": (
                "mass_assault",
                "mass_assault_meatwall",
                "mil_1",
            ),
            "LSM_apply_sov_very_hard_preset": (
                "mass_assault",
                "spacemarine",
                "mil_1",
            ),
        }
        build_flags = {
            "superior_firepower_low",
            "superior_firepower_high",
            "mass_assault_standard",
            "mass_assault_meatwall",
            "spacemarine",
        }
        economy_flags = {"civ_1", "civ_2", "civ_3", "mil_1"}

        for preset, (doctrine, build, economy) in expected.items():
            with self.subTest(preset=preset):
                effect = extract_effect(self.preset_effects, preset)
                self.assertIn(f"set_grand_doctrine = {doctrine}", effect)
                self.assertEqual(
                    {build},
                    {
                        flag
                        for flag in build_flags
                        if f"set_country_flag = {flag}" in effect
                    },
                )
                self.assertEqual(
                    {economy},
                    {
                        flag
                        for flag in economy_flags
                        if f"set_country_flag = {flag}" in effect
                    },
                )

    def test_startup_configuration_events_are_not_dispatched_by_on_actions(self):
        on_actions = "\n".join(
            path.read_text(encoding="utf-8-sig")
            for path in (ROOT / "common/on_actions").glob("*.txt")
        )
        configuration_event = re.compile(
            r"country_event\s*=\s*\{\s*id\s*=\s*"
            r"LSM_startup\.(?:1|10|76|77|78|79|80|81|82|83|84|85|100)\b"
        )

        self.assertIsNone(configuration_event.search(on_actions))


if __name__ == "__main__":
    unittest.main()
