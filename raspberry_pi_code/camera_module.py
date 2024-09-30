
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
        print("ī�޶� ��� ����")

    def capture_frames(self):
        cap = cv2.VideoCapture(0)  # ī�޶� ��ġ ��ȣ Ȯ�� �ʿ�
        while self.running:
            ret, frame = cap.read()
            if ret:
                # �̹��� ó�� ���� �߰� ����
                cv2.imshow('Camera', frame)
                if cv2.waitKey(1) & 0xFF == ord('q'):
                    self.running = False
            else:
                print("ī�޶� ������ �б� ����")
                time.sleep(0.1)
        cap.release()
        cv2.destroyAllWindows()
        print("ī�޶� ��� ����")

    def stop(self):
        self.running = False
        if self.capture_thread is not None:
            self.capture_thread.join()
