#!/usr/bin/env python3
"""Detect OpenAI GPT model IDs from official docs and propose conservative routing changes."""
import argparse, json, re, urllib.request
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
REG=ROOT/"model-watch/models.json"
PAT=re.compile(r"gpt-\d+(?:\.\d+)?-(?:sol|luna|astra)\b",re.I)

def fetch(url):
 req=urllib.request.Request(url,headers={"User-Agent":"codex-orchestrator-model-watch/1"})
 with urllib.request.urlopen(req,timeout=30) as r: return r.read().decode("utf-8","replace")

def version(model):
 m=re.match(r"gpt-(\d+)(?:\.(\d+))?-(\w+)",model)
 return (int(m.group(1)),int(m.group(2) or 0)) if m else (0,0)

def main():
 p=argparse.ArgumentParser(); p.add_argument("--offline",action="store_true"); p.add_argument("--write-report",default="model-watch/report.md"); a=p.parse_args()
 reg=json.loads(REG.read_text()); known=set(reg["models"]); found=set(known)
 if not a.offline:
  for url in reg["sources"]: found.update(x.lower() for x in PAT.findall(fetch(url)))
 new=sorted(found-known)
 lines=["# Model watch report","",f"Known models: {', '.join(sorted(known))}.",f"New official model IDs: {', '.join(new) if new else 'none'}.",""]
 recommendations=[]
 for model in new:
  tier=model.rsplit("-",1)[-1]
  current=[m for m in known if m.endswith("-"+tier)]
  if current and version(model)>max(map(version,current)):
   roles=[r for r,v in reg["routing"].items() if v[0] in current]
   recommendations.append((model,roles))
 if recommendations:
  lines+=["## Candidate routing updates",""]
  for model,roles in recommendations: lines.append(f"- Consider `{model}` for: {', '.join(roles)}. Validate supported efforts and run the benchmark before changing routing.")
 else: lines+=["## Candidate routing updates","","No automatic routing change is proposed."]
 lines+=["","The watcher never changes the active model matrix or merges a PR automatically. Human review is required."]
 out=ROOT/a.write_report; out.parent.mkdir(parents=True,exist_ok=True); out.write_text("\n".join(lines)+"\n")
 print(json.dumps({"new_models":new,"recommendations":recommendations}))
if __name__=="__main__": main()
