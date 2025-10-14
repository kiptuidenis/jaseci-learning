import os
import chainlit as cl
from dotenv import load_dotenv
from langchain_google_genai import ChatGoogleGenerativeAI

# Load .env variables
load_dotenv()

# Initialize Gemini model
llm = ChatGoogleGenerativeAI(
    model="gemini-2.5-flash",
    google_api_key=os.getenv("GOOGLE_API_KEY"),
    temperature=0.7
)

@cl.on_chat_start
async def start_chat():
    await cl.Message(content="👋 Hello! How can I help you today?").send()

@cl.on_message
async def handle_message(message: cl.Message):
    """Handle user input and stream Gemini’s reply"""
    try:
        response = llm.invoke(message.content)
        await cl.Message(content=response.content).send()
    except Exception as e:
        await cl.Message(content=f"⚠️ Error: {e}").send()
