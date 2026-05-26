# Flask File Explorer

A retro-styled, offline file browser web application built with Flask. Browse and download files from your Ubuntu machine using any device on your local network.

## Features

- 🖥️ **Retro UI Design** - Classic Windows 95 / early Mac OS aesthetic
- 📁 **File Browsing** - Navigate folders and view files
- 📥 **File Download** - Download files directly to your device
- 🔒 **Secure** - Protected against directory traversal attacks
- 📱 **Responsive** - Works on phones, tablets, and desktops
- 🌐 **Network Access** - Accessible from any device on your local network
- 💾 **100% Offline** - No external dependencies or cloud services

## Requirements

- Python 3.6 or higher
- Flask 2.0 or higher
- python-dotenv (for environment variables)

## Installation

1. Clone or download this repository

2. Install Python dependencies:
```bash
pip install -r requirements.txt
```

3. Run the app — SQLite database is created automatically on first start (`file_explorer.db` in the project folder). Override the path with `DB_PATH` in `.env` if needed.

## Configuration

By default, the app browses your home directory (`~`). To change the root directory, edit `app.py` and modify the `ROOT_DIRECTORY` variable:

```python
ROOT_DIRECTORY = os.path.expanduser("~")  # Change this to your desired directory
```

For example, to browse `/home/user/Documents`:
```python
ROOT_DIRECTORY = "/home/user/Documents"
```

## Running the Server

1. Navigate to the project directory:
```bash
cd /path/to/notes_app
```

2. Run the Flask application:
```bash
python app.py
```

The server will start on `http://0.0.0.0:5000` and display connection information.

## Accessing from Other Devices

### Find Your IP Address

On your Ubuntu machine, run:
```bash
hostname -I
```

This will display your machine's IP address (e.g., `192.168.1.100`).

### Connect from Another Device

1. **From your phone or Mac**, open a web browser
2. Navigate to: `http://<your-ip-address>:5000`
   - Example: `http://192.168.1.100:5000`
3. Make sure both devices are on the same local network (Wi-Fi)

### Troubleshooting

- **Can't connect?** Check that:
  - Both devices are on the same network
  - Your firewall allows connections on port 5000
  - You're using the correct IP address

- **Firewall configuration** (if needed):
```bash
sudo ufw allow 5000
```

## Usage

- **Browse Folders**: Click on folder names or icons to navigate
- **Download Files**: Click on file names or icons to download
- **Navigate Up**: Click the `..` entry at the top of the list
- **Breadcrumb Navigation**: Click any part of the breadcrumb path to jump to that directory
- **Toolbar**: Use Home, Back, and Forward buttons for navigation

## Security Notes

- The app is **read-only** - it cannot delete, modify, or upload files
- Directory traversal attacks are prevented
- Hidden files (starting with `.`) are not shown by default
- Only files within the configured root directory are accessible

## Authentication Guard

The application includes an **Authenticator Guard** that protects all endpoints when running in production mode.

### How It Works

- **Development Mode** (`FLASK_ENV=development` or not set): All routes are accessible without authentication
- **Production Mode** (`FLASK_ENV=production`): All routes require authentication via password

### Configuration

To enable authentication in production, add these variables to your `.env` file:

```env
FLASK_ENV=production
AUTH_PASSWORD=your_secure_password_here
SECRET_KEY=your_secret_key_here
```

**Important:**
- Set `FLASK_ENV=production` to activate the authentication guard
- Set `AUTH_PASSWORD` to your desired password (users will need this to access the app)
- Set `SECRET_KEY` to a random string for session security (or leave it blank to auto-generate)

### Usage

1. When `FLASK_ENV=production`, users will be redirected to a login page
2. Enter the password set in `AUTH_PASSWORD`
3. After successful login, users can access all features
4. Session persists until logout or browser session ends

### Logout

Users can logout by visiting `/logout` or the session will expire when the browser is closed.

## Project Structure

```
notes_app/
├── app.py                 # Main Flask application
├── requirements.txt       # Python dependencies
├── README.md             # This file
├── templates/
│   ├── index.html        # Main file browser template
│   └── error.html        # Error page template
└── static/
    ├── css/
    │   └── style.css     # Retro styling
    └── js/
        └── app.js        # Minimal JavaScript
```

## Customization

### Show Hidden Files

To show hidden files and folders, edit `app.py` and remove or comment out this section:

```python
# Skip hidden files/folders (optional - remove if you want to show them)
if entry.startswith('.'):
    continue
```

### Change Port

To use a different port, modify the last line in `app.py`:

```python
app.run(host='0.0.0.0', port=8080, debug=False)  # Change 5000 to your desired port
```

## License

This project is provided as-is for personal use.

## Credits

Designed with a nostalgic love for classic operating systems and file managers.

