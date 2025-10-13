sem Chat.respond = """Generate a helpful response to the user's message using chat history.""";

impl Chat.chat {
    response = self.respond(
        message=visitor.message,
        chat_history=visitor.chat_history
    );

    visitor.chat_history.append({"role": "assistant", "content": response});
    self.chat_history = visitor.chat_history;
    visitor.response = response;

    report {"response": response, "chat_history": visitor.chat_history};
}
