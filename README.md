# netrek-server-swift

### I am running an operational "Empire Mode" Swift Netrek server at netrek.networkmom.net (IPv4 + IPv6)
Playing via IPv6 requires an IPv6-capable client, such as my MacOS or iOS clients available for free in the Apple AppStore.

Full game: Thursday 7/30 6PM Pacific.

## This is a new _alpha_ Netrek Server written in Swift!
This does not use any Apple-specific frameworks.  It is developed on MacOS and runs on Linux.

## It supports IPv4 and IPv6!  If you run an IPv6-capable Netrek client (such as the MacOS-Swift or iOS-Swift client), you can play Netrek over IPv6!

# How to build / run:
* git clone https://github.com/darrellroot/netrek-server-swift.git
* cd netrek-server-swift
* swift build
* ./.build/x86_64-unknown-linux-gnu/debug/netrek-server-swift
** See --help for options, such as registering with the metaserver

(alternatively, you can build and run in Xcode on a mac)

## It supports Bronco mode with a command-line-option

## It supports a new Empire mode by default:

* 28-32 total players (starting with 28 robots)
* Four active teams
* Each player is assigned a homeworld randomly
* Each time you spawn, you join the team that owns your homeworld
* As teams gain planets, they gain ships
* Your team wins when you control 75% of the galaxy

### Not currently implemented:

* Robots do not bomb or planet take
* Launching robots when attacking 3rd party planets
* Observers
* Special starbase operations (docking, transwarp, rank requirements, spawn limitations, orbit limitations)
* advanced cloaking visibility (1 per second, hiding far away ships)
* hiding far away ships (PFSEEN flag?)
* UDP sockets
* Short packets
* Coups
* War logic (you are always at war with other teams)

### Supported, but everything needs more testing:

* IPv6 (and IPv4) TCP Sockets!
* Rank logic
* Messages
* Speed / direction
* Laser
* Plasma
* Torpedos
* Refitting ships at homeworld
* Metaserver submissions
* shields
* Remembering statistics between server restarts
* repair
* orbit
* Robots dogfight
* planet lock
* player lock
* bombing
* beaming up/down
* basic cloaking
* Detting friendly and enemy torps
* Tractor/pressor beam
* Logic around t-mode and genocide.
