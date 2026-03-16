## Apple Intelligence Remover について

**Apple Intelligence Remover** は、macOS 上の Apple Intelligence 関連コンポーネントに対して、次のような操作を行うための対話型シェルスクリプトです。

- **有効/無効状態の確認**：Apple Intelligence が有効かどうかを確認します。
- **モデル/キャッシュのスキャン**：Apple Intelligence や Siri が利用する可能性のあるモデルファイルおよびキャッシュディレクトリを検索します。
- **Apple Intelligence の無効化**：設定フラグを書き換えて Apple Intelligence を無効化しようとします。
- **モデル/キャッシュの削除**：見つかったモデルおよびキャッシュディレクトリを削除しようとします（可能な範囲で）。
- **リカバリ用スクリプトの生成**：Recovery OS から実行することを想定した削除用スクリプトを Desktop に生成します。

このツールは、**システムファイルの削除に伴うリスクを理解している上級ユーザー向け** です。  
macOS の System Integrity Protection (SIP) を無効化・回避する機能はありません。SIP により保護されている領域は削除に失敗し、その旨を表示するだけです。

### 仕組み

メインとなるスクリプトは `main.sh` です。内部では、メニューから呼び出される複数の関数に分割されています。

- **スキャン対象のモデル/キャッシュディレクトリ**
  - 以下のような既知のモデル/キャッシュ格納パスを固定でスキャンします。
    - `/System/Library/AssetsV2/com_apple_MobileAsset_UAF_FM_GenerativeModels`
    - `/System/Library/AssetsV2/com_apple_MobileAsset_UAF_FM_Visual`
    - `/Library/Apple/System/Library/AssetsV2/com_apple_MobileAsset_UAF_FM_GenerativeModels`
    - `/Library/Apple/System/Library/AssetsV2/com_apple_MobileAsset_UAF_FM_Visual`
    - `/Volumes/Data/System/Library/AssetsV2/com_apple_MobileAsset_UAF_FM_GenerativeModels`
    - `/Volumes/Data/System/Library/AssetsV2/com_apple_MobileAsset_UAF_FM_Visual`
  - さらに、キャッシュ用のパスも確認します。
    - `$HOME/Library/Caches/com.apple.intelligence`
    - `$HOME/Library/Caches/com.apple.siri`
    - `/private/var/db/MobileAsset/AssetsV2/com_apple_MobileAsset_UAF_FM_GenerativeModels`
    - `/private/var/db/MobileAsset/AssetsV2/com_apple_MobileAsset_UAF_FM_Visual`

- **`check_status` 関数**
  - `defaults read com.apple.Siri AppleIntelligenceEnabled` を実行し、設定値を読み取ります。
  - その結果から、Apple Intelligence が **有効 (ENABLED)** か **無効 (DISABLED)** かを表示します。

- **`scan_models` 関数**
  - 上記のパスを順番に調べ、存在するディレクトリをリストアップします。
  - 各ディレクトリに対して:
    - パスをメモリ上の配列 (`FOUND_PATHS`) に追加します。
    - `du -sk` でサイズ (KiB) を取得し、合計サイズに加算します。
    - `du -sh` で人間が読みやすい形式のサイズも表示します。
  - 最後に、見つかった全ディレクトリの合計サイズを GB 単位で表示します。

- **`disable_ai` 関数**
  - `com.apple.Siri` ドメインに対して以下のキーを書き込みます。
    - `AppleIntelligenceEnabled = false`
    - `LLMEnable = false`
  - これにより、設定レベルで Apple Intelligence の機能を無効化しようとします。

- **`remove_models` 関数**
  - 直近の `scan_models` で見つかった `FOUND_PATHS` を対象に削除処理を行います。
  - 削除対象のディレクトリ一覧を表示した上で、次のように確認を行います。
    - `Continue? (y/N):`
  - ユーザーが `y` を入力した場合、各ディレクトリに対して:
    - `sudo rm -rf "<path>"` を実行します。
  - SIP や権限の問題などで削除に失敗した場合は、その旨を表示します。

- **`generate_recovery_script` 関数**
  - デスクトップに `remove_apple_intelligence.sh` というスクリプトファイルを生成します。
  - そのスクリプトは以下のことを行います。
    - `Macintosh HD - Data` または `Data` のボリュームを `diskutil mount` でマウント。
    - `/Volumes/Data/System/Library/AssetsV2/...` 配下の `GenerativeModels` と `Visual` ディレクトリを `rm -rf` で削除。
  - 生成後に `chmod +x` で実行権限を付与します。
  - 主な想定利用シーンは、Recovery OS で起動した状態の Terminal からこのスクリプトを実行し、Data ボリューム上のモデルを削除するケースです。

- **対話型メニュー**
  - スクリプト末尾に無限ループがあり、毎回メニューを表示してユーザーの入力を受け付けます。
  - 入力された番号に応じて、上記の各関数を呼び出すか、終了します。

### 前提条件

- Apple Intelligence 関連コンポーネントが存在する macOS。
- モデル/キャッシュ削除のために `sudo rm -rf` を実行できる **管理者権限** を持つユーザーアカウント。
- Terminal アプリケーション（標準の Terminal や iTerm2 など）。

### 使い方

1. このリポジトリを **クローンまたはダウンロード** します。
2. **Terminal を開き**、プロジェクトディレクトリへ移動します。

   ```bash
   cd /path/to/apple-intelligence-remover
   ```

3. スクリプトに実行権限を付与します（初回のみ）。

   ```bash
   chmod +x main.sh
   ```

4. スクリプトを実行します。

   ```bash
   ./main.sh
   ```

5. 画面に表示されるメニューから操作します。
   - `1` – Apple Intelligence の有効/無効状態を確認。
   - `2` – モデル/キャッシュディレクトリをスキャンし、サイズを表示。
   - `3` – `defaults` を用いて Apple Intelligence を無効化。
   - `4` – 見つかったモデル/キャッシュディレクトリを削除（要確認・`sudo` パスワード入力の可能性あり）。
   - `5` – Recovery OS 用の削除スクリプトを Desktop に生成。
   - `6` – 終了。

### 注意事項・制限事項

- **System Integrity Protection (SIP) について**
  - 本スクリプトは SIP を無効化・回避しません。
  - SIP により保護されているパスについては削除が失敗し、「削除できなかった」というメッセージが表示されるだけです。

- **自己責任での利用**
  - システムアセットを削除すると、Apple Intelligence や Siri、その他のシステム機能に影響が出る可能性があります。
  - 削除したモデル/キャッシュファイルを自動的に復元する機能はありません。
  - 復元が必要になった場合、macOS や関連コンポーネントの再インストールが必要になる可能性があります。

- **macOS バージョン依存性**
  - 本スクリプトは、特定のバンドル ID、設定キー、ディレクトリパスに依存しています。
  - macOS のアップデートによってこれらが変更された場合、一部または全部の機能が動作しなくなる可能性があります。

### 英語版 README について

英語での説明は `README.md` を参照してください。
