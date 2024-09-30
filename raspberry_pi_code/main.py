
# main.py

import threading
import time
from drone_comm import DroneComm
from camera_module import CameraModule

def main():
    # ��� ��� ��ü �ʱ�ȭ
    drone = DroneComm(port='/dev/ttyUSB0', baud_rate=115200)
    drone.start()

    # ī�޶� ��� �ʱ�ȭ
    camera = CameraModule()
    camera.start()

    try:
        while True:
            # ����: ���� �ӵ� ��� ����
            motor_speeds = [1500, 1500, 1500, 1500]
            drone.send_motor_command(motor_speeds)
            time.sleep(1)

            # �߰� ���� ���� ����
            # ��: ���� ��� ���, ���� ������ �м� ��
    except KeyboardInterrupt:
        print("���α׷��� �����մϴ�.")
    finally:
        drone.stop()
        camera.stop()

if __name__ == '__main__':
    main()
