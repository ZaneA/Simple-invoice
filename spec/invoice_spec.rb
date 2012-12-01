require 'spec_helper'

describe Invoice do
  before :all do
    invoice = {
      'items' => [
        { 'description' => 'Description 1', 'rate' => 50, 'units' => 20 },
        { 'description' => 'Description 2', 'rate' => 120, 'units' => 1 }
      ]
    }

    File.write('2012-12-01-clientone-title.yml', YAML::dump(invoice))
  end

  before :each do
    @invoice = Invoice.new './2012-12-01-clientone-title.yml:2'
  end

  describe "#new" do
    it "takes a file parameter and returns an Invoice object" do
      @invoice.should be_an_instance_of Invoice
    end
  end

  describe "#parse_filename" do
    it "returns the correct hash" do
      correct_hash = {
        filename: './2012-12-01-clientone-title.yml',
        template: '2012-12-01-clientone-title',
        shortcode: '2',
        date: Date.new(2012, 12, 1),
        client: 'codeshack',
        title: 'title' 
      }

      @invoice.parse_filename('./2012-12-01-clientone-title.yml:2').should eql correct_hash
    end
  end

  describe "#generate" do
    it "generates a PDF in the current directory" do
      @invoice.generate

      File.exists? '2012-12-01-clientone-title.pdf'
    end
  end
end
