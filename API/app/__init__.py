from flask import Flask
from configs.settings import config
from flask_cors import CORS

def create_app():
    app = Flask(__name__)
    CORS(app)
    
    #Importer les routes API
    from app.routes.files import files_bp
    from app.routes.folders import folders_bp
    from app.routes.ips import ips_bp
    from app.routes.alerts import alerts_bp
    from app.routes.emails import emails_bp
    from app.routes.monitor import monitor_bp
    from app.routes.status import status_bp
    from app.routes.config import config_bp
    
    
    #Save blueprints
    app.register_blueprint(files_bp, url_prefix="/api/files")
    app.register_blueprint(folders_bp, url_prefix="/api/folders")
    app.register_blueprint(ips_bp, url_prefix="/api/ips")
    app.register_blueprint(alerts_bp, url_prefix="/api/alerts")
    app.register_blueprint(emails_bp, url_prefix="/api/emails")
    app.register_blueprint(monitor_bp, url_prefix="/api/monitor")
    app.register_blueprint(status_bp, url_prefix="/api/status") 
    app.register_blueprint(config_bp, url_prefix="/api/config")
    
    return app