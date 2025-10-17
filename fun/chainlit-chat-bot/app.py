import os
import chainlit as cl
from dotenv import load_dotenv
from langchain_google_genai import ChatGoogleGenerativeAI

load_dotenv()

# --- Initialize Gemini ---
llm = ChatGoogleGenerativeAI(
    model="gemini-2.5-flash",
    google_api_key=os.getenv("GOOGLE_API_KEY"),
    temperature=0.7,
    streaming=True
)

# --- Session memory manager ---
# Holds chat states per session
user_sessions = {}


def get_chat_state(user_id):
    """Return or initialize session state for a user."""
    if user_id not in user_sessions:
        user_sessions[user_id] = {
            "main": [],        # main chat messages
            "subchats": {}     # {"concept": [messages]}
        }
    return user_sessions[user_id]


@cl.on_chat_start
async def start_chat():
    user_id = cl.user_session.get("id", "anonymous")
    get_chat_state(user_id)
    await cl.Message(
        content="👋 Hey! Ask me anything. Hover over a concept (frontend feature) to dive deeper."
    ).send()


@cl.on_message
async def handle_message(message: cl.Message):
    """Handles messages for the MAIN chat."""
    user_id = cl.user_session.get("id", "anonymous")
    state = get_chat_state(user_id)

    # Save user message
    state["main"].append({"role": "user", "content": message.content})

    msg = cl.Message(content="")
    async for chunk in llm.astream(message.content):
        token = chunk.content
        if token:
            await msg.stream_token(token)

    await msg.send()

    # Save model message
    state["main"].append({"role": "assistant", "content": msg.content})


# --- Subchat handler ---
@cl.action_callback("dive_deeper")
async def dive_deeper(action):
    """
    Handles a frontend-triggered subchat action.
    Expects action.value = concept/topic text to expand.
    """
    user_id = cl.user_session.get("id", "anonymous")
    state = get_chat_state(user_id)

    concept = action.value.strip()
    await cl.Message(content=f"🔎 Diving deeper into **{concept}**...").send()

    # Create subchat entry if not exists
    if concept not in state["subchats"]:
        state["subchats"][concept] = []

    msg = cl.Message(content="")
    async for chunk in llm.astream(f"Explain in detail: {concept}"):
        token = chunk.content
        if token:
            await msg.stream_token(token)
    await msg.send()

    # Store in subchat state
    state["subchats"][concept].append(
        {"role": "assistant", "content": msg.content}
    )

    await cl.Message(content="🧩 You can now close this subchat and continue the main discussion.").send()
