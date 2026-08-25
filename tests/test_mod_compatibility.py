import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class ModCompatibilityTest(unittest.TestCase):
    def test_mod_does_not_override_national_focus_trees(self):
        focus_directory = ROOT / "common/national_focus"

        focus_files = (
            list(focus_directory.rglob("*.txt")) if focus_directory.exists() else []
        )

        self.assertEqual(
            [],
            focus_files,
            "Non Lag AI must leave national focus trees to the base game "
            "or companion mods",
        )

    def test_mod_does_not_replace_game_directories(self):
        descriptor = (ROOT / "descriptor.mod").read_text()

        self.assertNotIn("replace_path", descriptor)


if __name__ == "__main__":
    unittest.main()
