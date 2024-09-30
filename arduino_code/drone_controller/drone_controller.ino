
// drone_controller.ino

#include <Wire.h>       // I2C ����� ���� ���̺귯��
#include <Servo.h>      // ����(ESC) ��� ���� ���̺귯��
#include <MPU6050.h>    // IMU ������ ���� ���̺귯��

// ���� �� ���� ��ü ����
Servo esc1, esc2, esc3, esc4; // �������� ����
MPU6050 imu;

// ESC �� ����
const int ESC_PIN1 = 3;
const int ESC_PIN2 = 5;
const int ESC_PIN3 = 6;
const int ESC_PIN4 = 9;

// ��� ����
const long BAUD_RATE = 115200;

// ���� ����
float accX, accY, accZ;
float gyroX, gyroY, gyroZ;

void setup() {
  // �ø��� ��� �ʱ�ȭ
  Serial.begin(BAUD_RATE);

  // ESC �ʱ�ȭ
  esc1.attach(ESC_PIN1);
  esc2.attach(ESC_PIN2);
  esc3.attach(ESC_PIN3);
  esc4.attach(ESC_PIN4);

  // ESC �ʱ� ��ȣ (���� ����)
  esc1.writeMicroseconds(1000);
  esc2.writeMicroseconds(1000);
  esc3.writeMicroseconds(1000);
  esc4.writeMicroseconds(1000);

  // IMU �ʱ�ȭ
  Wire.begin();
  imu.initialize();
  if (!imu.testConnection()) {
    // IMU ���� ���� �� ���� ����
    while (1) {
      Serial.println("IMU ���� ����");
      delay(1000);
    }
  }

  Serial.println("Arduino �ʱ�ȭ �Ϸ�");
}

void loop() {
  // IMU ������ �б�
  imu.getAcceleration(&accX, &accY, &accZ);
  imu.getRotation(&gyroX, &gyroY, &gyroZ);

  // ������ ����
  Serial.print("IMU:");
  Serial.print(accX); Serial.print(",");
  Serial.print(accY); Serial.print(",");
  Serial.print(accZ); Serial.print(",");
  Serial.print(gyroX); Serial.print(",");
  Serial.print(gyroY); Serial.print(",");
  Serial.println(gyroZ);

  // ��� ���� �� ó��
  if (Serial.available()) {
    String command = Serial.readStringUntil('\n');
    processCommand(command);
  }

  delay(100); // ���� �ֱ� ����
}

void processCommand(String cmd) {
  // ��� ����: "MOTOR:1500,1500,1500,1500"
  if (cmd.startsWith("MOTOR:")) {
    cmd.remove(0, 6); // "MOTOR:" ����
    int motorSpeeds[4];
    for (int i = 0; i < 4; i++) {
      int index = cmd.indexOf(',');
      String value = (index != -1) ? cmd.substring(0, index) : cmd;
      motorSpeeds[i] = value.toInt();
      cmd = (index != -1) ? cmd.substring(index + 1) : "";
    }
    // ���� �ӵ� ����
    esc1.writeMicroseconds(motorSpeeds[0]);
    esc2.writeMicroseconds(motorSpeeds[1]);
    esc3.writeMicroseconds(motorSpeeds[2]);
    esc4.writeMicroseconds(motorSpeeds[3]);
  }
}
