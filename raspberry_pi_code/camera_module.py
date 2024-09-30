
# camera_module.py

import threading
import time
import cv2

class CameraModule:
    def __init__(self):
        self.running = False
        self.capture_thread = None

    def start(self):
        self.running = True
        self.capture_thread = threading.Thread(target=self.capture_frames)
        self.capture_thread.start()
        print("카메라 모듈 시작")

    def capture_frames(self):
        cap = cv2.VideoCapture(0)  # 카메라 장치 번호 확인 필요
        while self.running:
            ret, frame = cap.read()
            if ret:
                # 이미지 처리 로직 추가 가능
                cv2.imshow('Camera', frame)
                if cv2.waitKey(1) & 0xFF == ord('q'):
                    self.running = False
            else:
                print("카메라 프레임 읽기 실패")
                time.sleep(0.1)
        cap.release()
        cv2.destroyAllWindows()
        print("카메라 모듈 종료")

    def stop(self):
        self.running = False
        if self.capture_thread is not None:
            self.capture_thread.join()
