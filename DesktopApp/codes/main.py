import sys
from PyQt6.QtWidgets import QApplication
from GUI import SecurityApp

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = SecurityApp()
    window.show()
    sys.exit(app.exec())