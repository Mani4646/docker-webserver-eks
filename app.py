#Flask Webserver Application
from flask import Flask
import os
from datetime import datetime

app = Flask(__name__)
PORT = int(os.environ.get('PORT', 5000))
ENVIRONMENT = os.environ.get('ENVIRONMENT', 'development')

@app.route('/')
def home():
    return {
        'message': 'Welcome to Simple Webserver',
        'timestamp': datetime.utcnow().isoformat(),
        'environment': ENVIRONMENT,
        'status': 'running'
    }

@app.route('/health')
def health():
    return {'status': 'healthy', 'timestamp': datetime.utcnow().isoformat()}, 200

@app.route('/api/version')
def version():
    return {'version': '1.0.0', 'app': 'simple-webserver'}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=PORT, debug=(ENVIRONMENT == 'development'))