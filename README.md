MakerService
============
This is a very useful webservice that serves up data from Data::Maker.  The reason it's useful is because it makes it
possible for non-Perl code to use Data::Maker, which only works in Perl.

The current problem with it is that it still requires the description of the data needed to be written in Perl.  A high
priority for me is to change Data::Maker so that you can describe it's data in XML.  I think that change will be pretty
easy, actually, and that will open up this service to be much more useful.
