import utils;

node Supervisor {
    has url: str = "";

    can update_url with receiveurl entry;

    can start_delegation with receiveurl entry {
        print("Starting delegation to RepoMapper(still at supervisor)...");
        file_tree = delegate(url=self.url) spawn self;
    }
}

node RepoMapper {
    has url: str = "";
    has local_path: str = "";
    has status: str = "pending";

    # clones repo and updates local_path and status
    can clone_repo with delegate entry;


}

walker delegate {
    obj __specs__ {
        static has auth: bool = False;
    }
    has url: str = "";

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

    can validate_url with `root entry;
      
}
