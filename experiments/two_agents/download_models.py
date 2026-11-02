"""Pin and download only model data into the project's ignored directory."""
import json
from pathlib import Path
from huggingface_hub import snapshot_download

ROOT = Path(__file__).resolve().parents[2]
destination = ROOT / "PrivateAssets/AgentLab/models"
destination.mkdir(parents=True, exist_ok=True)
manifest = []
locked = json.loads(Path(__file__).with_name("models-lock.json").read_text())
for entry in locked:
    size, repo, revision = entry["size"], entry["repo"], entry["revision"]
    print(json.dumps({"download": repo, "revision": revision}), flush=True)
    path = destination / size
    snapshot_download(repo_id=repo, revision=revision, token=False, local_dir=path,
                      allow_patterns=["*.json", "*.safetensors", "*.jinja", "*.txt", "*.md"],
                      max_workers=2)
    manifest.append({"size": size, "repo": repo, "revision": revision,
                     "path": str(path.relative_to(ROOT)), "license": "Apache-2.0"})
    (destination / "manifest.json").write_text(json.dumps(manifest, indent=2)+"\n")
    print(json.dumps({"ready": size}), flush=True)
