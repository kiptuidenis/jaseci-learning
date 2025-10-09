# app.py
import os
import re
import shutil
import tempfile
from git import Repo
import streamlit as st
import jaclang  
from grader import grade_student_code  # from grader.jac


# --- Helper Function ---
def extract_code_files(repo_url, extensions=(".jac", ".py", ".txt")):
    """
    Clone a GitHub repo or subfolder and return a dictionary of code files.
    Handles URLs like:
      - https://github.com/user/repo
      - https://github.com/user/repo/tree/main/folder
    """
    match = re.match(r"^https://github\.com/([^/]+)/([^/]+)(?:/tree/[^/]+/(.*))?$", repo_url.strip())
    if not match:
        raise ValueError("❌ Invalid GitHub URL. Please paste a valid repository link (not a profile link).")

    user, repo, subdir = match.groups()
    base_repo = f"https://github.com/{user}/{repo}.git"
    temp_dir = tempfile.mkdtemp()

    try:
        Repo.clone_from(base_repo, temp_dir)
    except Exception as e:
        shutil.rmtree(temp_dir)
        raise ValueError(f"⚠️ Failed to clone repository: {e}")

    target_dir = os.path.join(temp_dir, subdir) if subdir else temp_dir
    if not os.path.exists(target_dir):
        shutil.rmtree(temp_dir)
        raise FileNotFoundError(f"📁 Subfolder '{subdir}' not found in repository.")

    code_data = {}
    for root, _, files in os.walk(target_dir):
        for file in files:
            if file.endswith(extensions):
                path = os.path.join(root, file)
                try:
                    with open(path, "r", encoding="utf-8", errors="ignore") as f:
                        rel = os.path.relpath(path, target_dir)
                        code_data[rel] = f.read()
                except Exception as e:
                    print(f"Skipping {path}: {e}")

    shutil.rmtree(temp_dir)
    return code_data


# --- Streamlit UI ---
st.set_page_config(page_title="AutoGrader", page_icon="🧠", layout="centered")
st.title("🤖 AutoGrader")
st.markdown("Paste your **GitHub repo URL** below and click *Grade Now*. *(For fun only)*")

repo_url = st.text_input("🔗 GitHub Repository URL", placeholder="https://github.com/username/repo")

# ✅ Optional rubric upload
st.markdown("### 📝 Rubric Selection")
uploaded_rubric = st.file_uploader("Upload your own rubric (optional)", type=["txt"])

use_default_rubric = st.checkbox("Use default rubric", value=True if not uploaded_rubric else False)

if st.button("🚀 Grade Now"):
    if not repo_url.startswith("https://github.com/"):
        st.error("Please enter a valid GitHub repository link.")
    else:
        try:
            with st.spinner("Grading... ⏳"):
                code_files = extract_code_files(repo_url, extensions=(".jac",))

                # --- Rubric logic ---
                if uploaded_rubric is not None and not use_default_rubric:
                    rubric_text = uploaded_rubric.read().decode("utf-8", errors="ignore")
                else:
                    rubric_path = os.path.join(os.path.dirname(__file__), "rubric.txt")
                    if not os.path.exists(rubric_path):
                        st.error("❌ Default rubric file not found. Please upload one.")
                        st.stop()
                    with open(rubric_path, "r", encoding="utf-8") as f:
                        rubric_text = f.read()

                # --- Grade using Jac ---
                result = grade_student_code(rubric_text, code_files)

                st.success("✅ Grading complete!")
                st.subheader("📊 Results")
                for key, value in result.items():
                    st.write(f"**{key.title()}**: {value}")

        except ValueError as e:
            st.error(str(e))
        except FileNotFoundError as e:
            st.error(str(e))
        except Exception as e:
            st.error(f"❌ Unexpected error: {e}")
