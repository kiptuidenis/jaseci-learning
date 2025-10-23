import utils;

node Supervisor {
    has url: str = "";

}

walker receiveurl {
    obj __specs__ {
        static has auth: bool = False;
    }
    has url: str = "";
    has validation: dict[bool, str] = {};

    can execute with `root entry {
        # verify the URL format
        validation = utils.validate_github_repo(self.url);

        # Step 2: Report results back to frontend
        if not validation["valid"] {
            report validation["message"];
            disengage;  # stop execution if invalid
        }

        report validation["message"];

        # Step 3: Continue with Supervisor in later steps
    }
     
}