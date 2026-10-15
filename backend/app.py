from flask import Flask, request, jsonify
from flask_cors import CORS
from groq import Groq
from dotenv import load_dotenv

import json
import os
import re
from datetime import datetime, timezone


# ---------- Application Setup ----------

app = Flask(__name__)
CORS(app)

load_dotenv()

GROQ_API_KEY = os.getenv("GROQ_API_KEY")
client = Groq(api_key=GROQ_API_KEY) if GROQ_API_KEY else None

# Groq model configuration
MODEL_NAME = "openai/gpt-oss-20b"


# ---------- Multilingual Warning Messages ----------

TEXT = {
    "en": {
        "empty": "No message was provided.",
        "enter": "Enter a message and try again.",
        "sensitive": "The message asks for sensitive information such as an OTP or UPI PIN.",
        "threat": "The message uses an account-blocking threat.",
        "urgency": "The message contains urgency, a suspicious link, or a prize/payment claim.",
        "no_match": "No selected warning phrases were detected. Other scams may still be present.",
        "high_action": "Do not share your OTP or UPI PIN. Do not follow suspicious instructions. Verify through your bank's official channels.",
        "medium_action": "Pause before acting. Verify the sender independently and avoid unknown links or unexpected payment requests.",
        "unknown_action": "Do not assume the message is safe. Verify the sender and any payment request independently.",
        "disclaimer": "This tool checks selected warning signs only and cannot guarantee that a message is safe.",
    },
    "kn": {
        "empty": "ಯಾವುದೇ ಸಂದೇಶವನ್ನು ನೀಡಲಾಗಿಲ್ಲ.",
        "enter": "ಸಂದೇಶವನ್ನು ನಮೂದಿಸಿ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.",
        "sensitive": "ಈ ಸಂದೇಶವು OTP ಅಥವಾ UPI PIN ನಂತಹ ರಹಸ್ಯ ಮಾಹಿತಿಯನ್ನು ಕೇಳುತ್ತದೆ.",
        "threat": "ಖಾತೆಯನ್ನು ನಿರ್ಬಂಧಿಸುವುದಾಗಿ ಈ ಸಂದೇಶ ಬೆದರಿಸುತ್ತದೆ.",
        "urgency": "ಈ ಸಂದೇಶದಲ್ಲಿ ತುರ್ತು ಒತ್ತಡ, ಅನುಮಾನಾಸ್ಪದ ಲಿಂಕ್ ಅಥವಾ ಬಹುಮಾನ/ಪಾವತಿಯ ಆಮಿಷವಿದೆ.",
        "no_match": "ನಾವು ಪರಿಶೀಲಿಸಿದ ಎಚ್ಚರಿಕೆಯ ಪದಗಳು ಕಂಡುಬಂದಿಲ್ಲ. ಆದರೂ ಇತರ ವಂಚನೆಗಳು ಇರಬಹುದು.",
        "high_action": "ನಿಮ್ಮ OTP ಅಥವಾ UPI PIN ಅನ್ನು ಯಾರಿಗೂ ಹಂಚಬೇಡಿ. ಅನುಮಾನಾಸ್ಪದ ಸೂಚನೆಗಳನ್ನು ಪಾಲಿಸಬೇಡಿ. ನಿಮ್ಮ ಬ್ಯಾಂಕಿನ ಅಧಿಕೃತ ಮಾರ್ಗಗಳ ಮೂಲಕ ಪರಿಶೀಲಿಸಿ.",
        "medium_action": "ತಕ್ಷಣ ಕ್ರಮ ಕೈಗೊಳ್ಳಬೇಡಿ. ಕಳುಹಿಸಿದವರನ್ನು ಸ್ವತಂತ್ರವಾಗಿ ಪರಿಶೀಲಿಸಿ. ಅಪರಿಚಿತ ಲಿಂಕ್‌ಗಳು ಮತ್ತು ಅನಿರೀಕ್ಷಿತ ಪಾವತಿ ವಿನಂತಿಗಳನ್ನು ತಪ್ಪಿಸಿ.",
        "unknown_action": "ಈ ಸಂದೇಶ ಸುರಕ್ಷಿತವಾಗಿದೆ ಎಂದು ಊಹಿಸಬೇಡಿ. ಕಳುಹಿಸಿದವರು ಮತ್ತು ಪಾವತಿ ವಿನಂತಿಯನ್ನು ಸ್ವತಂತ್ರವಾಗಿ ಪರಿಶೀಲಿಸಿ.",
        "disclaimer": "ಈ ಸಾಧನ ಕೆಲವು ಆಯ್ದ ಎಚ್ಚರಿಕೆಯ ಲಕ್ಷಣಗಳನ್ನು ಮಾತ್ರ ಪರಿಶೀಲಿಸುತ್ತದೆ; ಸಂದೇಶ ಸುರಕ್ಷಿತವೆಂದು ಖಚಿತಪಡಿಸುವುದಿಲ್ಲ.",
    },
    "hi": {
        "empty": "कोई संदेश नहीं दिया गया।",
        "enter": "संदेश लिखें और फिर कोशिश करें।",
        "sensitive": "यह संदेश OTP या UPI PIN जैसी गोपनीय जानकारी माँगता है।",
        "threat": "यह संदेश बैंक खाता बंद करने की धमकी देता है।",
        "urgency": "इस संदेश में जल्दबाज़ी, संदिग्ध लिंक या इनाम/भुगतान का लालच है।",
        "no_match": "चुने गए चेतावनी वाले शब्द नहीं मिले। फिर भी अन्य धोखाधड़ी हो सकती है।",
        "high_action": "अपना OTP या UPI PIN किसी के साथ साझा न करें। संदिग्ध निर्देशों का पालन न करें। अपने बैंक के आधिकारिक माध्यम से जाँच करें।",
        "medium_action": "कोई कदम उठाने से पहले रुकें। भेजने वाले की स्वतंत्र रूप से पुष्टि करें और अनजान लिंक या अचानक आए भुगतान अनुरोधों से बचें।",
        "unknown_action": "यह न मानें कि संदेश सुरक्षित है। भेजने वाले और भुगतान अनुरोध की स्वतंत्र रूप से पुष्टि करें।",
        "disclaimer": "यह टूल केवल कुछ चुने हुए चेतावनी संकेतों की जाँच करता है और संदेश के सुरक्षित होने की गारंटी नहीं देता।",
    },
}


# ---------- Phrase-Based Scam Detection ----------

HIGH_GROUPS = {
    "sensitive": [
        # English
        "share your otp",
        "share otp",
        "send otp immediately",
        "share your upi pin",
        "tell me your upi pin",
        "enter your pin to receive money",
        "reveal your otp",
        "send me your otp",
        "tell me the otp",

        # Kannada
        "ನಿಮ್ಮ otp ಹಂಚಿ",
        "ಒಟಿಪಿ ಹಂಚಿ",
        "ಒಟಿಪಿ ತಿಳಿಸಿ",
        "ನಿಮ್ಮ ಪಿನ್ ತಿಳಿಸಿ",
        "ಯುಪಿಐ ಪಿನ್ ಹಂಚಿ",
        "ಒಟಿಪಿ ಕಳುಹಿಸಿ",

        # Hindi
        "अपना otp साझा करें",
        "ओटीपी साझा करें",
        "ओटीपी बताएं",
        "अपना ओटीपी बताएं",
        "अपना यूपीआई पिन बताएं",
        "पिन साझा करें",
        "ओटीपी भेजें",
    ],
    "threat": [
        "account will be blocked",
        "account blocked",
        "your account will be suspended",
        "ನಿಮ್ಮ ಖಾತೆ ನಿರ್ಬಂಧಿಸಲಾಗುತ್ತದೆ",
        "ಖಾತೆ ನಿರ್ಬಂಧಿಸಲಾಗುತ್ತದೆ",
        "ಖಾತೆ ಬಂದ್ ಆಗುತ್ತದೆ",
        "आपका खाता बंद हो जाएगा",
        "खाता बंद कर दिया जाएगा",
        "आपका अकाउंट ब्लॉक हो जाएगा",
    ],
}

MEDIUM_PHRASES = [
    "urgent payment",
    "claim your prize",
    "click this link",
    "verify your account immediately",
    "limited time offer",
    "send money immediately",
    "ನಿಮ್ಮ ಬಹುಮಾನ ಪಡೆಯಿರಿ",
    "ಈ ಲಿಂಕ್ ಕ್ಲಿಕ್ ಮಾಡಿ",
    "ತಕ್ಷಣ ಹಣ ಕಳುಹಿಸಿ",
    "ತಕ್ಷಣ ಪರಿಶೀಲಿಸಿ",
    "ಬಹುಮಾನ ಗೆದ್ದಿದ್ದೀರಿ",
    "इनाम पाने के लिए",
    "इस लिंक पर क्लिक करें",
    "तुरंत पैसे भेजें",
    "तुरंत सत्यापित करें",
    "आपने इनाम जीता है",
    "सीमित समय का ऑफर",
]


@app.route("/", methods=["GET"])
def home():
    return jsonify({
        "app": "Easy Pay - Safe Pay",
        "status": "running"
    })


@app.route("/api/health", methods=["GET"])
def health():
    return jsonify({
        "status": "healthy",
        "ai_configured": client is not None
    })


@app.route("/api/analyze", methods=["POST"])
def analyze_message():
    data = request.get_json(silent=True) or {}

    raw_message = data.get("message", "")
    language = str(data.get("language", "en")).lower()

    if language not in TEXT:
        language = "en"

    t = TEXT[language]
    message = str(raw_message).strip().lower()

    if not message:
        return jsonify({
            "risk": "unverified",
            "reasons": [t["empty"]],
            "action": t["enter"],
            "disclaimer": t["disclaimer"],
            "language": language
        }), 400

    reasons = []
    high_risk = False

    for group, phrases in HIGH_GROUPS.items():
        if any(phrase.lower() in message for phrase in phrases):
            high_risk = True
            reasons.append(t[group])

    if any(phrase.lower() in message for phrase in MEDIUM_PHRASES):
        reasons.append(t["urgency"])

    if high_risk:
        risk = "high"
        action = t["high_action"]
    elif reasons:
        risk = "medium"
        action = t["medium_action"]
    else:
        risk = "unverified"
        action = t["unknown_action"]
        reasons.append(t["no_match"])

    return jsonify({
        "risk": risk,
        "reasons": reasons,
        "action": action,
        "disclaimer": t["disclaimer"],
        "language": language
    })


# ---------- Groq AI Assistant ----------

@app.route("/api/ai-help", methods=["POST"])
def ai_help():
    if not client:
        return jsonify({
            "error": "GROQ_API_KEY is missing. Configure it in your .env file."
        }), 500

    data = request.get_json(silent=True) or {}

    prompt = str(data.get("prompt", "")).strip()
    language = str(data.get("language", "en")).lower()

    if not prompt:
        return jsonify({
            "error": "Please enter a question."
        }), 400

    if len(prompt) > 4000:
        return jsonify({
            "error": "Please keep your question under 4000 characters."
        }), 400

    language_names = {
        "en": "simple English",
        "kn": "Kannada",
        "hi": "Hindi"
    }

    target_language = language_names.get(language, "simple English")

    system_instruction = f"""
    You are the EASY PAY - SAFE PAY assistant,
    helping older adults in India use digital payments safely.

    Respond in {target_language}.
    Use short sentences and simple words.
    Explain instructions one step at a time.
    Be patient, respectful, and encouraging.

    Never ask users to reveal their OTP, UPI PIN,
    password, or banking credentials.

    Never tell users to enter their PIN to receive money.
    Recommend official app stores and official bank channels.
    Never claim that you checked a bank account or transaction.

    If a user suspects fraud, advise them to contact their bank
    immediately and report cybercrime through official channels.
    """

    try:
        response = client.chat.completions.create(
            model=MODEL_NAME,
            messages=[
                {
                    "role": "system",
                    "content": system_instruction
                },
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            max_completion_tokens=500
        )

        answer = response.choices[0].message.content

        return jsonify({
            "response": answer or "Please try asking again.",
            "language": language
        })

    except Exception:
        app.logger.exception("Groq AI request failed")

        return jsonify({
            "error": "The AI service is temporarily unavailable. Please try again."
        }), 502


# ---------- Suspicious UPI ID Reports ----------

REPORTS_FILE = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "upi_reports.json"
)


def load_upi_reports():
    """Load saved reports, or return an empty list."""
    if not os.path.exists(REPORTS_FILE):
        return []

    try:
        with open(REPORTS_FILE, "r", encoding="utf-8") as file:
            reports = json.load(file)

            return reports if isinstance(reports, list) else []

    except (json.JSONDecodeError, OSError):
        return []


@app.route("/api/upi/reports", methods=["GET"])
def get_upi_reports():
    reports = load_upi_reports()

    upi_id = request.args.get("upi_id", "").strip().lower()

    if upi_id:
        reports = [
            report for report in reports
            if report.get("upi_id", "").lower() == upi_id
        ]

    reports.sort(
        key=lambda report: report.get("created_at", ""),
        reverse=True
    )

    return jsonify({
        "reports": reports,
        "count": len(reports),
        "disclaimer": "Reports are user-submitted and unverified."
    })


@app.route("/api/upi/reports", methods=["POST"])
def submit_upi_report():
    data = request.get_json(silent=True) or {}

    upi_id = str(data.get("upi_id", "")).strip().lower()
    reason = str(data.get("reason", "")).strip()
    description = str(data.get("description", "")).strip()

    if not re.fullmatch(
        r"[A-Za-z0-9._-]{2,256}@[A-Za-z0-9.-]{2,64}",
        upi_id
    ):
        return jsonify({
            "error": "Enter a valid-looking UPI ID format."
        }), 400

    allowed_reasons = {
        "Asked for UPI PIN or OTP",
        "Suspicious payment request",
        "Possible impersonation",
        "Money deducted unexpectedly",
        "Other"
    }

    if reason not in allowed_reasons:
        return jsonify({
            "error": "Select a valid report reason."
        }), 400

    if len(description) > 500:
        return jsonify({
            "error": "Description must be 500 characters or less."
        }), 400

    reports = load_upi_reports()

    report = {
        "id": str(
            int(datetime.now(timezone.utc).timestamp() * 1000)
        ),
        "upi_id": upi_id,
        "reason": reason,
        "description": description,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "status": "unverified"
    }

    reports.append(report)

    try:
        with open(REPORTS_FILE, "w", encoding="utf-8") as file:
            json.dump(
                reports,
                file,
                ensure_ascii=False,
                indent=2
            )

    except OSError:
        return jsonify({
            "error": "Could not save the report."
        }), 500

    return jsonify({
        "message": "Report submitted successfully.",
        "report": report,
        "disclaimer": "This is an unverified user submission."
    }), 201


# ---------- Start Application ----------

if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=int(os.getenv("PORT", "5001")),
        debug=os.getenv("FLASK_DEBUG", "false").lower() == "true"
    )