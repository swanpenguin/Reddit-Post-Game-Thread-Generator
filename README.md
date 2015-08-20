# Reddit Post-Game Thread Generator

This tool generates game threads in the appropriate sub-reddit when fed an ESPN link.

### Tech

This simple product is packaged in Ruby on Rails and Nokogiri for web-scraping. Is Ruby on Rails too big a framework for something this simple? Yes, but packaging was easy and we have free reign on scaling up the codebase.

### To-Do List

* Clean up code
* Documentation
* Put up a link on the website stating that it is now open-source, and have that link to the GitHub repository
* Prettier design
* Cross-reference ESPN team names with sub-reddit flairs and use this data to generate threads with flairs intact.
* Revamp the whole website so that users don't have to go to ESPN and manually type in a link. We keep track of CFB, NFL, CBB, and NBA games and will instead let users select which recently finished game they want to post.

### Contributing

Want to contribute? Awesome!

Fork this repository, get it onto your machine, then run `bundle install`. 

Once everything works on your side, start submitting issues and pull-requests for code you've written. To keep the commit list nice and orderly, please squash all of your commits down into 1 once you get the golden stamp of approval for your pull-request.

### License

MIT