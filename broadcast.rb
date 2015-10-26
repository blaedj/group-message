require 'json'
require 'open-uri'
require 'sinatra'
require 'twilio-ruby'

SPREADSHEET_ID = ENV['SPREADSHEET_ID']
MY_NUMBER = ENV['MY_NUMBER']


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

def contact_name(number)
  parse_contacts[number]
end



post '/message' do
  puts "INFO: #{params.inspect}"
  from = params['From']
  body = params['Body']
  media_url = params['MediaUrl0']

  if from == MY_NUMBER
    twiml = send_to_contacts(body, media_url)
  else
    twiml = send_to_me(from, body, media_url)
  end

  content_type 'text/xml'
  twiml

end


def send_to_contacts(body, media_url = nil)
  response = Twilio::TwiML::Response.new do |r|
    contacts_phone_numbers.each do |num|
      puts "INFO: creating message for #{num}"
      r.Message to: num do |msg|
        msg.Body body
        msg.Media media_url unless media_url.nil?
      end
    end
  end
  puts "INFO: response text: #{response.text}"
  response.text
end


def send_to_me(from, body, media_url = nil)
  from_name = contact_name(from)
  body = "#{from_name} (#{from}):\n#{body}"
  response = Twilio::TwiML::Response.new do |r|
    r.Message to: MY_NUMBER do |msg|
      msg.Body body
      msg.Media media_url unless media_url.nil?
    end
  end
  response.text
end
