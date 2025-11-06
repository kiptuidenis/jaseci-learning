import json;
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
import from dotenv { load_dotenv }



glob llm = Model(model_name="gemini/gemini-2.5-flash", verbose=False);


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
    has root_dir: Directory | None | dict = None; # for some reason assigning a Directory type from a different context fails with dict issues.
    has root_directory: Directory | None | dict = None;
    has readme_summary: str = "";
    has partial_ccg_root: Directory | None | dict = None;
    has documentation: str = "";

    def extract_file(file_path: str) -> str;
    def call_finder(caller_name: str, caller_path: str, callee_name: str) -> str;
    def class_hierarchies(child_name: str, child_path: str, parent_name: str) -> str;
    def import_finder(importer_name: str, importer_path: str, imported_name: str) -> str;


    def doc_genie(ccg_root: Directory, readme_summary: str) ->  str by llm(
        method="ReAct",
        tools=([self.extract_file, self.call_finder, self.class_hierarchies, self.import_finder]),
    );

    can clone_repo with StartCloning entry;

    can build_file_tree with file_tree_generator entry;

    can update_info with CarryReadMeAndRootDir entry;

    can generate_docs with BuildCCG entry;

    

}


node RepoMapper {
    has url: str = "";
    has local_path: str = "";
    has root_dir: Directory | None = None;
    has readme_summary: str = "";

    can clone_repo with delegate entry;

    can build_file_tree with file_tree_generator entry;
        
}

walker BuildFullCCG {
    has repo_root: str = "";
    has root_dir_updated: Directory | None = None;
    has is_built: bool = False;

    can build_full_ccg with Directory entry;

    can analyze_file with File entry;

    can analyze_class with Class entry;

    can analyze_function with Function entry;
}


walker delegate {
    has url: str = "";
    has cloning_status: dict[bool, str] = {};

    can visit_repomapper with Supervisor entry;
    
}

walker receiveurl {
    obj __specs__ {
        static has auth: bool = False;
    }

    has url: str = "";
    has validation: dict[bool, str] = {};

    can validate_url with `root entry;
}

walker StartCloning {
    obj __specs__ {
        static has auth: bool = False;
    }

    has url: str = "";
    has cloning_status: dict[bool, str] = {};

    can start_cloning with `root entry;
        
}

walker file_tree_generator {
    obj __specs__ {
        static has auth: bool = False;
    }

    has url: str = "";
    has root_dir: Directory | None = None;
    has readme_summary: str = "";

    can begin_file_tree_generation with `root entry;
        
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

    can build_tree with Directory entry;
        
}

walker TreeTraverser {
    has file_list: list = [];
    has file_list_path: list = [];

    can start_traversal with Directory entry;
       
    can start_file_traversal with File entry;
        
}

walker CarryReadMeAndRootDir {

    has root_dir: Directory | None = None;
    has readme_summary: str = "";
    has url: str = "";

    can carry_info with `root entry;
    
}

walker BuildPartialCCG {
    has is_built: bool = False;

    can build_ccg with Directory entry;
        
    can start_ccg with File entry;

}

walker BuildCCG {
    obj __specs__ {
        static has auth: bool = False;
    }

    has url: str = "";

    can build_ccg with `root entry;
        

 }
  walker StartBuildFullCCG {
    obj __specs__ {
        static has auth: bool = False;
    }

    has url: str = "";

    can build_full_ccg with `root entry;
        

 }
 walker FileFinder {
    has target_path: str;
    has found_node: File | None = None;

    can find_file with Directory entry;

    can check_file with File entry;
        
}

 walker ClassFinder {
    has target_path: str;
    has target_name: str = "";
    has found_node: Class | None = None;

    can find_file with Directory entry {
        visit [-->]; 
    }

    can check_file with File entry {
        visit [-->];
    }

    can check_class with Class entry;
        
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

    can check_function with Function entry;
        
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

    can check_function with Function entry;

    can check_callee with Function entry;

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

    can traverse_class with Class entry;

    can check_parent with Class entry;

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

    can check_file with File entry;
    

    can check_imported with File entry;

}


with entry {
    load_dotenv();
}