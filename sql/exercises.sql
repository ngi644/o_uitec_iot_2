-- ============================================================
-- SQL の演習（応用編 s05）
--   Adminer（http://<IPアドレス>:8082）の「SQLコマンド」に貼り付けて実行します．
--   'esp01' は自分のデバイスIDに読み替えてください．
--   ts は UTC で保存しています．日本時間で見るときは CONVERT_TZ(ts, '+00:00', '+09:00')．
--   （ターミナルの mariadb コマンドで日本語の列名を使うときは --default-character-set=utf8mb4 を付ける）
-- ============================================================


-- ------------------------------------------------------------
-- 問1 自分のデバイスの最新の10件を，新しい順に表示する
-- ------------------------------------------------------------
SELECT CONVERT_TZ(ts, '+00:00', '+09:00') AS 日本時間, temp, humid, press
FROM sensor_data
WHERE device = 'esp01'
ORDER BY ts DESC
LIMIT 10;


-- ------------------------------------------------------------
-- 問2 これまでに保存した件数を，デバイスごとに数える
-- ------------------------------------------------------------
SELECT device, COUNT(*) AS 件数, MIN(ts) AS 最初, MAX(ts) AS 最後
FROM sensor_data
GROUP BY device;


-- ------------------------------------------------------------
-- 問3 直近1時間の温度の平均・最低・最高を求める
-- ------------------------------------------------------------
SELECT ROUND(AVG(temp), 2) AS 平均, MIN(temp) AS 最低, MAX(temp) AS 最高
FROM sensor_data
WHERE device = 'esp01' AND ts >= NOW() - INTERVAL 1 HOUR;


-- ------------------------------------------------------------
-- 問4 温度が 25℃ 以上だった記録だけを表示する
--     （ESP32 のセンサを指で温めて試す）
-- ------------------------------------------------------------
SELECT CONVERT_TZ(ts, '+00:00', '+09:00') AS 日本時間, temp
FROM sensor_data
WHERE device = 'esp01' AND temp >= 25
ORDER BY ts DESC;


-- ------------------------------------------------------------
-- 問5 10分ごとの平均温度と件数（GROUP BY）
--     UNIX_TIMESTAMP で秒に直し，600秒（10分）ごとに切り捨ててまとめる
-- ------------------------------------------------------------
SELECT
  CONVERT_TZ(FROM_UNIXTIME(FLOOR(UNIX_TIMESTAMP(ts) / 600) * 600), '+00:00', '+09:00') AS 時刻,
  ROUND(AVG(temp), 1) AS 平均温度,
  COUNT(*) AS 件数
FROM sensor_data
WHERE device = 'esp01'
GROUP BY 1
ORDER BY 1 DESC;


-- ------------------------------------------------------------
-- 問6 1時間ごとの集計（Grafana の表と同じ SQL）
-- ------------------------------------------------------------
SELECT
  DATE_FORMAT(CONVERT_TZ(ts, '+00:00', '+09:00'), '%m/%d %H:00') AS 時刻,
  ROUND(AVG(temp), 1)  AS 平均温度,
  ROUND(MIN(temp), 1)  AS 最低温度,
  ROUND(MAX(temp), 1)  AS 最高温度,
  ROUND(AVG(humid), 0) AS 平均湿度,
  COUNT(*)             AS 件数
FROM sensor_data
WHERE device = 'esp01' AND ts >= NOW() - INTERVAL 24 HOUR
GROUP BY 1
ORDER BY 1 DESC;


-- ------------------------------------------------------------
-- 問7 接続状態の記録（いつ切断し，いつ復帰したか）
-- ------------------------------------------------------------
SELECT CONVERT_TZ(ts, '+00:00', '+09:00') AS 日本時間, device, state
FROM device_event
ORDER BY ts DESC
LIMIT 20;


-- ------------------------------------------------------------
-- 問8（2日目，NAS の共有環境で）全員の最新の温度を並べる
--     サブクエリで「デバイスごとの最新の時刻」を求めてから，その行を取り出す
-- ------------------------------------------------------------
SELECT s.device, CONVERT_TZ(s.ts, '+00:00', '+09:00') AS 日本時間, s.temp, s.humid
FROM sensor_data AS s
JOIN (
  SELECT device, MAX(ts) AS last_ts
  FROM sensor_data
  GROUP BY device
) AS latest ON s.device = latest.device AND s.ts = latest.last_ts
ORDER BY s.device;


-- ------------------------------------------------------------
-- 問9（2日目）直近10分で，平均温度がいちばん高いデバイスは？
-- ------------------------------------------------------------
SELECT device, ROUND(AVG(temp), 2) AS 平均温度
FROM sensor_data
WHERE ts >= NOW() - INTERVAL 10 MINUTE
GROUP BY device
ORDER BY 平均温度 DESC
LIMIT 1;
