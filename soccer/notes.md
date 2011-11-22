Installing IMW has been a bit of a trick.  When I do `gem install imw` within RVM, things install fine.  Butthen if I try to `require 'imw'`, I get the following: "LoadError: no such file to load -- imw/utils".

As Flip points out, a `require` statement magically finds the file you're trying to include, without you having to worry about where you are when you invoke it, or where the file is located.  Since the latest changes to IMW haven't been pushed to the public repo, we need to get Flip's own version and then make sure that Ruby uses that.  First off, we need to do `gem uninstall imw` (and `gem uninstall icss` for good measure) to start with a clean slate.  Then within a script, before the `require` statements, we need to tell Ruby to *unmagically* find the new versions:

    $LOAD_PATH
    $:.unshift("path/to/imw/lib")
    $:.unshift("path/to/icss/lib")

Then, in a shell prompt, we do the following to get the correct version of, say, ICSS:

    > git clone(icss)
    > cd
    > git checkout flip



Okay, so I'm trying to figure out the cleanest way to do this.  In particular, I'd like to do what you can do with Python's Pip: use the package manager to install the gem, but just provide a different source location via some option parameter.  A brief search on the web shows that, surprisingly, Python's ahead of Ruby on this: `gem` doesn't seem to have that functionality.  But I did find a [guide for installing a gem from code hosted on Git][gitgem].  Following this guide, my method has looked as follows:

* `rvm gemset create chimps`
* `rvm gemset use chimps`
* `gem install gemcutter` (`gem tumble` is unnecessary: Gemcutter.org is the default)
* `gem install jeweler`
* `gem install nokogiri -- --with-xslt-dir=/usr/local/Cellar/libxslt/1.1.26` (the lengthy option due to Nokogiri weirdness, with Homebrew to the rescue)
* `git clone git://github.com/mrflip/imw.git`
* `cd imw/`
* `rake -vT` to figure out what tasks you can do (the [guide][gitgem] says to run `rake gem`, but that gives an error; looking at the output of this command, we want `rake install`)

That seems to get [IMW][imw] installed, but honestly it doesn't seem to work.

[gitgem]: http://ruby.about.com/od/advancedruby/a/gitgem.htm "Installing Gems from Git"
[imw]: https://github.com/mrflip/imw "Infinite Monkeywrench"