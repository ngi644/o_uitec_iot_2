// 応用編のセンサノード
//   基礎編の esp32_sample04（センサ送信 + LED制御）に，次の点を加えたものです．
//   - トピックを「iot/<デバイスID>/...」にまとめた（2日目に全員が1台のブローカを使うため）
//   - Will で接続状態（online / offline）を知らせる（基礎編 s05 の実験と同じ仕組み）
//   - ブローカのユーザー名・パスワードに対応（空欄なら認証なし）
//
//   変更するのは「ここを書き換える」の部分だけです．
//   2日目に NAS へ移るときは MQTT_SERVER を NAS のIPアドレスに変えるだけです．

#include <WiFi.h>
#include <Wire.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <SparkFunBME280.h>

// ===== ここを書き換える =====================================
#define WIFI_SSID "{WiFiSSID}"
#define WIFI_PASSWORD "{WiFiパスワード}"

// MQTTブローカ（1日目: 自分の Raspberry Pi，2日目: NAS）
#define MQTT_SERVER "{ブローカのIPアドレス}"
#define MQTT_PORT 1883
// ブローカに認証を設定したときだけ書く（空欄 "" なら認証なし）
#define MQTT_USER ""
#define MQTT_PASSWORD ""

// デバイスID：参加者番号に合わせて esp01〜esp10．全員で重ならないようにする
#define DEVICE_ID "esp01"
// ============================================================

// センサデータの送信間隔 (ミリ秒)
#define SEND_INTERVAL_MS 5000

// LED
#define LED_PIN 4
#define BLINK_INTERVAL_MS 100

#define MQTT_BUFFER_SIZE 128

// トピック（setup() で DEVICE_ID から作る）
//   iot/esp01/bme         センサの値（ESP32 → ブローカ）
//   iot/esp01/led         LEDの指示（ブローカ → ESP32）  {"status":1} 点灯 / 2 消灯 / 3 点滅
//   iot/esp01/connection  接続状態（online / offline，Retain付き）
char topic_bme[64];
char topic_led[64];
char topic_connection[64];

// BME280
BME280 bme;
BME280_SensorMeasurements measurements;

// MQTT Subscribe用 / Publish用のJSON
JsonDocument json_request;
JsonDocument json_message;
char message_buffer[MQTT_BUFFER_SIZE];

// MQTT用インスタンス作成
WiFiClient espClient;
PubSubClient client(espClient);

// 最後にデータを送信した時刻 (millis()の値)
unsigned long lastSendTime = 0;

// LEDステータス (0:変更なし 1:点灯 2:消灯 3:点滅)
int led_status = 0;
bool blink_on = false;
unsigned long lastBlinkTime = 0;


// MQTT Subscribeのコールバック（メッセージを受信したときに呼ばれる）
void mqttCallback(char* topic, byte* payload, unsigned int length) {
  DeserializationError err = deserializeJson(json_request, payload, length);
  if (err) {
    Serial.print("Deserialize error: ");
    Serial.println(err.c_str());
    return;
  }
  serializeJson(json_request, Serial);
  Serial.println("");

  // "status" が無いときは 0 (変更なし) とする
  led_status = json_request["status"] | 0;
}


// WiFiへの接続
void setupWiFi() {
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("WiFi connecting");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(500);
  }
  Serial.println("");
  Serial.print("Connected : ");
  Serial.println(WiFi.localIP());
}


// MQTTブローカへの接続（切断されていたら再接続）
void connectMqtt() {
  while (!client.connected()) {
    Serial.print("MQTT connecting to ");
    Serial.println(MQTT_SERVER);

    // ユーザー名が空欄なら認証なしで接続する
    const char* user = (strlen(MQTT_USER) > 0) ? MQTT_USER : NULL;
    const char* pass = (strlen(MQTT_USER) > 0) ? MQTT_PASSWORD : NULL;

    // 引数: クライアントID, ユーザー名, パスワード, Willのトピック, WillのQoS, WillのRetain, Willのメッセージ
    if (client.connect(DEVICE_ID, user, pass, topic_connection, 0, true, "offline")) {
      // 接続できたら「online」をRetain付きで送る
      client.publish(topic_connection, "online", true);
      // 接続のたびに購読し直す
      client.subscribe(topic_led);
      Serial.println("MQTT connected");
    } else {
      // state: -2 ブローカに届かない（IPアドレス・ポートを確認）
      //         5 認証エラー（ユーザー名・パスワードを確認）
      Serial.print("failed, state=");
      Serial.println(client.state());
      delay(2000);
    }
  }
}


void sendSensorData() {
  // センサからデータの取得
  bme.readAllMeasurements(&measurements);

  // ペイロードを作成して送信する（基礎編と同じ形）
  json_message.clear();
  json_message["temp"] = measurements.temperature;
  json_message["humid"] = measurements.humidity;
  json_message["press"] = measurements.pressure / 100;
  serializeJson(json_message, message_buffer, sizeof(message_buffer));
  client.publish(topic_bme, message_buffer);

  Serial.print(topic_bme);
  Serial.print(" ");
  Serial.println(message_buffer);
}


// led_status に応じてLEDを制御する（delayを使わない）
void updateLed() {
  switch (led_status) {
    case 1:
      digitalWrite(LED_PIN, HIGH);
      break;
    case 2:
      digitalWrite(LED_PIN, LOW);
      break;
    case 3:
      if (millis() - lastBlinkTime >= BLINK_INTERVAL_MS) {
        lastBlinkTime = millis();
        blink_on = !blink_on;
        digitalWrite(LED_PIN, blink_on ? HIGH : LOW);
      }
      break;
    default:
      break;
  }
}


void setup() {
  Serial.begin(115200);

  // トピックを作る
  snprintf(topic_bme, sizeof(topic_bme), "iot/%s/bme", DEVICE_ID);
  snprintf(topic_led, sizeof(topic_led), "iot/%s/led", DEVICE_ID);
  snprintf(topic_connection, sizeof(topic_connection), "iot/%s/connection", DEVICE_ID);

  Wire.begin();
  bme.setI2CAddress(0x77);  // I2C address {0x76:GND or 0x77:VDD}
  if (bme.beginI2C() == false) {
    Serial.println("The sensor did not respond. Please check wiring.");
    while (1);
  }

  pinMode(LED_PIN, OUTPUT);

  setupWiFi();

  client.setServer(MQTT_SERVER, MQTT_PORT);
  client.setCallback(mqttCallback);
}


void loop() {
  // MQTT未接続の場合は，再接続
  if (!client.connected()) {
    connectMqtt();
  }
  // MQTTの送受信処理（受信するとここで mqttCallback が呼ばれる）
  client.loop();

  // 前回の送信から SEND_INTERVAL_MS 経過していたら送信する
  unsigned long now = millis();
  if (now - lastSendTime >= SEND_INTERVAL_MS) {
    lastSendTime = now;
    sendSensorData();
  }

  updateLed();
}
