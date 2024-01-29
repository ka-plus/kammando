# K&A+ Kammando

[![CircleCI](https://dl.circleci.com/status-badge/img/gh/ka-plus/kammando/tree/main.svg?style=shield)](https://dl.circleci.com/status-badge/redirect/gh/ka-plus/kammando/tree/main)

## Purpose

This is an example C64/KickAssembler project for K&A+ series of articles: "How to write an own game."
In this example project I have used several assets from Video Game Commando for C64 platform released by Elite/Capcom in 1985:

* Background graphics by Rory Green, Chris Harvey
* Soundtrack by Rob Hubbard

Graphics has been taken from CTM file attached as an example from Charpad Pro.
Music file (SID) has been downloaded from HVSC.


## How to build

You need Java 15 or higher. Go to the root of this project and type:

`gradlew build`

Your project will be built and you can run the executable `kammando.prg` via i.e. Vice.