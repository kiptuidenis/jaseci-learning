import from byllm.llm {Model}
import from byllm.types {Image, Video, Text}
import from tools {RagEngine}
import os;
import base64;
import mcp_client;
import from dotenv {load_dotenv}
::py::
load_dotenv()
::py::


glob rag_engine:RagEngine = RagEngine();
glob llm = Model(
    model_name="ollama/phi3",
    base_url=os.getenv('OLLAMA_BASE_URL', 'http://localhost:8050'),
    verbose=True
);
glob llm_reason = Model(
    model_name="gemini/gemini-2.0-flash",
    verbose=True
);
glob MCP_SERVER_URL: str = os.getenv('MCP_SERVER_URL', 'http://localhost:8899/mcp');


enum ChatType {
    RAG,
    QA,
    IMAGE,
    VIDEO
}


node Router {
    def classify(message: str) -> ChatType by llm_reason(method="Reason", temperature=0.8);
}

node Chat {
    has chat_type: ChatType;
}


walker infer {
    has message: str;
    has chat_history: list[dict];
    has response: str = "";
    has file_path: str = "";

    can init_router with `root entry {
        visit [-->](`?Router) else {
            router_node = here ++> Router();
            router_node ++> RagChat(chat_type=ChatType.RAG);
            router_node ++> QAChat(chat_type=ChatType.QA);
            router_node ++> ImageChat(chat_type=ChatType.IMAGE);
            router_node ++> VideoChat(chat_type=ChatType.VIDEO);
            visit router_node;
        }
    }
    can route with Router entry {
    classification = here.classify(message=self.message);
    print("🔍 Raw classification result:", classification);
    print("Routing message:", self.message, "to chat type:", classification);

    try {
        visit [-->](`?Chat)(?chat_type==classification);
    } except ValueError {
    print("⚠️ Routing failed — possible missing chat_type field");
}

    }
}


node ImageChat(Chat) {
    has chat_type: ChatType = ChatType.IMAGE;

    def respond_with_image(img: Image, text: Text, chat_history: list[dict]) -> str by llm(tools=([use_mcp_tool, list_mcp_tools]));

    can chat with infer entry;
}



node VideoChat(Chat) {
    has chat_type: ChatType = ChatType.VIDEO;

    def respond_with_video(video: Video, text: Text, chat_history: list[dict]) -> str by llm(
        method="Chain-of-Thoughts");

    can chat with infer entry;
}

node RagChat(Chat) {
    has chat_type: ChatType = ChatType.RAG;

    def respond(message:str, chat_history:list[dict]) -> str by llm(
            method="ReAct",
            tools=([list_mcp_tools, use_mcp_tool]),
            messages=chat_history,
            max_react_iterations=6
        );

    can chat with infer entry;
}

node QAChat(Chat) {
    has chat_type: ChatType = ChatType.QA;

    def respond(message:str, chat_history:list[dict]) -> str
        by llm(
            messages=chat_history,
            max_react_iterations=6
        );

    can chat with infer entry;
}

walker interact {
    has message: str;
    has session_id: str;
    has chat_history: list[dict] = [];
    has file_path: str = "";

    can init_session with `root entry {
        visit [-->](`?Session)(?id == self.session_id) else {
            session_node = here ++> Session(id=self.session_id, chat_history=[], file_path=self.file_path, status=1);
            visit session_node;
        }
    }
}



node Session {
    has id: str;
    has chat_history: list[dict];
    has status: int = 1;
    has file_path: str = "";

    can chat with interact entry {
        visitor.chat_history = self.chat_history;
        visitor.chat_history.append({"role": "user", "content": visitor.message});
        response = infer(message=visitor.message, chat_history=self.chat_history, file_path=visitor.file_path) spawn root;
        visitor.chat_history.append({"role": "assistant", "content": response.response});
        self.chat_history = visitor.chat_history;
        report {"response": response.response};
    }
}


walker upload_file {
    has file_name: str;
    has file_data: str;
    has session_id: str;

    can save_doc with `root entry;
}