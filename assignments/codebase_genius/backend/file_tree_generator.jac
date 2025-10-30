import utils;
import os;
import subprocess;
import ast;
import jedi;
import uuid;

node Directory {
    has path: str;
    has name: str;
    has subdirectories: list[Directory] = [];
    has files: list[File] = [];
}

node File {
    has uid: str = "";
    has path: str = "";
    has name: str = "";
}

node Class {
    has uid: str = "";
    has name: str = "";
}

node Function {
    has uid: str = "";
    has name: str = "";
}

walker BuildTreeWalker {
    has ignore_dirs: list = [
        ".git", "node_modules", "__pycache__", ".idea", ".vscode",
        "dist", "build", ".pytest_cache", ".mypy_cache", ".DS_Store",
        ".venv", "env", "venv", "coverage", ".next"
    ];

    has ignore_files: list = [
        ".gitignore", ".env", ".env.local", ".DS_Store",
        "Thumbs.db", "package-lock.json", "yarn.lock",
        ".pylintrc", ".eslintcache", ".coverage", ".mypy_cache"
    ];

    can build_tree with Directory entry {
        let entries = os.listdir(here.path);

        for entry in entries {
            let full_path = os.path.join(here.path, entry);

            if entry in self.ignore_dirs {
                continue;
            }

            if entry in self.ignore_files or entry.endswith((".pyc", ".log", ".tmp")) {
                continue;
            }

            if os.path.isdir(full_path) {
                let subdir_node = Directory(path=full_path, name=entry);
                here ++> subdir_node;
                visit subdir_node;
            } else {
                let file_node = File(uid=str(uuid.uuid4()), path=full_path, name=entry);
                here ++> file_node;
                visit file_node;
            }
        }
    }
}

walker TreeTraverser {
    has file_list: list = [];
    has file_list_path: list = [];

    can start_traversal with Directory entry {
        visit [-->] else { disengage; }
    }

    can start_file_traversal with File entry {
        self.file_list.append(here.name);
        self.file_list_path.append(here.path);
    }
}

walker BuildCCG {

    can build_ccg with Directory entry {
        visit [-->] else { disengage; }
    }
    can start_ccg with File entry {
        if here.name.endswith(".py") {
            try {
                let source_code = open(here.path).read();
                let tree = ast.parse(source_code);

                for node in ast.walk(tree) {
                    if isinstance(node, ast.ClassDef) {
                        let class_node = Class(uid=str(uuid.uuid4()), name=node.name);
                        here ++> class_node;

                        # attach methods
                        for body_item in node.body {
                            if isinstance(body_item, ast.FunctionDef) {
                                let method_node = Function(uid=str(uuid.uuid4()), name=body_item.name);
                                class_node ++> method_node;
                            }
                        }
                    } elif isinstance(node, ast.FunctionDef) {
                        let func_node = Function(uid=str(uuid.uuid4()), name=node.name);
                        here ++> func_node;
                    }
                }
            }

            except Exception as e {
                print(f"AST error in {here.path}: {e}");
            }
            print(f"Processed file for CCG: {here.path}");
        }
        
    }
}


with entry {
    root_dir = Directory(path="/home/denis/jaseci-learning/assignments/codebase_genius", name=os.path.basename("/home/denis/jaseci-learning/assignments/codebase_genius"));
    root_dir spawn BuildTreeWalker();
    root ++> root_dir;
    files = root_dir spawn TreeTraverser();

    py_files = [];
    jac_files = [];

    for file_path in files.file_list_path {
        if file_path.endswith(".py") {
            py_files.append(file_path);
        } elif file_path.endswith(".jac") or file_path.endswith(".impl.jac") {
            jac_files.append(file_path);
        }
    }

    print(f"Python files: {py_files}");
    print(f"Jac files: {jac_files}");

    # Convert .jac → .py
let converted_py_files = [];

for jac_path in jac_files {
    let result = subprocess.run(["jac", "tool", "ir", "py", jac_path],
        capture_output=True, text=True);

    if result.returncode == 0 {
        # Replace .jac extension with .py in the same directory
        let base_name = os.path.splitext(jac_path)[0] + ".py";

        with open(base_name, "w") as f {
            f.write(result.stdout);
        }

        converted_py_files.append(base_name);
        print(f"✅ Converted {jac_path} → {base_name}");
    } else {
        print(f"❌ Error converting {jac_path}: {result.stderr}");
    }
}

# Add converted .py files to parsing list
    py_files.extend(converted_py_files);

    #print(py_files);
    # Build partial Code Context Graph
    root_dir_updated = Directory(path="/home/denis/jaseci-learning/assignments/codebase_genius", name=os.path.basename("/home/denis/jaseci-learning/assignments/codebase_genius"));
    root_dir_updated spawn BuildTreeWalker();
    root ++> root_dir_updated;
    root_dir_updated spawn BuildCCG();
}
