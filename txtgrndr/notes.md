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

There are two basic places where issues can arise that can lead to [textgrounder][tg] going awry: the code itself, obviously, and the geographic database the user feeds it.  There are a couple issues that should be kept in mind when evaluating the above results:

* Database
    * The example databases for US geographical entities outlined in the [getting started][gs] guide have no column headers: so it's a little difficult to figure out how to add more refined data in a way that [textgrounder][tg] can read and employ to enhance performance.

* Source code
    * At least in [CandidateList.java][cl], [textgrounder][tg] seems to employ _physical distance_ (determined from the coordinates) as part of the algorithm.  If this actually factors heavily into the algorithm that ultimately determines what geolocation is being referenced, this might cause problems:
        * For example, though I know of and fully support the existence of Paris, Texas, when I say "Paris" I almost never refer to the Texas town, even though it's closer geographically.
            * Of course I suspect [textgrounder][tg]'s designers already thought of this; but I don't yet know how they get around it.
        * In particular there needs to be a way to distinguish names that are, simply, _popular_.  When "Alaska" occurs in an almost context-free setting (with no other geographical qualification), the default needs to be to the "most popular" use of "Alaska".  I.e., the _default_ must be that this refers to the northernmost region of the United States, and [Alaska, NM][anm] must _at most_ be a secondary option.
            * This actually doesn't seem like it'd be too hard in principle.  Essentially, if I say "Alaska", with no other qualification, it's pretty clear I mean the state.  The corresponding entry in the gazetteer has `"Alaska\tAlaska"`, i.e. it's the only entry that repeats the state name.  Similarly, there's one line `"New Mexico\tNew Mexico"`, which is the only line that should reasonably be associated with a contextless reference to "New Mexico".


To-dos
------

Some of the above issues may have more to do with how I prepared the text to be parsed than how [textgrounder][tg] functions.  So let's start a little list of stuff I have to check out:

*  I'll need to run the program on the same website, but trying this time to keep paragraph headers (i.e. entities not included in `<p> ... </p>` pairs), to see if the titles help improve performance.
    * Actually, my code already keeps the headers, since they're within the `<p> ... </p>` tags;
    * but they are surrounded by other HTML formatting elements, which might perhaps mess up [textgrounder][tg].
        * Update 2011-06-21: No noticable improvement (in fact, arguably worse performance) switching Nokogiri's `xpath("//p")` to `xpath("//text()")` to extract text.
* I need to figure out where in the code [textgrounder][tg] extracts items from the database to see if there's allowance made for different formats with more options.
    * For example, does [textgrounder][tg] only recognize "Alaska" and "AK" as valid symbols for that state, or is it also picking up on "Alas."?  It seems like it doesn't recognize the latter.
        * Update 2011-06-23: Okay, so a perusal of the code suggests that the basic processing of the gazetteer files (the geolocation databases used in the [getting started][gs] guide) happens in the files [GeoNamesGazetteer.java][gng] and [GeoNamesGazetteerWithList.java][gngl].  If I understand correctly, the data categories are hard-coded into [textgrounder][tg]: e.g., [textgrounder][tg] _assumes_ latitude is `fields[4]`, etc.  To make [textgrounder][tg] more robust, it would've been helpful if it instead read the field names from the first line of the file (or a separate file) and then created a hash with those names as keys.  The drawback is that would be much more memory-intensive than the appoach they've used of packing into arrays.
* A possible workaround: redundant entries.
    * It seems that "Beaver Springs, CO" will get correctly interpreted by [textgrounder][tg], since the substrings "Beaver Springs" and "CO" are part of the gazetteer of US placenames.  But it's not clear that "Beaver Springs, Colo." gets interpreted correctly, presumably because "Colo." is not a string it knows about.
    * Ideally there would simply be a way to tell [textgrounder][tg] that "Colo." is a valid alternative for "CO".  But lacking such an option, a pragmatic alternative would be to edit the database, adding another entry for "Beaver Springs, CO" identical in every way, except that "CO" is replaced by "Colo.".
    * This in fact can be scripted, and we can create a separate file of "alternates" that the script could check, creating a new entry for each variant.  This has the potential to make for some very big gazetteers, and hence might boost the memory requirements of [textgrounder][tg], but it seems a suitably MacGyver-style solution in the interim.
        * Update 2011-07-19: Done.  Ennis, MT now has an entry with state abbreviation "MT" and another with abbreviation "Mont".  Still [textgrounder][tg] locates the string "Ennis, Mont." in the [test page][test] in California, near Rubidoux.  And "White River National Forest" (in Colorado) is located in White River, CA.
        * I think I see part of what is going on: when there is a lot of geographic information in a relatively compact string, [textgrounder][tg] has difficulty figuring out which is the placename.  For example, an isolated reference to "Beaver Creek, Colo." now (after amplifying the gazetteer) gets correctly identified with Beaver Creek, CO and placed in Colorado (prior to amplifying, it was placed near Jackson, Mississippi).  But in the string that follows, we find "White River National Forest", and [textgrounder][tg] strips out "White River" and associates it with the entry White River, CA in the gazetteer.  That's not necessarily a solvable problem without a *much* more detailed gazetteer; but it implies that the output will always include a possibly large number of false positives.
        * As a side note, if [textgrounder][tg] at some point in the algorithm does in fact fall back on simple geographic proximity to determine geographic locations, then false positives can lead to a sort of cascading failure.  E.g. if [textgrounder][tg] first decides "White River" is in California and *then* encounters "Ennis", even if it has several possible "Ennis"es in the gazetteer, it may decide between them based on the falsely located "White River" in California.  And then other locales may be decided based on proximity to the falsely located "Ennis", etc.

[tg]: http://code.google.com/p/textgrounder/ "textgrounder wiki"
[pg]: http://www.gutenberg.org/wiki/Main_Page "Project Gutenberg homepage"
[nyt]: http://www.nytimes.com/ "New York Times"
[test]: http://travel.nationalgeographic.com/travel/hotels/2009/best-hotels-western-us/ "NatGeo test page"
[natgeo]: http://www.nationalgeographic.com/ "National Geographic"
[gs]: http://code.google.com/p/textgrounder/wiki/GettingStarted "textgrounder Getting Started guide"
[cl]: http://code.google.com/p/textgrounder/source/browse/src/main/java/opennlp/textgrounder/topo/gaz/CandidateList.java "CandidateList.java"
[gng]: http://code.google.com/p/textgrounder/source/browse/src/main/java/opennlp/textgrounder/topo/gaz/GeoNamesGazetteer.java "textgrounder file GeoNamesGazetteer.java"
[gngl]: http://code.google.com/p/textgrounder/source/browse/src/main/java/opennlp/textgrounder/topo/gaz/GeoNamesGazetteerWithList.java "textgrounder file GeoNamesGazetteerWithList.java"
[anm]: http://www.google.com/maphp?hl=en&tab=wl&q=alaska%2C%20new%20mexico "Alaska, New Mexico"