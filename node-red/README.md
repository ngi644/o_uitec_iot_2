# Node-RED 完成版フロー（応用編）

各演習が終わった時点の完成版フローです．遅れたときや，うまく動かないときに読み込んで使います．

|ファイル|内容|対応する資料|
|:-|:-|:-:|
|`s01_restore.json`|基礎編の復元：MQTTブローカ（Aedes），ダッシュボード，LEDの操作，接続状態（`iot/esp01/...`）|[s01](../s01.md)|
|`s05_mariadb.json`|MQTTで届いたセンサの値と接続状態を MariaDB に保存する（別タブ）|[s05](../s05.md)|
|`s07_alert_led.json`|Grafana のアラート（Webhook）を受けて LED を点滅・消灯する（別タブ）|[s07](../s07.md)|

3つのファイルは，同じ MQTT のサーバ設定（`localhost`）を共有しています．`s05` と `s07` は別のタブとして追加されるので，`s01` と一緒に使えます．

## 必要なノード

|ノード|使うファイル|インストール方法|
|:-|:-:|:-|
|node-red-contrib-aedes|s01（s04 で Mosquitto に切り替えるまで）|[基礎編 s03](https://github.com/ngi644/o_uitec_iot/blob/main/s03.md)|
|@flowfuse/node-red-dashboard|s01|`パレットの管理` → `ノードを追加`|
|node-red-node-mysql|s05|`パレットの管理` → `ノードを追加`|

## 読み込み方

1. GitHub でファイルを開き，`Raw` ボタンの右にあるダウンロードボタンで保存します．
2. Node-RED の右上のメニュー（≡）→ `読み込み` → `読み込むファイルを選択` で選び，`読み込み` を押します．
3. 「すでに同じノードがある」と表示された場合は `置換` を選びます．
4. `デプロイ` を押します．

## 読み込んだ後に変更すること

- **デバイスID**：フローは `esp01` になっています．参加者番号が01以外の人は，`mqtt in` / `mqtt out` ノードのトピックと，`s07` の function ノードの `DEFAULT_DEVICE` を自分のデバイスIDに変えます．
- **Aedes（s04 以降）**：Mosquitto に切り替えたら `Aedes MQTT broker` ノードを削除します．
- **MariaDB の設定（s05）**：`mysql` ノードの設定で User（`iot_writer`）と Password を入力します．パスワードはフローのファイルには保存されないので，読み込むたびに入力が必要です．
- **2日目（s08）**：MQTT のサーバと MariaDB の Host を NAS のIPアドレスに変えます．

## 動作確認について

Node-RED 4.1，node-red-node-mysql，Mosquitto 2.0，MariaDB で，MQTT の受信 → MariaDB への保存（センサの値・接続状態），SQL の実行，Webhook の受信 → MQTT での LED の指示までを確認しています．
