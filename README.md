# 📄 Scantron Grader

**Scantron Grader** is a powerful Flutter-based mobile application that scans and grades multiple-choice answer sheets (Scantrons) using AI-powered detection and custom answer key management. Designed for educators and students, it simplifies test evaluation using a camera, computer vision, and persistent history tracking.

---

## 🚀 Features

- 📸 **Photo Capture & Smart Cropping**  
  Uses a YOLOv8 (TFLite) object detection model to crop and align photos of Scantrons for consistent grading, even across different distances.

- 🧠 **Bubble Detection via ML Kit**  
  Detects filled bubbles and determines selected answers per question row using bounding box logic and confidence scoring.

- 📝 **Answer Key Creation**  
  - Manually input or import/export keys as CSV.
  - Supports 50 (one-sided) or 100 (two-sided) questions.

- 📊 **Automatic Grading & Feedback**  
  Compares scan results to saved answer keys and calculates real-time score percentages.

- 💾 **Persistent History**  
  Stores past scan sessions using Hive, including images, scores, and timestamps.

- 🔌 **Offline Capable**  
  Once installed, grading and history access works without an internet connection.

---

## 📁 Folder Overview

```plaintext
scantron_grader/
├── lib/
│   ├── models/               # Hive model (ScanHistoryEntry)
│   ├── screens/              # UI screens: capture, answer key, results
│   ├── services/             # ImageService and TFLiteService
│   ├── utils/                # Detection logic, alignment, storage
│   └── main.dart             # App entry & navigation
├── assets/
│   └── models/best_float32.tflite  # YOLOv8 model
├── pubspec.yaml              # Project config
├── README.md                 # This file

⚙️ Getting Started

1. Clone the Repo

git clone https://github.com/yourusername/scantron_grader.git
cd scantron_grader

2. Install Flutter Packages

flutter pub get

3. Generate Hive Type Adapters

flutter packages pub run build_runner build

4. Run the App

flutter run
✅ Ensure your assets/models/best_float32.tflite file exists and is listed in pubspec.yaml.

📦 Key Dependencies
tflite_flutter

google_mlkit_object_detection

hive, hive_flutter

image, file_picker, shared_preferences, path_provider, image_picker, camera

📚 How It Works

1. User selects or captures an image of a filled Scantron.

2. The YOLO model crops the form from the background.

3. Google ML Kit detects bubble positions.

4. Bubble areas are analyzed to determine answers.

5. Results are compared to a selected answer key.

6. Score and history are saved locally for later review.


👤 Author
Salvatore Gruttadauria


📄 License
This app is developed as a personal/portfolio project. For inquiries about collaboration or use in educational environments, please contact the author.