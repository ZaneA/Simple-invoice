This small Ruby program reads simple YAML documents and generates nice looking PDF invoices as output.

Usage
---

It's designed to be simple, I'm using it for my personal invoices. Quickstart:

    $ git clone git://github.com/ZaneA/Simple-invoice
    $ cd Simple-invoice
    $ bundle install
    $ ./invoice.rb example/2013-01-01-clientone-some-work.yml
    $ open 2013-01-01-clientone-some-work.pdf

Now how do I use it for myself?
---

Open `config.yml` in your favourite editor and define your clients, and any other required portions. Throw in a nice logo as well.

Invoices are specified with the bare minimum of work required and get their date, client name, and title from the filename (inspired by Jekyll). The file naming format is:

    YYYY-MM-DD-<clientname>-<invoice-title>.yml

The YAML inside is simple as well and should be self-explanatory:

    # Optional
    paid: 200

    items:
      - description: Web design and development.
        rate: 50
        units: 10
      - description: Annual web hosting.
        rate: 100
        units: 1

License
---

GPLv3
