walker ClassFinder {
    has target_path: str;
    has target_name: str = "";
    has found_node: Class | None = None;

    can find_file with Directory entry {
        if self.found_node != None {
            disengage;
        }
        visit [-->] else { disengage; }
    }

    can check_file with File entry {
        if self.found_node != None {
            disengage;
        }
        visit [-->] else { disengage; }
    }

    can check_class with Class entry {
        if here.path == self.target_path {
            if self.target_name == "" or here.name == self.target_name {
                self.found_node = here;
                print(f"✅ Found class {here.name} at {here.path}");
                disengage;
            }
        }
    }
}

walker FunctionFinder {
    has target_path: str;
    has target_name: str = "";
    has found_node: Function | None = None;

    can find_function with Directory entry {
        if self.found_node != None {
            disengage;
        }
        visit [-->] else { disengage; }
    }

    can check_file with File entry {
        if self.found_node != None {
            disengage;
        }
        visit [-->] else { disengage; }
    }

    can check_function with Function entry {
        if here.path == self.target_path {
            if self.target_name == "" or here.name == self.target_name {
                self.found_node = here;
                print(f"✅ Found function {here.name} at {here.path}");
                disengage;
            }
        }
    }
}
