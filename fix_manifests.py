#!/usr/bin/env python3
"""Fix corrupt Ollama manifests where config blob points to model GGUF instead of JSON config."""
import json, hashlib, os, struct, sys

USB_ROOT = "F:\\"
MANIFESTS_DIR = os.path.join(USB_ROOT, "ollama", "data", "manifests", "registry.ollama.ai", "library")
BLOBS_DIR = os.path.join(USB_ROOT, "ollama", "data", "blobs")
MODELS_DIR = os.path.join(USB_ROOT, "models")
IMPORT_LOG = os.path.join(USB_ROOT, "models", "manifest_fix.log")

def log(msg):
    with open(IMPORT_LOG, "a", encoding="utf-8") as f:
        f.write(f"{msg}\n")
    print(msg)

def extract_gguf_architecture(gguf_path):
    """Read GGUF header to extract model architecture."""
    try:
        with open(gguf_path, "rb") as f:
            magic = f.read(4)
            if magic != b"GGUF":
                return None
            version = struct.unpack("<I", f.read(4))[0]
            f.read(8)  # tensor_count
            kv_count = struct.unpack("<Q", f.read(8))[0]

            for _ in range(min(kv_count, 100)):
                key_len = struct.unpack("<Q", f.read(8))[0]
                key = f.read(key_len).decode("utf-8", errors="replace")
                val_type = struct.unpack("<I", f.read(4))[0]
                if key == "general.architecture":
                    if val_type == 8:  # string type
                        str_len = struct.unpack("<Q", f.read(8))[0]
                        val = f.read(str_len).decode("utf-8", errors="replace")
                        return val
                    break
                else:
                    skip_gguf_value(f, val_type)
            return None
    except Exception as e:
        log(f"  [WARN] Could not read GGUF header from {gguf_path}: {e}")
        return None

def skip_gguf_value(f, val_type):
    """Skip a GGUF metadata value."""
    if val_type == 0:  # uint8
        f.read(1)
    elif val_type == 1:  # int8
        f.read(1)
    elif val_type == 2:  # uint16
        f.read(2)
    elif val_type == 3:  # int16
        f.read(2)
    elif val_type == 4:  # uint32
        f.read(4)
    elif val_type == 5:  # int32
        f.read(4)
    elif val_type == 6:  # float32
        f.read(4)
    elif val_type == 7:  # bool
        f.read(1)
    elif val_type == 8:  # string
        str_len = struct.unpack("<Q", f.read(8))[0]
        f.read(str_len)
    elif val_type == 10:  # float64
        f.read(8)
    elif val_type == 11:  # uint64
        f.read(8)
    elif val_type == 12:  # int64
        f.read(8)
    elif val_type == 34:  # array
        arr_type = struct.unpack("<I", f.read(4))[0]
        arr_len = struct.unpack("<Q", f.read(8))[0]
        for _ in range(arr_len):
            skip_gguf_value(f, arr_type)
    else:
        log(f"  [WARN] Unknown GGUF type {val_type}, skipping 1024 bytes")
        f.read(1024)

def find_gguf_for_model(model_name):
    """Find the GGUF file in models dir matching this model name."""
    for root, dirs, files in os.walk(MODELS_DIR):
        for f in files:
            if f.endswith(".gguf"):
                if model_name in root.replace("\\", "/").lower() or model_name in f.lower():
                    return os.path.join(root, f)
    return None

def main():
    fixed = 0
    skipped = 0
    errors = 0

    if not os.path.isdir(MANIFESTS_DIR):
        log(f"ERROR: {MANIFESTS_DIR} not found")
        sys.exit(1)

    for model_dir in sorted(os.listdir(MANIFESTS_DIR)):
        manifest_path = os.path.join(MANIFESTS_DIR, model_dir, "latest")
        if not os.path.isfile(manifest_path):
            continue

        try:
            with open(manifest_path, "r", encoding="utf-8") as f:
                manifest = json.load(f)

            config_blob = manifest.get("config", {})
            layers = manifest.get("layers", [])

            if not layers or not config_blob:
                log(f"  [SKIP] {model_dir}: no layers or config")
                skipped += 1
                continue

            model_layer = layers[0]
            config_digest = config_blob.get("digest", "")
            model_digest = model_layer.get("digest", "")

            # Check if config == model blob (corrupt)
            if config_digest == model_digest:
                # Find GGUF and extract architecture
                gguf_path = find_gguf_for_model(model_dir)
                arch = "llama"  # default
                if gguf_path and os.path.isfile(gguf_path):
                    extracted = extract_gguf_architecture(gguf_path)
                    if extracted:
                        arch = extracted
                        log(f"  [INFO] {model_dir}: detected arch={arch} from {os.path.basename(gguf_path)}")

                # Get all layer digests for diff_ids
                diff_ids = []
                for layer in layers:
                    diff_ids.append(layer.get("digest", ""))

                # Guess model size label from layer 0 size
                model_size_bytes = model_layer.get("size", 0)
                if model_size_bytes > 20_000_000_000:
                    size_label = "B"
                elif model_size_bytes > 15_000_000_000:
                    size_label = "B"
                elif model_size_bytes > 10_000_000_000:
                    size_label = "B"
                else:
                    size_label = ""

                # Get file_type from model_name
                ft = "Q4_K_M"
                parts = model_dir.lower().split("-")
                for p in parts:
                    if p.startswith("q") and ("_" in p or len(p) > 1):
                        ft = p.upper()
                    elif p.startswith("iq"):
                        ft = p.upper()

                # Build config JSON (Docker container config)
                config_data = {
                    "model_format": "gguf",
                    "model_family": arch,
                    "model_families": [arch],
                    "model_type": size_label if size_label else "unknown",
                    "file_type": ft,
                    "architecture": "amd64",
                    "os": "linux",
                    "rootfs": {
                        "type": "layers",
                        "diff_ids": diff_ids
                    }
                }

                config_json = json.dumps(config_data, separators=(",", ":"))
                config_sha256 = hashlib.sha256(config_json.encode("utf-8")).hexdigest()
                config_blob_path = os.path.join(BLOBS_DIR, f"sha256-{config_sha256}")

                # Write config blob
                with open(config_blob_path, "wb") as f:
                    f.write(config_json.encode("utf-8"))

                # Update manifest
                manifest["config"] = {
                    "mediaType": "application/vnd.docker.container.image.v1+json",
                    "digest": f"sha256:{config_sha256}",
                    "size": len(config_json)
                }

                with open(manifest_path, "w", encoding="utf-8") as f:
                    json.dump(manifest, f, indent=4)

                log(f"  [FIXED] {model_dir}: config now points to sha256:{config_sha256} ({len(config_json)} bytes)")
                fixed += 1
            else:
                log(f"  [OK] {model_dir}: config is already correct")
                skipped += 1

        except Exception as e:
            log(f"  [ERROR] {model_dir}: {e}")
            errors += 1

    log(f"\nSummary: {fixed} fixed, {skipped} skipped, {errors} errors")

if __name__ == "__main__":
    main()
