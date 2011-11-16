Google Calendar fetch
=====================

Given a Google Calendar XML url, this Rack app simply returns an array of the current events as JSON.

Use it, together with some simple parsing of the titles it returns (that bit's up to you) to:

* find out what's in your calendar now
* schedule variables for your webapp that change on a schedule (you'd have to poll every so often)
* control your burglar alarm (set an appointment 'on' from 9am to 5pm every day)
* feed your pets by robot arm (at your own risk)
* ...

Intended to be used by other systems where you don't want the complexity of parsing xml.

You'll need either:

* the Private XML URL that Google calendar gives you.  Click your calendar settings
and look for 'Private Address', for more info see

http://www.google.com/support/calendar/bin/answer.py?answer=34576&ctx=tltp

* or the 'Calendar Address', if it's a public calendar

If you're running it locally, this will retrieve current events, if there are any (remember to URL encode the cal parameter):

http://localhost:9292/?cal=https%3A%2F%2Fwww.google.com%2Fcalendar%2Ffeeds%2F9fjf6vkf1ou50j2umnju2lnrss%2540group.calendar.google.com%2Fpublic%2Fbasic

An example of how you might use it (cross-domain JSONP) from JQuery:

    $(document).ready(function() {
        $.ajax({
            url: 'http://localhost:9292',  // or wherever you're running this Rack app
            data: {
              // pass the xml feed you get from google calendar
              "cal" : "https://www.google.com/calendar/feeds/9fjf6vkf1ou50j2umnju2lnrss%40group.calendar.google.com/public/basic"
            },
            dataType: 'jsonp',
            error: function(jqXHR, textStatus, errorThrown) { alert('error: ' + textStatus); },
            success: function(data, textStatus, jqXHR) { 
              console.log(data) 
            },
            type: 'GET',
        });
    });