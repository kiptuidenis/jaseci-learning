import os;

node Directory {
    has path: str;
    has name: str;
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

            # Skip ignored directories
            if entry in self.ignore_dirs {
                continue;
            }

            # Skip ignored files
            if entry in self.ignore_files or entry.endswith((".pyc", ".log", ".tmp")) {
                continue;
            }

            if os.path.isdir(full_path) {
                # It’s a subdirectory
                let subdir_node = Directory(path=full_path, name=entry);
                here ++> subdir_node;

                # Recursively visit subdir
                visit subdir_node;
            } else {
                # It’s a file
                let file_node = File(path=full_path, name=entry);
                here ++> file_node;
            }
        }
    }
}

walker TreeTraverser {
    can start_traversal with Directory entry {
        codebase_genius = [-->];
        backend = codebase_genius(`?Directory)(?name=="backend");
        print(backend);
    }
}
