# 🧠 AutoGrader – Jaseci LLM-Powered Code Grader

A simple **Jaseci** script that uses **Gemini LLM** to automatically grade code from a GitHub repo using a rubric.

---


## Clone the Repository
Clone this project and open the AutoGrader folder:

```bash
git clone https://github.com/kiptuidenis/jaseci-learning.git
cd jaseci-learning/fun/AutoGrader



## Requirements

- **Python 3.12+**
- **Jaclang** → `pip install jaclang`
- **GitPython** → `pip install gitpython`
- **byLLM** → `pip install byllm`
- **Gemini API key** → Get one from [Google AI Studio](https://aistudio.google.com/app/apikey)

### Set your Gemini API key:
**Linux / macOS**
`export GEMINI_API_KEY="your_api_key_here"`


**Windows**
`setx GEMINI_API_KEY "your_api_key_here"`


**Run the Grader**
`jac run grader.jac`

**You’ll be prompted to enter a GitHub repo URL:**
👉 Repo URL: https://github.com/student/assignment-repo


