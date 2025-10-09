import streamlit as st
import tempfile
import os
import shutil
from git import Repo
from byllm.llm import Model

# Initialize the LLM model
llm = Model(model_name="gemini/gemini-2.0-flash", verbose=False)

def grade_student_code(rubric: str, code_data: dict[str, str]) -> dict[str, str]:
    """Use LLM to grade code based on rubric."""
    return llm.run("grade_student_code", rubric, code_data)


def extract_code_files(repo_url, extensions=(".jac", ".py", ".txt")):
    """Clone repo and extract files with given extensions."""
    temp_dir = tempfile.mkdtemp()
    Repo.clone_from(repo_url.strip(), temp_dir)
    code_data = {}

    for root, _, files in os.walk(temp_dir):
        for file in files:
            if file.endswith(extensions):
                path = os.path.join(root, file)
                try:
                    with open(path, "r", encoding="utf-8") as f:
                        rel_path = os.path.relpath(path, temp_dir)
                        code_data[rel_path] = f.read()
                except Exception as e:
                    print(f"Skipping {path}: {e}")

    shutil.rmtree(temp_dir)
    return code_data


# ---- STREAMLIT UI ----
st.set_page_config(page_title="AutoGrader", page_icon="🧠", layout="centered")
st.title("🤖 AutoGrader for Assignment 1")
st.markdown(
    """
    Paste your **GitHub repo URL** below and click *Grade Now*  
    *(For fun only — not official grading 😄)*
    """
)

repo_url = st.text_input("🔗 GitHub Repository URL", placeholder="https://github.com/username/repo")

if st.button("🚀 Grade Now"):
    if not repo_url.startswith("https://github.com/"):
        st.error("Please enter a valid GitHub repository link.")
    else:
        with st.spinner("Cloning repository and grading... ⏳"):
            try:
                code_files = extract_code_files(repo_url, extensions=(".jac",))
                rubric_path = os.path.join(os.path.dirname(__file__), "rubric.txt")

                if not os.path.exists(rubric_path):
                    st.error("Rubric file not found. Please add rubric.txt next to app.py.")
                else:
                    with open(rubric_path, "r", encoding="utf-8") as f:
                        rubric_text = f.read()

                    result = grade_student_code(rubric_text, code_files)

                    st.success("✅ Grading complete!")
                    st.subheader("📊 Results")
                    for key, value in result.items():
                        st.write(f"**{key.title()}**: {value}")

            except Exception as e:
                st.error(f"❌ Error: {e}")
