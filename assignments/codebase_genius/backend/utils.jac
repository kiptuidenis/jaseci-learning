import re;
import requests;

def validate_github_repo(url: str) -> <>dict {
    let pattern = '^https:\\/\\/github\\.com\\/([\\w\\-]+)\\/([\\w\\-]+)(\\.git)?\\/?$';
    if not re.match(pattern, url) {
        return {'valid': False, 'message': 'Invalid GitHub repository URL format.'};
    }
    try {
        let <>match = re.match('^https:\\/\\/github\\.com\\/([\\w\\-]+)\\/([\\w\\-]+)', url);
        let (owner, repo) = <>match.groups();
        let api_url = f"https://api.github.com/repos/{owner}/{repo}";
        let resp = requests.get(api_url, timeout=10);
        if (resp.status_code == 200) {
            return {'valid': True, 'message': 'Repository is valid and reachable.'};
        } elif (resp.status_code == 404) {
            return {'valid': False, 'message': 'Repository not found on GitHub.'};
        } else {
            return {'valid': False, 'message': f"Unexpected GitHub response: {resp.status_code}"};
        }
    } except Exception as e {
        return {'valid': False, 'message': f"Error validating repository: {str(e)}"};
    }
}
