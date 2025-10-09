import from byllm.llm { Model }
import shutil;
import os;
import tempfile;
import from git { Repo }

glob llm = Model(model_name="gemini/gemini-2.0-flash", verbose=False);

def grade_student_code(rubric: str, code_data: dict[str, str]) -> dict[str, str] by llm;

::py::
def extract_code_files(repo_url, extensions=(".jac", ".py", ".txt")):
    """
    Clone a GitHub repo into a temp folder and extract all files
    that match the given extensions.
    Returns a dictionary {filename: code_content}.
    """
    temp_dir = tempfile.mkdtemp()
    Repo.clone_from(repo_url, temp_dir)
    
    code_data = {}
    for root, _, files in os.walk(temp_dir):
        for file in files:
            if file.endswith(extensions):
                file_path = os.path.join(root, file)
                try:
                    with open(file_path, "r", encoding="utf-8") as f:
                        relative_path = os.path.relpath(file_path, temp_dir)
                        code_data[relative_path] = f.read()
                except Exception as e:
                    print(f"Skipping {file_path}: {e}")
    shutil.rmtree(temp_dir)
    return code_data
::py::

with entry {
    # === Prompt user for GitHub repo link ===
    print("Enter the GitHub repository URL to grade:");
    repo_url: str = input("👉 Repo URL: ");

    # === Extract student's code ===
    extracted_files: dict[str, str] = extract_code_files(repo_url, extensions=(".jac",));

    # === Resolve rubric path dynamically (relative to this script) ===
    script_dir: str = os.path.dirname(os.path.abspath(__file__));
    rubric_path: str = os.path.join(script_dir, "rubric.txt");

    if not os.path.exists(rubric_path) {
        print(f"❌ Rubric file not found at: {rubric_path}");
        exit();
    }

    with open(rubric_path, "r", encoding="utf-8") as f {
        rubric_text: str = f.read();
    }

    # === Run grading ===
    result: dict[str, str] = grade_student_code(rubric_text, extracted_files);

    print("\n📊 === AUTO-GRADER RESULTS ===");
    for key in result {
        value = result[key];
        print(f"{key.title()}: {value}");
    }
    print("=============================\n");
}
