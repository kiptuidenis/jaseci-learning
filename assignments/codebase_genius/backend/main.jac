import utils;

node Supervisor {
    has url: str = "";
    can execute with receiveurl entry {}
}

walker receiveurl {
    obj __specs__ {
        static has auth: bool = False;
    }

    has url: str = "";
    has validation: dict[bool, str] = {};

    can execute with `root entry {}
      
}
