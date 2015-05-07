#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'date'
require 'open-uri'

require 'open-uri/cached'
# require 'colorize'
# require 'pry'
# require 'csv'

def noko(url)
  Nokogiri::HTML(open(url).read) 
end

BASE = "http://www.parliament.gov.bw/component/member/"
url = BASE + '?action=showAll&Itemid=110&limit=500'
page = noko(url)

data = page.xpath('//tr[.//div[@class="PhotoMemb"]]').map do |mem|

  member_page = BASE + mem.xpath('.//span[@class="label" and text()[contains(.,"Name")]]/ancestor::tr[1]/td[2]//a/@href').text
  details = noko(member_page)
  info = {
    # I can't get the sibling-td version of this to work, so up and down again
    name: details.xpath('.//span[@class="label" and text()[contains(.,"Name")]]/ancestor::tr[1]/td[2]').text.strip.gsub(/\s+/,' '),
    post: details.xpath('.//span[@class="label" and text()[contains(.,"Designation")]]/ancestor::tr[1]/td[2]').text.strip.gsub(/\s+/,' '),
    constituency: details.xpath('.//span[@class="labelDetails" and text()[contains(.,"Constituency")]]/ancestor::tr[1]/td[2]').text.strip.gsub(/\s+/,' '),
    party: details.xpath('.//span[@class="labelDetails" and text()[contains(.,"Party")]]/ancestor::tr[1]/td[2]').text.strip.gsub(/\s+/,' '),
    email: details.css('a[href^=mailto]').text,
    # image from the root page
    image: mem.css('img/@src').text,
    source: member_page,
  }
  info.delete(:image) if info[:image] == "/images/no_photo.jpg"
  info
end

ScraperWiki.save_sqlite([:name], data)
