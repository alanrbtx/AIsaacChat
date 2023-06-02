import os
import sys
from src.flask_manager import RestAPIManager
import logging

def get_enviroment_variables(env_var, default_var):
    value = os.environ.get(env_var)
    if value is None:
        value = default_var
        print(value)
        msg = 'Empty enviroment variable'
        #log.warning(msg)
    print('Test: ', value)
    return value


if __name__ == '__main__':
    flaskport = get_enviroment_variables('FLASK_PORT', '8080')
    #log.warning(f'RestAPI running on {flaskport}')
    conductor = RestAPIManager()
    print('Test')
    debug_flag = False
    conductor.run('0.0.0.0', flaskport, True)

else:
    conductor = RestAPIManager()
    gunicorn_app = conductor.create()
