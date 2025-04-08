import os
import openai
import PyPDF2
import json
from flask import Flask, request, jsonify
from flask_cors import CORS  # Important to allow Flutter to access the API

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Set your OpenAI API key
openai.api_key = "829956076330-iuu3isoeb74m5acl22185s3m6n0ttsfh.apps.googleusercontent.com"

@app.route("/gpt-schedule", methods=["POST"])
def gpt_schedule():
    # 1. Get uploaded file
    file = request.files.get("file")
    if not file:
        return jsonify({"error": "No file uploaded"}), 400

    try:
        # 2. Extract text from PDF
        reader = PyPDF2.PdfReader(file)
        pdf_text = "\n".join([page.extract_text() or "" for page in reader.pages])
        if not pdf_text.strip():
            return jsonify({"error": "PDF has no readable text"}), 400

        # 3. Ask GPT to structure the schedule
        prompt = f"""
You are a helpful assistant that extracts structured schedule information from class registration PDFs.
Return a JSON object with two lists: "weeklyEvents" and "exams".

- weeklyEvents should look like:
  {{
    "title": "MATH 18",
    "instructor": "Anzaldo, Leesa B",
    "location": "YORK 2722",
    "days": ["Monday", "Wednesday", "Friday"],
    "startTime": "11:00a",
    "endTime": "11:50a"
  }}

- exams should look like:
  {{
    "title": "MATH 20C",
    "type": "Midterm",
    "date": "04/24/2025",
    "startTime": "8:00p",
    "endTime": "9:50p",
    "location": "PCYNH 109"
  }}

Only return valid JSON, no explanation.

PDF content:
{pdf_text}
"""

        response = openai.ChatCompletion.create(
            model="gpt-4",
            messages=[{"role": "user", "content": prompt}],
            temperature=0
        )
        gpt_output = response.choices[0].message.content.strip()

        # 4. Try to parse JSON
        try:
            parsed = json.loads(gpt_output)
            return jsonify({"status": "success", "data": parsed}), 200
        except json.JSONDecodeError:
            return jsonify({"status": "error", "raw_output": gpt_output, "message": "Invalid JSON"}), 500

    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(debug=True)

