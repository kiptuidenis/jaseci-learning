import utils;

node Supervisor {
    has url: str = "";
    
    can update_url with receiveurl entry;

    can start_delegation with receiveurl entry {
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
    has url: str = "";

    can visit_repomapper with Supervisor entry{
        visit [-->](`?RepoMapper) else {
            new_mapper = RepoMapper(url=self.url);
            attached_mapper = root ++> new_mapper;
            visit attached_mapper;
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
