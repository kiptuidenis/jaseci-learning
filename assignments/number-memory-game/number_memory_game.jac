"""A Number Memory Game that adapts difficulty and gives encouraging feedback using LLM."""

import random;
import time;
import os;
import sys;
import from byllm.llm { Model }

# Use an LLM for difficulty adjustment and encouragement
glob llm = Model(model_name="gemini/gemini-2.0-flash", verbose=False);

# --- LLM-powered functions ---

"""
Decide the next difficulty level of the game.

Arguments:
- correct_sequence: the list of digits shown to the player.
- user_input: the list of digits the player typed.
- difficulty: the current difficulty level.

Return:
- An integer representing the new difficulty level. 
  Increase if correct, decrease (but not below 1) if incorrect.
"""
def adjust_difficulty(correct_sequence: list[int], user_input: list[int], difficulty: int) -> int by llm();


"""
Generate an encouraging or corrective response.

Arguments:
- correct_sequence: the list of digits shown to the player.
- user_input: the list of digits the player typed.

Return:
- A short motivational string that praises correctness 
  or encourages the player to try again.
"""
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


# --- Walker implementations ---

impl NumberMemoryGame.start_game {
    if not [root --> (`?Level)] {
        next = root ++> Level(user_input=[], difficulty=1, correct_sequence=[]);
    } else {
        next = [root --> (`?Level)];
    }
    visit next;
}

impl NumberMemoryGame.announce_level {
    if [-->] {
        visit [-->];
    } else {
        choice: str = input(f"Are you ready for level {here.difficulty}? [Y/N] ");
        if choice.lower() != "y" {
            print("Exiting game. Goodbye!");
            disengage;
        }
    }
}

impl NumberMemoryGame.generate_sequence {
    here.correct_sequence = [];
    for i in range(here.difficulty) {
        here.correct_sequence.append(random.randint(1, 9));
    }
}

impl NumberMemoryGame.flash_digits {
    # Countdown before showing sequence
    print("Get ready...");
    time.sleep(1);
    print("Starting soon...");
    time.sleep(1);
    print("Here we go!");
    time.sleep(1);

    # Now show the digits
    for digit in here.correct_sequence {
        print(str(digit), end="\r");
        sys.stdout.flush();
        time.sleep(1);

        print(" " * len(str(digit)), end="\r");
        sys.stdout.flush();
        time.sleep(0.5);
    }
}

impl NumberMemoryGame.prompt_user {
    raw: str = input("Enter digits you saw (no spaces): ");
    here.user_input = [int(x) for x in raw];
}

impl NumberMemoryGame.update_level {
    # Get LLM feedback
    print(encouraging_feedback(here.correct_sequence, here.user_input));

    # Adjust difficulty with LLM
    new_diff = adjust_difficulty(here.correct_sequence, here.user_input, here.difficulty);

    # Spawn next level
    new_lvl = (here ++> Level(
        user_input = here.user_input,
        difficulty = new_diff,
        correct_sequence = []
    ))[0];

    visit new_lvl;
}
