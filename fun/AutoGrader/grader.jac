# grader.jac
import from byllm.llm { Model }

glob llm = Model(model_name="gemini/gemini-2.0-flash", verbose=False);

def grade_student_code(rubric: str, code_data: dict[str, str]) -> dict[str, str] by llm;
