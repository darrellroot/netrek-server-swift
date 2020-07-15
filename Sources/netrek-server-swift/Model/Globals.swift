//
//  Globals.swift
//  NetrekServer
//
//  Created by Darrell Root on 5/31/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
// 

import Foundation

struct Globals {
    static let PORT = 2592
    //static let NAME_LEN = 16
    static let WARP1 = 20.0 // netrek units moved per 0.1 second at warp 1
    static let GalaxyWidth = 100000.0
}
let PACKET_SIZES: [Int: Int] =
    [0:0, // NULL
    1:84, // CP_MESSAGE 1
2:4, // CP_SPEED 2
3:4, // CP_DIRECTION 3
4:4, // CP_LASER 4
5:4, // CP_PLASMA 5
6:4, // CP_TORP 6
7:4, // CP_QUIT 7
8:52, // CP_LOGIN 8
9:4, // CP_OUTFIT 9
10:4, // CP_WAR 10
11:4, // CP_PRACTR 11
12:4, // CP_SHIELD 12
13:4, // CP_REPAIR 13
14:4, // CP_ORBIT 14
15:4, // CP_PLANLOCK 15
16:4, // CP_PLAYLOCK 16
17:4, // CP_BOMB 17
18:4, // CP_BEAM 18
19:4, // CP_CLOAK 19
20:4, // CP_DET_TORPS 20
21:4, // CP_DET_MYTORP 21
22:4, // CP_COPILOT 22
23:4, // CP_REFIT 23
24:4, // CP_TRACTOR 24
25:4, // CP_REPRESS 25
26:4, // CP_COUP 26
27:8, // CP_SOCKET 27
28:104, // CP_OPTIONS 28
29:4, // CP_BYE 29
30:4, // CP_DOCKPERM 30
31:8, // CP_UPDATES 31
32:4, // CP_RESETSTATS 32
33:36, // CP_RESERVED 33
35:8, // CP_UDP_REQ 35
36:4, // CP_SEQUENCE 36
37:100, // CP_RSA_KEY 37
38:10, //CP_PLANET 38
42:12, //CP_PING 42
43:4, //CP_S_REQ 43
44:4, //CP_SHORT_THRESHOLD
60:88, //CP_MESSAGE
]

/* TODO
 #define CP_PING_RESPONSE        42              /* client response */
 #define CP_S_MESSAGE    45              /* vari. Message Packet */
 #define CP_S_RESERVED   46
 #define CP_S_DUMMY      47
 
 */
