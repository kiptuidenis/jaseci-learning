import datetime;
import numpy;
import from sklearn.feature_extraction.text { TfidfVectorizer }
import from sklearn.metrics.pairwise { cosine_similarity }

glob vectorizer = TfidfVectorizer();

def search_tweets(query: str, tweet: str) -> int;

node Profile {
    has username: str = "";

    can update with update_profile entry;

    can get with get_profile entry;

    can follow with follow_request entry;

    can un_follow_request  entry;
}

obj TweetInfo {
    has username: str;
    has id: str;
    has content: str;
    has embedding: list;
    has likes: list;
    has comments: list;
}

node Tweet {
    has content: str;
    has embedding: list;
    has created_at: str = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S");

    can update with update_tweet exit;

    can delete with remove_tweet exit;

    can like_tweet with like_tweet entry;

    can remove_like with remove_like entry;

    can comment with comment_tweet entry;

    def get_info()-> TweetInfo;

    can get with load_feed entry;
}