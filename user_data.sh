#!/bin/bash
dnf update -y
dnf install -y python3-pip
pip3 install flask pymysql boto3

mkdir -p /opt/rdsapp
cat >/opt/rdsapp/app.py <<'PY'
import json
import os
import boto3
import pymysql
import time
from flask import Flask, request

REGION = os.environ.get("AWS_REGION", "us-east-2")
SECRET_ID = os.environ.get("SECRET_ID", "echobase/rds/mysql")

LOG_GROUP = "/aws/ec2/echobase-rds-app"
LOG_STREAM = "echobase-rds-app"

secrets = boto3.client("secretsmanager", region_name=REGION)
logs_client = boto3.client("logs", region_name=REGION)

def log_to_cloudwatch(message):                                                                                                                                                                                                                                  
    try:                                                                                                                                                                                                                                                         
        logs_client.put_log_events(                                                                                                                                                                                                                              
            logGroupName=LOG_GROUP,                                                                                                                                                                                                                              
            logStreamName=LOG_STREAM,                                                                                                                                                                                                                            
            logEvents=[{                                                                                                                                                                                                                                         
                'timestamp': int(time.time() * 1000),                                                                                                                                                                                                            
                'message': message                                                                                                                                                                                                                               
            }]                                                                                                                                                                                                                                                   
        )                                                                                                                                                                                                                                                        
    except Exception as e:                                                                                                                                                                                                                                       
        print(f"Failed to log to CloudWatch: {e}")

def get_db_creds():
    resp = secrets.get_secret_value(SecretId=SECRET_ID)
    s = json.loads(resp["SecretString"])
    # When you use "Credentials for RDS database", AWS usually stores:
    # username, password, host, port, dbname (sometimes)
    return s

def get_conn():                                                                                                                                                                                                                                                  
    try:                                                                                                                                                                                                                                                         
        c = get_db_creds()                                                                                                                                                                                                                                       
        host = c["host"]                                                                                                                                                                                                                                         
        user = c["username"]                                                                                                                                                                                                                                     
        password = c["password"]                                                                                                                                                                                                                                 
        port = int(c.get("port", 3306))                                                                                                                                                                                                                          
        db = c.get("dbname", "notesappdb")                                                                                                                                                                                                                       
        return pymysql.connect(host=host, user=user, password=password, port=port, database=db, autocommit=True)                                                                                                                                                 
    except Exception as e:                                                                                                                                                                                                                                       
        log_to_cloudwatch(f"ERROR: DB connection failed - {e}")                                                                                                                                                                                                  
        raise

app = Flask(__name__)

@app.route("/")
def home():
    return """
    <h2>EC2 → RDS Notes App</h2>
    <p>POST /add?note=hello</p>
    <p>GET /list</p>
    """

@app.route("/init")
def init_db():
    c = get_db_creds()
    host = c["host"]
    user = c["username"]
    password = c["password"]
    port = int(c.get("port", 3306))

    # connect without specifying a DB first
    conn = pymysql.connect(host=host, user=user, password=password, port=port, autocommit=True)
    cur = conn.cursor()
    cur.execute("CREATE DATABASE IF NOT EXISTS notesappdb;")
    cur.execute("USE notesappdb;")
    cur.execute("""
        CREATE TABLE IF NOT EXISTS notes (
            id INT AUTO_INCREMENT PRIMARY KEY,
            note VARCHAR(255) NOT NULL
        );
    """)
    cur.close()
    conn.close()
    return "Initialized notesappdb + notes table."

@app.route("/add", methods=["POST", "GET"])
def add_note():
    note = request.args.get("note", "").strip()
    if not note:
        return "Missing note param. Try: /add?note=hello", 400
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("INSERT INTO notes(note) VALUES(%s);", (note,))
    cur.close()
    conn.close()
    return f"Inserted note: {note}"

@app.route("/list")
def list_notes():
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("SELECT id, note FROM notes ORDER BY id DESC;")
    rows = cur.fetchall()
    cur.close()
    conn.close()
    out = "<h3>Notes</h3><ul>"
    for r in rows:
        out += f"<li>{r[0]}: {r[1]}</li>"
    out += "</ul>"
    return out

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
PY

cat >/etc/systemd/system/rdsapp.service <<'SERVICE'
[Unit]
Description=EC2 to RDS Notes App
After=network.target

[Service]
WorkingDirectory=/opt/rdsapp
Environment=SECRET_ID=echobase/rds/mysql
ExecStart=/usr/bin/python3 /opt/rdsapp/app.py
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable rdsapp
systemctl start rdsapp