.. Copyright © 2018 linuor. All Rights Reserved.

##########
uGtags.vim
##########

A automation vim plugin for GNU global tag system.

********
Features
********

uGtags.vim automatically and asynchronously updates tag files,
switch cscope database. And it keep operations in vim consistent.

GNU Global and the gtags.vim plugin shipped with it are both powerful tools,
they help a lot for using tags in vim.
But the gtags.vim is lack of automation and asynchronous,
and doesn't support multi-projects very well. So uGtags.vim is created.

*****
Usage
*****

For projects have GTAGS in it already, nothing special needs to do.

For a new project, which has no GTAGS in it, just execute the ``:UGtags``
command to create tag file first.
Since uGtags.vim never do anything to projects without GTAGS in them.
And that is all the things needs to do.

Other works such as updating index, setting cscope database,
switching between projects, etc,
are all processed by uGtags.vim automatically.

uGtags.vim use gtags-cscope shipped with GNU global,
instead of the traditional cscope program, to power the ``:cs`` commands,
and the ``<C-]>`` family key strokes.

All these make operations in vim consistent.

*******
Options
*******

uGtags.vim provides the following options to tweak its beheavior:

``g:ugtags_gtags_prg``
    A string of the gtags program, used to execute.
    The default value is ``'gtags'`` .

``g:ugtags_project_root_symbolics``
    A list of symbolics used to detect the project root.
    The direcotry directly containing any symbolic in the list,
    is the project root. The default value is ``['.git']`` .

``g:ugtags_options``
    A list of additional options pass to the gtags program. Just read
    https://www.gnu.org/software/global/globaldoc_toc.html#OPTIONS-1 
    for a full list of options.

    The default value is ``[]`` , just a empty list. Another sample is::

        ['-f', '"file"', '--skip-unreadable', '"/path/to/db"']

