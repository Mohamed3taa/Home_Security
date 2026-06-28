import firebase_admin
from firebase_admin import credentials, firestore, messaging

if not firebase_admin._apps:
    cred = credentials.Certificate("home-security-f3878-firebase-adminsdk-fbsvc-d371b1cb8a.json")
    firebase_admin.initialize_app(cred)

db = firestore.client()

def send_notification_to_user(user_id, title, body, image_url=None):
    try:
        user_ref = db.collection('Users').document(user_id)
        user_doc = user_ref.get()
        if not user_doc.exists:
            print(f"User {user_id} not found in database.")
            return
        user_data = user_doc.to_dict()
        tokens = user_data.get('fcmTokens', [])
        if not tokens:
            print(f"User {user_id} has no registered devices.")
            return

        print(f"Found {len(tokens)} device(s) for user. Sending...")

        success_count = 0
        failure_count = 0
        tokens_to_remove = []

        for token in tokens:
            try:
                message = messaging.Message(
                    notification=messaging.Notification(
                        title=title,
                        body=body,
                        image=image_url
                    ),
                    token=token,
                )

                response: str = messaging.send(message)
                print(f"Successfully sent to token: {token[:10]}...")
                success_count += 1

            except messaging.UnregisteredError:
                print(f"Token unregistered: {token[:10]}... → will be removed")
                tokens_to_remove.append(token)
                failure_count += 1
            except Exception as e:
                print(f"Failed to send to {token[:10]}...: {e}")
                failure_count += 1

        print(f"Successfully sent to {success_count} devices.")
        print(f"Failed on {failure_count} devices.")

        if tokens_to_remove:
            print(f"Cleaning up {len(tokens_to_remove)} invalid tokens...")
            user_ref.update({
                'fcmTokens': firestore.ArrayRemove(tokens_to_remove)
            })

    except Exception as e:
        print(f"Error in send_notification_to_user: {e}")


if __name__ == "__main__":
    TARGET_USER_ID = "2TpjUFgnPfWLzephAUbJ3bUsarf1"
    send_notification_to_user(
        user_id=TARGET_USER_ID,
        title="Intruder Alert!",
        body="Motion detected at the Front Door camera.",
        image_url="https://via.placeholder.com/600x400.png?text=Security+Cam+Capture"
    )