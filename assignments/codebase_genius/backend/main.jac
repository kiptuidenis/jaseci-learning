import utils;

node Supervisor {
    has url: str = "";
    can execute with receiveurl entry {
        self.url = visitor.url;
        print(f"Supervisor received valid URL: {self.url}");
    }
}

walker receiveurl {
    obj __specs__ {
        static has auth: bool = False;
    }

    has url: str = "";
    has validation: dict[bool, str] = {};

    can execute with `root entry {
        # Step 1: Validate the URL
        validation = utils.validate_github_repo(self.url);

        # Step 2: Always report something to the frontend
        if not validation["valid"] {
            report f"Error: {validation['message']}";
            disengage;
        }

        report f"Success: {validation['message']}";

        # Step 3: Continue with Supervisor 
        visit [-->](`?Supervisor) else {
            new_supervisor = Supervisor();
            attached_supervisor = root ++> new_supervisor;
            visit attached_supervisor;
        }
    }
}
