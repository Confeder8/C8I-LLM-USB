"""
HuggingFace Model Download Helper - LM Studio Directory Structure
Usage: hf_cli.py <command> [args...]
  hf_cli.py download <repo_id> <filename> <local_dir>
  hf_cli.py search <query>
  hf_cli.py list <dir>
  hf_cli.py organize <dir> - Move flat GGUFs into LM Studio structure
"""
import sys, os

os.environ["HF_HUB_DISABLE_PROGRESS_BARS"] = "1"
os.environ.setdefault("HF_HUB_DISABLE_TELEMETRY", "1")

class _PlainProgress:
    def __init__(self, *a, **kw):
        self.total = kw.get("total", None) or 0
        self.n = 0
        self._last_pct = -1
    def update(self, n):
        self.n += n
        if self.total > 0:
            pct = int(self.n * 100 / self.total)
            if pct != self._last_pct:
                self._last_pct = pct
                mb = self.n / (1024*1024)
                tb = self.total / (1024*1024)
                print(f"\r  {mb:.0f} / {tb:.0f} MB  ({pct}%)", end="", flush=True)
    def close(self):
        print()
    def set_description(self, *a, **kw): pass
    def refresh(self): pass

def _guess_publisher_from_filename(filename):
    """Try to guess publisher name from GGUF filename patterns."""
    base = filename.replace(".gguf", "")
    # Common patterns: ModelName-quant.gguf, user__Model-quant.gguf
    # Try to split on first dash if it looks like Publisher-Model
    parts = base.split("-", 1)
    if len(parts) > 1 and len(parts[0]) > 2:
        return parts[0]
    return None

def _guess_publisher_from_hf_repo(repo_id):
    """Extract publisher from HuggingFace repo ID (user/repo)."""
    parts = repo_id.split("/")
    if len(parts) >= 1:
        return parts[0]
    return None

def organize_models(models_dir):
    """Move flat GGUF files into LM Studio directory structure.
    Structure: models/<Publisher>/<ModelName>/<file>.gguf
    Reads HF cache metadata if available to determine publisher.
    """
    import json
    cache_dir = os.path.join(models_dir, ".hf_cache")

    # Build mapping from filename -> HF repo ID from cache
    filename_to_repo = {}
    if os.path.isdir(cache_dir):
        for root, dirs, files in os.walk(cache_dir):
            for f in files:
                if f.endswith(".json"):
                    try:
                        fp = os.path.join(root, f)
                        with open(fp, "r", encoding="utf-8") as fh:
                            data = json.load(fh)
                        if "repo_id" in data and "filename" in data:
                            filename_to_repo[data["filename"]] = data["repo_id"]
                    except Exception:
                        pass

    moved = 0
    skipped = 0
    for root, dirs, files in os.walk(models_dir):
        # Only process files in the root models dir (not already nested)
        if root != models_dir:
            continue
        for f in sorted(files):
            if not f.endswith(".gguf"):
                continue
            src = os.path.join(root, f)

            # Determine publisher from HF cache or filename
            repo_id = filename_to_repo.get(f)
            if repo_id:
                publisher = _guess_publisher_from_hf_repo(repo_id)
            else:
                publisher = _guess_publisher_from_filename(f)

            if not publisher:
                publisher = "local"

            # Model name = filename without extension
            model_name = f.replace(".gguf", "")

            # Target: models/<publisher>/<model_name>/<file>.gguf
            target_dir = os.path.join(models_dir, publisher, model_name)
            target_path = os.path.join(target_dir, f)

            if os.path.exists(target_path):
                print(f"  SKIP (exists): {publisher}/{model_name}/{f}")
                skipped += 1
                continue

            os.makedirs(target_dir, exist_ok=True)
            os.rename(src, target_path)
            print(f"  MOVED: {f} -> {publisher}/{model_name}/")
            moved += 1

    print(f"\n  Organized: {moved} moved, {skipped} skipped")
    return moved

def main():
    if len(sys.argv) < 2:
        print("Usage: hf_cli.py <download|search|list|organize> [args]")
        sys.exit(1)

    cmd = sys.argv[1]

    if cmd == "download":
        if len(sys.argv) < 5:
            print("Usage: hf_cli.py download <repo_id> <filename> <local_dir>")
            sys.exit(1)
        repo_id = sys.argv[2]
        filename = sys.argv[3]
        local_dir = sys.argv[4]

        os.environ.setdefault("HF_HOME", os.path.join(local_dir, ".hf_cache"))

        # Determine publisher from repo ID -> create LM Studio structure
        publisher = _guess_publisher_from_hf_repo(repo_id)
        model_name = filename.replace(".gguf", "")
        target_dir = os.path.join(local_dir, publisher, model_name) if publisher else local_dir
        os.makedirs(target_dir, exist_ok=True)

        try:
            from huggingface_hub import hf_hub_download
            import time
            start = time.time()
            path = hf_hub_download(repo_id=repo_id, filename=filename, local_dir=target_dir, tqdm_class=_PlainProgress)
            elapsed = time.time() - start
            size_mb = os.path.getsize(path) / (1024 * 1024)

            # Move from HF cache nested layout to flat model dir if needed
            actual_dir = os.path.dirname(path)
            if actual_dir != target_dir:
                import shutil
                dest = os.path.join(target_dir, filename)
                if not os.path.exists(dest):
                    shutil.move(path, dest)
                    path = dest

            print(f"OK|{path}|{size_mb:.1f}|{elapsed:.1f}")
        except Exception as e:
            print(f"FAIL|{e}")
            sys.exit(1)

    elif cmd == "search":
        query = " ".join(sys.argv[2:]) if len(sys.argv) > 2 else ""
        if not query:
            print("Usage: hf_cli.py search <query>")
            sys.exit(1)
        try:
            from huggingface_hub import HfApi
            api = HfApi()
            results = api.list_models(search=f"{query} GGUF", sort="downloads", direction=-1, limit=15)
            for m in results:
                dl = getattr(m, "downloads", 0) or 0
                print(f"  {m.id}  ({dl:,} downloads)")
        except Exception as e:
            print(f"Search failed: {e}")
            sys.exit(1)

    elif cmd == "list":
        target = sys.argv[2] if len(sys.argv) > 2 else "."
        count = 0
        for root, dirs, files in os.walk(target):
            for f in sorted(files):
                if f.endswith(".gguf"):
                    full_path = os.path.join(root, f)
                    rel_path = os.path.relpath(full_path, target)
                    size_gb = os.path.getsize(full_path) / (1024**3)
                    count += 1
                    print(f"  [{count}] {rel_path}  (~{size_gb:.1f} GB)")
        if count == 0:
            print("  No GGUF models found.")
        else:
            print(f"  Total: {count} model(s)")

    elif cmd == "organize":
        target = sys.argv[2] if len(sys.argv) > 2 else "."
        if not os.path.isdir(target):
            print(f"  Error: {target} is not a directory")
            sys.exit(1)
        organize_models(target)

    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)

if __name__ == "__main__":
    main()
