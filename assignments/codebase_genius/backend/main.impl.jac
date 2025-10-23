impl Supervisor.execute {
    self.url = visitor.url;
    print(f"Supervisor received valid URL: {self.url}");
}

impl receiveurl.execute {
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
