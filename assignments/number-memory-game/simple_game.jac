"""A Number Guessing Game"""

import random;
import time;
import os;
import sys;
import from byllm.llm { Model }

glob llm = Model(model_name="gemini/gemini-2.0-flash", verbose=False);

"""Give user an encouraging response based on whether they correctly input the numbers."""
def give_encouraging_response(correct_sequence: list[int], user_input: list[int]) -> str by llm();

node Level {
    has user_input: list[int];
    has difficulty: int;
    has correct_sequence: list[int] = [];
}

walker Game {
    can start with `root entry;
    can give_heads_up with Level entry;
    can generate_sequence with Level entry;
    can flash_digits with Level entry;
    can prompt_user with Level entry;
    can update_level with Level entry;
}

with entry {
    root spawn Game();
}

impl Game.start {
    if not [root --> (`?Level)] {
        next = root ++> Level(user_input=[], difficulty=1, correct_sequence=[]);
    } else {
        next = [root --> (`?Level)];
    }
    visit next;
}

impl Game.give_heads_up {
    if [-->] {
        visit [-->];
    } else {
        choice: str = input(f"Are you ready for level {here.difficulty}? [Y/N]");
        if choice.lower() != "y" {
            print("exiting..");
            disengage;
        }
    }
}

impl Game.generate_sequence {
    here.correct_sequence = [];
    for i in range(here.difficulty) {
        here.correct_sequence.append(random.randint(1, 10));
    }
}

impl Game.flash_digits {
    for digit in here.correct_sequence {
        # Show the digit
        print(str(digit), end="\r");
        sys.stdout.flush();
        time.sleep(1);

        # Hide it completely (pad with spaces)
        print(" " * len(str(digit)), end="\r");
        sys.stdout.flush();
        time.sleep(0.5);
    }
}

impl Game.prompt_user {
    raw: str = input("Enter digits you saw with the exact sequence (no spaces): ");
    here.user_input = [int(x) for x in raw];
}

impl Game.update_level {
    def incr_or_decr_difficulty_local(correct_sequence: list[int], user_input: list[int], difficulty: int) -> int {
        if correct_sequence == user_input {
            return difficulty + 1;
        } else {
            return max(1, difficulty - 1);
        }
    }

    # Get encouragement from the LLM
    print(give_encouraging_response(here.correct_sequence, here.user_input));

    # Update difficulty deterministically
    new_lvl = (here ++> Level(
        user_input = here.user_input,
        difficulty = incr_or_decr_difficulty_local(here.correct_sequence, here.user_input, here.difficulty),
        correct_sequence = []
    ))[0];

    visit new_lvl;
}
