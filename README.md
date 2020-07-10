# netrek-server-swift

## July 2020: WARNING: Code in middle of Swift-NIO conversion and is not currently usable.

## This is a new experimental Netrek Server written in Swift!
This does not use any Apple-specific frameworks.  It is developed on MacOS but is expected to run on Linux.

### Not currently implemented: (in rough order of imprtance)

* Logic around t-mode, genocide, coup.
* Authenticating logins
* Remembering statistics between server restarts
* Rank logic
* Metaserver compatiblity / observers
* No robots (not even iggy)
* Plasma
* Special starbase operations (docking, transwarp, rank requirements, spawn limitations, orbit limitations)
* Refitting ships at homeworld
* advanced cloaking visibility (1 per second, hiding far away ships)
* hiding far away ships (PFSEEN flag?)
* UDP sockets
* Short packets
* War logic (you are always at war with other teams)
* coup
* reset stats

### Supported, but everything needs more testing:

* IPv6 (and IPv4) TCP Sockets!
* Messages
* Speed / direction
* Laser
* Torpedos
* shields
* repair
* orbit
* planet lock
* player lock
* bombing
* beaming up/down
* basic cloaking
* Detting friendly and enemy torps
* Tractor/pressor beam


