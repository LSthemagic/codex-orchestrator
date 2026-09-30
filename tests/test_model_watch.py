import json, subprocess, sys, unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
class ModelWatchTests(unittest.TestCase):
 def test_registry_routing_is_supported(self):
  r=json.loads((ROOT/"model-watch/models.json").read_text())
  for role,(model,effort) in r["routing"].items():
   self.assertIn(model,r["models"],role); self.assertIn(effort,r["models"][model]["efforts"],role)
 def test_offline_watch_is_deterministic(self):
  cp=subprocess.run([sys.executable,str(ROOT/"scripts/model_watch.py"),"--offline"],cwd=ROOT,text=True,capture_output=True)
  self.assertEqual(cp.returncode,0,cp.stderr); self.assertIn('"new_models": []',cp.stdout)
 def test_benchmark_defaults_to_dry_run(self):
  cp=subprocess.run([sys.executable,str(ROOT/"scripts/benchmark_models.py")],cwd=ROOT,text=True,capture_output=True)
  self.assertEqual(cp.returncode,0,cp.stderr); self.assertIn('"mode": "dry-run"',cp.stdout)
if __name__=="__main__": unittest.main()
