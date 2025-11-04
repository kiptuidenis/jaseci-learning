import from dotenv { load_dotenv }
import utils;
import os;
import subprocess;
import ast;
import uuid;
import astroid;
import sys;
import importlib;
import from astroid { nodes }
import from byllm.llm { Model }
import os, json;

glob llm = Model(model_name="gemini/gemini-2.0-flash", verbose=False);


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


node Supervisor {
    has url: str = "";
    has root_dir: Directory | None | dict = None;
    has root_directory: Directory | None | dict = None;
    has readme_summary: str = "";
    has partial_ccg_root: Directory | None | dict = None;
    has documentation: str = "";

    def extract_file(file_path: str) -> str;
    def call_finder(caller_name: str, caller_path: str, callee_name: str) -> str;
    def class_hierarchies(child_name: str, child_path: str, parent_name: str) -> str;
    def import_finder(importer_name: str, importer_path: str, imported_name: str) -> str;
#    def diagram_generator()-> str;

    def doc_genie(ccg_root: Directory, readme_summary: str) ->  str by llm(
        method="ReAct",
        tools=([self.extract_file, self.call_finder, self.class_hierarchies, self.import_finder]),
    );

    can clone_repo with StartCloning entry {
        print("Starting delegation to RepoMapper (still at Supervisor)...");
        cloning = delegate(url=self.url) spawn self;

        if not cloning.cloning_status["valid"] {
            report f"Error: {cloning.cloning_status['message']}";
            disengage;
        }

        report f"Success: {cloning.cloning_status['message']}";
        disengage;
    }

    can build_file_tree with file_tree_generator entry {
        print(self);
        print("Visiting RepoMapper to build file tree...");

        visit [-->](`?RepoMapper)(?url==self.url) else {
            report "Error: No cloned repository found for this URL.";
            disengage;
        }
        #print(f"This is File Tree returned to Supervisor!!: {file_tree}");
    }

    can update_info with CarryReadMeAndRootDir entry {
        print("Updating Supervisor with README summary and root directory...");

        self.root_dir = visitor.root_dir;
        self.readme_summary = visitor.readme_summary;
        print(f"Updated readme summary: {self.readme_summary}");
        #print(f"Updated root directory: {self.root_dir}");
        #disengage;
    }

    can build_partial_CCG with BuildCCG entry {
        # did this because for some reason self.root_dir is a dict instead of Directory
        self.root_directory = Directory(
            path=self.root_dir["path"],
            name=self.root_dir["name"],
            #subdirectories=self.root_dir["subdirectories"],
            #files=self.root_dir["files"]
        );

        #print(self.root_directory);
        self.root_directory spawn BuildTreeWalker();
        files = self.root_directory spawn TreeTraverser();
        print(f"FINAL FILE TREE STRUCTURE: {self.root_directory}");

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
            let result = subprocess.run(
                ["jac", "tool", "ir", "py", jac_path],
                capture_output=True, text=True
            );

            if result.returncode == 0 {
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

        py_files.extend(converted_py_files);

        # --- Persist the partial CCG root node ---
        self.partial_ccg_root = Directory(
            path=self.root_directory.path,
            name=os.path.basename(self.root_directory.path)
        );

        # Build under that new root
        self.partial_ccg_root spawn BuildTreeWalker();
        root ++> self.partial_ccg_root;

        partial_ccg = self.partial_ccg_root spawn BuildPartialCCG();

        if partial_ccg.is_built {
            
            print(f"This is type of partcial_ccg_root when building full ccg: {type(self.partial_ccg_root)}");
            full_ccg = self.partial_ccg_root spawn BuildFullCCG(repo_root=self.partial_ccg_root.path, root_dir_updated=self.partial_ccg_root);
           if full_ccg.is_built {


    print("🧠 Generating markdown documentation via DocGenie...");

    self.documentation = self.doc_genie(
        ccg_root=self.partial_ccg_root,
        readme_summary=self.readme_summary
    );

    if self.documentation and len(self.documentation.strip()) > 0 {
        # ✅ Save docs in current working directory (not temp)

        repo_name = "repository";
        if hasattr(self, "repo_url") {
            repo_name = os.path.splitext(os.path.basename(self.repo_url))[0];
        }

        current_dir = os.getcwd();
        output_dir = f"{current_dir}/outputs/{repo_name}";
        os.makedirs(output_dir, exist_ok=True);

        output_path = f"{output_dir}/docs.md";

        with open(output_path, "w") as f {
            f.write(self.documentation);
        }

        print(f"✅ Documentation saved successfully at: {output_path}");

        # ✅ Return JSON so frontend can find the markdown path
        report json.dumps({
            "status": "valid",
            "message": "Documentation generated successfully.",
            "markdown_path": output_path
        });
    } else {
        print("⚠️ DocGenie returned empty documentation.");
        report json.dumps({
            "status": "invalid",
            "message": "CCG built successfully, but no documentation was generated."
        });
    }
} else {
    report json.dumps({
        "status": "invalid",
        "message": "Full CCG build failed."
    });
}



    
        } 
        else {
            report "Error: Partial CCG build failed.";
        }
        print(f"This is type of partcial_ccg_root when after building partial ccg: {type(self.partial_ccg_root)}");

        

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
            print("✅ Finished building full CCG.");
            self.is_built = True;
            #print(f"🏁 is_built set to {self.is_built}");
    }
}




node RepoMapper {
    has url: str = "";
    has local_path: str = "";
    has root_dir: Directory | None = None;
    has readme_summary: str = "";

    can clone_repo with delegate entry {
        self.url = visitor.url;
        print("Arrived at RepoMapper to clone the repository...");

        clone_result = utils.clone_repo(self.url);

        if clone_result["success"] {
            self.local_path = clone_result["path"];
            self.status = True;
            visitor.cloning_status = {
                "valid": self.status,
                "message": "Repository cloned successfully."
            };

            report visitor.cloning_status;
            print(f"Repository cloned to: {self.local_path}");
        } else {
            self.status = False;
            visitor.cloning_status = {
                "valid": self.status,
                "message": f"Cloning failed: {clone_result['message']}"
            };

            report visitor.cloning_status;
            print(f"Cloning failed: {clone_result['message']}");
        }
    }

    can build_file_tree with file_tree_generator entry {
        self.url = visitor.url;
        print(f"Building file tree for repo at {self.local_path}...");

        root_dir = Directory(path=self.local_path, name=os.path.basename(self.url));
        root_dir spawn BuildTreeWalker();
        root ++> root_dir;

        # --- Look for README files in root directory ---
        readme_files = [root_dir -->](`?File)(?name=="README.md");

        if readme_files and len(readme_files) > 0 {
            readme = readme_files[0];
            print(f"Found README file: {readme.path}");

            try {
                readme_contents = utils.read_file_contents(readme.path);
                readme_summary = utils.summarize_readme(readme_contents);
                print(readme_summary);

                if readme_summary {
                    print("README summary generated successfully.");
                    self.readme_summary = readme_summary;
                } else {
                    print("README summarization returned empty result.");
                }
            } except Exception as e {
                print(f"Warning: README summarization failed — proceeding without it. Error: {e}");
            }
        } else {
            print("No README file found in root directory.");
        }

        report "Success: File tree generated.";
        #root_dir spawn TreeTraverser();
        root spawn CarryReadMeAndRootDir(root_dir=root_dir, readme_summary=self.readme_summary, url=self.url);
        disengage;
    }
}

walker delegate {
    has url: str = "";
    has cloning_status: dict[bool, str] = {};

    can visit_repomapper with Supervisor entry {
        print("Visiting RepoMapper (still at Supervisor)...");

        visit [here -->](`?RepoMapper) else {
            new_mapper = RepoMapper(url=self.url);
            here ++> new_mapper;
            visit new_mapper;
            print("Created and visited new RepoMapper node.");
        }
    }
}

walker receiveurl {
    obj __specs__ {
        static has auth: bool = False;
    }

    has url: str = "";
    has validation: dict[bool, str] = {};

    can validate_url with `root entry {
        validation = utils.validate_github_repo(self.url);

        if not validation["valid"] {
            report f"Error: {validation['message']}";
            disengage;
        }

        report f"Success: {validation['message']}";
        disengage;
    }
}

walker StartCloning {
    obj __specs__ {
        static has auth: bool = False;
    }

    has url: str = "";
    has cloning_status: dict[bool, str] = {};

    can start_cloning with `root entry {
        visit [-->](`?Supervisor)(?url==self.url) else {
            new_supervisor = Supervisor(url=self.url);
            root ++> new_supervisor;
            visit new_supervisor;
            print("Created and visited new Supervisor node.");
        }
    }
}

walker file_tree_generator {
    obj __specs__ {
        static has auth: bool = False;
    }

    has url: str = "";
    has root_dir: Directory | None = None;
    has readme_summary: str = "";

    can begin_file_tree_generation with `root entry {
        print(self.url);
        print("Visiting Supervisor to build file tree...");

        visit [-->](`?Supervisor)(?url==self.url) else {
            print("No Supervisor found for this URL. Creating one...");
            new_supervisor = Supervisor(url=self.url);
            root ++> new_supervisor;
            visit new_supervisor;
        }
    }
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
                here.subdirectories.append(subdir_node);
                here ++> subdir_node;
                visit subdir_node;
            } else {
                let file_node = File(path=full_path, name=entry);
                here.files.append(file_node);
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

walker CarryReadMeAndRootDir {

    has root_dir: Directory | None = None;
    has readme_summary: str = "";
    has url: str = "";

    can carry_info with `root entry {
        visit [-->](`?Supervisor)(?url==self.url) else {
            disengage;
        }
    }
}

walker BuildPartialCCG {
    has is_built: bool = False;

    can build_ccg with Directory entry {
        visit [-->] else {
            report "Error: No files to process for CCG.";
            disengage; }
    }
    can start_ccg with File entry {
        if here.name.endswith(".py") {
            try {
                let source_code = open(here.path).read();
                let tree = ast.parse(source_code);

                for node in ast.walk(tree) {
                    if isinstance(node, ast.ClassDef) {
                        let class_node = Class(
                            uid=str(uuid.uuid4()),
                            name=node.name,
                            path=here.path        # ✅ Fix: set path
                        );
                        here ++> class_node;

                        # attach methods
                        for body_item in node.body {
                            if isinstance(body_item, ast.FunctionDef) {
                                let method_node = Function(
                                    uid=str(uuid.uuid4()),
                                    name=body_item.name,
                                    path=here.path        # ✅ Fix: set path
                                );
                                class_node ++> method_node;
                            }
                        }
                    } elif isinstance(node, ast.FunctionDef) {
                        let func_node = Function(
                            uid=str(uuid.uuid4()),
                            name=node.name,
                            path=here.path            # ✅ Fix: set path
                        );
                        here ++> func_node;
                    }
                }
            }
            except Exception as e {
                print(f"AST error in {here.path}: {e}");
            }
            self.is_built = True;
            print(f"Processed file for CCG: {here.path}");
        }
    }

}
 walker BuildCCG {
    obj __specs__ {
        static has auth: bool = False;
    }

    has url: str = "";

    can build_ccg with `root entry {
        visit [-->](`?Supervisor)(?url==self.url) else {
            report "Error: No Supervisor found for this URL.";
            disengage;
        }
    }

 }
  walker StartBuildFullCCG {
    obj __specs__ {
        static has auth: bool = False;
    }

    has url: str = "";

    can build_full_ccg with `root entry {
        visit [-->](`?Supervisor)(?url==self.url) else {
            report "Error: No Supervisor found for this URL.";
            disengage;
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

walker CallFinder {
    has caller_name: str = "";
    has caller_path: str = "";
    has callee_name: str = "";
    has found_content: str = "";
    has found_node: Function | Class | None = None;

    can find_callee with Directory entry {
        # Visit all subnodes in the graph recursively
        visit [-->];
    }
    can traverse_file with File entry {
       visit [-->];
    }
    can traverse_class with Class entry { 
        visit [-->];
    }

    can check_function with Function entry {

        # Step 1: Find the caller function by name and file path
        if here.name == self.caller_name and here.path == self.caller_path {
            print(f"✅ Found caller '{here.name}' at {here.path}");

            # Step 2: Traverse only the Calls edges from this caller to its callees
            visit [->:Calls:->(`?Function)](?name==self.callee_name);
        } else {
            visit [-->];
        }
    }
      can check_callee with Function entry {

        # Step 3: Once we’re visiting via Calls edge, match the callee name
        if here.name == self.callee_name {
            print(f"✅ Found callee '{here.name}' at {here.path}");

            if os.path.exists(here.path) {
                self.found_node = here;
                self.found_content = utils.read_file_contents(here.path);
                print(f"📄 Extracted contents for '{here.name}'");
            } else {
                print(f"⚠️ File not found for callee '{here.name}' at {here.path}");
                self.found_content = "";
            }

            disengage;
        }
    }


}
walker InheritsFromFinder {
    has child_name: str = "";
    has child_path: str = "";
    has parent_name: str = "";
    has found_content: str = "";
    has found_node: Class | None = None;

    can find_parent with Directory entry {
        # Visit all subnodes in the graph recursively
        visit [-->];
    }

    can traverse_file with File entry {
        visit [-->];
    }

    can traverse_class with Class entry {


        # Step 1: Find the child class by name and file path
        if here.name == self.child_name and here.path == self.child_path {
            print(f"✅ Found child class '{here.name}' at {here.path}");

            # Step 2: Traverse only the InheritsFrom edges to find the parent
            visit [->:InheritsFrom:->(`?Class)](?name==self.parent_name);
        } else {
            visit [-->];
        }
    }

    can check_parent with Class entry {

        # Step 3: Once we’re visiting via InheritsFrom edge, match the parent class
        if here.name == self.parent_name {
            print(f"✅ Found parent class '{here.name}' at {here.path}");

            if os.path.exists(here.path) {
                self.found_node = here;
                self.found_content = utils.read_file_contents(here.path);
                print(f"📄 Extracted contents for parent class '{here.name}'");
            } else {
                print(f"⚠️ File not found for parent '{here.name}' at {here.path}");
                self.found_content = "";
            }

            disengage;
        }
    }
}

walker ImportsFinder {
    has importer_name: str = "";
    has importer_path: str = "";
    has imported_name: str = "";
    has found_content: str = "";
    has found_node: File | None = None;

    can find_imported with Directory entry {
        # Visit all subnodes recursively to locate the importer file first
        visit [-->];
    }

    can check_file with File entry {

        # Step 1: Find the importer file by name and path
        if here.name == self.importer_name and here.path == self.importer_path {
            print(f"✅ Found importer file '{here.name}' at {here.path}");

            # Step 2: Traverse only the Imports edges from this file to its imports
            visit [->:Imports:->(`?File)](?name==self.imported_name);
        } else {
            visit [-->];
        }
    }

    can check_imported with File entry {

        # Step 3: Once visiting via Imports edge, match the imported module
        if here.name == self.imported_name {
            print(f"✅ Found imported file '{here.name}' at {here.path}");

            if os.path.exists(here.path) {
                self.found_node = here;
                self.found_content = utils.read_file_contents(here.path);
                print(f"📄 Extracted contents for imported file '{here.name}'");
            } else {
                print(f"⚠️ File not found for imported module '{here.name}' at {here.path}");
                self.found_content = "";
            }

            disengage;
        }
    }

}


with entry {
    load_dotenv();
}