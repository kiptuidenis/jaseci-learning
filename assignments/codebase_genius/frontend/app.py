import streamlit as st
import requests
import time

# ---------------------------
# Configuration
# ---------------------------
BACKEND_URL = "http://localhost:8000/walker"  # Base URL
VALIDATE_ENDPOINT = f"{BACKEND_URL}/receiveurl"
CLONE_ENDPOINT = f"{BACKEND_URL}/StartCloning"
FILE_TREE_ENDPOINT = f"{BACKEND_URL}/file_tree_generator"
GENERATE_DOCS_ENDPOINT = f"{BACKEND_URL}/BuildCCG"  # ✅ Combined CCG + Docs generation

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
# Helper: Send POST to Backend
# ---------------------------
def send_to_backend(endpoint: str, payload: dict, timeout=240):
    """Generic helper to send a POST request to backend."""
    try:
        response = requests.post(endpoint, json=payload, timeout=timeout)
        if response.status_code == 200:
            # If backend returns markdown directly (string)
            if response.headers.get("content-type", "").startswith("text/markdown"):
                return {"status": "valid", "markdown": response.text}

            result = response.json()
            reports = result.get("report") or result.get("reports")

            if reports:
                first = reports[0]
                if isinstance(first, dict):
                    message = first.get("message", str(first))
                    valid = first.get("valid", True)
                    return {"status": "valid" if valid else "invalid", "message": message}
                elif isinstance(first, str):
                    message = first.strip()
                    if message.lower().startswith("success"):
                        return {"status": "valid", "message": message.replace("Success:", "").strip()}
                    elif message.lower().startswith("error"):
                        return {"status": "invalid", "message": message.replace("Error:", "").strip()}
                else:
                    return {"status": "error", "message": f"Unexpected response: {first}"}
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
        # STEP 1: Validate GitHub URL
        with st.spinner("🔍 Validating GitHub URL..."):
            validation = send_to_backend(VALIDATE_ENDPOINT, {"url": github_url.strip()}, timeout=300)

        if validation["status"] == "invalid":
            st.error(validation["message"])

        elif validation["status"] == "error":
            st.error(f"⚠️ Backend error: {validation['message']}")

        elif validation["status"] == "valid":
            st.success(f"✅ {validation['message']}")

            # STEP 2: Clone Repository
            with st.spinner("🌀 Cloning repository... this may take a few moments."):
                cloning = send_to_backend(CLONE_ENDPOINT, {"url": github_url.strip()}, timeout=300)

            if cloning["status"] == "valid":
                st.success(f"📦 {cloning['message']}")

                # STEP 3: Generate File Tree
                with st.spinner("🌲 Building project file tree..."):
                    file_tree = send_to_backend(FILE_TREE_ENDPOINT, {"url": github_url.strip()}, timeout=300)

                if file_tree["status"] == "valid":
                    st.success(f"🌳 {file_tree['message']}")

                    # ✅ NEW MERGED STEP 4: Generate Docs (CCG + Markdown)
                    with st.spinner("📚 Generating documentation... this may take several minutes..."):
                        generate_docs = send_to_backend(GENERATE_DOCS_ENDPOINT, {"url": github_url.strip()}, timeout=600)

                    if generate_docs["status"] == "valid":
                        if "markdown" in generate_docs:
                            markdown_data = generate_docs["markdown"]
                            st.success("✅ Documentation generated successfully!")
                            st.download_button(
                                label="📄 Download Documentation (Markdown)",
                                data=markdown_data,
                                file_name="documentation.md",
                                mime="text/markdown"
                            )
                        else:
                            st.success(f"🧠 {generate_docs.get('message', 'Documentation generated successfully!')}")
                            st.info("⚠️ Backend did not return markdown content.")
                    else:
                        st.error(f"❌ Documentation generation failed: {generate_docs['message']}")
                else:
                    st.error(f"❌ File tree generation failed: {file_tree['message']}")
            else:
                st.error(f"❌ Cloning failed: {cloning['message']}")
