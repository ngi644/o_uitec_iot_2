-- データベースを初めて作るときに1回だけ実行されます．
-- （すでにデータがある場合は実行されません．作り直すときは s09 を参照）

USE iot;

-- センサの値（ESP32 から MQTT で届いたもの）
CREATE TABLE IF NOT EXISTS sensor_data (
  id     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  ts     DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '記録した時刻（UTC）',
  device VARCHAR(32)     NOT NULL COMMENT 'デバイスID（例: esp01）',
  temp   FLOAT           NULL     COMMENT '温度 [℃]',
  humid  FLOAT           NULL     COMMENT '湿度 [%]',
  press  FLOAT           NULL     COMMENT '気圧 [hPa]',
  PRIMARY KEY (id),
  KEY idx_device_ts (device, ts)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='センサの計測値';

-- デバイスの接続状態（MQTT の Will で届く online / offline）
CREATE TABLE IF NOT EXISTS device_event (
  id     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  ts     DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '記録した時刻（UTC）',
  device VARCHAR(32)     NOT NULL COMMENT 'デバイスID',
  state  VARCHAR(16)     NOT NULL COMMENT 'online / offline',
  PRIMARY KEY (id),
  KEY idx_device_ts (device, ts)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='デバイスの接続状態の記録';
