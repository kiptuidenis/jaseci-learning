"""Daily Motivation Journal - Enhanced, fixed Jac Implementation"""

# Standard imports
import random;
import datetime;
import json;
import os;
import re;
import byllm.llm;
# ---------------------------
# Configure the LLM (change model_name to one you have access to)
# ---------------------------
glob llm = byllm.llm.Model(model_name="groq/llama-3.1-8b-instant", verbose=False);

# ---------- LLM-backed functions ----------
def motivate(mood: str, note: str) -> str by llm(
    system="You are a motivational coach. Be empathetic, positive, and concise. Offer encouragement and a practical tip based on the user's mood and situation."
);

def summarize_entries(entries_text: str) -> str by llm(
    system="You are a reflective coach. Summarize the user's journal entries, detect patterns in mood, and provide uplifting suggestions for improvement."
);

def predict_mood_trend(recent_moods: str) -> str by llm(
    system="You are a mood analyst. Based on recent mood patterns, predict likely future mood trends and provide proactive wellness suggestions."
);

def generate_personalized_insight(user_data: str) -> str by llm(
    system="You are a personal development coach. Analyze the user's journal data and provide personalized insights for growth and well-being."
);

def suggest_goals(mood_patterns: str, current_challenges: str) -> str by llm(
    system="You are a goal-setting coach. Based on mood patterns and challenges, suggest 3-5 specific, achievable goals for personal improvement."
);

# ---------------------------
# Domain nodes
# ---------------------------
node journal_entry {
    has mood: str;
    has mood_score: int = 5;
    has note: str = "";
    has response: str = "";
    has timestamp: str = "";
    has tags: list = [];
    has energy_level: int = 5;
    has gratitude: str = "";
}

node goal {
    has title: str;
    has description: str = "";
    has target_date: str = "";
    has progress: int = 0;
    has created_date: str = "";
    has status: str = "active";
}

# ---------------------------
# Persistence
# ---------------------------
glob DATA_FILE = "journal_data.json";

def save_data_to_file(entries: list, goals: list) -> bool {
    try {
        data = {
            "entries": [],
            "goals": [],
            "last_updated": datetime.datetime.now().isoformat()
        };

        # serialize entries
        i = 0;
        while i < len(entries) {
            e = entries[i];
            data["entries"].append({
                "mood": e.mood,
                "mood_score": e.mood_score,
                "note": e.note,
                "response": e.response,
                "timestamp": e.timestamp,
                "tags": e.tags,
                "energy_level": e.energy_level,
                "gratitude": e.gratitude
            });
            i = i + 1;
        }

        # serialize goals
        j = 0;
        while j < len(goals) {
            g = goals[j];
            data["goals"].append({
                "title": g.title,
                "description": g.description,
                "target_date": g.target_date,
                "progress": g.progress,
                "created_date": g.created_date,
                "status": g.status
            });
            j = j + 1;
        }

        with open(DATA_FILE, 'w') as f {
            json.dump(data, f, indent=2);
        }
        return True;
    } except Exception as e {
        print("Error saving data: " + str(e));
        return false;
    }
}

def load_data_from_file(root_node: any) -> tuple {
    entries = [];
    goals = [];

    if not os.path.exists(DATA_FILE) {
        return (entries, goals);
    }

    try {
        with open(DATA_FILE, 'r') as f {
            data = json.load(f);
        }

        es = data.get("entries", []);
        k = 0;
        while k < len(es) {
            entry_data = es[k];
            # Create journal entry node and set attributes
            entry = journal_entry(mood=entry_data.get("mood", ""));
            entry.mood_score = entry_data.get("mood_score", 5);
            entry.note = entry_data.get("note", "");
            entry.response = entry_data.get("response", "");
            entry.timestamp = entry_data.get("timestamp", "");
            entry.tags = entry_data.get("tags", []);
            entry.energy_level = entry_data.get("energy_level", 5);
            entry.gratitude = entry_data.get("gratitude", "");
            entries.append(entry);
            k = k + 1;
        }

        gs = data.get("goals", []);
        m = 0;
        while m < len(gs) {
            goal_data = gs[m];
            goal_obj = root_node ++> goal(
                goal_data.get("title", ""),
                goal_data.get("description", ""),
                goal_data.get("target_date", ""),
                goal_data.get("progress", 0),
                goal_data.get("created_date", ""),
                goal_data.get("status", "active")
            );
            goals.append(goal_obj);
            m = m + 1;
        }

        print("✓ Loaded " + str(len(entries)) + " entries and " + str(len(goals)) + " goals from storage");
    } except Exception as e {
        print("Error loading data: " + str(e));
    }

    return (entries, goals);
}

# ---------------------------
# Utilities
# ---------------------------
def get_mood_score(mood: str) -> int {
    mood_lower = mood.lower();
    # Check for excellent moods
    if "excellent" in mood_lower or "amazing" in mood_lower or "fantastic" in mood_lower or "ecstatic" in mood_lower or "overjoyed" in mood_lower {
        return 10;
    } elif "great" in mood_lower or "happy" in mood_lower or "good" in mood_lower or "cheerful" in mood_lower or "positive" in mood_lower {
        return 8;
    } elif "okay" in mood_lower or "fine" in mood_lower or "alright" in mood_lower or "decent" in mood_lower or "neutral" in mood_lower {
        return 6;
    } elif "tired" in mood_lower or "stressed" in mood_lower or "worried" in mood_lower or "anxious" in mood_lower or "down" in mood_lower {
        return 4;
    } elif "sad" in mood_lower or "depressed" in mood_lower or "awful" in mood_lower or "terrible" in mood_lower or "miserable" in mood_lower {
        return 2;
    } else {
        return 5;
    }
}

def format_date(timestamp: str) -> str {
    try {
        dt = datetime.datetime.fromisoformat(timestamp);
        return dt.strftime("%Y-%m-%d %H:%M");
    } except Exception {
        return timestamp;
    }
}

def get_mood_emoji(score: int) -> str {
    if score >= 9 { return "😄"; }
    elif score >= 7 { return "😊"; }
    elif score >= 5 { return "😐"; }
    elif score >= 3 { return "😔"; }
    else { return "😢"; }
}

def print_separator(char: str = "=", length: int = 50) {
    i = 0;
    while i < length {
        print(char, end="");
        i = i + 1;
    }
    print("");
}

def print_header(title: str) {
    print_separator();
    print("  " + title);
    print_separator();
}

# ---------------------------
# Main Walker
# ---------------------------
walker JournalWalker {
    has action: str;
    has mood: str = "";
    has note: str = "";
    has search_term: str = "";
    has date_filter: str = "";
    has mood_filter: str = "";
    has goal_title: str = "";
    has goal_description: str = "";
    has goal_progress: int = 0;

    can act with `root entry;
}

impl JournalWalker.act {
    # load data at start of walk
    (entries, goals) = load_data_from_file(root);

    # NEW ENTRY
    if self.action == "NEW" {
        print_header("📝 New Journal Entry");

        energy_input = input("Energy level (1-10, press Enter for 5): ").strip();
        energy_level = 5;
        if energy_input.isdigit() {
            val = int(energy_input);
            if val >= 1 and val <= 10 {
                energy_level = val;
            }
        }

        gratitude_input = input("What are you grateful for today? (optional): ").strip();

        tags_input = input("Add tags (comma-separated, optional): ").strip();
        tags = [];
        if tags_input != "" {
            parts = tags_input.split(",");
            p = 0;
            while p < len(parts) {
                t = parts[p].strip();
                if t != "" {
                    tags.append(t);
                }
                p = p + 1;
            }
        }

        ts = datetime.datetime.now().isoformat();
        mood_score = get_mood_score(self.mood);

        # Create a new journal entry node
        new_entry = journal_entry(mood=self.mood);
        new_entry.mood_score = mood_score;
        new_entry.note = self.note;
        new_entry.response = "";
        new_entry.timestamp = ts;
        new_entry.tags = tags;
        new_entry.energy_level = energy_level;
        new_entry.gratitude = gratitude_input;

        context = "Mood: " + str(self.mood) + " (score: " + str(mood_score) + "/10), Energy: " + str(energy_level) + "/10";
        if gratitude_input != "" {
            context = context + ", Grateful for: " + gratitude_input;
        }
        if self.note != "" {
            context = context + ", Note: " + self.note;
        }

        # try to call AI, but if it fails, capture the exception text and store a fallback message
        try {
            new_entry.response = motivate(self.mood, context);
        } except Exception as e {
            new_entry.response = "AI unavailable: saved a neutral supportive message.";
        }

        entries.append(new_entry);

        print("\n📅 " + format_date(new_entry.timestamp));
        print("😊 Mood: " + new_entry.mood + " " + get_mood_emoji(mood_score) + " (" + str(mood_score) + "/10)");
        print("⚡ Energy: " + str(energy_level) + "/10");
        if new_entry.note != "" { print("📝 Note: " + new_entry.note); }
        if new_entry.gratitude != "" { print("🙏 Grateful: " + new_entry.gratitude); }
        if len(new_entry.tags) > 0 { print("🏷️  Tags: " + ', '.join(new_entry.tags)); }
        print("\n🤖 AI Coach:");
        print(new_entry.response);
        print_separator("-");

        if save_data_to_file(entries, goals) {
            print("✓ Entry saved successfully!\n");
        }
        disengage;
    }

    # LIST
    elif self.action == "LIST" {
        if not entries {
            print("\n📭 No journal entries found.\n");
            disengage;
        }

        print_header("📚 All Journal Entries (" + str(len(entries)) + " total)");
        idx = 0;
        while idx < len(entries) {
            e = entries[idx];
            print("\n[" + str(idx + 1) + "] " + format_date(e.timestamp));
            print("    😊 " + e.mood + " " + get_mood_emoji(e.mood_score) + " (" + str(e.mood_score) + "/10) | ⚡ Energy: " + str(e.energy_level) + "/10");
            if e.note != "" { print("    📝 " + e.note[:100] + ('...' if len(e.note) > 100 else '')); }
            if e.gratitude != "" { print("    🙏 " + e.gratitude[:80] + ('...' if len(e.gratitude) > 80 else '')); }
            if len(e.tags) > 0 { print("    🏷️  " + ', '.join(e.tags)); }
            if e.response != "" {
                short_response = e.response[:120] + ( "..." if len(e.response) > 120 else "" );
                print("    🤖 " + short_response);
            }
            idx = idx + 1;
        }
        print_separator("-");
        disengage;
    }

    # SEARCH
    elif self.action == "SEARCH" {
        if not entries {
            print("\n📭 No journal entries to search.\n");
            disengage;
        }

        filtered = [];
        idx = 0;
        while idx < len(entries) {
            e = entries[idx];
            is_match = True;

            if self.search_term != "" {
                s = self.search_term.lower();
                # Check if search term is in any tag
                tag_match = False;
                for tag in e.tags {
                    if s in tag.lower() {
                        tag_match = True;
                        break;
                    }
                }
                if not (s in e.mood.lower() or s in e.note.lower() or s in e.response.lower() or s in e.gratitude.lower() or tag_match) {
                    is_match = false;
                }
            }

            if self.date_filter != "" and is_match {
                if not e.timestamp.startswith(self.date_filter) {
                    is_match = false;
                }
            }

            if self.mood_filter != "" and is_match {
                if not (self.mood_filter.lower() in e.mood.lower()) {
                    is_match = false;
                }
            }

            if is_match {
                filtered.append(e);
            }
            idx = idx + 1;
        }

        if not filtered {
            print("\n🔍 No entries found matching your criteria.\n");
            disengage;
        }

        print_header("🔍 Search Results (" + str(len(filtered)) + " found)");
        fidx = 0;
        while fidx < len(filtered) {
            e = filtered[fidx];
            print("\n[" + str(fidx + 1) + "] " + format_date(e.timestamp));
            print("    😊 " + e.mood + " " + get_mood_emoji(e.mood_score) + " (" + str(e.mood_score) + "/10) | ⚡ Energy: " + str(e.energy_level) + "/10");
            if e.note != "" { print("    📝 " + e.note); }
            if e.gratitude != "" { print("    🙏 " + e.gratitude); }
            if len(e.tags) > 0 { print("    🏷️  " + ', '.join(e.tags)); }
            fidx = fidx + 1;
        }
        print_separator("-");
        disengage;
    }

    # ANALYTICS
    elif self.action == "ANALYTICS" {
        if not entries {
            print("\n📭 No journal entries to analyze.\n");
            disengage;
        }

        print_header("📊 Mood Analytics & Insights");

        total_entries = len(entries);
        sum_mood = 0;
        sum_energy = 0;
        t_idx = 0;
        while t_idx < len(entries) {
            ee = entries[t_idx];
            sum_mood = sum_mood + ee.mood_score;
            sum_energy = sum_energy + ee.energy_level;
            t_idx = t_idx + 1;
        }

        avg_mood = float(sum_mood) / float(total_entries);
        avg_energy = float(sum_energy) / float(total_entries);

        # recent entries
        rec_count = 7;
        start_idx = 0;
        if len(entries) > rec_count {
            start_idx = len(entries) - rec_count;
        }
        recent_sum = 0;
        r = start_idx;
        while r < len(entries) {
            recent_sum = recent_sum + entries[r].mood_score;
            r = r + 1;
        }
        recent_len = len(entries) - start_idx;
        recent_avg_mood = float(recent_sum) / float(recent_len);

        print("📈 Overall Statistics:");
        print("   • Total entries: " + str(total_entries));
        mood_emoji = get_mood_emoji(int(avg_mood));
        print("   • Average mood: " + str(avg_mood) + "/10 " + mood_emoji);
        print("   • Average energy: " + str(avg_energy) + "/10");
        print("   • Recent trend (last " + str(recent_len) + "): " + str(recent_avg_mood) + "/10");

        # mood distribution
        mood_counts = {};
        idx2 = 0;
        while idx2 < len(entries) {
            ee = entries[idx2];
            if ee.mood_score <= 3 {
                range_label = "😢 Low (1-3)";
            } elif ee.mood_score <= 5 {
                range_label = "😔 Below Average (4-5)";
            } elif ee.mood_score <= 7 {
                range_label = "😐 Average (6-7)";
            } elif ee.mood_score <= 9 {
                range_label = "😊 Good (8-9)";
            } else {
                range_label = "😄 Excellent (10)";
            }
            if range_label in mood_counts {
                mood_counts[range_label] = mood_counts[range_label] + 1;
            } else {
                mood_counts[range_label] = 1;
            }
            idx2 = idx2 + 1;
        }

        print("\n📊 Mood Distribution:");
        for key in list(mood_counts.keys()) {
            count = mood_counts[key];
            percentage = (float(count) / float(total_entries)) * 100.0;
            print("   • " + key + ": " + str(count) + " entries (" + str(percentage) + "%)");
        }

        # AI trend analysis (best-effort; may raise on no key/quota)
        recent_moods_text = "";
        s_idx = start_idx;
        while s_idx < len(entries) {
            recent_moods_text = recent_moods_text + entries[s_idx].mood + " (" + str(entries[s_idx].mood_score) + "), ";
            s_idx = s_idx + 1;
        }
        try {
            print("\n🤖 AI Trend Analysis:");
            trend_analysis = predict_mood_trend(recent_moods_text);
            print(trend_analysis);
        } except Exception as e {
            print("AI Trend Analysis unavailable (API issue).");
        }

        print_separator("-");
        disengage;
    }

    # SUMMARY
    elif self.action == "SUMMARY" {
        if not entries {
            print("\n📭 No journal entries to summarize.\n");
            disengage;
        }

        print_header("📋 AI Summary & Insights");

        # prepare last up to 10 entries
        blob = "Total entries: " + str(len(entries)) + "\n";
        s = 0;
        start = len(entries) - 10;
        if start < 0 { start = 0; }
        s = start;
        while s < len(entries) {
            ee = entries[s];
            note_str = ee.note if ee.note != "" else "(no note)";
            gratitude_str = " | Grateful: " + ee.gratitude if ee.gratitude != "" else "";
            tags_str = " | Tags: " + ', '.join(ee.tags) if len(ee.tags) > 0 else "";
            blob = blob + "- " + format_date(ee.timestamp) + " | " + ee.mood + " (" + str(ee.mood_score) + "/10) | Energy: " + str(ee.energy_level) + "/10 | " + note_str + gratitude_str + tags_str + "\n";
            s = s + 1;
        }

        print("🔄 Generating comprehensive analysis...");
        try {
            summary = summarize_entries(blob);
            print("\n" + summary);
        } except Exception as e {
            print("AI Summary unavailable (API issue).");
        }

        try {
            print("\n🎯 Personalized Insights:");
            insights = generate_personalized_insight(blob);
            print(insights);
        } except Exception {
            print("AI Insights unavailable (API issue).");
        }

        print_separator("-");
        disengage;
    }

    # GOALS_LIST
    elif self.action == "GOALS_LIST" {
        print_header("🎯 Personal Goals (" + str(len(goals)) + " total)");
        if not goals {
            print("📭 No goals set yet. Use 'Set Goal' to create your first goal!\n");
            disengage;
        }

        # active and completed
        active = [];
        completed = [];
        gg = 0;
        while gg < len(goals) {
            g = goals[gg];
            if g.status == "active" {
                active.append(g);
            } else {
                completed.append(g);
            }
            gg = gg + 1;
        }

        if len(active) > 0 {
            print("\n🔥 Active Goals (" + str(len(active)) + "):");
            aidx = 0;
            while aidx < len(active) {
                g = active[aidx];
                progress_bar = "█" * (g.progress // 10) + "░" * (10 - (g.progress // 10));
                print("[" + str(aidx + 1) + "] " + g.title);
                print("    📅 Target: " + (g.target_date if g.target_date != '' else 'No deadline'));
                print("    📊 Progress: [" + progress_bar + "] " + str(g.progress) + "%");
                if g.description != "" { print("    📝 " + g.description); }
                aidx = aidx + 1;
        }

        if len(completed) > 0 {
            print("\n✅ Completed Goals (" + str(len(completed)) + "):");
            cidx = 0;
            # show last up to 3 completed
            startc = len(completed) - 3;
            if startc < 0 { startc = 0; }
            cidx = startc;
            while cidx < len(completed) {
                print("    ✓ " + completed[cidx].title);
                cidx = cidx + 1;
            }
        }

        print_separator("-");
        disengage;
    }

    # GOAL_NEW
    elif self.action == "GOAL_NEW" {
        print_header("🎯 Set New Goal");

        new_goal = root ++> goal(
            self.goal_title,
            self.goal_description,
            input("Target date (YYYY-MM-DD, optional): ").strip(),
            0,
            datetime.datetime.now().isoformat(),
            "active"
        );
        goals.append(new_goal);
        print("✅ Goal '" + new_goal.title + "' created successfully!");
        if save_data_to_file(entries, goals) {
            print("💾 Goal saved to storage!\n");
        }
        disengage;
    }

    # GOAL_UPDATE
    elif self.action == "GOAL_UPDATE" {
        if not goals {
            print("📭 No goals found to update.\n");
            disengage;
        }

        print_header("📊 Update Goal Progress");

        # list active goals
        active_goals = [];
        gi = 0;
        while gi < len(goals) {
            if goals[gi].status == "active" {
                active_goals.append(goals[gi]);
            }
            gi = gi + 1;
        }

        if len(active_goals) == 0 {
            print("📭 No active goals to update.\n");
            disengage;
        }

        print("Active Goals:");
        p = 0;
        while p < len(active_goals) {
            print("[" + str(p + 1) + "] " + active_goals[p].title + " - Current: " + str(active_goals[p].progress) + "%");
            p = p + 1;
        }

        try {
            choice_str = input("Select goal to update (1-" + str(len(active_goals)) + "): ").strip();
            if not choice_str.isdigit() {
                print("❌ Invalid input. Please enter a number.");
                disengage;
            }
            choice = int(choice_str) - 1;
            if choice < 0 or choice >= len(active_goals) {
                print("❌ Invalid selection.");
                disengage;
            }
            selected_goal = active_goals[choice];
            new_prog_str = input("New progress for '" + selected_goal.title + "' (0-100): ").strip();
            if not new_prog_str.isdigit() {
                print("❌ Invalid progress value.");
                disengage;
            }
            new_progress = int(new_prog_str);
            if new_progress < 0 or new_progress > 100 {
                print("❌ Invalid progress value. Must be 0-100.");
                disengage;
            }
            selected_goal.progress = new_progress;
            if new_progress == 100 {
                selected_goal.status = "completed";
                print("🎉 Congratulations! Goal '" + selected_goal.title + "' completed!");
            } else {
                print("📊 Progress updated to " + str(new_progress) + "%");
            }
            if save_data_to_file(entries, goals) {
                print("💾 Changes saved!\n");
            }
        } except Exception {
            print("❌ Invalid input. Please enter a number.");
        }
        disengage;
    }

    # EXPORT
    elif self.action == "EXPORT" {
        if not entries {
            print("\n📭 No journal entries to export.\n");
            disengage;
        }

        print_header("📤 Export Journal Data");
        export_filename = "journal_export_" + datetime.datetime.now().strftime('%Y%m%d_%H%M%S') + ".txt";

        try {
            with open(export_filename, 'w', encoding='utf-8') as f {
                f.write("=== DAILY MOTIVATION JOURNAL EXPORT ===\n");
                f.write("Generated: " + datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S') + "\n");
                f.write("Total Entries: " + str(len(entries)) + "\n\n");

                eidx = 0;
                while eidx < len(entries) {
                    ee = entries[eidx];
                    f.write("--- Entry #" + str(eidx + 1) + " ---\n");
                    f.write("Date: " + format_date(ee.timestamp) + "\n");
                    f.write("Mood: " + ee.mood + " (" + str(ee.mood_score) + "/10)\n");
                    f.write("Energy Level: " + str(ee.energy_level) + "/10\n");
                    if ee.note != "" { f.write("Note: " + ee.note + "\n"); }
                    if ee.gratitude != "" { f.write("Gratitude: " + ee.gratitude + "\n"); }
                    if len(ee.tags) > 0 { f.write("Tags: " + ', '.join(ee.tags) + "\n"); }
                    if ee.response != "" { f.write("AI Response: " + ee.response + "\n"); }
                    f.write("\n");
                    eidx = eidx + 1;
                }

                if len(goals) > 0 {
                    f.write("=== GOALS ===\n");
                    gi2 = 0;
                    while gi2 < len(goals) {
                        gg = goals[gi2];
                        f.write("Goal: " + gg.title + "\n");
                        f.write("Status: " + gg.status + "\n");
                        f.write("Progress: " + str(gg.progress) + "%\n");
                        if gg.description != "" { f.write("Description: " + gg.description + "\n"); }
                        if gg.target_date != "" { f.write("Target Date: " + gg.target_date + "\n"); }
                        f.write("Created: " + format_date(gg.created_date) + "\n\n");
                        gi2 = gi2 + 1;
                    }
                }
            }
            print("✅ Journal exported successfully to: " + export_filename);
            print("📁 File contains " + str(len(entries)) + " entries and " + str(len(goals)) + " goals\n");
        } except Exception as e {
            print("❌ Export failed: " + str(e) + "\n");
        }
        disengage;
    }

    else {
        # unknown action
        print("❌ Unknown action for JournalWalker.");
        disengage;
    }
}
}

# ---------------------------
# CLI entrypoint
# ---------------------------
with entry {
    print("🌟 Welcome to Daily Motivation Journal (Enhanced) 🌟");
    print("Loading your data...");

    (entries, goals) = load_data_from_file(root);

    while True {
        print_separator("=", 60);
        print("🏠 MAIN MENU");
        print_separator("=", 60);
        print("📝 JOURNAL ENTRIES:");
        print("  1. ✍️  New entry");
        print("  2. 📚 List all entries");
        print("  3. 🔍 Search entries");
        print("  4. 📊 Analytics & insights");
        print("  5. 📋 AI summary");
        print("");
        print("🎯 GOALS & PROGRESS:");
        print("  6. 📋 View goals");
        print("  7. ➕ Set new goal");
        print("  8. 📊 Update goal progress");
        print("");
        print("🔧 UTILITIES:");
        print("  9. 📤 Export data");
        print("  10. ❓ Help");
        print("  0. 👋 Exit");
        print_separator("-", 60);

        opt = input("Choose an option (0-10): ").strip();

        if opt == "1" {
            print_separator();
            mood_input = input("😊 How are you feeling right now? (e.g., happy, stressed, excited): ").strip();
            if mood_input == "" {
                print("❌ Mood is required. Please try again.\n");
                continue;
            }
            note_input = input("📝 Any thoughts or notes? (press Enter to skip): ").strip();
            root spawn JournalWalker("NEW", mood_input, note_input);
        } elif opt == "2" {
            root spawn JournalWalker("LIST");
        } elif opt == "3" {
            print_separator();
            print("🔍 SEARCH OPTIONS:");
            print("Leave blank to skip any filter");
            search_term = input("🔤 Search text (in mood, notes, tags): ").strip();
            date_filter = input("📅 Date filter (YYYY-MM-DD format): ").strip();
            mood_filter = input("😊 Mood filter (partial match): ").strip();
            w = JournalWalker("SEARCH");
            w.search_term = search_term;
            w.date_filter = date_filter;
            w.mood_filter = mood_filter;
            root spawn w;
        } elif opt == "4" {
            root spawn JournalWalker("ANALYTICS");
        } elif opt == "5" {
            root spawn JournalWalker("SUMMARY");
        } elif opt == "6" {
            root spawn JournalWalker("GOALS_LIST");
        } elif opt == "7" {
            print_separator();
            goal_title = input("🎯 Goal title: ").strip();
            if goal_title == "" {
                print("❌ Goal title is required. Please try again.\n");
                continue;
            }
            goal_desc = input("📝 Goal description (optional): ").strip();
            w2 = JournalWalker("GOAL_NEW");
            w2.goal_title = goal_title;
            w2.goal_description = goal_desc;
            root spawn w2;
        } elif opt == "8" {
            root spawn JournalWalker("GOAL_UPDATE");
        } elif opt == "9" {
            root spawn JournalWalker("EXPORT");
        } elif opt == "10" {
            print_header("❓ HELP & FEATURES");
            print("📝 JOURNAL FEATURES:");
            print("   • Enhanced mood tracking with 1-10 scoring");
            print("   • Energy level tracking");
            print("   • Gratitude journaling");
            print("   • Tag system for categorization");
            print("   • AI-powered motivational responses");
            print("   • Persistent data storage");
            print("");
            print("🔍 SEARCH & ANALYTICS:");
            print("   • Search by text, date, or mood");
            print("   • Comprehensive mood analytics");
            print("   • Trend analysis and predictions");
            print("   • Personalized AI insights");
            print("");
            print("🎯 GOAL MANAGEMENT:");
            print("   • Set and track personal goals");
            print("   • Progress monitoring with visual bars");
            print("   • Goal completion celebrations");
            print("");
            print("💾 DATA MANAGEMENT:");
            print("   • Automatic data persistence");
            print("   • Export functionality");
            print("   • Data backup and recovery");
            print_separator("-");
            input("Press Enter to continue...");
        } elif opt == "0" {
            print_separator("=", 60);
            print("🌟 Thank you for using Daily Motivation Journal! 🌟");
            print("💪 Keep growing and stay motivated!");
            print("📊 Your progress has been saved automatically.");
            print_separator("=", 60);
            break;
        } else {
            print("❌ Invalid option. Please choose 0-10.\n");
            input("Press Enter to continue...");
        }
    }
}