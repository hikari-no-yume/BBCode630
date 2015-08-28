# BBCode630: The letter-quality printing processor of tomorrow!

Yes, it's true! With BBCode630, you too can produce stunning quality documents on your Diablo 630 (or compatible) printer!

...

Okay, for those not well-versed in 1980's printing technology, this is a print processor written in Haskell. It takes in UTF-8 text with BBCode-style formatting (`[b]`<b>bold</b>`[/b]` and `[u]`<u>underline</u>`[/u]`), and produces column-wrapped plaintext with the necessary escape sequences for the Royal LetterMaster to produce good printed output when given it. The Royal LetterMaster is a 1980's budget daisy-wheel printer, whose command set is a subset of [the Diablo 630's](http://www.undocprint.org/formats/page_description_languages/diablo_630).

For the story behind why I wrote this, read my blog post series [Daisy Wheel Diaries](http://blog.ajf.me/2015-04-08-daisy-wheel-diaries-part-1).

## Setup

This is just a plain Cabal package. `cabal build` and you're done.

## Usage

Make a UTF-8 text file with the page you want to print. You can use `[b]` and `[u]` for bold and underline formatting. For the most part, only ASCII characters work, but there are some exceptions: see "Character replacements" below. Your file doesn't need to be wrapped to 80 columns, this will be done for you by the Diablo630.

Once you have your file, you can pipe it to Diablo630's standard input, and Diablo630 will produce the printer version on standard output, which you can pipe to a file.

Supply the number of columns to wrap the output to as an argument. For the LetterMaster, this is 80 (for 12cpi with a 6.6" print line width) or 66 (for 10cpi, also with a 6.6" print line width).

So, on a Unix-like system for a column width of 80:

    cat mytext.bbcode | dist/build/BBCode630/BBCode630 80 > mytext.diablo

Or, on a Windows system:

    type mytext.bbcode | dist\build\BBCode630\BBCode630 80 > mytext.diablo

Then you can send the text to your printer. Setting up the printer is beyond the scope of this README (see Daisy Wheel Diaries, part 4), but usage isn't.

On OS X, you could print like so, assuming the printer is called `Royal-LetterMaster`:

    lp -d Royal-LetterMaster mytext.diablo

On Windows this might be possible with the `lpr` command, but I haven't yet tried it.

## Character replacements

The Royal LetterMaster only supports ASCII text. However, BBCode630 will replace some UTF-8 characters with ASCII equivalents where possible, which are listed below. If a character in the document is neither ASCII nor in this list, BBCode630 will throw an error.

### LetterMaster specific

These ones will probably cause trouble on other Diablo 630-like printers.

* ¢ (**U+00A2 CENT SIGN**) - The LetterMaster has an escape sequence that allows it to print a cent sign, which the UTF-8 character will be replaced with.
* { (left curly brace) - The LetterMaster's ASCII table has ¼ where you'd expect {, so { is replaced with ( overstriked with [ and - to visually approximate a curly brace.
* } (right curly brace) - Same situation here, replaced with ) overstriked with ] and -. 
* ¼ (**U+00BC VULGAR FRACTION ONE QUARTER**) - Replaced with ASCII {, which the LetterMaster prints as a quarter sign.
* ½ (**U+00BD VULGAR FRACTION ONE HALF**) - Replaced with ASCII }, which the LetterMaster prints as a half sign.

### Generic

These are probably fine on non-LetterMaster printers.

There aren't any of these yet, but some might be added in future. What would these be? Well, we can approximate certain accented characters with overstriking, and add these as replacements. For example, we could replace è with e overstriked with \`.

