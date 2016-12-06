from bs4 import BeautifulSoup
import datetime
import json
import requests
import time

API_BASE_URL = 'https://api.talkdeskapp.com'
LOGIN_URL = 'https://tawkify.mytalkdesk.com/users/sign_in'
TAWKIFY_ACCOUNT_ID = '551492e6a0bef55ed100043a'
TAWKIFY_EMAIL = 'eng@tawkify.com'
TAWKIFY_PASSWORD = 'td1Tawk7'
DOWNLOAD_REP_LIST = (
    'Josh Hall',
    'Glenn Norum',
    'Bea Richards',
    'Eliza Washington',
    'Stefan Wenger',
    'Caitlin Ryvlin',
    'Camille Presley',
    'Mary Diaz',
    'Lani Parker',
    'Lindsey Perkins',
    'Kim Helmuth'
)
MIN_CALL_TIME = 400
MAX_CALL_TIME = 3000

def authenticate():
    AUTH_REQUEST = {
        'client_id': '582df68b2957190004ad7111',
        'client_secret': 'COsfNDFwPaJyb5U4ngjdC0m154idg625Z4-aPV1sHFs=',
        'client_version': '1',
        'account': 'tawkify',
        'username': 'eng@tawkify.com',
        'password': 'td1Tawk7'
    }

    r = requests.post(API_BASE_URL + '/auth/token', data=AUTH_REQUEST)
    if r.status_code != 200:
        print 'Bad status code: %d' % r.status_code
        exit()

    access_token = r.json()['access_token']
    return {
        'Authorization': 'Bearer %s' % access_token
    }

def create_report_job():
    yesterday_str = (datetime.date.today() - datetime.timedelta(1)).strftime('%Y-%m-%d')
    from_time = '%s 00:00:00 UTC' % yesterday_str
    to_time = '%s 23:59:59 UTC' % yesterday_str

    print 'Creating report for calls from %s to %s' % (from_time, to_time)

    r = requests.post(API_BASE_URL + '/reports/calls/jobs', headers=auth_header, data={
        'format': 'json',
        'timespan[from]': from_time,
        'timespan[to]': to_time
    })
    if r.status_code != 202:
        print 'Bad status code: %d' % r.status_code
        exit()
    return r.json()

if __name__ == '__main__':
    auth_header = authenticate()
    print 'Successfully authenticated to API.'
    report_job = create_report_job()
    print 'Created report with id ' + report_job['id']

    while True:
        report = requests.get(API_BASE_URL + '/reports/calls/files/%s' % report_job['id'], headers=auth_header)
        if report.status_code == 200:
            report = report.json()
            print 'Report fetched.'
            break
        print 'Report not ready yet, sleeping...'
        time.sleep(10)

    login_session = requests.Session()
    login_page = login_session.get(LOGIN_URL)
    soup = BeautifulSoup(login_page.text, 'html.parser')
    authenticity_token = soup.find('input', attrs={'name': 'authenticity_token'})['value']
    login_response = login_session.post(LOGIN_URL, data={
        'authenticity_token': authenticity_token,
        'user[account_id]': TAWKIFY_ACCOUNT_ID,
        'user[email]': TAWKIFY_EMAIL,
        'user[password]': TAWKIFY_PASSWORD,
        'commit': 'Login',
    })
    if login_response.status_code != 200:
        print 'Error logging into Talkdesk to download recordings.'
        exit()
    print 'Successfully logged in for downloading call mp3s.'

    for entry in report['entries']:
        if entry['agent_name'] in DOWNLOAD_REP_LIST and MIN_CALL_TIME <= entry['total_time'] <= MAX_CALL_TIME:
            if entry['recording_url'] is not None:
                print 'Downloading call for %s from %s' % (entry['agent_name'], entry['recording_url'])
                r = login_session.get(entry['recording_url'], stream=True)
                with open('%s_%s.mp3' % (entry['agent_name'], entry['callsid']), 'wb') as fd:
                    for chunk in r.iter_content(chunk_size=1024):
                        fd.write(chunk)
            else:
                print 'recording_url for %s was None' % entry['agent_name'],
