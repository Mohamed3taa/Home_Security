# Install required Python packages for Firebase and QR code generation
python -m venv env
env\Scripts\activate
python -m pip install firebase-admin qrcode[pil]
