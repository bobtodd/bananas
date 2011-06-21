Notes on textgrounder
=====================

As I'm trying to evaluate [textgrounder][tg] for use in geolocating routines, seems like it'd be a good idea not to depend too greatly on my rapidly deteriorating memory and to jot down some observations on paper... er, in a file.  Whatever.

Basic Idea
------------

So I ran a test of [textgrounder][tg] the other day on a more-or-less randomly selected webpage.  I had a few vague criteria in mind:

* A webpage that people would actually _go_ to...
    * ... but with geographic entities embedded;
* Something not of a literary bent,
    * i.e. no [Project Gutenberg][pg] texts, no [New York Times][nyt], etc.;
* Something with some mildly extended text...
    * ... but with other surrounding, irrelevant code.

With these criteria in mind, I decided to test [this travel page][test] on the [National Geographic][natgeo] website.  Since we need a fairly robust geolocation routine, I wanted to do minimal preprocessing of the [test webpage][test], so I settled finally on simply picking out anything between `<p> ... </p>` pairs.  This picked out all the extended passages I wanted, and of course some ridiculous garbage with more angle-brackets.  Is it just me, or is HTML really stinkin' ugly?

Basic Issues
------------

So upon unleashing [this beast][tg] upon my unsuspecting [text][test], I received a mostly identifiable carcass, but with some appendages of uncertain origin mixed in.  Some stuff it got right, some not so much:

* Right
    * Fairbanks, AK
    * Seattle, WA

* Wrong
    * Simply "Alaska", which gets located in New Mexico;
    * "Anchorage, Alas.", which gets located in Utah;

* Indeterminate
    * "Colorado" in the phrase "Menu defines the region: Colorado elk", which gets located in Texas (even though "Rocky Mountain High" appears within the paragraph).


Observations on textgrounder's Source Code
------------------------------------------

There are two basic places issues can arise that can lead to [textgrounder][tg] going awry: the code itself, obviously, and the geographic database the user feeds it.  There are a couple issues that should be kept in mind when evaluating the above results:

* Database
    * The example databases for US geographical outlined in the [getting started][gs] guide have no column headers: so it's a little difficult to figure out how to add more refined data in a way that [textgrounder][tg] can read and employ to enhance performance.

* Source code
    * At least in [CandidateList.java][cl], [textgrounder][tg] seems to employ _physical distance_ (determined from the coordinates) as part of the algorithm.  If this actually factors heavily into the algorithm thatultimately determines what geolocation is being referenced, this might cause problems:
        * For example, though I know of and fully support the existence of Paris, Texas, when I say "Paris" I almost never refer to the Texas town, even though it's closer geographically.


To-dos
------

Some of the above issues may have more to do with how I prepared the text to be parsed than how [textgrounder][tg] functions.  So let's start a little list of stuff I have to check out:

*  I'll need to run the program on the same website, but trying this time to keep paragraph headers (i.e. entities not included in `<p> ... </p>` pairs), to see if the titles help improve performance.


[tg]: http://code.google.com/p/textgrounder/ "textgrounder wiki"
[pg]: http://www.gutenberg.org/wiki/Main_Page "Project Gutenberg homepage"
[nyt]: http://www.nytimes.com/ "New York Times"
[test]: http://travel.nationalgeographic.com/travel/hotels/2009/best-hotels-western-us/ "NatGeo test page"
[natgeo]: http://www.nationalgeographic.com/ "National Geographic"
[gs]: http://code.google.com/p/textgrounder/wiki/GettingStarted "textgrounder Getting Started guide"
[cl]: http://code.google.com/p/textgrounder/source/browse/src/main/java/opennlp/textgrounder/topo/gaz/CandidateList.java "CandidateList.java"