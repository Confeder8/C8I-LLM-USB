"""
Organize flat GGUF files into LM Studio directory structure.
Structure: models/<Publisher>/<ModelName>/<file>.gguf

Reads HuggingFace cache metadata to determine publisher from original repo.
Also copies existing Modelfiles into the model directories.

Usage: python organize_models.py [models_dir]
  Default models_dir = same directory as this script / models
"""
import sys, os, json, shutil

def get_publisher_from_hf_cache(cache_dir, filename):
    """Look up publisher from HF download cache metadata."""
    if not os.path.isdir(cache_dir):
        return None
    for root, dirs, files in os.walk(cache_dir):
        for f in files:
            if f.endswith(".json"):
                try:
                    fp = os.path.join(root, f)
                    with open(fp, "r", encoding="utf-8") as fh:
                        data = json.load(fh)
                    if data.get("filename") == filename and "repo_id" in data:
                        parts = data["repo_id"].split("/")
                        if len(parts) >= 1:
                            return parts[0]
                except Exception:
                    pass
    return None

def get_publisher_from_filename(filename):
    """Guess publisher from GGUF filename patterns."""
    base = filename.replace(".gguf", "")
    parts = base.split("-", 1)
    if len(parts) > 1 and len(parts[0]) > 2:
        return parts[0]
    return None

def organize(models_dir):
    """Move flat GGUFs into LM Studio structure."""
    cache_dir = os.path.join(models_dir, ".hf_cache")
    moved = 0
    skipped = 0

    # Find all GGUF files in root only (not already nested)
    for f in sorted(os.listdir(models_dir)):
        if not f.endswith(".gguf"):
            continue
        src = os.path.join(models_dir, f)
        if not os.path.isfile(src):
            continue

        # Determine publisher
        publisher = get_publisher_from_hf_cache(cache_dir, f)
        if not publisher:
            publisher = get_publisher_from_filename(f)
        if not publisher:
            publisher = "local"

        model_name = f.replace(".gguf", "")
        target_dir = os.path.join(models_dir, publisher, model_name)
        target_path = os.path.join(target_dir, f)

        if os.path.exists(target_path):
            print(f"  SKIP (exists): {publisher}/{model_name}/{f}")
            skipped += 1
            # Remove flat copy if nested exists
            os.remove(src)
            continue

        os.makedirs(target_dir, exist_ok=True)
        shutil.move(src, target_path)
        print(f"  MOVED: {f} -> {publisher}/{model_name}/")
        moved += 1

        # Also move matching Modelfile if it exists in root
        modelfile_name = f"Modelfile-{model_name}"
        modelfile_path = os.path.join(models_dir, modelfile_name)
        if os.path.exists(modelfile_path):
            dest_modelfile = os.path.join(target_dir, "Modelfile")
            if not os.path.exists(dest_modelfile):
                shutil.move(modelfile_path, dest_modelfile)
                print(f"    + Modelfile copied")

    print(f"\n  Result: {moved} moved, {skipped} skipped")
    return moved

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    models_dir = sys.argv[1] if len(sys.argv) > 1 else os.path.join(script_dir, "models")

    if not os.path.isdir(models_dir):
        print(f"  Error: {models_dir} is not a directory")
        sys.exit(1)

    print(f"  Organizing GGUF files in: {models_dir}")
    print(f"  Structure: models/<Publisher>/<ModelName>/<file>.gguf")
    print()
    organize(models_dir)

if __name__ == "__main__":
    main()
