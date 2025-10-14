import from byllm.llm {Model}
import os;

glob llm = Model(model_name="gemini/gemini-2.5-flash", verbose=True);

node Chat {
    # Ask the LLM to return a JSON object (dict) with "concepts": [ { "content": "..." }, ... ]
    def respond_with_concepts(message: str, chat_history: list[dict[str, str]]) -> dict[str, str] by llm(
        messages=chat_history
    );

    can chat with infer entry;
}


walker infer {
    has message: str;
    has chat_history: list[dict];
    has response: dict[str, str] = {};

    can init_chat with `root entry {
        visit [-->](`?Chat) else {
            chat_node = here ++> Chat();
            visit chat_node;
        }
    }
}

node Session {
    has id: str;
    has chat_history: list[dict];
    has status: int = 1;

    can chat with interact entry {
        visitor.chat_history = self.chat_history;
        visitor.chat_history.append({"role": "user", "content": visitor.message});

        response = infer(message=visitor.message, chat_history=self.chat_history) spawn root;
        visitor.chat_history.append({"role": "assistant", "content": response.response});

        self.chat_history = visitor.chat_history;
        report {"response": response.response};
    }
}

walker interact {
    has message: str;
    has session_id: str;
    has chat_history: list[dict] = [];

    can init_session with `root entry {
        visit [-->](`?Session)(?id == self.session_id) else {
            session_node = here ++> Session(id=self.session_id, chat_history=[], status=1);
            visit session_node;
        }
    }
}
