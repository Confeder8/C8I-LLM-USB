"""
Portable HuggingFace Model Downloader
Usage: python download_model.py <repo_id> <filename> <local_dir>
"""
import sys, os, time

def main():
    if len(sys.argv) < 4:
        print("Usage: download_model.py <repo_id> <filename> <local_dir>", file=sys.stderr)
        sys.exit(1)

    repo_id = sys.argv[1]
    filename = sys.argv[2]
    local_dir = sys.argv[3]

    os.environ.setdefault("HF_HOME", os.path.join(os.path.dirname(local_dir), ".hf_cache"))
    os.environ.setdefault("HF_HUB_DISABLE_TELEMETRY", "1")

    from huggingface_hub import hf_hub_download
    from huggingface_hub.utils import HfHubHTTPError
    import tqdm as _tqdm

    class ProgressDownloader:
        def __init__(self):
            self.pbar = None
            self.start_time = time.time()

        def __call__(self, bytes_downloaded, total_size):
            if self.pbar is None:
                if total_size and total_size > 0:
                    self.pbar = _tqdm.tqdm(total=total_size, unit="B", unit_scale=True, desc=filename, ncols=80, file=sys.stderr)
                else:
                    print(f"Downloading {filename}...", file=sys.stderr)
            if self.pbar and total_size and total_size > 0:
                self.pbar.n = bytes_downloaded
                self.pbar.refresh()

        def close(self):
            if self.pbar:
                self.pbar.close()

    progress = ProgressDownloader()
    try:
        path = hf_hub_download(
            repo_id=repo_id,
            filename=filename,
            local_dir=local_dir,
            tqdm_class=None,
        )
        progress.close()
        file_size = os.path.getsize(path) if os.path.exists(path) else 0
        elapsed = time.time() - progress.start_time
        print(f"OK|{path}|{file_size}|{elapsed:.1f}")
    except Exception as e:
        progress.close()
        print(f"ERR|{e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
