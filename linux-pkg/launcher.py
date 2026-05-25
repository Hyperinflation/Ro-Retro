#!/usr/bin/env python3
import http.server
import socketserver
import webbrowser
import socket
import sys
import threading
import time
import os

def get_free_port():
    """Finds an unused local port to run the web server on."""
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.bind(('127.0.0.1', 0))
    port = s.getsockname()[1]
    s.close()
    return port

# Determine the directory where static assets reside (either build/web/ or current path)
DIRECTORY = os.path.dirname(os.path.abspath(__file__))
if os.path.exists(os.path.join(DIRECTORY, 'build', 'web')):
    DIRECTORY = os.path.join(DIRECTORY, 'build', 'web')

PORT = get_free_port()

class RoRetroHandler(http.server.SimpleHTTPRequestHandler):
    """Custom request handler that captures a shutdown beacon signal."""
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def do_POST(self):
        if self.path == '/shutdown':
            self.send_response(200)
            self.send_header('Content-type', 'text/plain')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(b'Shutdown sequence initiated')
            print("Received close request from browser. Terminating server...")
            
            # Shutdown in a separate thread to prevent deadlock of request socket
            threading.Thread(target=self.server.shutdown).start()
            return
        super().do_POST()

    def do_GET(self):
        # Support fallback GET shutdown in addition to beacon POST
        if self.path == '/shutdown':
            self.send_response(200)
            self.send_header('Content-type', 'text/plain')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(b'Shutdown sequence initiated')
            print("Received close request from browser. Terminating server...")
            threading.Thread(target=self.server.shutdown).start()
            return
        super().do_GET()

    def log_message(self, format, *args):
        # Suppress logging server requests to stdout for a clean terminal output
        pass

def open_browser():
    """Waits for server setup and triggers browser navigation."""
    time.sleep(0.6)
    webbrowser.open(f"http://127.0.0.1:{PORT}")

if __name__ == '__main__':
    print(f"Starting Ro-Retro Game Hub (Flutter Edition) server...")
    print(f"Directory: {DIRECTORY}")
    print(f"Endpoint:  http://127.0.0.1:{PORT}")
    
    # Restrict to local loopback (localhost) for security
    socketserver.TCPServer.allow_reuse_address = True
    server = socketserver.TCPServer(("127.0.0.1", PORT), RoRetroHandler)
    
    # Spawn browser in separate thread
    browser_thread = threading.Thread(target=open_browser)
    browser_thread.daemon = True
    browser_thread.start()
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nKeyboard interrupt received.")
    finally:
        server.server_close()
        print("Server shutdown completed. Goodbye!")
        sys.exit(0)
