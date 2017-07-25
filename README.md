# ABLLinkSwiftWrapper
Swift wrapper for ABLLink. Allows Swift-based programs to access the ABLLink functions.
Original repo here : https://github.com/jasonjsnell/ABLLinkSwiftWrapper

REQUIRED:

1) Make sure to include libc++.tbd 
(Find project in Targets, go to Build Phases, expand Link Binary With Libraries, click + sign, add the libc++.tbd library)

2) Get all the ABLLink files from 
ABLLink.h
ABLLinkSettingsViewController.h
ABLLinkUtils.h
libABLLink.a

These can be found here: https://github.com/Ableton/LinkKit/releases


The actual project is an exemple with the bridging header to help you.
