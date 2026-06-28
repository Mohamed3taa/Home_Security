import os
import json
import uuid
from cryptography.fernet import Fernet
import config

class CryptoManager:
    def __init__(self):
        self.device_id = None
        self.key = None
        self.cipher = None
        self.load_or_generate_credentials()

    def load_or_generate_credentials(self):
        if os.path.exists(config.CREDENTIALS_FILE):
            try:
                with open(config.CREDENTIALS_FILE, 'r') as f:
                    data = json.load(f)
                    self.device_id = data.get("device_id")
                    self.key = data.get("key").encode()
            except Exception:
                self.generate_credentials()
        else:
            self.generate_credentials()
        
        self.cipher = Fernet(self.key)

    def generate_credentials(self):
        self.device_id = str(uuid.uuid4())[:8]
        self.key = Fernet.generate_key()
        
        data = {
            "device_id": self.device_id,
            "key": self.key.decode()
        }
        
        with open(config.CREDENTIALS_FILE, 'w') as f:
            json.dump(data, f, indent=4)

    def encrypt_message(self, message_bytes):
        return self.cipher.encrypt(message_bytes)

    def get_topic(self):
        return f"{config.TOPIC_VIDEO_BASE}/{self.device_id}"