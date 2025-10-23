import streamlit as st
import requests
import time

# ---------------------------
# Configuration
# ---------------------------
BACKEND_URL = "http://localhost:8000/walker/receiveurl"  # Adjust if your Jac server runs on another port

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
# Function to call backend
# ---------------------------
def send_to_backend(url: str):
    """Send the GitHub URL to the Jac backend and handle response."""
    try:
        response = requests.post(BACKEND_URL, json={"url": url}, timeout=240)
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
# Logic when button clicked
# ---------------------------
if generate_button:
    if not github_url.strip():
        st.error("❌ Please enter a GitHub URL before proceeding.")
    else:
        with st.spinner("🔍 Validating GitHub URL..."):
            validation = send_to_backend(github_url.strip())
            # time.sleep(1)  # small UX delay for smoother experience

        if validation["status"] == "invalid":
            st.error(validation["message"])

        elif validation["status"] == "error":
            st.error(f"⚠️ Backend error: {validation['message']}")

        elif validation["status"] == "valid":
            st.success(validation["message"])

            # Now simulate document generation phase
            with st.spinner("🧠 Generating docs... this may take a few moments."):
                try:
                    # Simulated wait while backend processes (you’ll replace this later with actual API)
                    time.sleep(5)

                    # Example final call to fetch generated documentation (later)
                    # response = requests.get(f"{BACKEND_URL}/output?repo={repo_name}")
                    # For now, simulate success
                    st.success("✅ Documentation generated successfully!")
                    st.download_button(
                        label="📄 Download Documentation (Markdown)",
                        data="# Example Documentation\n\nThis is a placeholder doc.",
                        file_name="docs.md",
                        mime="text/markdown"
                    )

                except Exception as e:
                    st.error(f"❌ Failed to retrieve documentation: {e}")