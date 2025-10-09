import streamlit as st
import os
from jaseci.utils.utils import TestCaseHelper
from jaseci_ai.jac import JacRunner  # allows running Jac files programmatically

# Streamlit UI
st.set_page_config(page_title="AutoGrader", page_icon="🧠", layout="centered")
st.title("🤖 AutoGrader for Assignment 1")
st.markdown("Paste your **GitHub repo URL** below and click Grade Now. *(For fun only)*")

repo_url = st.text_input("🔗 GitHub Repository URL", placeholder="https://github.com/username/repo")

if st.button("🚀 Grade Now"):
    if not repo_url.startswith("https://github.com/"):
        st.error("Please enter a valid GitHub repository link.")
    else:
        with st.spinner("Grading in progress... ⏳"):
            try:
                # Path to your grader.jac
                jac_path = os.path.join(os.path.dirname(__file__), "grader.jac")

                # Create a Jac runner
                runner = JacRunner(jac_path)

                # Call the 'entry' program
                # You can pass the repo_url as an argument if you modify your Jac entry to accept parameters
                runner.run("entry", repo_url=repo_url)

                st.success("✅ Grading completed!")

            except Exception as e:
                st.error(f"❌ Error: {e}")
