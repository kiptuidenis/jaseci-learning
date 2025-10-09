import from byllm.llm { Model }
glob llm = Model(model_name="gemini/gemini-2.0-flash", verbose=False);


"""The user is  traversing a dungeon consisting of multiple room.
each room has a word that the user has to guess, with correct letters
being revealed with each guess. Your job is to give them clues on what the word could be
based on the letters they guess. give hints that describe the word. not examples of what it could be."""
def giveHint(correctWord: str, guessedLetters: list) -> str by llm();


walker Player {
    has rooms: list = [];

    can start with `root entry;
    can processGuess with `root entry;
}


node room {
    has correctWord: str;
}


with entry:__main__ {
    root spawn Player();
}