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
        # Step 1: Validate the URL
        validation = utils.validate_github_repo(self.url);

        # Step 2: Always report something to the frontend
        if not validation["valid"] {
            report f"Error: {validation['message']}";
            disengage;
        }

        report f"Success: {validation['message']}";

        # Step 3: (Future) Continue with Supervisor logic here later
    }
}
