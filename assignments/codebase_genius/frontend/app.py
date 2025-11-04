import streamlit as st
import requests
import os
import json

# ---------------------------
# Configuration
# ---------------------------
BACKEND_URL = "http://localhost:8000/walker"
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
    """Safe backend call — never returns None."""
    try:
        response = requests.post(endpoint, json=payload, timeout=timeout)

        # Non-200 response
        if response.status_code != 200:
            return {
                "status": "error",
                "message": f"Backend returned {response.status_code}: {response.text}",
            }

        # If markdown directly returned
        if response.headers.get("content-type", "").startswith("text/markdown"):
            return {"status": "valid", "markdown": response.text}

        # Try JSON
        try:
            result = response.json()
        except Exception:
            return {"status": "error", "message": "Invalid JSON response from backend."}

        reports = result.get("report") or result.get("reports")
        if not reports:
            return {"status": "error", "message": "No reports returned from backend."}

        first = reports[0]

        # Handle JSON-encoded strings
        if isinstance(first, str):
            try:
                parsed = json.loads(first)
                return {
                    "status": parsed.get("status", "valid"),
                    "message": parsed.get("message", ""),
                    "data": parsed,
                }
            except json.JSONDecodeError:
                msg = first.strip()
                if msg.lower().startswith("success"):
                    return {"status": "valid", "message": msg.replace("Success:", "").strip()}
                elif msg.lower().startswith("error"):
                    return {"status": "invalid", "message": msg.replace("Error:", "").strip()}
                else:
                    return {"status": "valid", "message": msg}

        # Handle dict reports
        if isinstance(first, dict):
            message = first.get("message", "")
            valid = first.get("valid", True)
            return {"status": "valid" if valid else "invalid", "message": message, "data": first}

        # Fallback
        return {"status": "error", "message": f"Unexpected report format: {first}"}

    except requests.exceptions.RequestException as e:
        return {"status": "error", "message": f"Failed to connect to backend: {e}"}
    except Exception as e:
        return {"status": "error", "message": f"Unexpected error: {e}"}


# ---------------------------
# Logic when button clicked
# ---------------------------
if generate_button:
    if not github_url.strip():
        st.error("❌ Please enter a GitHub URL before proceeding.")
    else:
        # STEP 1: Validate URL
        with st.spinner("🔍 Validating GitHub URL..."):
            validation = send_to_backend(VALIDATE_ENDPOINT, {"url": github_url.strip()}, timeout=300)

        if validation.get("status") == "invalid":
            st.error(validation.get("message", "Invalid repository."))
            st.stop()
        elif validation.get("status") == "error":
            st.error(validation.get("message", "Validation failed."))
            st.stop()

        st.success(f"✅ {validation.get('message', 'Repository validated successfully.')}")

        # STEP 2: Clone Repo
        with st.spinner("🌀 Cloning repository..."):
            cloning = send_to_backend(CLONE_ENDPOINT, {"url": github_url.strip()}, timeout=300)
        if cloning.get("status") != "valid":
            st.error(f"❌ Cloning failed: {cloning.get('message', '')}")
            st.stop()
        st.success(f"📦 {cloning.get('message', '')}")

        # STEP 3: File Tree
        with st.spinner("🌲 Building file tree..."):
            file_tree = send_to_backend(FILE_TREE_ENDPOINT, {"url": github_url.strip()}, timeout=300)
        if file_tree.get("status") != "valid":
            st.error(f"❌ File tree generation failed: {file_tree.get('message', '')}")
            st.stop()
        st.success(f"🌳 {file_tree.get('message', '')}")

        # STEP 4: Generate Docs
        with st.spinner("📚 Generating documentation... please wait..."):
            generate_docs = send_to_backend(GENERATE_DOCS_ENDPOINT, {"url": github_url.strip()}, timeout=900)

        # ✅ Ensure safe fallback
        if not generate_docs or not isinstance(generate_docs, dict):
            generate_docs = {"status": "error", "message": "No valid response from backend."}

        if generate_docs.get("status") == "valid":
            backend_data = generate_docs.get("data") or {}
            markdown_path = backend_data.get("markdown_path")

            if markdown_path and os.path.exists(markdown_path):
                with open(markdown_path, "r") as f:
                    markdown_data = f.read()
                st.success("✅ Documentation generated successfully!")
                st.download_button(
                    label="📄 Download Documentation (Markdown)",
                    data=markdown_data,
                    file_name="documentation.md",
                    mime="text/markdown",
                )
            else:
                st.success("✅ Documentation generated successfully!")
                st.info("⚠️ Markdown file not found or not accessible.")
        else:
            st.error(f"❌ Documentation generation failed: {generate_docs.get('message', 'Unknown error')}")
