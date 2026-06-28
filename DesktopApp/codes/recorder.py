import cv2
import threading
import time

class VideoRecorder:
    def __init__(self, filename, device_index=0):
        if filename.endswith(".mp4"):
            filename = filename.replace(".mp4", ".avi")
            
        self.filename = filename
        self.device_index = device_index
        self.recording = False
        self.out = None
        self.lock = threading.Lock()
        
        self.latest_frame = None
        self.frame_id = 0
        
        self.frame_width = 0
        self.frame_height = 0

    def start(self):
        self.cap = cv2.VideoCapture(self.device_index)
        
        self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
        self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)

        ret, first_frame = self.cap.read()
        if not ret:
            self.cap.release()
            return

        self.frame_height, self.frame_width = first_frame.shape[:2]
        
        with self.lock:
            self.latest_frame = first_frame
            self.frame_id = 1
        
        fourcc = cv2.VideoWriter_fourcc(*'MJPG')
        self.out = cv2.VideoWriter(self.filename, fourcc, 20.0, (self.frame_width, self.frame_height))
        self.out.write(first_frame)
        
        self.recording = True
        self.thread = threading.Thread(target=self.record, daemon=True)
        self.thread.start()

    def split_recording(self, new_filename):
        if new_filename.endswith(".mp4"):
            new_filename = new_filename.replace(".mp4", ".avi")

        with self.lock:
            if self.out:
                self.out.release()
            
            self.filename = new_filename
            fourcc = cv2.VideoWriter_fourcc(*'MJPG')
            self.out = cv2.VideoWriter(self.filename, fourcc, 20.0, (self.frame_width, self.frame_height))

    def record(self):
        while self.recording:
            ret, frame = self.cap.read()
            if ret:
                with self.lock:
                    if self.out:
                        self.out.write(frame)
                    
                    self.latest_frame = frame
                    self.frame_id += 1
            else:
                break
        
        with self.lock:
            if self.out:
                self.out.release()
        self.cap.release()

    def get_frame(self):
        with self.lock:
            return self.latest_frame, self.frame_id

    def stop(self):
        self.recording = False
        if hasattr(self, 'thread'):
            self.thread.join()