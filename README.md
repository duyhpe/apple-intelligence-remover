## Apple Intelligence Remover

**Apple Intelligence Remover** is a small interactive shell script that helps you:

- **Check** whether Apple Intelligence is enabled on your Mac.
- **Scan** for on‑disk AI model and cache directories used by Apple Intelligence / Siri.
- **Disable** Apple Intelligence via its preference flags.
- **Remove** large model/cache directories (where possible).
- **Generate** a separate recovery script that you can run from Recovery OS to remove models from the `Data` volume.

This tool is intended for advanced users who understand the risks of deleting system assets.  
It does **not** bypass macOS security features like SIP; protected files will simply fail to delete.

### How it works

The main script is `main.sh`. Internally it is structured into a few functions that the menu calls:

- **Model paths it looks for**
  - It scans a fixed list of known model and cache directories:
    - `/System/Library/AssetsV2/com_apple_MobileAsset_UAF_FM_GenerativeModels`
    - `/System/Library/AssetsV2/com_apple_MobileAsset_UAF_FM_Visual`
    - `/Library/Apple/System/Library/AssetsV2/com_apple_MobileAsset_UAF_FM_GenerativeModels`
    - `/Library/Apple/System/Library/AssetsV2/com_apple_MobileAsset_UAF_FM_Visual`
    - `/Volumes/Data/System/Library/AssetsV2/com_apple_MobileAsset_UAF_FM_GenerativeModels`
    - `/Volumes/Data/System/Library/AssetsV2/com_apple_MobileAsset_UAF_FM_Visual`
  - It also checks cache locations:
    - `$HOME/Library/Caches/com.apple.intelligence`
    - `$HOME/Library/Caches/com.apple.siri`
    - `/private/var/db/MobileAsset/AssetsV2/com_apple_MobileAsset_UAF_FM_GenerativeModels`
    - `/private/var/db/MobileAsset/AssetsV2/com_apple_MobileAsset_UAF_FM_Visual`

- **`check_status`**
  - Reads the `AppleIntelligenceEnabled` flag from `com.apple.Siri` using:
    - `defaults read com.apple.Siri AppleIntelligenceEnabled`
  - Displays whether Apple Intelligence appears **ENABLED** or **DISABLED**.

- **`scan_models`**
  - Iterates through the directories above.
  - For each existing directory it:
    - Adds the path to an in‑memory list (`FOUND_PATHS`).
    - Uses `du -sk` to get its size in KiB.
    - Accumulates the total size and prints human‑readable per‑directory sizes with `du -sh`.
  - At the end it prints the **total combined size** of all found directories in GB.

- **`disable_ai`**
  - Writes two preference keys under `com.apple.Siri`:
    - `AppleIntelligenceEnabled = false`
    - `LLMEnable = false`
  - This attempts to turn off Apple Intelligence features at the preference level.

- **`remove_models`**
  - Operates on the `FOUND_PATHS` list from the last `scan_models` run.
  - Shows the directories that would be removed and asks for confirmation:
    - `Continue? (y/N):`
  - For each path, runs:
    - `sudo rm -rf "<path>"`
  - If deletion fails (commonly due to SIP or permissions), it reports that the directory could not be removed.

- **`generate_recovery_script`**
  - Creates `remove_apple_intelligence.sh` on your Desktop.
  - That script:
    - Tries to mount `Macintosh HD - Data` (or `Data`).
    - Runs `rm -rf` on the `GenerativeModels` and `Visual` directories under `/Volumes/Data/System/Library/AssetsV2/...`.
  - The script is marked executable (`chmod +x`).
  - Intended usage: boot into Recovery OS, open Terminal, and run the generated script to remove data from the `Data` volume where SIP restrictions may differ.

- **Interactive menu loop**
  - The bottom of `main.sh` contains a loop:
    - Shows a numbered menu.
    - Reads your choice.
    - Calls the corresponding function (or exits) and then shows the menu again.

### Requirements

- macOS with Apple Intelligence / related assets present.
- A user account with **administrator** privileges to run `sudo rm -rf` when deleting model directories.
- A Terminal application (e.g., built‑in Terminal or iTerm2).

### Usage

1. **Clone or download** this repository.
2. **Open Terminal** and navigate to the project directory:

   ```bash
   cd /path/to/apple-intelligence-remover
   ```

3. **Make the script executable** (only needed once):

   ```bash
   chmod +x main.sh
   ```

4. **Run the script**:

   ```bash
   ./main.sh
   ```

5. **Use the menu:**
   - `1` – Check Apple Intelligence status.
   - `2` – Scan for AI model/cache directories and show their sizes.
   - `3` – Disable Apple Intelligence via `defaults`.
   - `4` – Remove the found model/cache directories (after explicit confirmation; may prompt for `sudo` password).
   - `5` – Generate a recovery script on your Desktop for use from Recovery OS.
   - `6` – Exit.

### Safety, limitations, and caveats

- **System Integrity Protection (SIP):**
  - The script does **not** disable or bypass SIP.
  - Any SIP‑protected path will fail to delete, and the script will report that it could not remove the directory.

- **Use at your own risk:**
  - Deleting system assets may affect Apple Intelligence, Siri, or other system features.
  - There is no automatic restore of deleted model/cache files.
  - You may need to reinstall system components or macOS to fully restore them.

- **Version assumptions:**
  - The script relies on specific bundle IDs, preference keys, and directory paths that may change between macOS releases.
  - If Apple changes these paths/keys, some options may stop working or only partially work.

### Japanese README

For a Japanese explanation of this project and its behavior, see the separate file `README.ja.md`.
