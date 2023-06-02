from flask import Flask, url_for
from src.rest_api import setup_rest_api


from flask import Flask
app = Flask(__name__)


class RestAPIManager:
    def __init__(self):
        self.app = Flask('rest_api-manager')
        self.api = setup_rest_api(self)

    def run(self, host, port_num, debug_flag):
        try:
            self.app.run(host, port=port_num, debug=debug_flag, use_reloader=False)
        except Exception as exc:
            raise RuntimeError(str(exc))


    def create(self):
        return self.app 


    
 
