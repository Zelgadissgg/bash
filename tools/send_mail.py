#!/usr/bin/python3

import argparse
import csv
import smtplib
import socket
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.header import Header
import datetime

class FWMail:
    message = MIMEMultipart()
    date = ""
    hostname = socket.gethostname()
    smtpObj = None
    def __init__(self, smtp):
        cur_date = datetime.datetime.now()
        self.date = " " + str(cur_date.year) + "-" + str(cur_date.month) + "-" + str(cur_date.day)
        
        if len(smtp) > 0 :
            self.smtpObj = smtplib.SMTP(smtp['host'])
        else:
            self.smtpObj = smtplib.SMTP('localhost')
        
        smtp_reply = self.smtpObj.ehlo()
        if smtp_reply[0] != 250: # RFC821 define SMTP HELO: S:250
            self.smtpObj.quit()
            print(smtp_reply)
            raise Exception("Send Mail module couldn't work with current network setting", smtp_reply[0])
        
        if len(smtp) > 0 :
            try:
                self.smtpObj.login(smtp['user'], smtp['passwd'])
            except smtplib.SMTPAuthenticationError:
                self.smtpObj.quit()
                raise Exception("Login smtp server " + smtp['host'] + " by user: " + smtp['user'] + " Failed")
            try:
                self.smtpObj.starttls()
            except smtplib.SMTPNotSupportedError:
                print("Server don't support STARTTLS extension, skip this feature")
        
        smtp_reply = self.smtpObj.ehlo()
        if smtp_reply[0] != 250: # RFC821 define SMTP HELO: S:250
            self.smtpObj.quit()
            print(smtp_reply)
            raise Exception("Send Mail module couldn't work with current network setting", smtp_reply[0])
        
        smtp_reply = self.smtpObj.connect()
        if smtp_reply[0] != 220: # RFC821 define SMTP connect: S:220
            self.smtpObj.quit()
            raise Exception("Send Mail module couldn't work with current network setting")
    
    def attchmentFile(self, filename, att_name):
        if filename is None:
            return
        
        att_file = MIMEText(open(filename, 'rb').read(), 'base64', 'utf-8')
        att_file["Content-Type"] = 'application/octet-stream'
        att_file["Content-Disposition"] = 'attachment; filename="' + att_name +'"'
        self.message.attach(att_file)
    
    def send(self, mailto, case_dict):
        receivers = mailto
        self.message['To'] = mailto
        self.message['From'] = Header("VATS Auotmation Test" + self.hostname, 'utf-8')
        self.message['Subject'] = Header("Automation " + self.date , 'utf-8')
        msg_html = '<html><head><title>' + "Mail of " + self.date + '</title></head>'
        msg_html +='<body><p><b><font face="verdana">' + "Mail of " + self.date
        msg_html += '</font></b></p>'
        
        case_table_html= '<tr><td>Case Name</td><td>Test Result</td><td>Total Run time</td><td>Run Type</td><td>Run Count</td><td>Average Run time</td>'
        case_total = len(case_dict)
        case_nrun = 0
        case_pass = 0
        for id, item in case_dict.items():
            case_table_html += '<tr><td>' + id + '</td>'
            case_table_html += '<td>' + item['name'] + '</td>'
            if item['result'] == 'PASS':
                case_pass += 1
                case_table_html += '<td><font color="green">' + item['result'] + '</font></td>'
            elif item['result'] == 'FAIL':
                case_table_html += '<td><b><i><font color="red">' + item['result'] + '</font></i><b></td>'
            elif item['result'] == 'NRUN':
                case_nrun += 1
                case_table_html += '<td><i><font color="gray">' + item['result'] + '</font></i></td>'
            elif item['result'] == 'BLOCK':
                case_table_html += '<td><b><i><font color="black">' + item['result'] + '</font></i></b></td>'
            else:
                case_table_html += '<td><font color="yellow">' + item['result'] + '</font></td>'
            case_table_html += '<td>' + item['total'] + '</td><td>' + item['type'] + '</td><td>' + item['count'] + '</td><td>' + item['average'] + '</td></tr>'
        
        case_total -= case_nrun
        msg_html += '<table border="0">'
        msg_html += '<tr><td colspan="7" align="center"><b>Test Result</b><td><tr>'
        msg_html += '<tr><td align="left" colspan="2"><b>Total: ' + str(case_total) + '</b></td>'
        msg_html += '<td align="left"><b><font colspan="2"> color="green">Pass: ' + str(case_pass) + '</font></b></td>'
        msg_html += '<td align="left"><b><font colspan="2" color="red">Fail: ' + str(case_total - case_pass) + '</font></b></td>'
        msg_html += '<td align="left"><b><font color="gray">Skip: ' + str(case_nrun) + '</font></b></td></tr></table>'
        msg_html += '<table border="1"><tr><td colspan="7" align="center"><b>Detail Result</b><td><tr>'
        msg_html += case_table_html
        msg_html += '</table>'
        msg_html += '</body></html>'
        
        self.message.attach(MIMEText(msg_html, 'html', 'utf-8'))

        try:
            smtp_reply = self.smtpObj.ehlo()
            if smtp_reply[0] != 250: # RFC821 define SMTP HELO: S:250
                self.smtpObj.quit()
                print(smtp_reply)
                return 1
            self.smtpObj.sendmail("automation@" + self.hostname, receivers, self.message.as_string())
            print("mail send success")
            return 0
        except smtplib.SMTPException as err:
            print("mail send failed")
            print(err)
            return 1

mail_to = None
smtp_conf = {}

# Parser for command-line options
parser = argparse.ArgumentParser(description='VATS framework send mail module.')
parser.add_argument('-a', '--attachment', type=str, help='email attachment file name')
parser.add_argument('-m', '--mailto', type=str, help='Send the mail to target')
parser.add_argument('-r', '--result', type=str, help='summary result file')
parser.add_argument('-s', '--smtp', type=str, help='SMTP Server setting if needed')

args = vars(parser.parse_args())

if args['result'] is None or args['mailto'] is None:
    print("Miss attachment File to send the mail")
    exit(1)

case_dict = {}

with open(args['result']) as csvfile:
    reader = csv.DictReader(csvfile)
    for row in reader:
        case_dict[row['id']]={}
        case_dict[row['id']]['name']=row['name']
        case_dict[row['id']]['result']=row['result']
        case_dict[row['id']]['total']=row['total']
        case_dict[row['id']]['type']=row['type']
        case_dict[row['id']]['count']=row['count']
        case_dict[row['id']]['average']=row['average']

if args['smtp']is not None:
    with open(args['smtp']) as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            smtp_conf['host']=row['host']
            smtp_conf['user']=row['user']
            smtp_conf['passwd']=row['passwd']

exit(0)

try:
    fwmail = FWMail(smtp_conf)
    fwmail.attchmentFile(args['attachment'], "result.zip")
    exit(fwmail.send(args['mailto'], case_dict))
except Exception as err:
    print(err)
    exit(1)
