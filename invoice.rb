#!/usr/bin/env ruby

# This program reads simple YAML documents and generates
# nice looking PDF invoices as output.
#
# Author::    Zane Ashby (mailto:zane.a@demonastery.org)
# Copyright:: Copyright (c) 2012 Zane Ashby
# License::   GPLv3

require 'prawn'
require 'prawn/measurement_extensions'

require 'yaml'

# Add to this class a quick method to add thousands
# separators to a number, for use in currency output.

class String
  def add_thousands_separator
    number = self.to_s.reverse
    number.gsub!(/(\d\d\d)(?=\d)(?!\d*\.)/) do |match|
      $1 + ','
    end

    number.to_s.reverse
  end
end

# The main class that reads in the config and each
# invoice document and generates the PDF layout.

class Invoice
  def initialize(invoice, output = nil)
    # Load config
    @config = YAML::load(File.read('config.yml'))

    @file_hash = parse_filename(invoice)

    # Output to the same name as invoice with pdf extension
    @output = @file_hash[:template] + ".pdf"

    # Load invoice
    @invoice = YAML::load(File.read(@file_hash[:filename]))

    @invoice['to'] = @config['clients'][@file_hash[:client]] unless @invoice['to']
  #rescue
    #$stderr.puts "Couldn't load or parse: #{$1}"
  end

  def generate
    config = @config
    invoice = @invoice

    file_hash = @file_hash

    info = {
      Title: "#{file_hash[:title]} Invoice",
      Author: config['name']
    }

    Prawn::Document.generate(@output, info: info) do
      default_leading 3.mm

      image config['logo']['path'], at: [bounds.width - config['logo']['width'], bounds.height], width: config['logo']['width']

      text "Invoice".upcase, size: 36

      transparent(0.6) do
        text file_hash[:date].strftime('%d %B %Y'), size: 14

        text "Invoice No. <b>#{file_hash[:date].strftime '%Y%m%d'}-#{file_hash[:shortcode]}</b>", inline_format: true
      end

      move_down 1.cm

      # To
      text invoice['to'].first, style: :bold, size: 16
      invoice['to'].drop(1).each do |line|
        text line
      end

      move_down 1.cm

      total = 0.0

      cells = [[
        '<b>Item</b>',
        { content: '<b>Rate</b>', align: :right },
        { content: '<b>Units</b>', align: :right }
      ]]

      invoice['items'].each do |item|
        cells << [
          item['description'],
          { content: sprintf('$%.2f', item['rate']).add_thousands_separator, align: :right },
          { content: item['units'].to_s, align: :right }
        ]

        total += item['rate'] * item['units']
      end

      table cells,
        header: true,
        column_widths: [420, 60, 60],
        row_colors: ['fcfcfc', 'eeeeee'],
        cell_style: {
          borders: [:bottom],
          inline_format: true,
          overflow: :shrink_to_fit}

      move_down 1.cm

      # Calculate discount
      discount = invoice['discount'] || 0.0
      total_discount = total * (discount / 100.0)

      # Calculate tax
      tax = config['tax'] || 0.0
      total_tax = total * (tax / 100.0)

      net = total
      net = net - total_discount
      net = net + total_tax

      text "Total: #{sprintf('$%.2f', total).add_thousands_separator}", size: 13, align: :right

      if discount != 0.0
        text "Discount: #{discount}%", size: 13, align: :right
      end

      if tax != 0.0
        text "GST: #{sprintf('$%.2f', gst).add_thousands_separator}", size: 13, align: :right
      end

      text "Amount Due: #{sprintf('$%.2f', net).add_thousands_separator}", size: 14, align: :right, style: :bold

      move_down 2.cm

      span 420, position: :center do
        text config['note'], inline_format: true, align: :center, leading: 1.mm, size: 13
      end

      bounding_box([0, 1.5.cm], width: bounds.width, height: 2.cm) do
        transparent(0.6) do
          text config['footer'], inline_format: true, align: :center, size: 13
        end
      end
    end
  end

  # Parse a filename like "path/to/year-month-day-clientname-title.yml:shortcode"
  # and return a hash containing :filename, :template, :shortcode, :date, :client, :title.

  def parse_filename(filename)
    shortcode = '1'

    parts = filename.split(':')

    if parts[1]
      shortcode = parts[1]
    end

    filename = parts[0]

    basename = File.basename(filename)

    filename_no_ext = File.basename(basename, File.extname(basename))

    filename_no_ext =~ /(\d+)-(\d+)-(\d+)-(\w+)-([a-z\-]+)/

    {
      filename: filename,
      template: filename_no_ext,
      shortcode: shortcode,
      date: Date.new($1.to_i, $2.to_i, $3.to_i),
      client: $4,
      title: $5
    }
  end
end

if __FILE__ == $0
  # Being run as a command-line utility.
  
  if ARGV.length == 0
    $stderr.puts "Usage: invoice <path> [path ...]"
    exit 1
  end

  ARGV.each do |source|
    puts "Processing #{source}."

    invoice = Invoice.new source
    invoice.generate
  end
end
