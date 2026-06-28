import cv2

def scan_video_devices():
    devices = []
    for index in range(5):
        cap = cv2.VideoCapture(index)
        if cap.isOpened():
            ret, _ = cap.read()
            if ret:
                devices.append(index)
            cap.release()
    return devices