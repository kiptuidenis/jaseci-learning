import re;
import requests;
import os;
import tempfile;
import git;
import jedi, ast;
import astroid;
import sys;
import importlib;
import uuid;
import from astroid { nodes }
import from byllm.llm { Model }

glob llm = Model(model_name="gemini/gemini-2.5-flash", verbose=False);



def resolve_module_to_path(module_name: str, here_path: str, level: int=0, is_from: bool=False) -> str | None {
    try {
        let repo_root = os.getenv("REPO_ROOT") or os.getcwd();

        if module_name and module_name != "" {
            try {
                let mod = astroid.MANAGER.ast_from_module_name(module_name);
                if mod and getattr(mod, "file", None) and os.path.exists(mod.file) {
                    return os.path.abspath(mod.file);
                }
            }
            except Exception as _a { }

            let parts = module_name.split(".");
            let direct = os.path.join(repo_root, *parts) + ".py";
            if os.path.exists(direct) {
                return os.path.abspath(direct);
            }

            let pkg_init = os.path.join(repo_root, *parts, "__init__.py");
            if os.path.exists(pkg_init) {
                return os.path.abspath(pkg_init);
            }
        }

        if level and level > 0 {
            let rel = os.path.relpath(here_path, repo_root);
            let pkg = os.path.splitext(rel)[0].replace(os.sep, ".");
            let comps = pkg.split(".");
            let prefix = comps[:len(comps)-level] if len(comps) >= level else [];
            let full = ".".join(prefix + module_name.split(".")) if module_name and module_name != "" else ".".join(prefix);

            if full and full != "" {
                let parts2 = full.split(".");
                let cand = os.path.join(repo_root, *parts2) + ".py";
                if os.path.exists(cand) {
                    return os.path.abspath(cand);
                }

                let cand2 = os.path.join(repo_root, *parts2, "__init__.py");
                if os.path.exists(cand2) {
                    return os.path.abspath(cand2);
                }
            }
        }

        let last = module_name.split(".")[-1] if module_name and module_name != "" else None;
        if last {
            for (root_dir_walk, dirs, files) in os.walk(repo_root) {
                if any(p in root_dir_walk for p in ["/.git/", "/venv/", "/.venv/", "/env/"]) {
                    continue;
                }
                if f"{last}.py" in files {
                    return os.path.abspath(os.path.join(root_dir_walk, f"{last}.py"));
                }
            }
        }

        return None;
    }
    except Exception as e {
        print(f"⚠️ resolve_module_to_path error: {e}");
        return None;
    }
}


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


"""
Take in contents of ReadMe and summarize it into useful summary that can be used to generate 
in depth documentation of the repository.
"""
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

::py::
def resolve_imports_with_jedi(source, path):
    script = jedi.Script(source, path=path)
    tree = ast.parse(source)
    resolved = []

    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            for alias in node.names:
                name = alias.name.split('.')[0]
                defs = script.goto(line=node.lineno, column=0)
                for d in defs:
                    if d.module_path:
                        resolved.append((name, d.module_path))

        elif isinstance(node, ast.ImportFrom):
            mod = node.module
            for alias in node.names:
                name = alias.name
                defs = script.goto(line=node.lineno, column=0)
                for d in defs:
                    if d.module_path:
                        resolved.append((f"{mod}.{name}", d.module_path))
    return resolved
::py::