
// drone_controller.ino

#include <Wire.h>       // I2C 통신을 위한 라이브러리
#include <Servo.h>      // 모터(ESC) 제어를 위한 라이브러리
#include <MPU6050.h>    // IMU 센서를 위한 라이브러리

// 모터 및 센서 객체 생성
Servo esc1, esc2, esc3, esc4; // 쿼드콥터 기준
MPU6050 imu;

// ESC 핀 정의
const int ESC_PIN1 = 3;
const int ESC_PIN2 = 5;
const int ESC_PIN3 = 6;
const int ESC_PIN4 = 9;

// 통신 설정
const long BAUD_RATE = 115200;

// 변수 선언
float accX, accY, accZ;
float gyroX, gyroY, gyroZ;

void setup() {
  // 시리얼 통신 초기화
  Serial.begin(BAUD_RATE);

  // ESC 초기화
  esc1.attach(ESC_PIN1);
  esc2.attach(ESC_PIN2);
  esc3.attach(ESC_PIN3);
  esc4.attach(ESC_PIN4);

  // ESC 초기 신호 (모터 정지)
  esc1.writeMicroseconds(1000);
  esc2.writeMicroseconds(1000);
  esc3.writeMicroseconds(1000);
  esc4.writeMicroseconds(1000);

  // IMU 초기화
  Wire.begin();
  imu.initialize();
  if (!imu.testConnection()) {
    // IMU 연결 실패 시 무한 루프
    while (1) {
      Serial.println("IMU 연결 실패");
      delay(1000);
    }
  }

  Serial.println("Arduino 초기화 완료");
}

void loop() {
  // IMU 데이터 읽기
  imu.getAcceleration(&accX, &accY, &accZ);
  imu.getRotation(&gyroX, &gyroY, &gyroZ);

  // 데이터 전송
  Serial.print("IMU:");
  Serial.print(accX); Serial.print(",");
  Serial.print(accY); Serial.print(",");
  Serial.print(accZ); Serial.print(",");
  Serial.print(gyroX); Serial.print(",");
  Serial.print(gyroY); Serial.print(",");
  Serial.println(gyroZ);

  // 명령 수신 및 처리
  if (Serial.available()) {
    String command = Serial.readStringUntil('\n');
    processCommand(command);
  }

  delay(100); // 루프 주기 조절
}

void processCommand(String cmd) {
  // 명령 형식: "MOTOR:1500,1500,1500,1500"
  if (cmd.startsWith("MOTOR:")) {
    cmd.remove(0, 6); // "MOTOR:" 제거
    int motorSpeeds[4];
    for (int i = 0; i < 4; i++) {
      int index = cmd.indexOf(',');
      String value = (index != -1) ? cmd.substring(0, index) : cmd;
      motorSpeeds[i] = value.toInt();
      cmd = (index != -1) ? cmd.substring(index + 1) : "";
    }
    // 모터 속도 설정
    esc1.writeMicroseconds(motorSpeeds[0]);
    esc2.writeMicroseconds(motorSpeeds[1]);
    esc3.writeMicroseconds(motorSpeeds[2]);
    esc4.writeMicroseconds(motorSpeeds[3]);
  }
}
