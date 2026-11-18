# IoTシステムの構築とその活用（応用編）

# 講師の準備

講習の前日までに準備することをまとめます．会場のネットワークでコンテナのイメージを6台同時にダウンロードすると時間がかかるため，**イメージの事前ダウンロード** を強くおすすめします．

## 1. 配布物（紙）

公開リポジトリにはパスワードを書かないため，次の内容を紙で配ります．

|項目|1日目（Raspberry Pi）|2日目（NAS）|
|:-|:-|:-|
|ブローカ・DB・Grafana のIPアドレス|各自の Raspberry Pi のIP|NAS のIP|
|`DB_ROOT_PASSWORD`|練習用（全員共通でよい）|講師のみ|
|`DB_WRITER_PASSWORD`（`iot_writer`）|練習用|NAS 用|
|`GRAFANA_ADMIN_PASSWORD`|練習用|講師のみ|
|Grafana の個人ユーザー|―|`user01`〜`user06` とパスワード|
|デバイスID|`esp01`〜`esp06`（参加者番号）|同じ|
|Wi-Fi の SSID とパスワード（2.4GHz）|〃|〃|

## 2. Raspberry Pi（参加者全員分）

Raspberry Pi OS（**64bit 版**）を使います．

1. Node-RED，`node-red-contrib-aedes`，`@flowfuse/node-red-dashboard` をインストールする（基礎編 s03，s04）．基礎編の受講者が使った Raspberry Pi をそのまま使う場合は確認のみ．
2. `node-red-node-mysql` をインストールしておく（`パレットの管理` から．s05 の時間短縮）．
3. Node-RED の自動起動：`sudo systemctl enable nodered.service`
4. Docker をインストールし，教材を取得して，イメージを事前にダウンロードする．

   ```shell
   $ curl -fsSL https://get.docker.com | sudo sh
   $ sudo usermod -aG docker $USER
   # ログインし直してから
   $ cd ~ && git clone https://github.com/ngi644/o_uitec_iot_2.git
   $ cd o_uitec_iot_2/local-iot
   $ docker compose pull                      # 4つのイメージをダウンロード（数分）
   $ docker pull hello-world                  # s03 で使う
   ```

   この準備をした場合，参加者は s03 の「1. Docker のインストール」を確認だけ，s04 の `git clone` は不要（`cd ~/o_uitec_iot_2 && git pull` で最新にする）になります．

5. microSD の空き容量が 4GB 以上あることを確認する（`df -h`）．

## 3. NAS（QNAP）

### 3-1. 事前の確認

- QTS に **Container Station**（3.x）をインストールする（App Center）．
- **SSH を有効にする**：`コントロールパネル` → `ネットワークとファイルサービス` → `Telnet / SSH`．
- 使うポートが空いているか確認する．

  |ポート|用途|重なりやすいもの|
  |:-:|:-|:-|
  |1883|Mosquitto|QNAP の IoT 系アプリ，既存の MQTT ブローカ|
  |3306|MariaDB|QNAP の `MariaDB` アプリ／`SQL Server` 機能|
  |3000|Grafana|ほかの Web アプリ|
  |8082|Adminer|QTS の管理画面（8080），Web Server（8081）は避けてある|

  重なる場合は `.env` の `MQTT_PORT` などを変えます（ESP32 や Node-RED の接続先のポートも合わせて変える）．

### 3-2. ファイルを置く

NAS の共有フォルダ（例：Container Station が作る `Container` 共有フォルダ）に，このリポジトリの `local-iot` フォルダを置きます．

- GitHub の `Code` → `Download ZIP` で取得して展開し，File Station でアップロードする，または
- PC から `scp -r local-iot admin@<NASのIP>:/share/Container/` でコピーする．

### 3-3. .env を作る

```shell
$ ssh admin@<NASのIP>
$ cd /share/Container/local-iot
$ cp .env.example .env
$ vi .env
```

- パスワードを NAS 用に書き換える（**最初の起動の前に**．後から変えても DB には反映されない）．
- `ALERT_WEBHOOK_URL` を **講師の Raspberry Pi** の Node-RED にする：`http://<講師のRaspberry PiのIP>:1880/grafana-alert`

### 3-4. 起動する

```shell
$ docker compose up -d        # 古い環境では docker-compose up -d
$ docker compose ps
```

起動したら，Container Station の画面でコンテナが4つ動いていることを確認します．

> **Container Station の画面（アプリケーション → 作成）から起動する場合**
> YAML を貼り付ける画面では，`./mosquitto/config` のような相対パスと `.env` が使えないことがあります．その場合は，`volumes` の `./` を `/share/Container/local-iot/` のような絶対パスに書き換え，`${...}` の部分に値を直接書いた YAML を貼り付けます（パスワードを書いた YAML は公開しないこと）．講習では SSH から `docker compose` を使う方法をおすすめします．

### 3-5. Grafana のユーザーを作る

`http://<NASのIP>:3000` に `admin` でログインし，`管理` → `ユーザーとアクセス` → `ユーザー` で `user01`〜`user06` を作り，ロールを **Editor** にします（各自がアラートルールを作るため）．

## 4. 講師の Raspberry Pi（2日目のアラート担当）

1. Node-RED に [`node-red/s07_alert_led.json`](node-red/s07_alert_led.json) を読み込む．
2. MQTT のサーバ設定を **NAS のIP** にする．
3. デプロイし，`アラート発生を試す` で参加者の LED が点滅するか確認する（inject の JSON のデバイスIDを変えて試す）．
4. NAS の Grafana の `連絡先` → `Node-RED（LED）` → `テスト` で，講師の Node-RED に届くことを確認する．

## 5. 当日のトラブルへの備え

|起こりうること|代わりの方法|
|:-|:-|
|Raspberry Pi に Docker が入らない・イメージが落ちてこない|その参加者は1日目から NAS の環境を使う（s08 の接続先の切り替えを先に行う．デバイスIDが重ならないので他の人と混ざらない）|
|NAS が使えない|講師の Raspberry Pi（またはPC）で同じ compose を動かし，全員の接続先にする|
|ESP32 が会場の Wi-Fi につながらない|2.4GHz の SSID か確認．講師が用意したモバイルルータを使う|

## 6. 講習の後

- 2日目の Miro ボードの設計シートを書き出して参加者に共有する．
- NAS のデータを残す場合は `./backup.sh` でバックアップを取る．残さない場合は `docker compose down -v` で削除する．
- 配布したパスワードを変更する（講習用の Grafana ユーザーを削除する）．
