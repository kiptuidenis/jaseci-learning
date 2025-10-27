import utils;
import file_tree;

node Supervisor {
    has url: str = "";
    has file_tree_root: Directory;


    can clone_repo with start_cloning entry {
        print("Starting delegation to RepoMapper(still at supervisor)...");
        cloning = delegate(url=self.url) spawn self;
        if not cloning.cloning_status["valid"] {
            report f"Error: {cloning.cloning_status['message']}";
            disengage;
        }
        report f"Success: {cloning.cloning_status['message']}";
        disengage;
    }

    can build_file_tree with file_tree_generator entry {
        print("Visiting RepoMapper to build file tree...");
        visit [-->](`?RepoMapper)(?url==self.url) else {
            report "Error: No cloned repository found.";
            disengage;
        }
        
    }
}



node RepoMapper {
    has url: str = "";
    has local_path: str = "";


    # clones repo and updates local_path and status
    can clone_repo with delegate entry{
        print("Arrived at RepoMapper to clone the repository...");
        clone_result = utils.clone_repo(self.url);
        if (clone_result["success"]) {
            self.local_path = clone_result["path"];
            self.status = True;
            visitor.cloning_status = {"valid": self.status, 'message': 'Repository cloned successfully.'};
            report visitor.cloning_status;
            print(f"Repository cloned to: {self.local_path}");
        } else {
            self.status = False;
            visitor.cloning_status = {"valid": self.status, 'message': f"Cloning failed: {clone_result['message']}"};
            report visitor.cloning_status;
            print(f"Cloning failed: {clone_result['message']}");
        }
    }

    # builds file tree from local_path
    can build_file_tree with file_tree_generator entry {
        root_dir = utils.walk_directory(self.local_path);
    }


}

walker delegate {
    has url: str = "";
    has cloning_status: dict[bool, str] = {};

    can visit_repomapper with Supervisor entry{
        print("visiting RepoMapper(still at supervisor)...");
        visit [here --> ](`?RepoMapper) else {
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
              # Step 1: Validate the URL
        validation = utils.validate_github_repo(self.url);

        # Step 2: Always report something to the frontend
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

    can begin_cloning with `root entry{
        visit [-->](`?Supervisor) else {
            new_supervisor = Supervisor(url=self.url);
            visit new_supervisor;
            print("Created and visited new Supervisor node.");
        }
    }
}

walker file_tree_generator {
    obj __specs__ {
        static has auth: bool = False;
    }

    can begin_file_tree_generation with `root entry{
        visit [-->](`?Supervisor);
    }
}
