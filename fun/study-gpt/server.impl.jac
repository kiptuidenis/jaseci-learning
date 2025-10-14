sem Chat.respond_with_concepts = """
Respond naturally to the user's message, but ensure your full output is a JSON object/dict 
with a single top-level key "concepts". Each concept represents one coherent idea, 
sentence, or paragraph that contributes to a natural, flowing explanation.

Do not include any extra text, code fences, or commentary outside the JSON object. 
The JSON must strictly follow this format:

{
  "concepts": [
    {"content": "First part of your natural explanation..."},
    {"content": "Next related idea, continuing naturally..."},
    {"content": "And so on, until the answer feels complete."}
  ]
}
""";



impl Chat.chat {
    # Call LLM and get a dict like: { "concepts": [ {"content": "..."}, ... ] }
    structured = self.respond_with_concepts(
        message=visitor.message,
        chat_history=visitor.chat_history
    );

    # Append structured response into the visitor chat_history.
    # Storing structured content preserves concept chunks for later retrieval.
    visitor.chat_history.append({"role": "assistant", "content": structured});

    # update the chat node's history (if you keep it)
    self.chat_history = visitor.chat_history;

    # expose the structured result back up the call stack
    visitor.response = structured;

    # Return the structured JSON directly in the report
    report {"response": structured};
}
