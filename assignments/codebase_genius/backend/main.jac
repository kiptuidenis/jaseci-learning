import utils;
import os;
import uuid;
import subprocess;
import ast;
import jedi;


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


node Supervisor {
    has url: str = "";
    has root_dir: Directory | None | dict = None;
    has root_directory: Directory | None | dict = None;
    has readme_summary: str = "";

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
        print(f"Updated root directory: {self.root_dir}");
        disengage;
    }

    can build_partial_CCG with BuildCCG entry {
        self.root_directory = Directory(path=self.root_dir["path"], name=self.root_dir["name"], subdirectories=self.root_dir["subdirectories"], files=self.root_dir["files"]);

        print(self.root_directory);
        self.root_directory spawn BuildTreeWalker();
        files = self.root_directory spawn TreeTraverser();

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
        root_dir_updated = Directory(path=self.root_directory.path, name=os.path.basename(self.root_directory.path));
        root_dir_updated spawn BuildTreeWalker();
        root ++> root_dir_updated;
        partial_ccg = root_dir_updated spawn BuildPartialCCG();
        if partial_ccg.is_built {
            report "Success: Partial CCG built successfully.";
        } else {
            report "Error: Partial CCG build failed.";

        }
        disengage;
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
        root_dir spawn TreeTraverser();
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
            attached_mapper = here ++> new_mapper;
            visit attached_mapper;
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
                #here.subdirectories.append(subdir_node);
                here ++> subdir_node;
                visit subdir_node;
            } else {
                let file_node = File(path=full_path, name=entry);
                #here.files.append(file_node);
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
