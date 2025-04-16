from flask import Flask, render_template, request, redirect
from flask_sqlalchemy import SQLAlchemy
import os
import json
import boto3
from botocore.exceptions import ClientError
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()
app = Flask(__name__)

def get_secret():
    """
    Retrieve database credentials from AWS Secrets Manager
    """
    secret_name = os.getenv("SECRET_NAME")
    region_name = os.getenv("AWS_REGION", "us-east-1")
    
    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )
    
    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        # Handle potential errors
        app.logger.error(f"Error retrieving secret: {e}")
        # Fall back to environment variables if secret retrieval fails
        return {
            "username": os.getenv("DB_USER", "flaskuser"),
            "password": os.getenv("DB_PASSWORD", ""),
            "host": os.getenv("DB_HOST", ""),
            "port": os.getenv("DB_PORT", "3306"),
            "dbname": os.getenv("DB_NAME", "flask_todo_db")
        }
    else:
        # Decrypted secret
        if 'SecretString' in get_secret_value_response:
            secret = get_secret_value_response['SecretString']
            return json.loads(secret)
        else:
            app.logger.error("Unable to retrieve secret text")
            return None

# Get database credentials from Secrets Manager
db_credentials = get_secret()

print("DB credentials loaded:")
for k, v in db_credentials.items():
    print(f"{k}: {v}")


if db_credentials:
    # Build the connection string from the secret values
    db_uri = f"mysql+mysqlconnector://{db_credentials['username']}:{db_credentials['password']}@{db_credentials['host']}:{db_credentials['port']}/{db_credentials['dbname']}"
    app.config['SQLALCHEMY_DATABASE_URI'] = db_uri
else:
    # Fallback to environment variable if secret retrieval fails
    app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv('DATABASE_URI')

app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)

class Todo(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    task = db.Column(db.String(200), nullable=False)

@app.route('/')
def index():
    todos = Todo.query.all()
    return render_template('index.html', todos=todos)

@app.route('/add', methods=['POST'])
def add():
    task = request.form.get('task')
    if task:
        new_task = Todo(task=task)
        db.session.add(new_task)
        db.session.commit()
    return redirect('/')

@app.route('/delete/<int:id>')
def delete(id):
    task = Todo.query.get(id)
    if task:
        db.session.delete(task)
        db.session.commit()
    return redirect('/')

if __name__ == '__main__':
    with app.app_context():
        db.create_all()  # Creates tables if they don't exist
    app.run(host='0.0.0.0', port=5000)