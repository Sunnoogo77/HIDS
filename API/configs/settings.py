class Config:
    DEBUG = True
    SECRET_KEY = "My058Sc@Ckey"
    
class DevelopmentConfig(Config):
    ENV = "development"
    
config = {
    "development": DevelopmentConfig
}
