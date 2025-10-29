import utils;
import file_tree_generator;
import os;

node Directory {
    has path: str;
    has name: str;
    has subdirectories: list[Directory] = [];
    has files: list[File] = [];
}

node File {
    has path: str;
    has name: str;
}

node Supervisor {
    has url: str = "";

    can clone_repo with start_cloning entry {
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
        print(f"This is the type of root_dir: {type(root_dir)}");
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

walker start_cloning {
    obj __specs__ {
        static has auth: bool = False;
    }

    has url: str = "";
    has cloning_status: dict[bool, str] = {};

    can begin_cloning with `root entry {
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
    can start_traversal with Directory entry {
        print(here);
            print("\n");
                 visit [-->] else{
                disengage;
    }     
}

can start_file_traversal with File entry {
        print(here);
        print("\n");
                
}
}