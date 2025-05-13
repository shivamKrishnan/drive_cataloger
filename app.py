import os
import sqlite3
import functools
from datetime import datetime
from flask import Flask, jsonify, request, send_from_directory, redirect, session
from flask_cors import CORS
from supabase import create_client
from dotenv import load_dotenv
from authlib.integrations.flask_client import OAuth

# Load environment variables
load_dotenv()

app = Flask(__name__)
CORS(app)

# Secret key for sessions
app.secret_key = os.getenv('FLASK_SECRET_KEY', 'fallback_secret_key')

# Supabase Configuration
SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_KEY')
supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

# OAuth Configuration
oauth = OAuth(app)
google = oauth.register(
    name='google',
    client_id=os.getenv('GOOGLE_CLIENT_ID'),
    client_secret=os.getenv('GOOGLE_CLIENT_SECRET'),
    authorize_url='https://accounts.google.com/o/oauth2/auth',
    authorize_params=None,
    access_token_url='https://accounts.google.com/o/oauth2/token',
    access_token_params=None,
    refresh_token_url=None,
    redirect_url='/callback',
    client_kwargs={'scope': 'openid email profile'}
)

def login_required(f):
    @functools.wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user' not in session:
            return redirect('/login')
        return f(*args, **kwargs)
    return decorated_function

@app.route('/')
def index():
    if 'user' in session:
        return send_from_directory('.', 'index.html')
    return redirect('/login')

@app.route('/login')
def login():
    redirect_uri = request.url_root + 'callback'
    return google.authorize_redirect(redirect_uri)

@app.route('/callback')
def callback():
    token = google.authorize_access_token()
    resp = google.get('userinfo')
    user_info = resp.json()
    
    # Store user in session
    session['user'] = user_info['email']
    session['name'] = user_info.get('name', 'User')
    
    return redirect('/')

@app.route('/logout')
def logout():
    session.pop('user', None)
    session.pop('name', None)
    return redirect('/login')

@app.route('/index_files', methods=['POST'])
@login_required
def index_files():
    path = request.json.get('path', 'D:\\TV')
    user_email = session['user']
    
    try:
        # Initialize or clear existing files for this user
        supabase.table('files').delete().eq('user_email', user_email).execute()
        
        # Walk through directory and index files
        files_to_insert = []
        for root, dirs, files in os.walk(path):
            for file in files:
                file_path = os.path.join(root, file)
                try:
                    file_data = {
                        'name': file,
                        'path': file_path,
                        'folder_path': os.path.relpath(root, path),
                        'size': os.path.getsize(file_path),
                        'modified': datetime.fromtimestamp(os.path.getmtime(file_path)).isoformat(),
                        'user_email': user_email
                    }
                    files_to_insert.append(file_data)
                except Exception as file_error:
                    print(f"Error processing file {file_path}: {file_error}")
        
        # Bulk insert files
        if files_to_insert:
            supabase.table('files').insert(files_to_insert).execute()
        
        return jsonify({
            "status": "success", 
            "message": f"Indexed {len(files_to_insert)} files",
            "files_count": len(files_to_insert)
        })
    
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/files')
@login_required
def get_files():
    try:
        user_email = session['user']
        # Fetch files for the logged-in user
        response = supabase.table('files').select('*').eq('user_email', user_email).execute()
        
        # Organize files into a tree structure
        tree = {"files": [], "subfolders": {}}
        for file in response.data:
            folder_path = file['folder_path'].split(os.sep) if file['folder_path'] else []
            
            # Navigate to the correct folder in the tree
            current = tree
            for folder in folder_path:
                if folder:
                    if 'subfolders' not in current:
                        current['subfolders'] = {}
                    if folder not in current['subfolders']:
                        current['subfolders'][folder] = {"files": []}
                    current = current['subfolders'][folder]
            
            current['files'].append({
                "name": file['name'],
                "path": file['path'],
                "size": file['size'],
                "modified": file['modified']
            })
        
        return jsonify(tree)
    
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/search')
@login_required
def search_files():
    try:
        query = request.args.get('q', '').lower()
        user_email = session['user']
        
        # Search files for the logged-in user
        response = supabase.table('files').select('*').eq('user_email', user_email).execute()
        
        # Filter files based on search query
        filtered_files = [
            file for file in response.data 
            if query in file['name'].lower() or query in file['folder_path'].lower()
        ]
        
        # Organize filtered files into tree structure
        tree = {"files": [], "subfolders": {}}
        for file in filtered_files:
            folder_path = file['folder_path'].split(os.sep) if file['folder_path'] else []
            
            # Navigate to the correct folder in the tree
            current = tree
            for folder in folder_path:
                if folder:
                    if 'subfolders' not in current:
                        current['subfolders'] = {}
                    if folder not in current['subfolders']:
                        current['subfolders'][folder] = {"files": []}
                    current = current['subfolders'][folder]
            
            current['files'].append({
                "name": file['name'],
                "path": file['path'],
                "size": file['size'],
                "modified": file['modified']
            })
        
        return jsonify(tree)
    
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    
print("Client ID:", os.getenv('GOOGLE_CLIENT_ID'))
print("Client Secret:", os.getenv('GOOGLE_CLIENT_SECRET'))


@app.route('/check_auth')
def check_auth():
    if 'user' in session:
        return jsonify({
            'authenticated': True,
            'name': session.get('name', 'User')
        })
    return jsonify({'authenticated': False})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)