import from byllm.llm { Model }
import shutil;
import os;
import tempfile;
import from git { Repo }
import streamlit as st;

glob llm = Model(model_name="gemini/gemini-2.0-flash", verbose=False);

def grade_student_code(rubric: str, code_data: dict[str, str]) -> dict[str, str] by llm;

::py::
from urllib.parse import urlparse
import re

def extract_code_files(repo_url, extensions=(".jac", ".py", ".txt")):
    # Handle GitHub subfolder links like .../tree/main/folder/subfolder
    match = re.match(r"(https://github\.com/[^/]+/[^/]+)(/tree/[^/]+/(.*))?", repo_url.strip())
    if not match:
        raise ValueError("Invalid GitHub URL format")

    base_repo = match.group(1) + ".git"  # Cloneable URL
    subdir = match.group(3) or ""        # Optional subfolder inside repo

    temp_dir = tempfile.mkdtemp()
    Repo.clone_from(base_repo, temp_dir)

    # Navigate into subfolder if provided
    target_dir = os.path.join(temp_dir, subdir) if subdir else temp_dir
    if not os.path.exists(target_dir):
        raise FileNotFoundError(f"Subfolder '{subdir}' not found in repo")

    code_data = {}
    for root, _, files in os.walk(target_dir):
        for file in files:
            if file.endswith(extensions):
                file_path = os.path.join(root, file)
                try:
                    with open(file_path, "r", encoding="utf-8") as f:
                        relative_path = os.path.relpath(file_path, target_dir)
                        code_data[relative_path] = f.read()
                except Exception as e:
                    print(f"Skipping {file_path}: {e}")

    shutil.rmtree(temp_dir)
    return code_data
::py::


with entry {
    st.set_page_config(page_title="AutoGrader", page_icon="🧠", layout="centered");
    st.title("🤖 AutoGrader for Assignment 1");
    st.markdown("Paste your **GitHub repo URL** below and click Grade Now. *(For fun only)*");

    # --- User Input ---
    repo_url: str = st.text_input("🔗 GitHub Repository URL", placeholder="https://github.com/username/repo");

    if st.button("🚀 Grade Now") {
        if not repo_url.startswith("https://github.com/") {
            st.error("Please enter a valid GitHub repository link.");
        } else {
            with st.spinner("Grading... ⏳") {
                # Extract code
                code_files: dict[str, str] = extract_code_files(repo_url, extensions=(".jac",));

                # Load rubric dynamically
                script_dir: str = os.path.dirname(os.path.abspath(__file__));
                rubric_path: str = os.path.join(script_dir, "rubric.txt");

                if not os.path.exists(rubric_path) {
                    st.error("Rubric file not found. Please add rubric.txt next to this script.");
                } else {
                    with open(rubric_path, "r", encoding="utf-8") as f {
                        rubric_text: str = f.read();
                    }

                    # Grade
                    result: dict[str, str] = grade_student_code(rubric_text, code_files);

                    st.success("✅ Grading complete!");
                    st.subheader("📊 Results");
                    for key in result {
                        value = result[key];
                        st.write(f"**{key.title()}**: {value}");
                    }
                }
            }
        }
    }
}
