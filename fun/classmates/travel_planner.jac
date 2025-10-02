import from byllm { Model }

# Load the AI model and give it instructions
glob llm = Model(
    model_name="gemini/gemini-2.5-flash",
    system_prompt="""You are an expert travel planner. When given a city and travel preferences, 
    create a detailed 5-day itinerary that includes:
    - Day-by-day activities with morning, afternoon, and evening suggestions
    - Popular attractions, landmarks, and hidden gems tailored to the traveler's interests
    - Local food recommendations (including budget options if specified)
    - Practical tips (transportation, best times to visit, weather considerations)
    - Approximate costs in USD
    - Cultural etiquette tips where relevant
    
    Adapt the itinerary based on:
    - Budget level (budget/mid-range/luxury)
    - Travel style (relaxed/moderate/packed)
    - Interests (culture/food/adventure/nature/nightlife/shopping/history)
    
    Format clearly with emojis, day numbers, and time slots. Keep it engaging and practical."""
);

# Function to generate customized 5-day itinerary
def plan_trip(prompt: str) -> str by llm();

# Function to get user preferences
def get_preferences() -> dict {
    print("\n📋 Let's customize your itinerary!\n");
    
    # Get budget preference
    print("Budget level:");
    print("  1. Budget (backpacker-friendly)");
    print("  2. Mid-range (comfortable travel)");
    print("  3. Luxury (premium experiences)");
    budget_choice = input("Choose (1-3): ").strip();
    budget_map = {"1": "budget", "2": "mid-range", "3": "luxury"};
    budget = budget_map.get(budget_choice, "mid-range");
    
    # Get pace preference
    print("\nTravel pace:");
    print("  1. Relaxed (2-3 activities per day)");
    print("  2. Moderate (4-5 activities per day)");
    print("  3. Packed (6+ activities per day)");
    pace_choice = input("Choose (1-3): ").strip();
    pace_map = {"1": "relaxed", "2": "moderate", "3": "packed"};
    pace = pace_map.get(pace_choice, "moderate");
    
    # Get interests
    print("\nYour interests (separate multiple with commas):");
    print("  Options: culture, food, adventure, nature, nightlife, shopping, history, art");
    interests = input("Enter interests: ").strip();
    if not interests {
        interests = "general sightseeing";
    }
    
    return {"budget": budget, "pace": pace, "interests": interests};
}

# Main program entry point
with entry {
    print("=" * 70);
    print("✈️  PERSONALIZED 5-DAY TRAVEL ITINERARY PLANNER  ✈️");
    print("=" * 70);
    print("Get a customized 5-day itinerary tailored to YOUR preferences!");
    print("Type 'exit' at any time to quit.\n");
    
    while True {
        city = input("🌍 Enter a city name (or 'exit' to quit): ").strip();
        
        if city.lower() == "exit" {
            print("\n👋 Thank you for using the Travel Planner. Safe travels!");
            break;
        }
        
        if not city {
            print("⚠️  Please enter a valid city name.\n");
            continue;
        }
        
        # Get user preferences
        prefs = get_preferences();
        
        print(f"\n🔄 Generating your personalized itinerary for {city}...");
        print(f"   Budget: {prefs['budget']} | Pace: {prefs['pace']} | Interests: {prefs['interests']}\n");
        print("=" * 70);
        
        itinerary = plan_trip(
            f"Create a 5-day itinerary for {city}. Budget: {prefs['budget']}. Pace: {prefs['pace']}. Interests: {prefs['interests']}."
        );
        print(itinerary);
        print("=" * 70);
        
        # Ask if user wants to plan another trip
        print("\n");
        another = input("Plan another trip? (yes/no): ").strip().lower();
        if another not in ["yes", "y"] {
            print("\n👋 Thank you for using the Travel Planner. Safe travels!");
            break;
        }
        print("\n");
    }
}