import re;
import requests;
import os;
import tempfile;
import git;
import from byllm.llm { Model }

glob llm = Model(model_name="gemini/gemini-2.0-flash", verbose=False);

def validate_github_repo(url: str) -> <>dict {
    let pattern = '^https:\\/\\/github\\.com\\/([\\w\\-]+)\\/([\\w\\-]+)(\\.git)?\\/?$';
    if not re.match(pattern, url) {
        return {'valid': False, 'message': 'Invalid GitHub repository URL format.'};
    }
    try {
        let <>match = re.match('^https:\\/\\/github\\.com\\/([\\w\\-]+)\\/([\\w\\-]+)', url);
        let (owner, repo) = <>match.groups();
        let api_url = f"https://api.github.com/repos/{owner}/{repo}";
        let resp = requests.get(api_url, timeout=10);
        if (resp.status_code == 200) {
            return {'valid': True, 'message': 'Repository is valid and reachable.'};
        } elif (resp.status_code == 404) {
            return {'valid': False, 'message': 'Repository not found on GitHub.'};
        } else {
            return {'valid': False, 'message': f"Unexpected GitHub response: {resp.status_code}"};
        }
    } except Exception as e {
        return {'valid': False, 'message': f"Error validating repository: {str(e)}"};
    }
}


def clone_repo(url: str) -> dict {
    try {
        
        print("creating temp dir...");
        temp_dir = tempfile.mkdtemp(prefix='repo_');
        print("Finished creating temp dir:", temp_dir);
        git.Repo.clone_from(url, temp_dir, depth=1, single_branch=True);
        print("Cloning...");
        return {
            'success': True,
            'path': temp_dir,
            'message': f"Repository cloned (shallow) to {temp_dir}"
        };
    } except Exception as e {
        return {
            'success': False,
            'path': None,
            'message': f"Failed to clone repository: {str(e)}"
        };
    }
}


def read_file_contents(file_path: str) -> str {
    try {
        with open(file_path, 'r', encoding='utf-8') as f {
            return f.read();
        }
    } except Exception as e {
        print(f"Error reading file {file_path}: {e}");
        return '';
    }
}



def summarize_readme(path: str) -> str by llm();

sem find_entry_files = """
You are an expert software repository analyzer.

Your task is to infer which files in a given  list of file paths are likely to be the main entry points of the project.

Entry points are files where program execution typically starts — for example (these are just examples, not an exhaustive list):
- Python: main.py, app.py, run.py, manage.py, cli.py, server.py
- Jac: main.jac cli.jac, run.jac
- Other indicative names like index.py, launcher.py, start.py, etc.

You will be given a list of file paths from a repository. 
Analyze them intelligently using file path semantics and return list of file paths that are most likely to be entry points of the project.
if you find similar names return file paths """;

def find_entry_files(file_list_path: list) -> list[str] by llm();

