import os
import qrcode
import json
from PIL import Image

def generate_device_qr(device_id, logo_path, output_path):
    try:
        qr_data = {
            "device_id": device_id,
            "type": "hardware"
        }
        qr_payload = json.dumps(qr_data)

        qr = qrcode.QRCode(
            version=None,
            error_correction=qrcode.constants.ERROR_CORRECT_H,
            box_size=10,
            border=4,
        )
        qr.add_data(qr_payload)
        qr.make(fit=True)

        qr_image = qr.make_image(fill_color="black", back_color="white").convert('RGBA')

        if os.path.exists(logo_path):
            logo = Image.open(logo_path)
            
            qr_w, qr_h = qr_image.size
            logo_size = int(qr_w * 0.25)
            
            logo = logo.resize((logo_size, logo_size), Image.Resampling.LANCZOS)
            
            pos = ((qr_w - logo_size) // 2, (qr_h - logo_size) // 2)
            
            mask = logo if logo.mode == 'RGBA' else None
            qr_image.paste(logo, pos, mask=mask)

        qr_image.save(output_path)
        print(f"QR Code generated: {output_path}")
        print(f"Payload: {qr_payload}")
        return True

    except Exception as e:
        print(f"QR Generation Error: {e}")
        return False

if __name__ == "__main__":
    DEVICE_ID = "Q66yzzufLIb0Ygwp9lbbrVHoV842"
    LOGO_FILE = "logo.png"
    OUTPUT_FILE = f"qr_{DEVICE_ID}.png"
    generate_device_qr(DEVICE_ID, LOGO_FILE, OUTPUT_FILE)