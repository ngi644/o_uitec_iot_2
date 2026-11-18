# IoTシステムの構築とその応用

# つまずき対応集

ESP32 や Node-RED の基本的なトラブルは，基礎編の[つまずき対応集](https://github.com/ngi644/o_uitec_iot/blob/main/troubleshooting.md)も参照してください．

## 調べ方の基本

困ったときは，まず **ログ** を見ます．

```shell
$ cd ~/o_uitec_iot_2/local-iot
$ docker compose ps                 # どのコンテナが動いていないか
$ docker compose logs mariadb       # そのコンテナのログ（mosquitto / grafana / adminer）
$ docker compose logs -f grafana    # 流し続ける（Ctrl+C で抜ける）
```

MQTT のメッセージが届いているかは，次のコマンドで確認できます．

```shell
$ docker compose exec mosquitto mosquitto_sub -t 'iot/#' -v
```

## Docker

|症状|原因と対処|
|:-|:-|
|`permission denied while trying to connect to the Docker daemon socket`|`docker` グループに入っていない，またはログインし直していない．`sudo usermod -aG docker $USER` の後，ログアウト・ログイン（または再起動）|
|`Bind for 0.0.0.0:1883 failed: port is already allocated` など|そのポートを別のソフトが使っている．1883 なら Node-RED の Aedes ノードが残っている（削除してデプロイ）．`sudo ss -ltnp \| grep 1883` で使っているソフトが分かる|
|`required variable DB_ROOT_PASSWORD is missing a value`|`.env` がない，または `compose.yaml` と別のフォルダにある．`cp .env.example .env`|
|`docker compose` が見つからない（NAS）|古い環境では `docker-compose`（ハイフンあり）を使う|
|イメージのダウンロードが遅い・止まる|会場のネットワークが混んでいる．講師が事前に `docker compose pull` しておく（[講師の準備](instructor.md)）|
|microSD の容量が足りない|`docker system df` で使用量を確認．使っていないイメージは `docker image prune`|

## MariaDB

|症状|原因と対処|
|:-|:-|
|`mariadb` が `(healthy)` にならない|初回は30秒〜1分かかる．`docker compose logs mariadb` でエラーを確認|
|Node-RED や Adminer で `Access denied for user 'iot_writer'`|パスワードの間違い．または **データベースを作った後に `.env` のパスワードを変えた**（DB のパスワードは最初の起動時だけ設定される）．下の「パスワードを変える」を参照|
|Node-RED で `connect ECONNREFUSED 127.0.0.1:3306`|MariaDB のコンテナが動いていない（`docker compose ps`），または Host の設定が違う（2日目は NAS のIP）|
|`sensor_data` テーブルがない|`mariadb/init/` のファイルは **データベースを初めて作ったときだけ** 実行される．作り直す（下）|
|時刻が9時間ずれている|仕様です．`ts` は UTC で保存している．日本時間は `CONVERT_TZ(ts, '+00:00', '+09:00')`．Grafana は自動で日本時間で表示する|
|ターミナルの `mariadb` コマンドで日本語が化ける・エラーになる|`mariadb --default-character-set=utf8mb4 ...` を付ける（Adminer では不要）|

### パスワードを変える

root で入って変更します（`.env` も同じ値に書き換えておく）．

```shell
$ docker compose exec mariadb sh -c 'mariadb -uroot -p"$MARIADB_ROOT_PASSWORD"'
MariaDB [(none)]> ALTER USER 'iot_writer'@'%' IDENTIFIED BY '新しいパスワード';
MariaDB [(none)]> exit
```

`grafana` ユーザーのパスワードを変えた場合は，`.env` の `DB_READER_PASSWORD` を同じ値にして `docker compose up -d` します（Grafana のデータソースに反映される）．

### データベースを最初から作り直す

**すべてのデータが消えます**．必要なら先に `./backup.sh`．

```shell
$ docker compose down -v      # ボリュームごと削除
$ docker compose up -d        # 作り直し（init のファイルが実行される）
```

## Node-RED

|症状|原因と対処|
|:-|:-|
|`mysql` ノードがパレットにない|`node-red-node-mysql` をインストールする（`パレットの管理`）|
|`Failed to parse JSON string`|MQTT で JSON 以外のデータが届いた（手で送ったテストなど）．保存はされないだけなので問題なし|
|同じデータが何回も保存される|2日目に，複数の Node-RED が同じトピックを保存している．各自の `mqtt in` は自分のデバイスのトピックだけにする|
|`mqtt in` が `接続中` のまま|ブローカのIPアドレスの間違い，Mosquitto が動いていない，または Mosquitto に認証をかけたのに Node-RED のセキュリティ設定が空|

## ESP32

|症状|原因と対処|
|:-|:-|
|`failed, state=-2`|ブローカに届かない．IPアドレス，ポート，Mosquitto が動いているか，同じネットワークか|
|`failed, state=5`|認証エラー．Mosquitto に認証をかけたなら `MQTT_USER` / `MQTT_PASSWORD` を設定|
|つながったり切れたりを繰り返す|**デバイスIDが他の人と重なっている**（同じクライアントIDはお互いを切断し合う）|

## Grafana

|症状|原因と対処|
|:-|:-|
|ダッシュボードが `No data`|データがまだ保存されていない（Adminer で確認），`デバイス` の選択が空・違う，表示期間が合っていない|
|データソースのエラー `Access denied for user 'grafana'`|`.env` の `DB_READER_PASSWORD` を DB 作成後に変えた（上の「パスワードを変える」）|
|アラートが `Firing` にならない|ルールの `プレビュー` で値を確認．しきい値，SQL のデバイスID，評価グループの間隔を確認|
|`Firing` なのに LED が点滅しない|① Node-RED の `アラート→LED` タブの `http in` に届いているか（デバッグ）② 連絡先の URL（2日目の NAS では `host.docker.internal` ではなく講師の Raspberry Pi のIP）③ ラベル `device` が付いているか|
|アラートが解決しても LED がなかなか消えない|通知の `グループ間隔` が既定の5分のまま．ルールの通知の設定で `1m` にする|
|`.env` の `ALERT_WEBHOOK_URL` を変えたのに反映されない|`docker compose up -d` で Grafana を作り直す（`restart` では環境変数は変わらない）|

テスト用に，Grafana を使わずに Node-RED の受け口を確かめるには，Raspberry Pi で次を実行します．

```shell
$ curl -X POST -H 'Content-Type: application/json' \
  -d '{"status":"firing","alerts":[{"status":"firing","labels":{"device":"esp01"}}]}' \
  http://localhost:1880/grafana-alert
```

`ok` と返り，LED が点滅すれば Node-RED 側は正常です．
