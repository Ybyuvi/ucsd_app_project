import os
import json
import openai
import PyPDF2
from zoneinfo import ZoneInfo

from flask import Flask, request, redirect, flash, url_for, render_template_string, session, abort
from functools import wraps

import google.auth.transport.requests
from google.oauth2 import id_token, credentials
from google_auth_oauthlib.flow import Flow
from googleapiclient.discovery import build
import requests
from pip._vendor import cachecontrol
from datetime import datetime, timedelta

# ========= CONFIGURATION =========
app = Flask(__name__)
app.secret_key = os.urandom(24)

# For local testing: allow non-HTTPS redirect
os.environ["OAUTHLIB_INSECURE_TRANSPORT"] = "1"

# Replace with your actual Google client ID and path to client secrets
GOOGLE_CLIENT_ID = "829956076330-iuu3isoeb74m5acl22185s3m6n0ttsfh.apps.googleusercontent.com"
client_secrets = {
    "web": {
        "client_id": os.environ["GOOGLE_CLIENT_ID"],
        "project_id": os.environ.get("GOOGLE_PROJECT_ID", ""),
        "auth_uri": os.environ.get("GOOGLE_AUTH_URI", "https://accounts.google.com/o/oauth2/auth"),
        "token_uri": os.environ.get("GOOGLE_TOKEN_URI", "https://oauth2.googleapis.com/token"),
        "auth_provider_x509_cert_url": os.environ.get("GOOGLE_AUTH_PROVIDER", "https://accounts.google.com"),
        "client_secret": os.environ["GOOGLE_CLIENT_SECRET"],
        "redirect_uris": [os.environ["GOOGLE_REDIRECT_URIS"]]
    }
}


# Replace with your real OpenAI API key
openai.api_key = os.environ["OPENAI_API_KEY"]

# Set up the OAuth flow, including Calendar scope
flow = Flow.from_client_config(
    client_secrets,
    scopes=[
        "https://www.googleapis.com/auth/userinfo.profile",
        "https://www.googleapis.com/auth/userinfo.email",
        "openid",
        "https://www.googleapis.com/auth/calendar.events"
    ],
    redirect_uri=client_secrets["web"]["redirect_uris"][0]
)


# ========= DECORATOR =========
def login_is_required(func):
    """Require a valid Google login session to access certain routes."""
    @wraps(func)
    def wrapper(*args, **kwargs):
        if "google_id" not in session:
            return abort(401)  # Not logged in
        return func(*args, **kwargs)
    return wrapper

# ========= HTML TEMPLATES =========
INDEX_HTML = """
<!doctype html>
<html>
  <head><title>PDF -> Google Calendar</title></head>
  <body>
    <h1>Welcome!</h1>
    <p><a href="/login"><button>Log in with Google</button></a></p>
  </body>
</html>
"""

UPLOAD_HTML = """
<!doctype html>
<html>
  <head><title>Upload PDF</title></head>
  <body>
    <h1>Upload Your Class Schedule PDF</h1>
    <form method="POST" enctype="multipart/form-data">
      <input type="file" name="file" accept="application/pdf" required>
      <input type="submit" value="Upload">
    </form>
    <a href="/logout"><button>Logout</button></a>
    {% with messages = get_flashed_messages() %}
      {% if messages %}
        <ul>
          {% for message in messages %}
          <li>{{ message }}</li>
          {% endfor %}
        </ul>
      {% endif %}
    {% endwith %}
  </body>
</html>
"""

PREVIEW_HTML = """
<!doctype html>
<html>
  <head><title>Schedule Preview</title></head>
  <body>
    <h1>Schedule Preview</h1>
    <h2>Extracted PDF Text</h2>
    <pre style="background-color:#eee; padding:10px;">{{ pdf_text }}</pre>

    <h2>GPT Organized Schedule (JSON)</h2>
    <pre style="background-color:#eee; padding:10px;">{{ schedule_text }}</pre>

    <h2>Import to Google Calendar</h2>
    <p>Click this button to POST schedule data to /import-to-calendar.</p>
    <button id="importBtn">Import to Google Calendar</button>

    <script>
        const scheduleData = {{ schedule_json|tojson }};
        
        document.getElementById("importBtn").addEventListener("click", importToCalendar);

        function importToCalendar() {
            const btn = document.getElementById("importBtn");
            btn.disabled = true;
            btn.textContent = "Importing...";
            
            console.log("Sending data:", scheduleData);
            
            fetch("/import-to-calendar", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json"
                },
                body: JSON.stringify(scheduleData)
            })
            .then(response => {
                if (!response.ok) {
                    throw new Error(`HTTP error! status: ${response.status}`);
                }
                return response.json();
            })
            .then(data => {
                console.log("Response:", data);
                alert("Successfully imported: " + (data.created || []).join(", "));
            })
            .catch(error => {
                console.error("Error:", error);
                alert("Error importing: " + error.message);
            })
            .finally(() => {
                btn.disabled = false;
                btn.textContent = "Import to Google Calendar";
            });
        }
    </script>

    <hr>
    <a href="/logout"><button>Logout</button></a>
  </body>
</html>
"""

# ========= ROUTES =========
@app.route("/")
def index():
    return render_template_string(INDEX_HTML)

@app.route("/login")
def login():
    authorization_url, state = flow.authorization_url()
    session["state"] = state
    return redirect(authorization_url)

@app.route("/callback")
def callback():
    # Finish the OAuth handshake
    flow.fetch_token(authorization_response=request.url)

    if session.get("state") != request.args.get("state"):
        return abort(500)  # State mismatch

    creds = flow.credentials
    # Validate token
    request_session = requests.session()
    cached_session = cachecontrol.CacheControl(request_session)
    token_request = google.auth.transport.requests.Request(session=cached_session)

    id_info = id_token.verify_oauth2_token(
        creds._id_token, token_request, GOOGLE_CLIENT_ID
    )

    # Store relevant data in session
    session["google_id"] = id_info.get("sub")
    session["name"] = id_info.get("name")
    session["credentials"] = {
        "token": creds.token,
        "refresh_token": creds.refresh_token,
        "token_uri": creds.token_uri,
        "client_id": creds.client_id,
        "client_secret": creds.client_secret,
        "scopes": creds.scopes
    }

    return redirect("/upload")

@app.route("/logout")
def logout():
    session.clear()
    return redirect("/")

@app.route("/upload", methods=["GET", "POST"])
@login_is_required
def upload():
    if request.method == "POST":
        # 1) Check file
        file = request.files.get("file")
        if not file or file.filename == "":
            flash("No file selected.")
            return redirect(request.url)

        # 2) Extract text from PDF
        try:
            pdf_reader = PyPDF2.PdfReader(file)
            pdf_text = "\n".join(page.extract_text() or "" for page in pdf_reader.pages)
        except Exception as e:
            flash(f"Error reading PDF: {e}")
            return redirect(request.url)

        if not pdf_text.strip():
            flash("PDF has no readable text.")
            return redirect(request.url)

        # 3) Prompt GPT to parse schedule
        prompt = f"""
You are an assistant that converts a PDF class schedule into an organized JSON format:
- weeklyEvents: a list of events that repeat each week
- exams: any tests or finals
Use the format:
{{
  "weeklyEvents": [
    {{
      "title": "...",
      "instructor": "...",
      "location": "...",
      "days": ["Monday","Wednesday"],
      "startTime": "7:00a",
      "endTime": "7:50a"
    }}
  ],
  "exams": [
    {{
      "title": "...",
      "type": "Midterm",
      "date": "04/24/2025",
      "startTime": "8:00p",
      "endTime": "9:50p",
      "location": "..."
    }}
  ]
}}

Raw PDF text:
{pdf_text}
"""
        try:
            response = openai.ChatCompletion.create(
                model="gpt-4",
                messages=[{"role": "user", "content": prompt}],
                temperature=0
            )
            schedule_text = response.choices[0].message.content.strip()
        except Exception as e:
            flash(f"OpenAI API error: {e}")
            return redirect(request.url)

        # 4) Validate the JSON
        try:
            schedule_json = json.loads(schedule_text)
        except json.JSONDecodeError:
            flash("GPT response is not valid JSON.")
            schedule_json = {}

        # 5) Render preview page
        return render_template_string(
            PREVIEW_HTML,
            pdf_text=pdf_text,
            schedule_text=schedule_text,
            schedule_json=schedule_json
        )

    return render_template_string(UPLOAD_HTML)

@app.route("/import-to-calendar", methods=["POST"])
@login_is_required
def import_to_calendar():
    """Take the schedule JSON and create events in the user's Google Calendar with proper timezone."""
    schedule_data = request.json or {}
    creds_data = session.get("credentials")

    if not creds_data:
        return {"status": "error", "message": "No credentials in session"}

    # Rebuild credentials and build the Calendar service
    creds = credentials.Credentials(**creds_data)
    service = build("calendar", "v3", credentials=creds)

    events_created = []
    la_tz = ZoneInfo("America/Los_Angeles")  # Define the LA timezone

    def create_event(title, location, start_dt, end_dt, is_weekly=False):
        print(f"Creating: {title} from {start_dt} to {end_dt}")
        event_body = {
            "summary": title,
            "location": location,
            "start": {
                "dateTime": start_dt.isoformat(), 
                "timeZone": "America/Los_Angeles"
            },
            "end": {
                "dateTime": end_dt.isoformat(), 
                "timeZone": "America/Los_Angeles"
            },
        }
        if is_weekly:
            event_body["recurrence"] = ["RRULE:FREQ=WEEKLY;UNTIL=20250613T235959Z"]

        created_event = service.events().insert(calendarId="primary", body=event_body).execute()
        events_created.append(created_event.get("summary", "Untitled Event"))

    # Helper: convert "11:00a" or "7:00p" to a time object (naive)
    def parse_12h_time(tstr):
        tstr = tstr.strip().lower().replace(" ", "")
        # Normalize abbreviations like "11:30a" or "7:00p" to "11:30am" / "7:00pm"
        if tstr.endswith("a") or tstr.endswith("p"):
            tstr = tstr[:-1] + ("am" if tstr.endswith("a") else "pm")
        return datetime.strptime(tstr, "%I:%M%p").time()

    # Day-of-week map for weekly events
    days_map = {
        "Monday": 0, "Tuesday": 1, "Wednesday": 2,
        "Thursday": 3, "Friday": 4, "Saturday": 5, "Sunday": 6
    }

    base_date = datetime(2025, 3, 31)  # Monday of Spring Quarter 2025

    # Process Weekly Events
    for ev in schedule_data.get("weeklyEvents", []):
        title = ev.get("title", "Untitled")
        location = ev.get("location", "")
        days = ev.get("days", [])
        try:
            start_time = parse_12h_time(ev["startTime"])  # returns a time object
            end_time = parse_12h_time(ev["endTime"])
        except Exception as e:
            print(f"Error parsing time: {e}")
            continue

        for day in days:
            if day not in days_map:
                continue
            offset = (days_map[day] - base_date.weekday()) % 7
            event_date = base_date + timedelta(days=offset)
            # Combine the date and time, then attach the LA timezone
            start_dt = datetime.combine(event_date.date(), start_time).replace(tzinfo=la_tz)
            end_dt = datetime.combine(event_date.date(), end_time).replace(tzinfo=la_tz)
            create_event(title, location, start_dt, end_dt, is_weekly=True)

    # Process Exams
    for exam in schedule_data.get("exams", []):
        title = f"{exam.get('title', 'Exam')} - {exam.get('type', 'Exam')}"
        location = exam.get("location", "")
        try:
            exam_date = datetime.strptime(exam["date"], "%m/%d/%Y").date()
            start_time = parse_12h_time(exam["startTime"])
            end_time = parse_12h_time(exam["endTime"])
            start_dt = datetime.combine(exam_date, start_time).replace(tzinfo=la_tz)
            end_dt = datetime.combine(exam_date, end_time).replace(tzinfo=la_tz)
            create_event(title, location, start_dt, end_dt, is_weekly=False)
        except Exception as e:
            print(f"Error processing exam: {e}")
            continue

    return {"status": "success", "created": events_created}



# ========= MAIN =========
if __name__ == "__main__":
    app.run(debug=True)