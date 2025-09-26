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
