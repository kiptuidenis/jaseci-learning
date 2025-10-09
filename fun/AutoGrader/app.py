# app.py
import os
import re
import shutil
import tempfile
from git import Repo
import streamlit as st

# 👇 Import Jac language support
import jaclang  
from grader import grade_student_code  # Import from grader.jac

# --- Python helper ---
def extract_code_files(repo_url, extensions=(".jac", ".py", ".txt")):
    import re
    match = re.match(r"(https://github\.com/[^/]+/[^/]+)(/tree/[^/]+/(.*))?", repo_url.strip())
    if not match:
        raise ValueError("Invalid GitHub URL format")

    base_repo = match.group(1) + ".git"
    subdir = match.group(3) or ""

    temp_dir = tempfile.mkdtemp()
    Repo.clone_from(base_repo, temp_dir)

    target_dir = os.path.join(temp_dir, subdir) if subdir else temp_dir
    if not os.path.exists(target_dir):
        raise FileNotFoundError(f"Subfolder '{subdir}' not found in repo")

    code_data = {}
    for root, _, files in os.walk(target_dir):
        for file in files:
            if file.endswith(extensions):
                path = os.path.join(root, file)
                try:
                    with open(path, "r", encoding="utf-8", errors="ignore") as f:
                        relative = os.path.relpath(path, target_dir)
                        code_data[relative] = f.read()
                except Exception as e:
                    print(f"Skipping {path}: {e}")

    shutil.rmtree(temp_dir)
    return code_data



# --- Streamlit UI ---
st.set_page_config(page_title="AutoGrader", page_icon="🧠", layout="centered")
st.title("🤖 AutoGrader")
st.markdown("Paste your **GitHub repo URL** below and click Grade Now. *(For fun only)*")

repo_url = st.text_input("🔗 GitHub Repository URL", placeholder="https://github.com/username/repo")

if st.button("🚀 Grade Now"):
    if not repo_url.startswith("https://github.com/"):
        st.error("Please enter a valid GitHub repository link.")
    else:
        with st.spinner("Grading... ⏳"):
            code_files = extract_code_files(repo_url, extensions=(".jac",))

            rubric_path = os.path.join(os.path.dirname(__file__), "rubric.txt")
            if not os.path.exists(rubric_path):
                st.error("Rubric file not found. Please add rubric.txt next to this script.")
            else:
                with open(rubric_path, "r", encoding="utf-8") as f:
                    rubric_text = f.read()

                # 👇 Call the Jac function directly
                result = grade_student_code(rubric_text, code_files)

                st.success("✅ Grading complete!")
                st.subheader("📊 Results")
                for key, value in result.items():
                    st.write(f"**{key.title()}**: {value}")
