import cv2
import base64
import queue
import time
import config

def video_stream_worker(client, crypto_manager):
    topic = crypto_manager.get_topic()
    while True:
        try:
            frame = config.video_stream_queue.get(timeout=1)
            
            while not config.video_stream_queue.empty():
                try:
                    frame = config.video_stream_queue.get_nowait()
                except queue.Empty:
                    break

            if frame is None:
                break
            
            _, buffer = cv2.imencode('.jpg', frame, [int(cv2.IMWRITE_JPEG_QUALITY), config.STREAM_QUALITY])
            jpg_bytes = base64.b64encode(buffer)
            
            encrypted_payload = crypto_manager.encrypt_message(jpg_bytes)
            
            client.publish(topic, encrypted_payload.decode('utf-8'), qos=0)
            
        except queue.Empty:
            continue
        except Exception:
            time.sleep(0.01)