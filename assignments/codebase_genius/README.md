# Codebase Genius
[![Watch the demo](https://img.youtube.com/vi/Nbe9paxmsGI/0.jpg)](https://youtu.be/Nbe9paxmsGI)
## Overview
Codebase Genius is an AI-powered code analysis tool that helps developers understand and navigate complex codebases. It uses advanced language models and static analysis to provide insights into your code repository.

## Features
- Python and Jac Repository analysis and code understanding
- AI-powered code documentation generation
- Code structure visualization
- Intelligent code search and navigation
- Documentation output in markdown format

## Project Structure
```
codebase_genius/
├── backend/           # Jaseci backend server
├── frontend/         # Streamlit web interface
├── outputs/         # Generated documentation and analysis
└── jac-env/         # Python virtual environment
```

## Prerequisites
- Python 3.12+
- Jaseci
- Git

## Dependencies

### Backend Dependencies
```bash
jaseci
astroid
jedi
gitpython
python-dotenv
```

### Frontend Dependencies
```bash
streamlit
requests
```

## Installation and Setup

### 1. Clone the Repository
```bash
git clone https://github.com/kiptuidenis/jaseci-learning.git
cd jaseci-learning/assignments/codebase_genius
```

### 2. Environment Setup

#### Backend Setup
1. Create and activate a Python virtual environment:
```bash
python3 -m venv jac-env
source jac-env/bin/activate  # On Linux/Mac
# or
.\jac-env\Scripts\activate   # On Windows
```

2. Install backend dependencies:
```bash
pip install jaseci astroid jedi 
```

3. Create a `.env` file in the `codebase_genius` folder:

Add your environment variables:
```env
GEMINI_API_KEY=your_api_key_here
```

#### Frontend Setup
1. Install frontend dependencies:
```bash
pip install streamlit requests
```

## Running the Application

### 1. Start the Backend Server
From the project root directory:
```bash
jac serve backend/main.jac
```
The  server will start on `http://localhost:8000`

### 2. Start the Frontend Application
In a new terminal, cd into codebase_genius folder.
Activate virtual environment:
```bash
source ./jac-env/bin/activate
```
Run frontend:
```bash
streamlit run frontend/app.py
```
The Streamlit interface will open in your default web browser at `http://localhost:8501`

You can use this repo as an example to generate docs `https://github.com/kiptuidenis/AirBnB_clone_v2.git`

## Output and Documentation
- Download and use markdown viewer to view documentation
- Generated documentation and analysis results are stored in the `outputs/repository` directory
- Documentation is generated in markdown format (`docs.md`)


## External Libraries Used
- **Jaseci**: Main backend framework
- **Streamlit**: Frontend web interface
- **Astroid**: Python static code analysis
- **Jedi**: Python code analysis and autocompletion
- **GitPython**: Git repository management
- **Dotenv**: Environment variable management

## Contributing
1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License
This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments
- Built with Jaseci framework
- Powered by Gemini language model
