impl Game.play {
    raise NotImplementedError("Subclasses must implement this method");
}

impl GuessTheNumber.init {
    self.attempts = 10;
    self.correct_number = random.randint(1, 10);

}

impl GuessTheNumber.play {
    
}

impl GuessTheNumber.process_guess {

}