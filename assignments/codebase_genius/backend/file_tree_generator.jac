import utils;
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

    can start_traversal with Directory entry {
                 visit [-->] else{
                disengage;
    }     
}

can start_file_traversal with File entry {
        self.file_list.append(here.name);                
}
}

with entry {
    root_dir = Directory(path="/home/denis/jaseci-learning/assignments/codebase_genius", name=os.path.basename("/home/denis/jaseci-learning/assignments/codebase_genius"));
    root_dir spawn BuildTreeWalker();
    root ++> root_dir;
    files = root_dir spawn TreeTraverser();
    print(f"All files collected: {files.file_list}");

}