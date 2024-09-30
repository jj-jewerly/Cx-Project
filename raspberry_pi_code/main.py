
# main.py

import threading
import time
from drone_comm import DroneComm
from camera_module import CameraModule

def main():
    # 드론 통신 객체 초기화
    drone = DroneComm(port='/dev/ttyUSB0', baud_rate=115200)
    drone.start()

    # 카메라 모듈 초기화
    camera = CameraModule()
    camera.start()

    try:
        while True:
            # 예시: 모터 속도 명령 전송
            motor_speeds = [1500, 1500, 1500, 1500]
            drone.send_motor_command(motor_speeds)
            time.sleep(1)

            # 추가 로직 구현 가능
            # 예: 비행 경로 계산, 센서 데이터 분석 등
    except KeyboardInterrupt:
        print("프로그램을 종료합니다.")
    finally:
        drone.stop()
        camera.stop()

if __name__ == '__main__':
    main()
