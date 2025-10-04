"""A Number Memory Game that adapts difficulty and gives encouraging feedback using LLM."""

import random;
import time;
import os;
import sys;
import from byllm.llm { Model }

# Use an LLM for difficulty adjustment and encouragement
glob llm = Model(model_name="gemini/gemini-2.0-flash", verbose=False);

# --- LLM-powered functions ---


def adjust_difficulty(correct_sequence: list[int], user_input: list[int], difficulty: int) -> int by llm();



def encouraging_feedback(correct_sequence: list[int], user_input: list[int]) -> str by llm();


# --- Core game data structure ---
node Level {
    has user_input: list[int];
    has difficulty: int;
    has correct_sequence: list[int] = [];
}


# --- Game walker ---
walker NumberMemoryGame {
    can start_game with `root entry;
    can announce_level with Level entry;
    can generate_sequence with Level entry;
    can flash_digits with Level entry;
    can prompt_user with Level entry;
    can update_level with Level entry;
}


# --- Entry point ---
with entry {
    root spawn NumberMemoryGame();
}


