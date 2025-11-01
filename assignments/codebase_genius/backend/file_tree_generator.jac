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
    has path: str = "";
}

node Function {
    has uid: str = "";
    has name: str = "";
    has path: str = "";
}
edge Imports{}
edge InheritsFrom{}
edge Calls{}


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

walker BuildFullCCG {
    has repo_root: str = "";
    has root_dir_updated: Directory | None = None;

    can build_full_ccg with Directory entry {
        print("🔎 Traversing repository for full CCG enrichment...");
        visit [-->] else { disengage; }
    }

    can analyze_file with File entry {
    if here.name.endswith(".py") {
        print(f"This is file {here.name} with path {here.path}");

        try {
            import astroid;
            import sys;
            import os;
            import importlib;
            import uuid;
            import from astroid { nodes }

            # Ensure repo root and its parent are on sys.path for resolution
            let repo_root = self.repo_root if self.root_dir_updated == None else self.root_dir_updated.path;
            let parent_root = os.path.dirname(repo_root);
            if parent_root not in sys.path {
                sys.path.insert(0, parent_root);
                print(f"🧭 Added parent directory to sys.path: {parent_root}");
            }
            if repo_root not in sys.path {
                sys.path.insert(0, repo_root);
                print(f"🧭 Added repo root to sys.path: {repo_root}");
            }

            let source_code = open(here.path).read();
            let tree = astroid.parse(source_code);
            print(f"📄 Analyzing imports in {here.name}...");

            # helper: try astroid then filesystem then repo search
            def resolve_module_to_path(module_name: str, here_path: str, level: int=0, is_from: bool=False) -> str | None {
                # module_name may be None for statements like 'from . import foo'
                try {
                    if module_name and module_name != "" {
                        # try astroid
                        try {
                            let mod = astroid.MANAGER.ast_from_module_name(module_name);
                            if mod and getattr(mod, "file", None) {
                                let candidate = mod.file;
                                if os.path.exists(candidate) {
                                    return os.path.abspath(candidate);
                                }
                            }
                        }
                        except Exception as _a {
                            # fallthrough to filesystem checks
                        }

                        # try direct join from repo root: repo_root/<module_name>.py or /<module_name>/__init__.py
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

                    # handle relative imports (level > 0)
                    if level and level > 0 {
                        # compute package for current file: e.g. tests.test_models.test_user
                        let rel = os.path.relpath(here_path, repo_root);
                        let pkg = os.path.splitext(rel)[0].replace(os.sep, ".");
                        let comps = pkg.split(".");
                        # parent prefix is comps up to -level
                        if len(comps) >= level {
                            let prefix = comps[:len(comps)-level];
                        } else {
                            let prefix = [];
                        }

                        if module_name and module_name != "" {
                            let full = ".".join(prefix + module_name.split("."));
                        } else {
                            let full = ".".join(prefix);
                        }

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

                    # Last resort: search repo for file named like last segment
                    let last = module_name.split(".")[-1] if module_name and module_name != "" else None;
                    if last {
                        for (root_dir_walk, dirs, files) in os.walk(repo_root) {
                            # quick prune: skip venvs, .git
                            if any(p in root_dir_walk for p in ["/.git/", "/venv/", "/.venv/", "/env/"]){
                                continue;
                            }
                            if f"{last}.py" in files {
                                # prefer matches where the on-disk path contains the module path segments
                                let candidate = os.path.join(root_dir_walk, f"{last}.py");
                                return os.path.abspath(candidate);
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

            # iterate over top-level import statements
            for node in tree.body {
                try {
                    if isinstance(node, nodes.Import) {
                        for (name, alias) in node.names {
                            let mod_name = name;
                            print(f"🔎 Found Import: {mod_name}");
                            let path_found = resolve_module_to_path(mod_name, here.path, level=0, is_from=False);

                            if path_found != None and path_found.startswith(repo_root) {
                                let finder = self.root_dir_updated spawn FileFinder(target_path=path_found);
                                if finder.found_node != None {
                                    here +>:Imports:+> finder.found_node;
                                    print(f"✅ Connected import: {here.name} → {finder.found_node.name} ({mod_name})");
                                } else {
                                    print(f"⚠️ Internal import file not found in graph: {path_found} for module {mod_name}");
                                }
                            } else {
                                print(f"🌐 Treated as external/unresolved import: {mod_name}");
                            }
                        }
                    } elif isinstance(node, nodes.ImportFrom) {
                        # ImportFrom: could be relative (node.level > 0)
                        let modname = getattr(node, "modname", None);
                        let level = getattr(node, "level", 0) or 0;
                        print(f"🔎 Found ImportFrom: module='{modname}' level={level} names={[n[0] for n in node.names]}");
                        
                        # compute candidate resolution (handles relative imports)
                        let candidate_path = resolve_module_to_path(modname, here.path, level=level, is_from=True);

                        if candidate_path != None and candidate_path.startswith(repo_root) {
                            let finder = self.root_dir_updated spawn FileFinder(target_path=candidate_path);
                            if finder.found_node != None {
                                here +>:Imports:+> finder.found_node;
                                print(f"✅ Connected from-import: {here.name} → {finder.found_node.name} (module {modname})");
                            } else {
                                print(f"⚠️ From-import target not found in graph: {candidate_path} for module {modname}");
                            }
                        } else {
                            # If specific names are imported from a package, attempt to find those names as files under the package
                            if modname {
                                for (n, alias) in node.names {
                                    # try modname + '.' + n as module
                                    let composed = f"{modname}.{n}";
                                    let p2 = resolve_module_to_path(composed, here.path, level=level, is_from=True);
                                    if p2 != None and p2.startswith(repo_root) {
                                        let finder2 = self.root_dir_updated spawn FileFinder(target_path=p2);
                                        if finder2.found_node != None {
                                            here +>:Imports:+> finder2.found_node;
                                            print(f"✅ Connected from-import (member-as-module): {here.name} → {finder2.found_node.name} ({composed})");
                                            continue;
                                        }
                                    }
                                }
                            }

                            print(f"🌐 External or unresolved from-import skipped: {modname}");
                        }
                    }
                }
                except Exception as inner_e {
                    print(f"❌ Error resolving a specific import in {here.path}: {inner_e}");
                }
            }

        }
        except Exception as e {
            print(f"ASTROID error in {here.path}: {e}");
        }
    }
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
                        let class_node = Class(uid=str(uuid.uuid4()), name=node.name, path=here.path);
                        here ++> class_node;

                        # attach methods
                        for body_item in node.body {
                            if isinstance(body_item, ast.FunctionDef) {
                                let method_node = Function(uid=str(uuid.uuid4()), name=body_item.name, path=here.path);
                                class_node ++> method_node;
                            }
                        }
                    } elif isinstance(node, ast.FunctionDef) {
                        let func_node = Function(uid=str(uuid.uuid4()), name=node.name, path=here.path);
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

walker FileFinder {
    has target_path: str;
    has found_node: File | None = None;

    can find_file with Directory entry {
        # Stop traversal if the file was already found
        if self.found_node != None {
            disengage;
        }
        visit [-->] else { disengage; }
    }

    can check_file with File entry {
        # Stop traversal if already found
        if self.found_node != None {
            disengage;
        }

        if here.path == self.target_path {
            self.found_node = here;
            print(f"✅ Found file node for {here.path}");
            disengage;
        }
    }
}


walker ClassFinder {
    has target_path: str;
    has target_name: str = "";
    has found_node: Class | None = None;

    can find_file with Directory entry {
        if self.found_node != None {
            disengage;
        }
        visit [-->] else { disengage; }
    }

    can check_file with File entry {
        if self.found_node != None {
            disengage;
        }
        visit [-->] else { disengage; }
    }

    can check_class with Class entry {
        if here.path == self.target_path {
            if self.target_name == "" or here.name == self.target_name {
                self.found_node = here;
                print(f"✅ Found class {here.name} at {here.path}");
                disengage;
            }
        }
    }
}

walker FunctionFinder {
    has target_path: str;
    has target_name: str = "";
    has found_node: Function | None = None;

    can find_function with Directory entry {
        if self.found_node != None {
            disengage;
        }
        visit [-->] else { disengage; }
    }

    can check_file with File entry {
        if self.found_node != None {
            disengage;
        }
        visit [-->] else { disengage; }
    }

    can check_function with Function entry {
        if here.path == self.target_path {
            if self.target_name == "" or here.name == self.target_name {
                self.found_node = here;
                print(f"✅ Found function {here.name} at {here.path}");
                disengage;
            }
        }
    }
}

walker TraversePartialCCG {
    can traverse_directory with Directory entry {
        print("visiting files..");
        visit [-->] else { disengage; }
    }

    can go_to_classes with File entry {
        if here.name.endswith('.py'){
            print(f"This is file {here.name} with path {here.path}");
            visit [-->];
        }
    }
    can go_to_func with Class entry {
        print(f"This is class {here.name} with path {here.path}");
        visit [-->](`?Function);
        
    }
    can finish with Function entry {
        print(f"This is function {here.name} with path {here.path}");
    }
}




with entry {
    root_dir = Directory(path="/home/denis/jaseci-learning/fun/classmates/AirBnB_clone_v2", name=os.path.basename("/home/denis/jaseci-learning/fun/classmates/AirBnB_clone_v2"));
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
    root_dir_updated = Directory(path="/home/denis/jaseci-learning/fun/classmates/AirBnB_clone_v2", name=os.path.basename("/home/denis/jaseci-learning/fun/classmates/AirBnB_clone_v2"));
    root_dir_updated spawn BuildTreeWalker();
    root ++> root_dir_updated;
    root_dir_updated spawn BuildCCG();
    #root_dir_updated spawn TraversePartialCCG();
    root_dir_updated spawn BuildFullCCG(repo_root=root_dir_updated.path, root_dir_updated=root_dir_updated);

}



