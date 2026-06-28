import os
import io
import cv2
import firebase_admin
from firebase_admin import credentials, firestore, messaging
import cloudinary
import cloudinary.uploader
import config

# Initialize Cloudinary
print("DEBUG: Initializing Cloudinary configuration...")
cloudinary.config(
  cloud_name = config.CLOUDINARY_CLOUD_NAME,
  api_key = config.CLOUDINARY_API_KEY,
  api_secret = config.CLOUDINARY_API_SECRET
)

# Initialize Firebase
if not firebase_admin._apps:
    print(f"DEBUG: Checking Firebase credentials file at: {config.FIREBASE_CREDENTIALS_FILE}")
    if os.path.exists(config.FIREBASE_CREDENTIALS_FILE):
        cred = credentials.Certificate(config.FIREBASE_CREDENTIALS_FILE)
        firebase_admin.initialize_app(cred)
        print("DEBUG: Firebase Admin SDK Initialized.")
    else:
        print(f"ERROR: Firebase credentials file NOT FOUND at '{config.FIREBASE_CREDENTIALS_FILE}'.")

def get_db():
    try:
        return firestore.client()
    except Exception as e:
        print(f"ERROR: Error getting Firestore client: {e}")
        return None

def get_family_members(user_id):
    """
    Fetches family members (name and image URL) for a specific user.
    """
    print(f"DEBUG: Fetching family members for User ID: {user_id}")
    db = get_db()
    if not db:
        return []
    
    try:
        members_ref = db.collection('Users').document(user_id).collection('family_members')
        docs = members_ref.stream()
        
        family_list = []
        for doc in docs:
            data = doc.to_dict()
            name = data.get('name')
            image_url = data.get('imageUrl')
            if name and image_url:
                if "cloudinary.com" in image_url and "/upload/" in image_url:
                    image_url = image_url.replace("/upload/", "/upload/w_400,q_auto/")
                
                family_list.append({'name': name, 'image_url': image_url})
        
        print(f"DEBUG: Found {len(family_list)} family members.")
        return family_list
    except Exception as e:
        print(f"ERROR: Failed to fetch family members: {e}")
        return []

def upload_frame_to_cloudinary(frame):
    print("DEBUG: >>> Starting Cloudinary Upload process")
    try:
        if frame is None:
            print("ERROR: Frame provided to upload is None")
            return None

        ret, buffer = cv2.imencode('.jpg', frame)
        if not ret:
            print("ERROR: Failed to encode frame to JPG")
            return None
        
        io_buf = io.BytesIO(buffer)
        
        response = cloudinary.uploader.upload(io_buf, resource_type="image")
        url = response.get('secure_url')
        print(f"DEBUG: Image uploaded successfully. URL: {url}")
        return url
    except Exception as e:
        print(f"ERROR: Cloudinary Upload Failed: {e}")
        return None

def send_notification_to_user(user_id, title, body, push_body=None, image_url=None):
    print(f"DEBUG: >>> Starting Notification process for User ID: {user_id}")
    db = get_db()
    if not db:
        print("ERROR: Database connection failed.")
        return

    final_push_body = push_body if push_body else "Anomaly detected! Check app for details."

    try:
        user_ref = db.collection('Users').document(user_id)
        user_doc = user_ref.get()
        
        if not user_doc.exists:
            print(f"ERROR: User {user_id} does not exist.")
            return
        
        user_data = user_doc.to_dict()
        tokens = user_data.get('fcmTokens', [])
        
        if tokens:
            tokens_to_remove = []
            for token in tokens:
                try:
                    message = messaging.Message(
                        notification=messaging.Notification(
                            title=title,
                            body=final_push_body,
                            image=image_url
                        ),
                        token=token,
                    )
                    messaging.send(message)
                except messaging.UnregisteredError:
                    tokens_to_remove.append(token)
                except Exception as e:
                    print(f"ERROR: FCM Send Error: {e}")

            if tokens_to_remove:
                user_ref.update({
                    'fcmTokens': firestore.ArrayRemove(tokens_to_remove)
                })
        
    except Exception as e:
        print(f"ERROR: FCM Process failed: {e}")

    try:
        notification_data = {
            'title': title,
            'body': body, 
            'pushBody': final_push_body,
            'imageUrl': image_url if image_url else "",
            'timestamp': firestore.SERVER_TIMESTAMP,
            'read': False
        }
        
        db.collection('Users').document(user_id).collection('notifications').add(notification_data)
        print("DEBUG: Notification saved to DB.")
        
    except Exception as e:
        print(f"ERROR: Firestore Save Failed: {e}")

def trigger_hardware_alarm(user_id):
    """
    Finds all hardware devices paired with the user and sends a SET_ALARM command.
    """
    print(f"DEBUG: >>> Triggering hardware alarm for user {user_id}")
    db = get_db()
    if not db:
        print("ERROR: Database connection failed. Cannot trigger alarm.")
        return

    try:
        # Step 1: Find all hardware connected to this user
        hardware_ref = db.collection('Users').document(user_id).collection('hardware')
        hardware_docs = hardware_ref.stream()

        devices_triggered = 0

        # Step 2: Iterate and send the SET_ALARM command to each
        for doc in hardware_docs:
            hardware_data = doc.to_dict()
            device_id = hardware_data.get('device_id')
            
            if device_id:
                command_data = {
                    'command': 'SET_ALARM',
                    'params': {'state': 'ON'},
                    'timestamp': firestore.SERVER_TIMESTAMP,
                    'triggered_by': user_id
                }
                
                # Push the command to the hardware's command queue
                db.collection('Hardware').document(device_id).collection('commands').add(command_data)
                print(f"DEBUG: Successfully sent SET_ALARM command to device: {device_id}")
                devices_triggered += 1

        if devices_triggered == 0:
            print("DEBUG: No hardware devices found for this user.")

    except Exception as e:
        print(f"ERROR: Failed to trigger hardware alarm: {e}")