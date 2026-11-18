# IoTシステムの構築とその活用（応用編）

## クラウドを使わずに，NASでIoTシステムを動かす

演習ドキュメント

[基礎編](https://github.com/ngi644/o_uitec_iot)では，ESP32で測ったデータを MQTT で Raspberry Pi に集め，**クラウド（Firebase）** に保存して Webアプリで見えるようにしました．

応用編では，**同じ仕組みを，学校や職場の中だけで動かします**．クラウドの代わりに，コンテナ（Docker）で動かすデータベースや可視化ツールを使い，最後は **NAS** の上で全員分のデータをまとめて運用します．
インターネットに出せないデータを扱う現場，クラウドの費用をかけられない学校でも，自分たちで IoTシステムを持てるようになることが目標です．

## 構成

```
                         1日目：自分の Raspberry Pi の上で練習
                        ┌──────────────── docker compose ────────────────┐
[BME280] → [ESP32] ─MQTT→ │ Mosquitto  →  Node-RED  →  MariaDB  →  Grafana │ → ブラウザ
              ↑          └──────────────────────────────────────────────────┘      │
              └──────────── LEDの点滅（Grafanaのアラート → Node-RED → MQTT） ────────┘

                         2日目：同じ compose ファイルを NAS で動かし，全員のデータを集める
```

基礎編との対応は次のとおりです．ESP32 のプログラムは，トピック名と接続先を変えるだけでそのまま使えます．

|役割|基礎編（クラウド）|応用編（ローカル）|
|:-|:-|:-|
|MQTTブローカ|Aedes（Node-REDの中）|Mosquitto（コンテナ）|
|データの保存|Firebase Realtime Database|MariaDB（コンテナ）|
|データを見る画面|Firebase Hosting の Webアプリ|Grafana（コンテナ）|
|ログイン|Firebase Authentication|Grafana のユーザー管理|
|LEDの操作|Webアプリのボタン|Grafana のアラート → Node-RED → MQTT|
|動かす場所|Google のクラウド|Raspberry Pi → 学校の NAS|

## 時間割（目安）

### 1日目

|時刻|内容|資料|
|:-:|:-|:-:|
|9:00|オリエンテーション，講義「クラウドかローカルか」|[s02](s02.md)|
|9:40|基礎編の復元：ESP32 と Node-RED を動く状態に戻す|[s01](s01.md)|
|11:00|Docker とコンテナの基本|[s03](s03.md)|
|12:00|昼休み||
|13:00|docker compose でローカルIoT基盤を起動する|[s04](s04.md)|
|14:00|MariaDB にデータを貯める（Node-RED → SQL）|[s05](s05.md)|
|15:30|Grafana で可視化する|[s06](s06.md)|
|16:20|1日目の振り返り||

### 2日目

|時刻|内容|資料|
|:-:|:-|:-:|
|9:00|アラートで LED を動かす（Grafana → Node-RED → ESP32）|[s07](s07.md)|
|10:30|NAS で本番運用する（全員のデータを1か所に）|[s08](s08.md)|
|11:30|運用と保守（バックアップ，保存期間，更新，認証，監視ツールの選び方）|[s09](s09.md)|
|12:00|昼休み||
|13:00|運用と保守（続き）|[s09](s09.md)|
|13:40|設計ワーク：自分の現場でローカル運用するなら|[s10](s10.md)|
|15:30|発表と意見交換||
|16:15|まとめ，アンケート||

## 目次

|No.|内容|
|:-:|:-|
|[s01](s01.md)|基礎編の復元（ESP32，Node-RED，応用編のトピック）|
|[s02](s02.md)|クラウドかローカルか（講義資料）|
|[s03](s03.md)|Docker とコンテナの基本|
|[s04](s04.md)|docker compose でローカルIoT基盤（Mosquitto，MariaDB，Grafana）を起動する|
|[s05](s05.md)|MariaDB にデータを貯める（SQLの基本，Node-REDからの保存，集計）|
|[s06](s06.md)|Grafana で可視化する|
|[s07](s07.md)|アラートで LED を動かす（Grafana → Node-RED → ESP32），デバイスの停止を検知する|
|[s08](s08.md)|NAS で本番運用する（QNAP Container Station，接続先の切り替え，ユーザー）|
|[s09](s09.md)|運用と保守（バックアップ，保存期間，更新，MQTTの認証，Zabbix などの監視ツール）|
|[s10](s10.md)|設計ワーク：自分の現場でローカル運用するなら|
|[つまずき対応集](troubleshooting.md)|よくあるトラブルと確認方法|
|[講師の準備](instructor.md)|講習前に講師が準備すること（NAS，Raspberry Pi，配布物）|

## ファイル

|ファイル|内容|対応する資料|
|:-|:-|:-:|
|`arduino_code/a01_sensor_node`|ESP32 のプログラム（センサ送信，LED，Will．基礎編 sample04 の発展版）|s01|
|`local-iot/compose.yaml`|ローカルIoT基盤の構成（Mosquitto，MariaDB，Grafana，Adminer）|s04，s08|
|`local-iot/.env.example`|パスワードなどの設定のひな形（コピーして `.env` を作る）|s04|
|`local-iot/mariadb/init/`|データベースの初期化（テーブルとユーザーの作成）|s05|
|`local-iot/grafana/`|Grafana の自動設定（データソース，ダッシュボード，アラートの通知先）|s06，s07|
|`local-iot/backup.sh`|データベースのバックアップ|s09|
|`node-red/s01_restore.json`|基礎編の復元（ブローカ，ダッシュボード，LED，接続状態）|s01|
|`node-red/s05_mariadb.json`|MQTT で届いたデータを MariaDB に保存する|s05|
|`node-red/s07_alert_led.json`|Grafana のアラートを受けて LED を点滅させる|s07|
|`sql/exercises.sql`|SQL の演習問題と解答例|s05|

## 動作環境（2026年度）

- ESP32-DevKitC，BME280，LED（基礎編と同じ），Arduino IDE 2.x，ESP32 Arduinoコア 3.x，PubSubClient，ArduinoJson 7.x
- Raspberry Pi 5（Raspberry Pi OS 64bit），Node-RED 4.x，node-red-node-mysql，@flowfuse/node-red-dashboard
- Docker Engine と Docker Compose（Raspberry Pi），QNAP NAS と Container Station 3
- コンテナ：eclipse-mosquitto 2，MariaDB 11.8（LTS），Grafana 13.3，Adminer
