
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
        time.sleep(2)  # �ø��� ��Ʈ ����ȭ ���
        self.running = True
        self.read_thread = threading.Thread(target=self.read_from_drone)
        self.read_thread.start()
        print("��� ��� ����")

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
        # IMU ������ ó�� ����
        print(f"IMU ������: {imu_values}")

    def send_motor_command(self, motor_speeds):
        command = f"MOTOR:{','.join(map(str, motor_speeds))}\n"
        self.serial_conn.write(command.encode('utf-8'))
        print(f"���� ��� ����: {motor_speeds}")

    def stop(self):
        self.running = False
        if self.read_thread is not None:
            self.read_thread.join()
        if self.serial_conn is not None:
            self.serial_conn.close()
        print("��� ��� ����")
