impl Supervisor.update_url {
    self.url = visitor.url;
    print(f"Supervisor received valid URL: {self.url}");
}

impl RepoMapper.clone_repo {
    clone_result = utils.clone_repo(self.url);
        if (clone_result["success"]) {
            self.local_path = clone_result["path"];
            self.status = "cloned";
            print(f"Repository cloned to: {self.local_path}");
        } else {
            self.status = "failed";
            print(f"Cloning failed: {clone_result['message']}");
        }
}

impl receiveurl.validate_url {
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
