
# drone_comm.py

import serial
import threading
import time

class DroneComm:
    def __init__(self, port='/dev/ttyUSB0', baud_rate=115200):
        self.port = port
        self.baud_rate = baud_rate
        self.serial_conn = None
        self.running = False
        self.read_thread = None

    def start(self):
        self.serial_conn = serial.Serial(self.port, self.baud_rate, timeout=1)
        time.sleep(2)  # 시리얼 포트 안정화 대기
        self.running = True
        self.read_thread = threading.Thread(target=self.read_from_drone)
        self.read_thread.start()
        print("드론 통신 시작")

    def read_from_drone(self):
        while self.running:
            if self.serial_conn.in_waiting > 0:
                data = self.serial_conn.readline().decode('utf-8').strip()
                if data.startswith("IMU:"):
                    imu_values = data[4:].split(',')
                    self.process_imu_data(imu_values)
            else:
                time.sleep(0.1)

    def process_imu_data(self, imu_values):
        # IMU 데이터 처리 로직
        print(f"IMU 데이터: {imu_values}")

    def send_motor_command(self, motor_speeds):
        command = f"MOTOR:{','.join(map(str, motor_speeds))}\n"
        self.serial_conn.write(command.encode('utf-8'))
        print(f"모터 명령 전송: {motor_speeds}")

    def stop(self):
        self.running = False
        if self.read_thread is not None:
            self.read_thread.join()
        if self.serial_conn is not None:
            self.serial_conn.close()
        print("드론 통신 종료")
