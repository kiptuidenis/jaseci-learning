import streamlit as st
import requests
import time

# ---------------------------
# Configuration
# ---------------------------
BACKEND_URL_VALIDATE = "http://localhost:8000/walker/receiveurl"  # Validation walker
BACKEND_URL_CLONE = "http://localhost:8000/walker/delegate"       # Cloning walker

st.set_page_config(page_title="Codebase Genius", page_icon="🧠", layout="centered")

# ---------------------------
# UI Layout
# ---------------------------
st.title("🧠 Codebase Genius")
st.subheader("Autonomous Code Documentation Generator")

st.write("Enter a GitHub repository URL below and click **Generate Docs** to begin.")

github_url = st.text_input("🔗 GitHub Repository URL", placeholder="https://github.com/user/repo")

generate_button = st.button("Generate Docs")


# ---------------------------
# Helper functions
# ---------------------------
def send_to_backend(url: str, endpoint: str):
    """Send a POST request to the given Jac walker endpoint."""
    try:
        response = requests.post(endpoint, json={"url": url}, timeout=240)
        if response.status_code == 200:
            result = response.json()
            reports = result.get("report") or result.get("reports")

            if reports:
                message = reports[0].strip()
                if message.lower().startswith("success"):
                    return {"status": "valid", "message": message.replace("Success:", "").strip()}
                elif message.lower().startswith("error"):
                    return {"status": "invalid", "message": message.replace("Error:", "").strip()}
                else:
                    return {"status": "error", "message": f"Unexpected message: {message}"}
            else:
                return {"status": "error", "message": "No reports returned from backend."}
        else:
            return {"status": "error", "message": f"Backend returned {response.status_code}: {response.text}"}
    except requests.exceptions.RequestException as e:
        return {"status": "error", "message": f"Failed to connect to backend: {e}"}


# ---------------------------
# Main Logic
# ---------------------------
if generate_button:
    if not github_url.strip():
        st.error("❌ Please enter a GitHub URL before proceeding.")
    else:
        # Step 1: Validate the GitHub URL
        with st.spinner("🔍 Validating GitHub URL..."):
            validation = send_to_backend(github_url.strip(), BACKEND_URL_VALIDATE)

        if validation["status"] == "invalid":
            st.error(validation["message"])

        elif validation["status"] == "error":
            st.error(f"⚠️ Backend error: {validation['message']}")

        elif validation["status"] == "valid":
            st.success(validation["message"])

            # Step 2: Trigger repo cloning after validation
            with st.spinner("🌀 Cloning repository... please wait."):
                clone_status = send_to_backend(github_url.strip(), BACKEND_URL_CLONE)

            if clone_status["status"] == "valid":
                st.success(f"✅ Repository cloned successfully! {clone_status['message']}")
            elif clone_status["status"] == "invalid":
                st.error(f"❌ Cloning failed: {clone_status['message']}")
            else:
                st.error(f"⚠️ Unexpected cloning error: {clone_status['message']}")

            # Step 3: Simulate doc generation phase (placeholder for future)
            with st.spinner("🧠 Generating docs... this may take a few moments."):
                time.sleep(3)
                st.success("✅ Documentation generated successfully!")
                st.download_button(
                    label="📄 Download Documentation (Markdown)",
                    data="# Example Documentation\n\nThis is a placeholder doc.",
                    file_name="docs.md",
                    mime="text/markdown"
                )
