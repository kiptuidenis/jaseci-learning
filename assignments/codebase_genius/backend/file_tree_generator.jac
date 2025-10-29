import utils;
import os;
import ast;
import jedi;
import subprocess;
import uuid;

node Directory {
    has uid: str = "";
    has path: str = "";
    has name: str = "";
    has subdirectories: list[Directory] = [];
    has files: list[File] = [];
}

node File {
    has uid: str = "";
    has path:  str = "";
    has name: str;
}

node Module {
    has uid: str = "";
    has path: str = "";
    has name: str  = "";
    has classes: list[ClassNode] = [];
    has functions: list[FunctionNode] = [];
}

node ClassNode {
    has uid: str = "";
    has name: str = "";
    has file_path: str = "";
    has methods: list[FunctionNode] = [];
}

node FunctionNode {
    has uid: str = "";
    has name: str = "";
    has args: list[str] = [];
    has docstring: str = "";
    has file_path: str = "";
    has class_name: str = "";
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
                let subdir_node = Directory(
                    path=full_path,
                    name=entry,
                    uid=str(uuid.uuid5(uuid.NAMESPACE_URL, full_path))
                );
                here ++> subdir_node;
                visit subdir_node;
            } else {
                let file_node = File(
                    path=full_path,
                    name=entry,
                    uid=str(uuid.uuid5(uuid.NAMESPACE_URL, full_path))
                );
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
        visit [-->] else {
            disengage;
        }
    }

    can start_file_traversal with File entry {
        self.file_list.append(here.name);
        self.file_list_path.append(here.path);
    }
}


walker CodeAnalyzer {
    can analyze with File entry {
        if here.name.endswith(".py") {
            try {
                with open(here.path, "r") as f {
                    source = f.read();
                }
                let tree = ast.parse(source);

                # Create unique identifier for this module
                let module_node = Module(
                    path=here.path,
                    name=here.name,
                    uid=str(uuid.uuid5(uuid.NAMESPACE_URL, here.path))
                );
                here ++> module_node;

                for node in ast.walk(tree){
                    if isinstance(node, ast.ClassDef){
                        let class_uid = str(uuid.uuid5(uuid.NAMESPACE_URL, here.path + ":" + node.name));
                        let cls = ClassNode(name=node.name, file_path=here.path, uid=class_uid);
                        module_node ++> cls;

                        for child in node.body{
                            if isinstance(child, ast.FunctionDef){
                                let func_uid = str(uuid.uuid5(uuid.NAMESPACE_URL, here.path + ":" + node.name + "." + child.name));
                                let fn = FunctionNode(
                                    name=child.name,
                                    args=[arg.arg for arg in child.args.args],
                                    docstring=ast.get_docstring(child) or "",
                                    file_path=here.path,
                                    class_name=node.name,
                                    uid=func_uid
                                );
                                cls.methods.append(fn);
                                cls ++> fn;
                            }
                        }
                    }
                    elif isinstance(node, ast.FunctionDef){
                        let func_uid = str(uuid.uuid5(uuid.NAMESPACE_URL, here.path + ":" + node.name));
                        let fn = FunctionNode(
                            name=node.name,
                            args=[arg.arg for arg in node.args.args],
                            docstring=ast.get_docstring(node) or "",
                            file_path=here.path,
                            uid=func_uid
                        );
                        module_node ++> fn;
                    }
                }

            except Exception as e{
                print(f"AST parsing failed for {here.name}: {e}");
            }

        elif here.name.endswith(".jac"){
            try {
                result = subprocess.run(
                    ["jac", "tool", "ir", "ast", here.path],
                    capture_output=True,
                    text=True
                );
                if result.returncode == 0 {
                    print(f"Jac AST for {here.name}: {result.stdout[:200]}...");
                }
                else{
                    print(f"Error generating Jac AST: {result.stderr}");
                }
            except Exception as e {
                print(f"Jac AST parsing failed: {e}");
            }
        }
    }
}
}
    }
}



with entry {
    root_dir = Directory(
        path="/home/denis/jaseci-learning/assignments/codebase_genius",
        name=os.path.basename("/home/denis/jaseci-learning/assignments/codebase_genius"),
        uid=str(uuid.uuid5(uuid.NAMESPACE_URL, "/home/denis/jaseci-learning/assignments/codebase_genius"))
    );

    root_dir spawn BuildTreeWalker();
    root ++> root_dir;

    files = root_dir spawn TreeTraverser();
    entry_files = utils.find_entry_files(files.file_list_path);

    py_files = [];
    jac_files = [];
    for file_path in entry_files {
        if file_path.endswith(".py") {
            py_files.append(file_path);
        } elif file_path.endswith(".jac") {
            jac_files.append(file_path);    
        }
    }
    print(f"Python entry files: {py_files}");
    print(f"Jac entry files: {jac_files}");

    # Analyze Python and Jac files
    for f in files.file_list_path {
        if f.endswith(".py") or f.endswith(".jac") {
            let file_node = File(
                path=f,
                name=os.path.basename(f),
                uid=str(uuid.uuid5(uuid.NAMESPACE_URL, f))
            );
            root_dir ++> file_node;
            file_node spawn CodeAnalyzer();
        }
    }
}
