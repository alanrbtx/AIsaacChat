set -e
if [ -z ${1} ]; then
    echo "--"
    echo 'Start RestAPI'
    echo "--"
    python3 app.py
elif [ \"$@\" == \"debug\" ]; then
    echo "--"
    echo 'Start RestAPI in debug mode'
    echo "--"
    python3 app.py -v
elif [ \"$@\" == \"gunicorn\"]; then
    echo "--"
    echo 'Start RestAPI in gunicorn mode'
    echo "--"
    gunicorn -w 5 --timeout 300 --bind :5000 app:gunicorn_app
else 
    exec "$@"
fi
