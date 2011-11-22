Installing IMW has been a bit of a trick.  When I do `gem install imw` within RVM, things install fine.  But then if I try to `require 'imw'`, I get the following: "LoadError: no such file to load -- imw/utils".

Pearls from the Master
----------------------

As Flip points out, a `require` statement magically finds the file you're trying to include, without you having to worry about where you are when you invoke it, or where the file is located.  Since the latest changes to IMW haven't been pushed to the public repo, we need to get Flip's own version and then make sure that Ruby uses that.  First off, we need to do `gem uninstall imw` (and `gem uninstall icss` for good measure) to start with a clean slate.  Then within a script, before the `require` statements, we need to tell Ruby to *unmagically* find the new versions:

    $LOAD_PATH
    $:.unshift("path/to/imw/lib")
    $:.unshift("path/to/icss/lib")

Then, in a shell prompt, we do the following to get the correct version of, say, ICSS:

    > git clone(icss)
    > cd
    > git checkout flip



The Erratic Path of the Grasshopper
-----------------------------------

Okay, so I'm trying to figure out the cleanest way to do this.  In particular, I'd like to do what you can do with Python's Pip: use the package manager to install the gem, but just provide a different source location via some option parameter.  A brief search on the web shows that, surprisingly, Python's ahead of Ruby on this: `gem` doesn't seem to have that functionality.  But I did find a [guide for installing a gem from code hosted on Git][gitgem].  Following this guide, my method has looked as follows:

* Create a clean gemset to do all this stuff: `rvm gemset create chimps`;
* ... and start using it: `rvm gemset use chimps`.
* Start installing necessary gems: `gem install gemcutter` (the `gem tumble` command is unnecessary: Gemcutter.org is the default).
* `gem install jeweler`.
* Though not strictly necessary for building and installing [ICSS][icss] and [IMW][imw], it's useful to install Nokogiri, since it's used in one of the [ICSS][icss] examples: `gem install nokogiri -- --with-xslt-dir=/usr/local/Cellar/libxslt/1.1.26` (the lengthy option due to Nokogiri weirdness, with Homebrew to the rescue... goes down smooth like a mountain stream).
* Get [**Flip's** version of IMW][imw], **not** the version in Infochimps' repo: `git clone git://github.com/mrflip/imw.git`.
* `cd imw/`.
* `rake -vT` to figure out what tasks you can do (the [guide][gitgem] says to run `rake gem`, but that gives an error; looking at the output of this command, we want `rake install`).
* Build and install the gem: `rake install`.

That seems to get [IMW][imw] installed, but honestly it doesn't seem to work.

After doing the above procedure, I then installed [ICSS][icss] via `gem install icss` (also in the same `chimps` gemset).  But upon trying to run the example script [html_selector.rb][hselect] (where is this file now?... I can't find it in the repo... ah, that's because it was in the `example/` subdirectory of either the installed [IMW][imw] or [ICSS][icss] gem in RVM, but I can't find it now), I get the following output.

    ~/.rvm/gems/ruby-1.9.2-p180@chimps/gems/imw-0.1.1/lib/imw/utils/extensions/array.rb:15:in `<class:Array>': uninitialized constant Array::ActiveSupport (NameError)
	from ~/.rvm/gems/ruby-1.9.2-p180@chimps/gems/imw-0.1.1/lib/imw/utils/extensions/array.rb:14:in `<top (required)>'
	from ~/.rvm/rubies/ruby-1.9.2-p180/lib/ruby/site_ruby/1.9.1/rubygems/custom_require.rb:36:in `require'
	from ~/.rvm/rubies/ruby-1.9.2-p180/lib/ruby/site_ruby/1.9.1/rubygems/custom_require.rb:36:in `require'
	from ~/.rvm/gems/ruby-1.9.2-p180@chimps/gems/imw-0.1.1/lib/imw/utils/extensions/core.rb:2:in `<top (required)>'
	from ~/.rvm/rubies/ruby-1.9.2-p180/lib/ruby/site_ruby/1.9.1/rubygems/custom_require.rb:36:in `require'
	from ~/.rvm/rubies/ruby-1.9.2-p180/lib/ruby/site_ruby/1.9.1/rubygems/custom_require.rb:36:in `require'
	from ~/.rvm/gems/ruby-1.9.2-p180@chimps/gems/imw-0.1.1/lib/imw/utils.rb:19:in `<top (required)>'
	from ~/.rvm/rubies/ruby-1.9.2-p180/lib/ruby/site_ruby/1.9.1/rubygems/custom_require.rb:36:in `require'
	from ~/.rvm/rubies/ruby-1.9.2-p180/lib/ruby/site_ruby/1.9.1/rubygems/custom_require.rb:36:in `require'
	from ~/.rvm/gems/ruby-1.9.2-p180@chimps/gems/imw-0.1.1/lib/imw.rb:3:in `<top (required)>'
	from ~/.rvm/rubies/ruby-1.9.2-p180/lib/ruby/site_ruby/1.9.1/rubygems/custom_require.rb:58:in `require'
	from ~/.rvm/rubies/ruby-1.9.2-p180/lib/ruby/site_ruby/1.9.1/rubygems/custom_require.rb:58:in `rescue in require'
	from ~/.rvm/rubies/ruby-1.9.2-p180/lib/ruby/site_ruby/1.9.1/rubygems/custom_require.rb:35:in `require'
	from ./html_selector.rb:6:in `<main>'

What may be happening is that `gem` installs an older version of [ICSS][icss], similar to the issue with [IMW][imw].  So we'll try following a similar procedure to the one above.

* Get rid of the current version of [ICSS][icss]: `gem uninstall icss`.
* If you're still in the `imw/` directory, `cd` out of it: `cd ..`.
* Clone the latest version of [ICSS][icss]: `git clone git://github.com/infochimps/icss.git`.
* `cd icss/`.
* Build and install: `rake install`.

The output there was

    Could not find gem 'rcov (>= 0) ruby' in any of the gem sources listed in your Gemfile.
    Run `bundle install` to install missing gems

So we'll try that:

* `bundle install`.

That gave the following:

     > bundle install
     Fetching source index for http://rubygems.org/
     Installing rake (0.9.2.2) 
     Using activesupport (3.0.11) 
     Using builder (2.1.2) 
     Using i18n (0.5.0) 
     Using activemodel (3.0.11) 
     Using bundler (1.0.21) 
     Installing diff-lcs (1.1.3) 
     Using git (1.2.5) 
     Using json (1.6.1) 
     Using gorillib (0.1.7) 
     Installing jeweler (1.5.2) 
     Installing rcov (0.9.11) with native extensions 
     Installing rspec-core (2.3.1) 
     Installing rspec-expectations (2.3.0) 
     Installing rspec-mocks (2.3.0) 
     Installing rspec (2.3.0) 
     Installing yard (0.6.8) 
     Your bundle is complete! Use `bundle show [gemname]` to see where a bundled gem is installed.
     > bundle show icss
     Could not find gem 'icss' in the current bundle.
     > bundle show rcov
     ~/.rvm/gems/ruby-1.9.2-p180@chimps/gems/rcov-0.9.11
     > rake install
     WARNING:  description and summary are identical
       Successfully built RubyGem
       Name: icss
       Version: 0.1.3
       File: icss-0.1.3.gem
     Executing "ruby -S gem install ./pkg/icss-0.1.3.gem":
     WARNING: Global access to Rake DSL methods is deprecated.  Please include
         ...  Rake::DSL into classes and modules which use the Rake DSL methods.
     WARNING: DSL method Jeweler::Commands::InstallGem#sh called at ~/.rvm/gems/ruby-1.9.2-p180@chimps/gems/jeweler-1.5.2/lib/jeweler/commands/install_gem.rb:14:in `run'
     ruby -S gem install ./pkg/icss-0.1.3.gem
     Successfully installed icss-0.1.3
     1 gem installed
     Installing ri documentation for icss-0.1.3...
     Building YARD (yri) index for icss-0.1.3...
     Installing RDoc documentation for icss-0.1.3...
     > 

Supposedly it works right.  Let's see.... (slight pause).  Nope.  If I run `irb` and type `require 'imw'`, I get the same error: 'NameError: unitialized constant Array::ActiveSupport'.  No change if I uninstall both [ICSS][icss] and [IMW][imw] and install them in the reverse order (first [ICSS][icss], then [IMW][imw]).

Interestingly, in the gemset `chimps` the command `gem list` shows that I have `activesupport (3.1.3, 3.0.11)`.  If I run `irb` and type `require 'active_support'`, it returns `nil` (this happened even before I ran `gem update activesupport`, when the only version present was `activesupport (3.0.11)`).  But in the global gemset, I have `activesupport (3.0.9)`, and typing `require 'active_support'` in `irb` returns `true`.  I'm not sure why there's the difference in behavior.

Hmmm... what to do....

Well, let's take a look at what I *have* managed to do.  Though nothing works (evidently typical for me), I have managed to *change the error message*.  At the beginning of this journey, Ruby couldn't load `imw/utils`.  That's no longer the case: it seems Ruby can find all the files it needs for [ICSS][icss] and [IMW][imw].  That's good: it suggests that the above method is a nice, clean way to use `gem` together with `git` to install the most recent version of these two packages (as should be the case, according to the [guide][gitgem]).  That means that perhaps I can avoid the *unmagical incantation* from **The Master**, which we'd need to place in the preamble of every script; instead, we should be able to confine all the shenanigans to the gem installation procedure itself.

If I understand the error messages I'm getting now, then it seems the problem has something to do with [ICSS][icss] or [IMW][imw] not playing well with ActiveSupport.  That might be a versioning issue, and so perhaps the next step is to figure out what specific version of ActiveSupport is required by the Infochimps gems.

[gitgem]: http://ruby.about.com/od/advancedruby/a/gitgem.htm "Installing Gems from Git"
[imw]: https://github.com/mrflip/imw "Infinite Monkeywrench"
[icss]: https://github.com/infochimps/icss "Infochimps Stupid Schema"
[hselect]: https://github.com/bobtodd/bananas/blob/master/soccer/html_selector.rb "html_selector.rb"