import cv2
import time
import json
import requests
import threading
from concurrent.futures import ThreadPoolExecutor
from io import BytesIO
from google import genai
from PyQt6.QtCore import QThread, pyqtSignal
from PIL import Image
import config
import notification_sender

class AIDetector(QThread):
    sig_anomaly_detected = pyqtSignal(str)

    def __init__(self, recorder_instance):
        super().__init__()
        self.recorder = recorder_instance
        self.running = False
        self.client = None
        self.family_references = [] 
        self.cached_member_signatures = set()
        
        # PERFECT OPTIMIZATION: Thread pool to allow 10 concurrent requests
        self.executor = ThreadPoolExecutor(max_workers=10)
        self.active_tasks = 0
        self.task_lock = threading.Lock()
        
        self._configure_genai()

    def _configure_genai(self):
        if hasattr(config, 'GEMINI_API_KEY') and config.GEMINI_API_KEY:
            try:
                self.client = genai.Client(api_key=config.GEMINI_API_KEY)
                print("DEBUG: Gemini Client Initialized.")
            except Exception as e:
                print(f"ERROR: Gemini Init Error: {e}")
                self.sig_anomaly_detected.emit(f"AI Config Error: {str(e)}")
        else:
            print("ERROR: GEMINI_API_KEY missing.")

    def _load_family_data(self):
        """Downloads family images from URLs only if data has changed"""
        if not hasattr(config, 'TARGET_USER_ID') or not config.TARGET_USER_ID:
            return

        try:
            members = notification_sender.get_family_members(config.TARGET_USER_ID)
        except Exception as e:
            print(f"ERROR: Failed to check family updates: {e}")
            return

        # Create a signature set: (name, image_url) to detect changes
        current_signatures = set((m['name'], m['image_url']) for m in members)

        # If signatures match exactly, no changes needed -> Skip download
        if current_signatures == self.cached_member_signatures and self.family_references:
            return

        print("DEBUG: Family configuration changed. Updating reference images...")
        
        new_references = []
        for m in members:
            try:
                print(f"DEBUG: Downloading reference for {m['name']}...")
                # Set timeout to prevent hanging
                response = requests.get(m['image_url'], timeout=10)
                if response.status_code == 200:
                    img_data = BytesIO(response.content)
                    pil_img = Image.open(img_data).convert('RGB')
                    
                    # OPTIMIZATION: Downscale reference image to speed up API uploads drastically
                    pil_img.thumbnail((640, 640))
                    
                    new_references.append({
                        'name': m['name'],
                        'image': pil_img
                    })
                    print(f"DEBUG: Loaded reference for {m['name']}")
            except Exception as e:
                print(f"ERROR: Failed to load image for {m['name']}: {e}")
        
        # Update state with new data
        self.family_references = new_references
        self.cached_member_signatures = current_signatures
        print(f"DEBUG: Total family references updated: {len(self.family_references)}")

    def run(self):
        if not self.client: return
        self.running = True
        print("DEBUG: AI Surveillance Started.")

        self._load_family_data()
        last_family_check = time.time()

        while self.running:
            # Use the interval defined in config.py (set to 0.1 for 10 requests/sec)
            time.sleep(config.AI_CHECK_INTERVAL)
            
            if not self.running: 
                break

            # Only check family data every 5 seconds to prevent network spam
            if time.time() - last_family_check > 5.0:
                self._load_family_data()
                last_family_check = time.time()

            if self.recorder:
                # Check if we already have 10 requests running to Gemini
                with self.task_lock:
                    if self.active_tasks >= 10:
                        # Skip this frame! Prevents massive RAM explosion & lag
                        continue 
                    self.active_tasks += 1

                frame, _ = self.recorder.get_frame()
                if frame is not None:
                    # Offload to the 10-thread pool
                    self.executor.submit(self._analyze_wrapper, frame)
                else:
                    with self.task_lock:
                        self.active_tasks -= 1

    def _analyze_wrapper(self, frame):
        """Wraps analyze_frame to safely free up the thread slot when done"""
        try:
            self._analyze_frame(frame)
        finally:
            with self.task_lock:
                self.active_tasks -= 1

    def _analyze_frame(self, frame):
        try:
            rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            target_pil = Image.fromarray(rgb_frame)
            
            # OPTIMIZATION: Downscale the target frame to prevent massive payload hanging
            target_pil.thumbnail((800, 800))

            # Build the prompt content dynamically
            contents = []
            
            # 1. Add Reference Images (Context)
            if self.family_references:
                contents.append("CONTEXT: Here are reference photos of known family members:")
                for ref in self.family_references:
                    contents.append(ref['image'])
                    contents.append(f"Reference Person: {ref['name']}")
            
            # 2. Add Target Image
            contents.append("TASK: Analyze the following Surveillance Frame:")
            contents.append(target_pil)
            
            # 3. Add Text Instructions (Full original prompt intact)
            prompt = (
                "You are an advanced intelligent security camera AI analyst.\n"
                "Analyze this single frame very carefully from a surveillance perspective.\n"
                "**CONTEXT**: Reference photos of known family members have been provided above (if any).\n"
                "Your task:\n"
                "1. **Face Recognition**: Compare people in the frame against the Reference Photos.\n"
                "   - If a known family member is seen, identify them by Name. This is a noteworthy event.\n"
                "   - If a person is seen but matches NO reference, label as 'Unknown Person' or 'Intruder'.\n"
                "2. Detect ANY abnormal, suspicious, dangerous or noteworthy elements.\n"
                "3. Be sensitive but not over-triggering on normal daily activity.\n"
                "4. Common anomalies/events to look for:\n"
                "- **Family Member Detected** (Identify by name)\n"
                "- Person / people (especially if unexpected location/time)\n"
                "- Face mask, balaclava, disguise, covered face\n"
                "- Weapon (gun, knife, bat, explosive device, suspicious object held aggressively)\n"
                "- Violence / fight / aggressive posture\n"
                "- Unauthorized / suspicious object (bag left alone, crowbar, gas can...)\n"
                "- Fire, smoke, broken glass/window\n"
                "- Loitering in restricted area\n"
                "- Running in panic / abnormal crowd behavior\n"
                "- Anything that looks clearly out of place or dangerous\n"
                "Response rules — strict:\n"
                "- Return **ONLY** valid JSON — nothing else\n"
                "- Structure:\n"
                "{\n"
                '  "anomaly_detected": boolean,\n'
                '  "confidence": number between 0.0–1.0,\n'
                '  "notification_summary": "Very short (max 10 words) urgent summary for push notification (e.g., \'John is at the camera\', \'Knife detected\')",\n'
                '  "anomalies": [\n'
                '    {"type": "Family"|"Intruder"|"Threat", "description": "very short clear description", "severity": "info"|"low"|"medium"|"high"}\n'
                '  ]\n'
                "}\n"
                "- If nothing suspicious and no family detected → {\"anomaly_detected\": false, \"confidence\": 0.95, \"anomalies\": []}\n"
                "- Use severity wisely: high = immediate threat, info = family member detected.\n"
            )
            contents.append(prompt)

            print("DEBUG: Sending request to Gemini...")
            response = self.client.models.generate_content(
                model='gemini-2.5-flash',
                contents=contents
            )
            
            text_response = response.text.strip()
            if text_response.startswith("```json"): 
                text_response = text_response[7:-3]
            elif text_response.startswith("```"): 
                text_response = text_response[3:-3]

            data = json.loads(text_response)
            print(f"DEBUG: AI Response: {data}")

            if data.get("anomaly_detected"):
                summary = data.get("notification_summary", "Activity Detected")
                anomalies = data.get("anomalies", [])
                
                # Construct detailed body
                details = "\n".join([f"- {a['description']}" for a in anomalies])
                
                self.sig_anomaly_detected.emit(f"AI Alert: {summary}")
                
                if hasattr(config, 'TARGET_USER_ID') and config.TARGET_USER_ID:
                    
                    # OPTIMIZATION: Threading to prevent GUI freezes during uploads and notifications
                    def handle_notifications_and_alarms(captured_frame):
                        print("DEBUG: Uploading frame to Cloudinary...")
                        image_url = notification_sender.upload_frame_to_cloudinary(captured_frame)
                        
                        # 1. Send Push Notification to Mobile
                        print("DEBUG: Sending push notification...")
                        notification_sender.send_notification_to_user(
                            user_id=config.TARGET_USER_ID,
                            title="Home Security Update",
                            body=f"Event Detected:\n{details}",
                            push_body=summary,
                            image_url=image_url
                        )

                        # 2. Evaluate if we should trigger the physical alarm
                        is_threat = any(
                            a.get('severity') in ['medium', 'high'] or
                            a.get('type') in ['Intruder', 'Threat']
                            for a in anomalies
                        )

                        if is_threat:
                            print("DEBUG: Threat detected. Triggering hardware alarms...")
                            notification_sender.trigger_hardware_alarm(config.TARGET_USER_ID)
                        else:
                            print("DEBUG: Anomaly detected but not classified as a severe threat. Skipping hardware alarm.")

                    # Start the threaded notification process using a copy of the frame
                    threading.Thread(target=handle_notifications_and_alarms, args=(frame.copy(),), daemon=True).start()

        except Exception as e:
            print(f"ERROR: Analysis failed: {e}")

    def stop(self):
        self.running = False
        # Shutdown the executor gracefully to stop pending requests
        if hasattr(self, 'executor'):
            self.executor.shutdown(wait=False)
        # OPTIMIZATION: Add timeout so closing the app doesn't hang indefinitely
        self.wait(2000)