import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WORKSHOP_ID = "3789983756"


class WorkshopToolingTest(unittest.TestCase):
    def test_descriptor_and_initial_workshop_state(self):
        descriptor = (ROOT / "descriptor.mod").read_text()
        item = (ROOT / "steam/workshop.item").read_text().strip()
        template = (ROOT / "steam/workshop.vdf").read_text()

        self.assertIn('version="0.1.0"', descriptor)
        self.assertIn('name="Non Lag AI"', descriptor)
        self.assertIn('supported_version="1.17.3.0"', descriptor)
        self.assertIn('"Balance"', descriptor)
        self.assertEqual(f"publishedfileid={WORKSHOP_ID}", item)
        self.assertIn(f'"publishedfileid"\t"{WORKSHOP_ID}"', template)
        self.assertIn('"visibility"\t\t"2"', template)
        self.assertIn('"title"\t\t\t\t"Non Lag AI"', template)

    def test_thumbnail_is_a_valid_png(self):
        thumbnail = (ROOT / "Thumbnail.png").read_bytes()

        self.assertTrue(thumbnail.startswith(b"\x89PNG\r\n\x1a\n"))
        self.assertGreater(len(thumbnail), 0)

    def test_shell_scripts_are_valid_and_guard_new_items(self):
        for script_name in ("export-workshop.sh", "upload-workshop.sh"):
            result = subprocess.run(
                ["bash", "-n", str(ROOT / script_name)],
                check=False,
                capture_output=True,
                text=True,
            )
            self.assertEqual(0, result.returncode, result.stderr)

        with tempfile.TemporaryDirectory() as temporary_directory:
            temporary = Path(temporary_directory)
            isolated_script = temporary / "upload-workshop.sh"
            isolated_script.write_bytes((ROOT / "upload-workshop.sh").read_bytes())
            isolated_script.chmod(0o755)
            (temporary / "steam").mkdir()
            (temporary / "steam/workshop.item").write_text("publishedfileid=0\n")

            result = subprocess.run(
                [str(isolated_script), "--skip-export", "test-user"],
                check=False,
                capture_output=True,
                text=True,
            )
            self.assertNotEqual(0, result.returncode)
            self.assertIn("nenhum PublishedFileId registrado", result.stderr)

    def test_export_creates_a_clean_mod_build(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            temporary = Path(temporary_directory)
            build = temporary / "non-lag-ai-build"
            result = subprocess.run(
                [str(ROOT / "export-workshop.sh"), "--out", str(build)],
                check=False,
                capture_output=True,
                text=True,
            )

            self.assertEqual(0, result.returncode, result.stderr)
            self.assertTrue((build / "descriptor.mod").is_file())
            self.assertTrue((build / "Thumbnail.png").is_file())
            self.assertTrue((build / "common").is_dir())
            self.assertFalse((build / ".git").exists())
            self.assertFalse((build / "docs").exists())
            self.assertFalse((build / "tests").exists())
            self.assertFalse((build / "steam").exists())
            self.assertFalse((build / "upload-workshop.sh").exists())

            launcher = temporary / "non-lag-ai-build.mod"
            launcher_text = launcher.read_text()
            self.assertIn('name="Non Lag AI [build]"', launcher_text)
            self.assertIn('"Balance"', launcher_text)
            self.assertIn(f'path="{build}"', launcher_text)

    def test_cross_platform_scripts_use_project_identity(self):
        paths = (
            ROOT / "export-workshop.sh",
            ROOT / "export-workshop.ps1",
            ROOT / "upload-workshop.sh",
            ROOT / "upload-workshop.ps1",
        )
        contents = "\n".join(path.read_text() for path in paths)

        self.assertNotIn("non-lag-historical", contents)
        self.assertNotIn("No Lag Historical", contents)
        self.assertIn("non-lag-ai-build", contents)
        self.assertIn("Non Lag AI", contents)
        self.assertIn("NewItem", (ROOT / "upload-workshop.ps1").read_text())


if __name__ == "__main__":
    unittest.main()
