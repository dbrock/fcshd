This package aims to remove pain points for Adobe Flex developers who
prefer to compile code from the terminal or their favorite editor:

  * It speeds up compilation by leveraging Adobe’s own Flex Compiler
    Shell (`fcsh`) and a client-server architecture: basically, you
    start the `fcshd` server, and then use the client program `fcshc`
    as a faster and more usable replacement for `mxmlc`.

  * It abstracts away the crazy command-line interface of `mxmlc` and
    gives you a simpler and more `gcc`-like interface to work with.

  * It postprocesses all compiler output, simplifies most of the
    verbose (sometimes bordering on rambling) error messages, and
    converts the stack traces into a more conventional GNU-style
    format (so that tools like Emacs can understand them).

  * It provides a rudimentary library lookup mechanism which lets you
    reference any source directory or SWC you link into `~/.fcshd-lib`
    (or `$FCSHD_LIBRARY_PATH`, if set) through the `-l` option.


It makes the easy easy:

```
$ fcshc src/foo.mxml
```

And the hard possible:

```
$ fcshc --help
Usage: fcshc MAIN.{as,mxml} [SRCDIR|SWCDIR|SWC]... [-o OUT.swf]
       fcshc SRCDIR... [SWCDIR|SWC]... -o OUT.swc
```

To compile an SWF, name the main application source file, then any
additional source directories, SWC directories, or SWC files.

To compile an SWC using `compc`, you must provide the `-o` option, and
then at least one source directory, SWC directory, or SWC file.

Dependencies can also be specified by name using the `-l LIB` option,
which will search for LIB or LIB.swc in `~/.fcshd-lib`.  Both source
directories, SWC directories, and SWC files can be named in this way.

To pass extra arguments, use e.g. `-X -include-file -X NAME -X FILE`.

```
    -o, --output OUTPUT.[swf|swc]    Name of the resulting binary
    -l, --library LIBRARY            Search LIBRARY when compiling

    -p, --production                 Leave out debugging metadata
        --no-rsls                    Do not use Flex RSLs
        --static-rsls                Use static linking for RSLs

    -3, --flex-3                     Use -compatibility-version=3
        --halo                       Use the Halo theme

    -X EXTRA-ARGUMENT                Pass through EXTRA-ARGUMENT

    -R, --restart                    Restart the compiler first
    -n, --dry-run                    Only print the compiler command
        --verbose                    Also print the compiler command

    -v, --version                    Show fcshd version
    -h, --help                       Show this message
```
