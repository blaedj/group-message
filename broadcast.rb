require 'json'
require 'open-uri'

SPREADSHEET_ID = "1nEfyscOTWqsGoVGlwWp_m5bVsvO4HyyTISU4DD2rUG8"

def spreadsheet_url
  "http://spreadsheets.google.com/feeds/list/#{SPREADSHEET_ID}/od6/public/values?alt=json"
end


# sanitize phone numbers for twilio
def sanitize(number)
  # replace leading '1' and non-digits with ""
  "+1" + number.gsub(/^1|\D/, "")
end


def data_from_spreadsheet
  file = open(spreadsheet_url).read
  JSON.parse(file)
end

def parse_contacts
  contacts = {}
  data_from_spreadsheet['feed']['entry'].each do |entry|
    first = entry['gsx$first']['$t']
    last = entry['gsx$last']['$t']
    number = entry['gsx$phone']['$t']
    contacts[sanitize(number)] = "#{first} #{last}"
  end
  contacts
end

def contacts_phone_numbers
  parse_contacts.keys
end

def contacts_names
  parse_contacts[number]
end
