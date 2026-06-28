import time
import random
import json
import threading
import os
import qrcode
import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

# ==========================================
# CONFIGURATION
# ==========================================
DEVICE_ID = "sim_gate_01"  # Unique ID for this device
DEVICE_NAME = "Main Gate Simulator"
SERVICE_ACCOUNT_FILE = "home-security-f3878-firebase-adminsdk-fbsvc-d371b1cb8a.json" # Path to your Firebase Admin Key

# Check if service account file exists
if not os.path.exists(SERVICE_ACCOUNT_FILE):
    print(f"ERROR: {SERVICE_ACCOUNT_FILE} not found.")
    print("Please download it from Firebase Console > Project Settings > Service accounts")
    exit(1)

# Initialize Firebase
cred = credentials.Certificate(SERVICE_ACCOUNT_FILE)
firebase_admin.initialize_app(cred)
db = firestore.client()

class HardwareSimulator:
    def __init__(self, device_id):
        self.device_id = device_id
        # Initial State
        self.state = {
            "state": "Online",
            "temperature": 22.0,
            "humidity": 45.0,
            "gate": False,      # False = Closed, True = Open
            "alarm_state": False # False = Off, True = On
        }
        self.running = True
        
        # References
        self.device_ref = db.collection("Hardware").document(self.device_id)
        self.commands_ref = self.device_ref.collection("commands")
        self.states_ref = self.device_ref.collection("states")

    def generate_pairing_qr(self):
        """Generates a QR code to pair with the mobile app"""
        data = json.dumps({"device_id": self.device_id, "type": "hardware"})
        qr = qrcode.make(data)
        qr.save("device_qr.png")
        print(f"[*] QR Code saved as 'device_qr.png'. Scan this with the app to pair.")

    def on_command_snapshot(self, col_snapshot, changes, read_time):
        """Callback for real-time updates from the 'commands' collection"""
        for change in changes:
            if change.type.name == 'ADDED':
                cmd_data = change.document.to_dict()
                self.process_command(cmd_data)
                # Cleanup command to prevent reprocessing (optional, or mark as handled)
                change.document.reference.delete()

    def process_command(self, cmd):
        """Execute received commands"""
        command_type = cmd.get('command')
        params = cmd.get('params', {})
        
        print(f"\n[!] Received Command: {command_type} | Params: {params}")

        if command_type == 'SET_GATE':
            desired = params.get('state')
            if desired == 'OPEN':
                self.state['gate'] = True
                print("   >>> ACTUATOR: Opening Gate...")
            elif desired == 'CLOSE':
                self.state['gate'] = False
                print("   >>> ACTUATOR: Closing Gate...")
        
        elif command_type == 'SET_ALARM':
            desired = params.get('state')
            if desired == 'ON':
                self.state['alarm_state'] = True
                print("   >>> ALARM: !!! SIREN ACTIVATED !!!")
            elif desired == 'OFF':
                self.state['alarm_state'] = False
                print("   >>> ALARM: Siren Silenced.")

        # Publish new state immediately after command execution
        self.publish_state()

    def publish_state(self):
        """Pushes current state to Firestore"""
        # Add timestamp
        payload = self.state.copy()
        payload['timestamp'] = firestore.SERVER_TIMESTAMP
        
        # We use .add() to create a time-series history in 'states' collection
        # Or .set() on a specific doc if we only care about latest. 
        # The App listens to 'states' ordered by timestamp, so .add() is good for history.
        self.states_ref.add(payload)
        
        print(f"[*] State Synced: Temp={payload['temperature']:.1f}C, Gate={'OPEN' if payload['gate'] else 'CLOSED'}, Alarm={'ON' if payload['alarm_state'] else 'OFF'}")

    def simulate_environment(self):
        """Randomly fluctuates sensor data"""
        while self.running:
            # Randomize Temp +/- 0.5 degrees
            self.state['temperature'] += random.uniform(-0.5, 0.5)
            # Clamp temp
            self.state['temperature'] = max(10.0, min(40.0, self.state['temperature']))

            # Randomize Humidity +/- 1%
            self.state['humidity'] += random.uniform(-1.0, 1.0)
            self.state['humidity'] = max(20.0, min(90.0, self.state['humidity']))

            self.publish_state()
            
            # Wait 5 seconds before next sensor update
            time.sleep(5)

    def start(self):
        print(f"--- Starting Hardware Simulator: {self.device_id} ---")
        self.generate_pairing_qr()
        
        # Listen for commands in background
        self.commands_watch = self.commands_ref.on_snapshot(self.on_command_snapshot)
        
        try:
            self.simulate_environment()
        except KeyboardInterrupt:
            print("\nStopping simulator...")
            self.running = False
            self.commands_watch.unsubscribe()

if __name__ == "__main__":
    sim = HardwareSimulator(DEVICE_ID)
    sim.start()