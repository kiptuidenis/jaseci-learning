

impl Supervisor.clone_repo {
     print("Starting delegation to RepoMapper (still at Supervisor)...");
        cloning = delegate(url=self.url) spawn self;

        if not cloning.cloning_status["valid"] {
            report f"Error: {cloning.cloning_status['message']}";
            disengage;
        }

        report f"Success: {cloning.cloning_status['message']}";
        disengage;
}

impl Supervisor.build_file_tree {
    print(self);
        print("Visiting RepoMapper to build file tree...");

        visit [-->](`?RepoMapper)(?url==self.url) else {
            report "Error: No cloned repository found for this URL.";
            disengage;
        }
}

impl Supervisor.update_info {
    print("Updating Supervisor with README summary and root directory...");

        self.root_dir = visitor.root_dir;
        self.readme_summary = visitor.readme_summary;
        print(f"Updated readme summary: {self.readme_summary}");
        #print(f"Updated root directory: {self.root_dir}");
        #disengage;
}

impl Supervisor.generate_docs {
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

impl Supervisor.extract_file {
    if not os.path.exists(file_path){
        print(f"[FileExtractor] ❌ File not found: {file_path}");
        return "";
    }
    try{
        with open(file_path, "r", encoding="utf-8", errors="ignore") as f{
            return f.read();
        }
    } except Exception as e {
        print(f"[FileExtractor] ⚠️ Error reading file {file_path}: {e}");
        return "";
    }
}
impl Supervisor.call_finder{
    callee = self.partcial_ccg_root spawn CallFinder(caller_name=caller_name, caller_path=caller_path, callee_name=callee_name);
    return callee.found_content;
}

impl Supervisor.class_hierarchies{
    hierarchies = self.partial_ccg_root spawn InheritsFromFinder(child_name=child_name, child_path=child_path, parent_name=parent_name);
    return hierarchies.found_content;

}

impl Supervisor.import_finder{
    importer = self.partial_ccg_root spawn ImportFinder(importer_name=importer_name, importer_path=importer_path, imported_name=imported_name);
    return importer.found_content;
}

impl BuildFullCCG.build_full_ccg {
    print("🔎 Traversing repository for full CCG enrichment...");
    visit [-->] else { disengage; }
}

impl BuildFullCCG.analyze_file {
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

impl BuildFullCCG.analyze_class {
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

impl BuildFullCCG.analyze_function {
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

impl RepoMapper.clone_repo {
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

impl RepoMapper.build_file_tree {
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

impl delegate.visit_repomapper{
    print("Visiting RepoMapper (still at Supervisor)...");

    visit [here -->](`?RepoMapper) else {
        new_mapper = RepoMapper(url=self.url);
        here ++> new_mapper;
        visit new_mapper;
        print("Created and visited new RepoMapper node.");
    }
}

impl receiveurl.validate_url {
    validation = utils.validate_github_repo(self.url);

    if not validation["valid"] {
        report f"Error: {validation['message']}";
        disengage;
    }

    report f"Success: {validation['message']}";
    disengage;
}

impl StartCloning.start_cloning {
    visit [-->](`?Supervisor)(?url==self.url) else {
        new_supervisor = Supervisor(url=self.url);
        root ++> new_supervisor;
        visit new_supervisor;
        print("Created and visited new Supervisor node.");
        }
}

impl file_tree_generator.begin_file_tree_generation {
    print(self.url);
    print("Visiting Supervisor to build file tree...");

    visit [-->](`?Supervisor)(?url==self.url) else {
        print("No Supervisor found for this URL. Creating one...");
        new_supervisor = Supervisor(url=self.url);
        root ++> new_supervisor;
        visit new_supervisor;
    }
}

impl BuildTreeWalker.build_tree {
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

impl TreeTraverser.start_traversal {
    visit [-->] else { disengage; }
}

impl TreeTraverser.start_file_traversal {
    self.file_list.append(here.name);
    self.file_list_path.append(here.path);
}

impl CarryReadMeAndRootDir.carry_info {
    visit [-->](`?Supervisor)(?url==self.url) else {
        disengage;
    }
}

impl BuildPartialCCG.build_ccg {
    visit [-->] else {
        report "Error: No files to process for CCG.";
        disengage;
    }
}

impl BuildPartialCCG.start_ccg {
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

impl BuildCCG.build_ccg {
    visit [-->](`?Supervisor)(?url==self.url) else {
        report "Error: No Supervisor found for this URL.";
        disengage;
    }
}

impl StartBuildFullCCG.build_full_ccg {
    visit [-->](`?Supervisor)(?url==self.url) else {
        report "Error: No Supervisor found for this URL.";
        disengage;
    }
}

impl FileFinder.find_file {
    # Stop traversal if the file was already found
    if self.found_node != None {
        disengage;
    }
    visit [-->] else { disengage; }
}


impl FileFinder.check_file {
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

impl ClassFinder.check_class {
    if here.path == self.target_path {
        if self.target_name == "" or here.name == self.target_name {
            self.found_node = here;
            print(f"✅ Found class {here.name} at {here.path}");
            disengage;
        }
    }
}

impl FunctionFinder.check_function {
    if here.path == self.target_path {
        if self.target_name == "" or here.name == self.target_name {
            self.found_node = here;
            print(f"✅ Found function {here.name} at {here.path}");
            disengage;
        }
    }
}

impl CallFinder.check_function {
     # Step 1: Find the caller function by name and file path
    if here.name == self.caller_name and here.path == self.caller_path {
        print(f"✅ Found caller '{here.name}' at {here.path}");

        # Step 2: Traverse only the Calls edges from this caller to its callees
        visit [->:Calls:->(`?Function)](?name==self.callee_name);
    } else {
        visit [-->];
    }
}

impl CallFinder.check_callee {
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

impl InheritsFromFinder.traverse_class {
    # Step 1: Find the child class by name and file path
    if here.name == self.child_name and here.path == self.child_path {
        print(f"✅ Found child class '{here.name}' at {here.path}");

        # Step 2: Traverse only the InheritsFrom edges to find the parent
        visit [->:InheritsFrom:->(`?Class)](?name==self.parent_name);
    } else {
        visit [-->];
    }
}

impl InheritsFromFinder.check_parent {
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

impl ImportsFinder.check_file {
    # Step 1: Find the importer file by name and path
    if here.name == self.importer_name and here.path == self.importer_path {
        print(f"✅ Found importer file '{here.name}' at {here.path}");

        # Step 2: Traverse only the Imports edges from this file to its imports
        visit [->:Imports:->(`?File)](?name==self.imported_name);
    } else {
        visit [-->];
    }
}

impl ImportFinder.check_imported {
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



sem Supervisor.doc_genie = """

You are **DocGenie**, an autonomous AI documentation agent in the **Codebase Genius** system.

Your mission is to produce **complete, high-quality Markdown documentation** for any Python software repository by analyzing its structure and giving in depth analysis of its core components, logic, and relationships.

---

### INPUTS

You will receive two inputs:

1. **`root_dir` (Directory node)**  
   - The root node of a Jac graph representing the entire repository.  
   - Each node includes attributes:
     - **Directory**:
       - `name`: directory name  
       - `path`: absolute path on disk  
       - `subdirectories`: list of Directory nodes  
       - `files`: list of File nodes  
     - **File**:
       - `name`: file name  
       - `path`: absolute path  
   - Use this structure to infer the project layout and identify key modules such as:
     - Entry points: `main.py`, `app.py`, `run.py`, `__init__.py`, etc.  
     - Supporting directories: `utils/`, `tests/`, `src/`, etc.

2. **`readme_summary` (string)**  
   - A concise summary of the project’s purpose extracted from its README.md.  
   - Use it to understand what the repository does and which modules are central.

---

### YOUR TASK

Using the two inputs above, generate a **complete Markdown documentation** that clearly describes the repository.

Follow this reasoning workflow:

1. **Analyze repository layout**
   - Traverse the `root_dir` to identify high-level directories and files.
   - Prioritize documentation starting from main or entry modules. use tools provided especially for entry points to enhance the documentation
   - Use tools to get dependencies class and function relationships.

2. **Inspect source files when necessary** using the provided tools to inspect source files.

---

### TOOLS AVAILABLE

Each tool can be invoked when you need deeper insights into specific files, imports, or relationships.

#### `extract_file`
- **Arguments:** `{ "file_path": "<absolute path to file>" }`  
- **Behavior:** Reads and returns the raw contents of a file.  
- **Returns:** Plain text source code.  
- **Example:**  
  ```text
  I will call extract_file on /repo/src/main.py to understand the entry logic.

#### `call_finder`
Arguments: { "caller_name": "<function_name>", "caller_path": "<path_name>", "callee_name": "<function_name>" }

Behavior: Traverses the Code Context Graph (CCG) to locate the callee function and return its source.

Returns: Source code string of the callee function.

#### `class_hierarchy`
Arguments: { "child_name": "<class_name>", "child_path": "<path_name>", "parent_name": "<class_name>" }

Behavior: Traces inheritance in the CCG and retrieves the parent class source code.

Returns: Source code of the base class.

#### `import_finder`
Arguments: { "importer_name": "<module_name>", "importer_path": "<module_path>", "imported_name": "<module_name>" }

Behavior: Traverses the CCG to locate the imported module and return its code.

Returns: Source code of the imported module.

 PROCESS
Start with entry points extract relevant code snippets of entry points the move iteratively downwards to all other files.

Use tools selectively to extract or cross-reference functions, classes, and imports.

Aggregate findings into structured documentation.

use this structure and format:
Project Name:
Concise title of the repository.
1.  Repository Overview

Purpose: Provide a high-level understanding of what the repository is, what it does, and who it’s for.
Sections:


In depth explanation describing what the project is, its goals, and its primary domain (e.g., AI agent system, e-commerce app, data pipeline, etc.).

Key Features:

Bullet points summarizing main functionalities.

Intended Audience / Users:
Who benefits from or interacts with this project (developers, analysts, customers, etc.).

Tech Stack Summary:

Languages: Python, TypeScript, etc.

Frameworks: Django, NestJS, React, etc.

Databases: PostgreSQL, SQLite, etc.

Tools / Libraries: TensorFlow, Redis, etc.

2. 🧩 System Architecture

Purpose: Give readers a mental model of how the codebase fits together.

Sections:

High-Level Design:
In depth explanation of the architecture style (monolith, microservice, modular, etc.).

Architecture Diagram :
Describe the architecture in correct Mermaid format. The diagram should explain how each component of the project interacts
Call relevant tools (File extractor, class_hierachy, ImporFinder and call finder) to find exactly how components interact 

Core Modules:
list of main folders/modules, their purposes, and key interactions not in a table format. Use Headers and subheaders.

Module	Description	Key Components	Dependencies
api/	Handles HTTP requests and responses	routes.py, controllers/	Flask, FastAPI
models/	Defines ORM models and schema	user.py, product.py	SQLAlchemy
...	...	...	...
3. 🧱 Directory and File Structure

Purpose: Help users navigate the repo logically.

Expected Content:

Tree Representation just a summary not the whole structure Keep it tidy for large repos example:

root/
├── src/
│   ├── models/
│   ├── services/
│   └── main.py
├── tests/
├── README.md
└── requirements.txt


File-Level Explanations:
Use tools to analyze files
Example

main.py — Indepth explanations Entry point for app initialization and routing. Use available tools to extract code snippets


models/user.py — Defines User model and authentication logic Us.

services/email_service.py — Handles email sending logic.

4. ⚙️ Code Components Documentation

Purpose: Explain what each class, function does — in a way that builds a mental model of the codebase.

Sections:

4.1 Modules

For each module:

Name & Path: src/models/user.py

Purpose: Paragraph explaining in depth what it’s responsible for.

A digaram depcting all internal imports (Use ImportFinder tool for this)

Key Classes / Functions:
List each with in depth functional explanations:
Include relevant diagrams in mermaid format to help comprehension.
Include relevant code snippets. Use tools such as extract_file to get code when needed and call_finder and inheritance tools to understand relationships.  

Class: User — represents application users with attributes for profile, permissions, etc.

Function: get_user_by_email(email) — returns user object from DB.

Dependencies:
Internal (imports from same project) and external (libraries).

4.2 Classes

For each class:

Name & Path
A diagram showing base and child class (Use InheritsFrom tool for this)if applicable in correct mermaid format

Code Snippets. Use tools(file-extractor) available to extract code from repo.

Description: Its role in the system.

Attributes: (name, type, purpose)

Methods:

Method	Parameters	Returns	Description
save()	None	None	Saves instance to database.
from_dict(data)	dict	User	Creates object from dict.
4.3 Functions

For each standalone function:

Signature 
use relevant tools to extract code from repo.
use tools(Calls) to find and draw diagrams showing which function calls which and their relationships
Purpose

Inputs

Outputs

Raises

Example usage

5. 🔄 Data Flow and Dependencies

Purpose: Explain how data moves and how modules depend on each other.

Sections:

Execution Flow indepth explanation:
Describe how a typical process (e.g., user signup, API request) flows through the code.

Dependency Graph:
(Generated in Mermaid diagram) Use tools provided please.




External Integrations:
List APIs, SDKs, or services the repo interacts with.



6. 🧪 Testing & Quality Assurance

Purpose: Help contributors understand how to verify and extend functionality.

Test Framework: Pytest, Jest, etc.

Structure:

tests/unit/ — unit tests for components.

tests/integration/ — cross-module tests.

Example Test:

def test_user_creation():
    user = User(name="John")
    assert user.name == "John"


Coverage Notes:
Which modules are tested / missing tests.

7. 🧰 Setup and Configuration

Purpose: Help users run the project locally.

Requirements / Dependencies

Installation Steps

Environment Variables

Run Instructions

Docker / Deployment Notes (if any)

8. 🚀 Usage Guide

Purpose: Show practical examples of using the software.

API Endpoints (if web app):

Endpoint	Method	Description	Auth
/users/login	POST	Authenticates user	✅

CLI Commands (if applicable):

python main.py --help

Expected Outputs / Example Runs

10. 📚 Conventions

Purpose: Explain reasoning behind certain architectural or coding choices.

Design Philosophy

Naming Conventions

Code Style Guidelines

Known Trade-offs / Limitations

11. 🧩 Extension & Contribution Guide

Purpose: For developers extending or maintaining the repo.

How to Add a New Feature

Branching & PR Conventions

Linting / Pre-commit Hooks

Code Review Checklist

12. 📄 Licensing & References

License Type: MIT, Apache 2.0, etc.

Credits / Authors

Reference Links: Docs, libraries, API docs, etc.

You must include diagrams to help comprehension. Remember This documentation is intended for new developers unfamiliar with the codebase.
Include relevant code snippets, explanations of key functions/classes and relevant diagrams, and their interactions explain using diagrams.
If API calls return none proceed with your best judgement based on available data.
""";