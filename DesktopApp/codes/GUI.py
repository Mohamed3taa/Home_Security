import sys
import os
import time
import datetime
import threading
import json
import ssl
import cv2
import paho.mqtt.client as mqtt
import qrcode
from PIL import Image

from PyQt6.QtWidgets import (QMainWindow, QWidget, QVBoxLayout, 
                             QHBoxLayout, QLabel, QPushButton, QTextEdit)
from PyQt6.QtCore import QTimer, Qt, pyqtSignal
from PyQt6.QtGui import QImage, QPixmap, QIcon

import config
import recorder
import streamer
from crypto_manager import CryptoManager
from ai_detector import AIDetector

class SecurityApp(QMainWindow):
    sig_recording_started = pyqtSignal(str)
    sig_recording_stopped = pyqtSignal()
    sig_log_message = pyqtSignal(str)

    def __init__(self):
        super().__init__()
        self.crypto = CryptoManager()
        self.recorder = None
        self.mqtt_client = None
        self.stream_thread = None
        self.ai_thread = None
        self.chunk_timer_start = 0
        
        self.last_stream_time = 0
        self.last_processed_frame_id = -1
        
        self.init_ui()
        self.setup_mqtt()
        
        self.sig_recording_started.connect(self.on_recording_started)
        self.sig_recording_stopped.connect(self.on_recording_stopped)
        self.sig_log_message.connect(self.log)
        
        if not os.path.exists(config.OUTPUT_FOLDER):
            os.makedirs(config.OUTPUT_FOLDER)

    def init_ui(self):
        self.setWindowTitle("Secure Camera Recorder")
        self.setGeometry(100, 100, 950, 700)
        
        if os.path.exists("logo.png"):
            self.setWindowIcon(QIcon("logo.png"))

        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        main_layout = QHBoxLayout(central_widget)

        left_layout = QVBoxLayout()
        self.video_label = QLabel("Camera Feed")
        self.video_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.video_label.setStyleSheet("background-color: black; color: white;")
        self.video_label.setMinimumSize(640, 480)
        left_layout.addWidget(self.video_label)

        btn_layout = QHBoxLayout()
        self.start_btn = QPushButton("Start Recording")
        self.start_btn.clicked.connect(self.start_recording)
        self.stop_btn = QPushButton("Stop Recording")
        self.stop_btn.clicked.connect(self.stop_recording)
        self.stop_btn.setEnabled(False)
        btn_layout.addWidget(self.start_btn)
        btn_layout.addWidget(self.stop_btn)
        left_layout.addLayout(btn_layout)

        self.log_area = QTextEdit()
        self.log_area.setReadOnly(True)
        self.log_area.setMaximumHeight(150)
        left_layout.addWidget(self.log_area)
        main_layout.addLayout(left_layout, stretch=2)

        right_layout = QVBoxLayout()
        right_layout.setAlignment(Qt.AlignmentFlag.AlignTop)
        
        if os.path.exists("logo.png"):
            logo_label = QLabel()
            logo_pixmap = QPixmap("logo.png")
            logo_label.setPixmap(logo_pixmap.scaled(150, 150, Qt.AspectRatioMode.KeepAspectRatio))
            logo_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
            right_layout.addWidget(logo_label)

        info_label = QLabel("Scan to Pair")
        info_label.setStyleSheet("font-weight: bold; font-size: 16px;")
        info_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        right_layout.addWidget(info_label)

        self.qr_label = QLabel()
        self.qr_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.generate_and_show_qr()
        right_layout.addWidget(self.qr_label)

        id_text = QLabel(f"Device ID:\n{self.crypto.device_id}")
        id_text.setStyleSheet("font-size: 14px; margin-top: 10px; font-weight: bold;")
        id_text.setAlignment(Qt.AlignmentFlag.AlignCenter)
        right_layout.addWidget(id_text)
        main_layout.addLayout(right_layout, stretch=1)

        self.update_timer = QTimer()
        self.update_timer.timeout.connect(self.update_frame)

        self.chunk_timer = QTimer()
        self.chunk_timer.timeout.connect(self.check_chunk_time)

        self.log(f"System Initialized.")
        self.log(f"Stream limit: {config.STREAM_INTERVAL}s interval")

    def generate_and_show_qr(self):
        qr_data = json.dumps({
            "device_id": self.crypto.device_id,
            "key": self.crypto.key.decode(),
            "mqtt_topic": self.crypto.get_topic(),
            "broker": config.MQTT_BROKER
        })
        qr = qrcode.QRCode(version=1, box_size=8, border=2)
        qr.add_data(qr_data)
        qr.make(fit=True)
        img = qr.make_image(fill_color="black", back_color="white")
        img = img.convert("RGBA")
        data = img.tobytes("raw", "RGBA")
        qim = QImage(data, img.size[0], img.size[1], QImage.Format.Format_RGBA8888)
        self.qr_label.setPixmap(QPixmap.fromImage(qim))

    def log(self, message):
        timestamp = datetime.datetime.now().strftime("%H:%M:%S")
        self.log_area.append(f"[{timestamp}] {message}")

    def on_mqtt_connect(self, client, userdata, flags, rc, properties=None):
        if rc == 0:
            self.sig_log_message.emit("MQTT Connected Successfully.")
        else:
            self.sig_log_message.emit(f"MQTT Connect Failed. Code: {rc}")

    def on_mqtt_disconnect(self, client, userdata, flags, rc, properties=None):
        if rc != 0:
            self.sig_log_message.emit(f"MQTT Disconnected (Code: {rc}). Auto-reconnecting...")
        else:
            self.sig_log_message.emit("MQTT Disconnected cleanly.")

    def setup_mqtt(self):
        self.mqtt_client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2, transport="tcp")
        self.mqtt_client.max_inflight_messages_set(20)

        if config.MQTT_PORT == 8883:
            self.mqtt_client.tls_set(tls_version=ssl.PROTOCOL_TLS)
        if config.MQTT_USERNAME and config.MQTT_PASSWORD:
            self.mqtt_client.username_pw_set(config.MQTT_USERNAME, config.MQTT_PASSWORD)
        
        self.mqtt_client.on_connect = self.on_mqtt_connect
        self.mqtt_client.on_disconnect = self.on_mqtt_disconnect
        
        try:
            self.mqtt_client.connect(config.MQTT_BROKER, config.MQTT_PORT, 60)
            self.mqtt_client.loop_start()
            self.log(f"Connecting to HiveMQ Cloud...")
        except Exception as e:
            self.log(f"MQTT Connection Error: {e}")
            self.mqtt_client = None

    def get_filenames(self):
        now = datetime.datetime.now()
        day_folder = now.strftime("%Y-%m-%d")
        timestamp = now.strftime("%Y-%m-%d_%H-%M-%S")
        
        full_path = os.path.join(config.OUTPUT_FOLDER, day_folder)
        
        if not os.path.exists(full_path):
            os.makedirs(full_path)
            
        return os.path.join(full_path, f"rec_{timestamp}.avi")

    def start_recording(self):
        self.start_btn.setEnabled(False)
        self.start_btn.setText("Starting...")
        threading.Thread(target=self._start_recording_thread, daemon=True).start()

    def _start_recording_thread(self):
        filename = self.get_filenames()
        self.recorder = recorder.VideoRecorder(filename, device_index=config.VIDEO_DEVICE_INDEX)
        self.recorder.start()
        
        if self.mqtt_client:
            self.stream_thread = threading.Thread(
                target=streamer.video_stream_worker, 
                args=(self.mqtt_client, self.crypto), 
                daemon=True
            )
            self.stream_thread.start()
            
        self.ai_thread = AIDetector(self.recorder)
        self.ai_thread.sig_anomaly_detected.connect(self.log)
        self.ai_thread.start()
        
        self.sig_recording_started.emit(filename)

    def on_recording_started(self, filename):
        self.chunk_timer_start = time.time()
        self.last_stream_time = 0
        
        self.update_timer.start(33)
        self.chunk_timer.start(1000)
        
        self.start_btn.setText("Start Recording")
        self.start_btn.setEnabled(False)
        self.stop_btn.setEnabled(True)
        self.log(f"Recording started: {os.path.basename(filename)}")

    def stop_recording(self):
        self.stop_btn.setEnabled(False)
        self.stop_btn.setText("Stopping...")
        self.update_timer.stop()
        self.chunk_timer.stop()
        threading.Thread(target=self._stop_recording_thread, daemon=True).start()

    def _stop_recording_thread(self):
        if self.ai_thread:
            self.ai_thread.stop()
            self.ai_thread = None

        if self.recorder:
            self.recorder.stop()
        
        if self.mqtt_client:
            config.video_stream_queue.put(None)
            if self.stream_thread and self.stream_thread.is_alive():
                self.stream_thread.join(timeout=2.0)
        
        self.sig_recording_stopped.emit()

    def on_recording_stopped(self):
        self.start_btn.setEnabled(True)
        self.stop_btn.setEnabled(False)
        self.stop_btn.setText("Stop Recording")
        self.video_label.clear()
        self.video_label.setText("Camera Feed Stopped")
        self.log("Recording stopped.")

    def check_chunk_time(self):
        if time.time() - self.chunk_timer_start > config.CHUNK_DURATION:
            self.log("Splitting recording chunk...")
            new_filename = self.get_filenames()
            self.recorder.split_recording(new_filename)
            self.chunk_timer_start = time.time()
            self.log(f"Started new chunk: {os.path.basename(new_filename)}")

    def update_frame(self):
        if self.recorder:
            frame, frame_id = self.recorder.get_frame()
            
            if frame is not None:
                rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                h, w, ch = rgb_frame.shape
                bytes_per_line = ch * w
                qt_image = QImage(rgb_frame.data, w, h, bytes_per_line, QImage.Format.Format_RGB888)
                self.video_label.setPixmap(QPixmap.fromImage(qt_image).scaled(
                    self.video_label.width(), self.video_label.height(), Qt.AspectRatioMode.KeepAspectRatio))
                
                current_time = time.time()
                if self.mqtt_client and (current_time - self.last_stream_time > config.STREAM_INTERVAL):
                    if frame_id > self.last_processed_frame_id:
                        self.last_stream_time = current_time
                        self.last_processed_frame_id = frame_id
                        
                        try:
                            small_frame = cv2.resize(frame, (config.STREAM_WIDTH, config.STREAM_HEIGHT))
                            
                            while not config.video_stream_queue.empty():
                                try:
                                    config.video_stream_queue.get_nowait()
                                except:
                                    break
                            
                            config.video_stream_queue.put(small_frame)
                        except Exception:
                            pass

    def closeEvent(self, event):
        if self.recorder and self.recorder.recording:
            self.recorder.stop()
            if self.mqtt_client:
                config.video_stream_queue.put(None)
        
        if self.ai_thread:
            self.ai_thread.stop()
            
        if self.mqtt_client:
            self.mqtt_client.loop_stop()
        event.accept()