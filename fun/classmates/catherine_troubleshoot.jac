import from langdetect { detect }
import from googletrans { Translator}

walker translator {
    has text_to_translate: str;
    has detected_lang: str;
    has translated_text: str;

    can detect_language with `root entry {
         self.detected_lang = detect(self.text_to_translate);
         report("Detected language: " + self.detected_lang);
    }

    can translate_to_english with `root entry {
        translator = Translator();
        report("Translated text: " + self.translated_text);
    }
}
