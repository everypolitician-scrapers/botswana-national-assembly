#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'
# require 'scraped_page_archive/open-uri'

def noko(url)
  Nokogiri::HTML(open(url).read)
end

ScraperWiki.sqliteexecute('DELETE FROM data') rescue nil

BASE = 'http://www.parliament.gov.bw/component/member/'
url = BASE + '?action=showAll&Itemid=110&limit=500'
page = noko(url)

data = page.xpath('//tr[.//div[@class="PhotoMemb"]]').map do |mem|
  member_page = BASE + mem.xpath('.//span[@class="label" and text()[contains(.,"Name")]]/ancestor::tr[1]/td[2]//a/@href').text
  details = noko(member_page)
  info = {
    # I can't get the sibling-td version of this to work, so up and down again
    name:         details.xpath('.//span[@class="label" and text()[contains(.,"Name")]]/ancestor::tr[1]/td[2]').text.tidy,
    post:         details.xpath('.//span[@class="label" and text()[contains(.,"Designation")]]/ancestor::tr[1]/td[2]').text.tidy,
    constituency: details.xpath('.//span[@class="labelDetails" and text()[contains(.,"Constituency")]]/ancestor::tr[1]/td[2]').text.tidy,
    party:        details.xpath('.//span[@class="labelDetails" and text()[contains(.,"Party")]]/ancestor::tr[1]/td[2]').text.tidy,
    email:        details.css('a[href^=mailto]').text,
    # image from the root page
    image:        mem.css('img/@src').text,
    source:       member_page,
  }
  info.delete(:image) if info[:image] == '/images/no_photo.jpg'
  info
end

# puts data
ScraperWiki.save_sqlite([:name], data)
