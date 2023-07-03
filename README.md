# What

Fallout dialogs automatically parsed by simple scripts (no neural networks or manual adjustment).

Check `generated` for files for offline or other use (I don't own content itself but whatever is generated outside of it is WTFPL).

# But

Only obvious connections that do not depend on any random or other calculations are made.
So some information is lost and fuller extraction is possible with more demanding tools like GPT for example.
Technically popups with code could provide some hint about such lost information but it looks like they are more useful to see conditional logics behind the scenes.

I didn't check the data too much so feel free to create an issue in case of issues.

# How

If you want to have this generated for specific version/translation then here are the steps:

NOTE: some rake commands should work in specific directories in `generated/` if they are prefixed like this `WHICH=en-f2-gog rake output` but this is later addition and is not very tested.

1. have ruby installed
1. have graphviz installed
1. run `bundle` here nearby to install dependencies (may need install bundler by `gem install bundler` before)
1. find `master.dat` among your Fallout files
1. extract all files from `master.dat` somewhere (I used Windows, DatExplorer for FO2 and undat for FO1, these should be downloadable from nma and/or teamx.ru, also some tools may error unless things are placed shalowly like c:/FO2)
1. decompile `scripts/*.int` into `.ssl` files using some other tools (I used Windows and `int2ssl`)
1. put resulting `.ssl` and `dialogs/*.MSG` files (from `text/english/dialog`) into the `input/` directory here nearby
1. run `rake -T` to see the menu of possible commands (I tested stuff from this step forward on linux)
1. (this command moves files inside input directory) run `rake segregate` to see result like this
   
   > Moved 970 irrelevant files
   > Moved 50 .ssl files with missing .msg file
   > Moved 50 .msg files with missing .ssl file
   > Moved 3 pairs of files because .ssl file is empty or unconforming
   > Moved 1 pairs of files because .ssl file is empty
   > Remaining are 400 pairs of files for visualization

1. run `rake messages_yml` (in rare instances there is encoding problem inside the file, opening it with vim and saving back was enough to fix it for me)
   (during these parsing steps it may fail to parse some code and then fixing it by hand may be needed like adding "end" where procedures have "begin" but lack "end")
1. run `rake codes_yml`, it parses scripts
   (if it tells that error is at some line then the line 1 is assumed to be the line before the first "begin")
1. run `rake nodes_yml`, it collects from yml files info about connections between nodes and messages that is on the surface (it is not exhaustive)
1. run `rake viz`, this generates mainly svg diagrams (slowest command but it should not fail if graphviz is installed and is available)
1. run `rake output`, this generates the website to explore diagrams
1. run `rake preview`, to optionally explore what was generated locally at (http://localhost:3000)

# Also

- I may try it on other mods as well at some point (Nevada, Sonora, ...).
- Also sometimes there is warning saying "ids collision" when it comes to messages parsing and maybe it looses some information there
- Possibly sorting svgs by size is the way to select most informative ones, also showing number of nodes and connections near the name could be of use
- I used Fixed Editions for Russian F1,F2 and older generated English F1 is possibly GOG
- I got same content for F2 GOG and Restoration Project, probably there is no error

- [x] added node names to code
- [ ] to have html files as independent as svgs (remove jq,underscore dependencies)
- [ ] do I need code popup being paused and scrollable?
