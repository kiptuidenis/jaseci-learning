import utils;
import os;
import subprocess;
import ast;
import uuid;
import astroid;
import sys;
import importlib;
import from astroid { nodes }


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
    has is_built: bool = False;

    can build_full_ccg with Directory entry {
        print("🔎 Traversing repository for full CCG enrichment...");
        visit [-->] else { disengage; }
    }

    can analyze_file with File entry {
        if here.name.endswith(".py") {
            #print(f"This is file {here.name} with path {here.path}");
            try {
                self.file_count += 1;

                let repo_root = self.repo_root if self.root_dir_updated == None else self.root_dir_updated.path;
                let parent_root = os.path.dirname(repo_root);
                if parent_root not in sys.path {
                    sys.path.insert(0, parent_root);
                   #print(f"🧭 Added parent directory to sys.path: {parent_root}");
                }
                if repo_root not in sys.path {
                    sys.path.insert(0, repo_root);
                   #print(f"🧭 Added repo root to sys.path: {repo_root}");
                }

                let source_code = open(here.path).read();
                let tree = astroid.parse(source_code);
                #print(f"📄 Analyzing imports in {here.name}...");

                for node in tree.body {
                    try {
                        if isinstance(node, nodes.Import) {
                            for (name, alias) in node.names {
                                let mod_name = name;
                                #print(f"🔎 Found Import: {mod_name}");
                                let path_found = utils.resolve_module_to_path(mod_name, here.path, level=0, is_from=False);

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
                            let modname = getattr(node, "modname", None);
                            let level = getattr(node, "level", 0) or 0;
                            #print(f"🔎 Found ImportFrom: module='{modname}' level={level} names={[n[0] for n in node.names]}");

                            let candidate_path = utils.resolve_module_to_path(modname, here.path, level=level, is_from=True);

                            if candidate_path != None and candidate_path.startswith(repo_root) {
                                let finder = self.root_dir_updated spawn FileFinder(target_path=candidate_path);
                                if finder.found_node != None {
                                    here +>:Imports:+> finder.found_node;
                                    print(f"✅ Connected from-import: {here.name} → {finder.found_node.name} (module {modname})");
                                } else {
                                    print(f"⚠️ From-import target not found in graph: {candidate_path} for module {modname}");
                                }
                            } else {
                                if modname {
                                    for (n, alias) in node.names {
                                        let composed = f"{modname}.{n}";
                                        let p2 = utils.resolve_module_to_path(composed, here.path, level=level, is_from=True);
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
                #print(f"Number of files visited: {self.file_count}");
            }
            except Exception as e {
                print(f"ASTROID error in {here.path}: {e}");
            }
            visit [-->](`?Class);
        }
    }

    can analyze_class with Class entry {
        try {
            print(f"🏷️ Analyzing class {here.name} at {here.path}");
            import astroid;

            let source_code = open(here.path).read();
            let tree = astroid.parse(source_code);
            let class_nodes = [n for n in tree.body if isinstance(n, astroid.nodes.ClassDef) and n.name == here.name];
            #print(f"These are class nodes found: {class_nodes}");

            for cnode in class_nodes {
                for base in cnode.bases {
                    #print(f"These are bases in class_nodes: {base}");
                    try {
                        let inferred = list(base.infer());
                       # print(f"This is infered : {inferred}");
                        for b in inferred {
                            try {
                                let base_path = "";
                                if hasattr(b, "file") and b.file != None {
                                    base_path = os.path.abspath(b.file);
                                } elif hasattr(b.root(), "file") and b.root().file != None {
                                    base_path = os.path.abspath(b.root().file);
                                } else {
                                    base_path = here.path;
                                }

                               # print(f"📁 This is the base path of file where class: {base_path}");

                                let base_name = getattr(b, "name", "");
                                #print(f"🔍 Searching for base class '{base_name}' in {base_path}");

                                if base_path.startswith(self.repo_root) {
                                    let finder = self.root_dir_updated spawn ClassFinder(
                                        target_path=base_path,
                                        target_name=base_name
                                    );
                                    if finder.found_node != None {
                                        here +>:InheritsFrom:+> finder.found_node;
                                        print(f"✅ Connected inheritance: {here.name} → {finder.found_node.name}");
                                    } else {
                                        print(f"⚠️ Base class '{base_name}' not found in graph for {here.name}");
                                    }
                                } else {
                                    print(f"🌐 External base class {base_name} ignored");
                                }
                            } except Exception as b_e {
                                print(f"❌ Error in base analysis: {b_e}");
                            }
                        }

                    }
                    except Exception as base_e {
                        print(f"❌ Error analyzing base class of {here.name}: {base_e}");
                    }
                }
            }
            visit [-->](`?Function);
        }
        except Exception as e {
            print(f"❌ Error analyzing class {here.name}: {e}");
        }
    }

            can analyze_function with Function entry {
        try {
            print(f"🔧 Analyzing function {here.name} at {here.path}");

            let source_code = open(here.path).read();
            let tree = astroid.parse(source_code);

            # find this specific function node
            let func_nodes = [n for n in tree.body if isinstance(n, astroid.nodes.FunctionDef) and n.name == here.name];
            if len(func_nodes) == 0 {
                # might be inside a class body
                for n in tree.body {
                    if isinstance(n, astroid.nodes.ClassDef) {
                        for inner in n.body {
                            if isinstance(inner, astroid.nodes.FunctionDef) and inner.name == here.name {
                                func_nodes.append(inner);
                            }
                        }
                    }
                }
            }

            # collect all function names in this file for fallback
            let all_func_names = [n.name for n in tree.body if isinstance(n, astroid.nodes.FunctionDef)];
            for n in tree.body {
                if isinstance(n, astroid.nodes.ClassDef) {
                    for inner in n.body {
                        if isinstance(inner, astroid.nodes.FunctionDef) {
                            all_func_names.append(inner.name);
                        }
                    }
                }
            }

            for fnode in func_nodes {
                print(f"📞 Searching calls inside function {fnode.name}...");
                for call in fnode.nodes_of_class(astroid.nodes.Call) {
                    try {
                        let resolved = False;
                        let inferred = list(call.func.infer());

                        for target in inferred {
                            if hasattr(target, "name") and hasattr(target, "root") and hasattr(target.root(), "file") {
                                let target_name = getattr(target, "name", "");
                                let target_path = os.path.abspath(target.root().file) if target.root().file != None else here.path;

                                # only connect if it's internal
                                if target_path.startswith(self.repo_root) and target_name != "" {
                                    let finder = self.root_dir_updated spawn FunctionFinder(
                                        target_path=target_path,
                                        target_name=target_name
                                    );
                                    if finder.found_node != None {
                                        here +>:Calls:+> finder.found_node;
                                        print(f"✅ Connected call: {here.name} → {finder.found_node.name}");
                                        resolved = True;
                                    }
                                }
                            }
                        }

                        # fallback: local same-file calls by name match
                        if not resolved {
                            let call_name = getattr(call.func, "name", None);
                            if call_name != None and call_name in all_func_names {
                                let finder2 = self.root_dir_updated spawn FunctionFinder(
                                    target_path=here.path,
                                    target_name=call_name
                                );
                                if finder2.found_node != None {
                                    here +>:Calls:+> finder2.found_node;
                                    print(f"✅ Connected local call: {here.name} → {finder2.found_node.name}");
                                    resolved = True;
                                }
                            }
                        }

                        if not resolved {
                            #print(f"🌐 External or unresolved call ignored: {getattr(call.func, 'name', 'unknown')}");
                        }

                    }
                    except Exception as ce {
                        #print(f"❌ Error analyzing call in {here.name}: {ce}");
                    }
                }
            }
            
        }
        except Exception as e {
            #print(f"❌ Error analyzing function {here.name}: {e}");
        }
            #print("✅ Finished building full CCG.");
            self.is_built = True;
            #print(f"🏁 is_built set to {self.is_built}");
    }
}


walker BuildCCG {

    can build_ccg with Directory entry {
        visit [-->];
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
            #print(f"✅ Found file node for {here.path}");
            disengage;
        }
    }
}


walker ClassFinder {
    has target_path: str;
    has target_name: str = "";
    has found_node: Class | None = None;

    can find_file with Directory entry {
        visit [-->]; #else { disengage; }
    }

    can check_file with File entry {
        visit [-->]; #else { disengage; }
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

        visit [-->];
    }

    can check_file with File entry {
        visit [-->];
    }

    can check_class with Class entry {
        visit [-->];
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
    full_ccg = root_dir_updated spawn BuildFullCCG(repo_root=root_dir_updated.path, root_dir_updated=root_dir_updated);
    if full_ccg.is_built {
        print("Yeeeeeyyyyyyy..Finished Succesfully");
    }
    else {
        print("Tooo baaaaddd...Unsuccessful tree building");
    }

}



