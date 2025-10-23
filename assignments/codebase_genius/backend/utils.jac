walker receiveurl {
    has url: str = "";

    can execute with `root entry {
        print("Received URL: " + self.url);
    }
}