#!/bin/bash
# データベース（iot）を，backup フォルダに SQL ファイルとして書き出します．
#   使い方:  ./backup.sh
#   NAS の共有フォルダに置いておけば，NAS のスナップショットやバックアップの対象になります．
#   戻し方:  docker compose exec -T mariadb sh -c 'mariadb -uroot -p"$MARIADB_ROOT_PASSWORD"' < backup/ファイル名.sql
set -eu
cd "$(dirname "$0")"
mkdir -p backup
file="backup/iot_$(date +%Y%m%d_%H%M%S).sql"
# パスワードはコンテナの中の環境変数を使うので，コマンドに直接書かなくてよい
docker compose exec -T mariadb sh -c 'mariadb-dump -uroot -p"$MARIADB_ROOT_PASSWORD" --single-transaction --databases iot' > "$file"
echo "保存しました: $file ($(du -h "$file" | cut -f1))"
