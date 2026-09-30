#!/usr/bin/env python3
"""Run the representative Codex benchmark harness. No live calls unless --live is passed."""
import argparse, json, subprocess, time
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
def main():
 p=argparse.ArgumentParser(); p.add_argument("--live",action="store_true"); p.add_argument("--codex",default="codex"); a=p.parse_args()
 tasks=json.loads((ROOT/"benchmarks/tasks.json").read_text())["tasks"]
 if not a.live:
  print(json.dumps({"mode":"dry-run","tasks":[t["id"] for t in tasks]},indent=2)); return
 results=[]
 for t in tasks:
  started=time.monotonic()
  cp=subprocess.run([a.codex,"exec",t["prompt"]],cwd=ROOT,text=True,capture_output=True)
  results.append({"id":t["id"],"exit_code":cp.returncode,"elapsed_seconds":round(time.monotonic()-started,3),"output_bytes":len(cp.stdout.encode())})
 print(json.dumps({"mode":"live","results":results},indent=2))
 raise SystemExit(1 if any(r["exit_code"] for r in results) else 0)
if __name__=="__main__": main()
