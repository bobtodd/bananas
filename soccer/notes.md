Installing IMW has been a bit of a trick.  When I do `gem install imw` within RVM, things install fine.  Butthen if I try to `require 'imw'`, I get the following: "LoadError: no such file to load -- imw/utils".

As Flip points out, a `require` statement magically finds the file you're trying to include, without you having to worry about where you are when you invoke it, or where the file is located.  Since the latest changes to IMW haven't been pushed to the public repo, we need to get Flip's own version and then make sure that Ruby uses that.  First off, we need to do `gem uninstall imw` (and `gem uninstall icss` for good measure) to start with a clean slate.  Then within a script, before the `require` statements, we need to tell Ruby to *unmagically* find the new versions:

    $LOAD_PATH
    $:.unshift("path/to/imw/lib")
    $:.unshift("path/to/icss/lib")

Then, in a shell prompt, we do the following to get the correct version of, say, ICSS:

    > git clone(icss)
    > cd
    > git checkout flip

