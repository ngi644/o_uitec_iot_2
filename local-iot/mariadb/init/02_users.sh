#!/bin/bash
# データベースを初めて作るときに1回だけ実行されます．
# 用途ごとに，必要な権限だけを持つユーザーを作ります（root は普段使わない）．
#   iot_writer : Node-RED がデータを書き込む（INSERT と SELECT だけ）
#   grafana    : Grafana がデータを読む（SELECT だけ）
# パスワードは compose.yaml 経由で .env から渡されます．
# ※このファイルに実行権限を付けないこと（付けると別プロセスで実行され，docker_process_sql が使えなくなる）

docker_process_sql --database=iot <<-EOSQL
	CREATE USER IF NOT EXISTS 'iot_writer'@'%' IDENTIFIED BY '${DB_WRITER_PASSWORD}';
	GRANT SELECT, INSERT ON iot.* TO 'iot_writer'@'%';

	CREATE USER IF NOT EXISTS 'grafana'@'%' IDENTIFIED BY '${DB_READER_PASSWORD}';
	GRANT SELECT ON iot.* TO 'grafana'@'%';

	FLUSH PRIVILEGES;
EOSQL
