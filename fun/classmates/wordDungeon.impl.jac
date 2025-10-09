import from wonderwords { RandomWord }


impl Player.start{
    rw = RandomWord();
    #creating 5 rooms with random words:
    self.rooms =
        [];
    for i = 0 to i < 5 by i += 1 {
        word = rw.word();
        temp = root ++> room(word);
        n = temp[0];
        self.rooms.append(n);
    }
    #connecting the rooms together
     for i = 0 to i < len(self.rooms) - 1 by i += 1 {
        self.rooms[i] ++> self.rooms[i + 1];
    }
}


impl Player.processGuess{
    count = 0;
    wins = 0;
    print("Starting dungeon traversal...");
    # loop over every room
     for r in self.rooms {
        print(f"You are now in room {count + 1}");
        visit r;
        wordGuess = [];
        wrongLetters = [];
        for i in r.correctWord {
            wordGuess.append(" _ ");
        }
        print(wordGuess);
        print(f"The word has {len(r.correctWord)} letters.");
        for m = 0 to m < 6 by m += 1 {
            print(f"You have {6 - m} guesses remaining.");
            guess = input("Enter your guess: ");
            if guess == r.correctWord {
                print("Congratulations! You can now progress to the next room.");
                print("||||||||");
                print("||||||||");
                wins += 1;
                break;
            } else {
                for j in guess {
                    if (r.correctWord.find(j) >= 0) {
                        wordGuess[r.correctWord.find(j)] = j;
                    } else {
                        if j not in wrongLetters {
                            wrongLetters.append(j);
                        }
                    }
                }
                print(wordGuess);
                print(giveHint(r.correctWord, wordGuess));
                print(f"The following letters are wrong: {wrongLetters}");
            }
        }
        if wins <= count {
            print(
                f"Damn! You lost. the correct word was {r.correctWord} better luck next time."
            );
            disengage;
        }
        count += 1;
    }
    print("You’ve explored the whole dungeon!");
}