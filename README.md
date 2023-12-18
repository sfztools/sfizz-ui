# sfizz

[![build actions]](https://github.com/sfztools/sfizz-ui/actions)
[![build obs]](https://build.opensuse.org/package/show/home:sfztools:sfizz:develop/sfizz)
[![Discord Badge Image]](https://discord.gg/3ArE9Mw)

AU, LV2, Pure Data and VST3 plugins using the [sfizz](https://github.com/sfztools/sfizz/) library.<br/>
Please check [our website] for more details, or [our wiki] for further information.

![Screenshot](screenshot.png)

## Using sfizz

Sfizz can be used most easily within an [LV2] host such as [Carla] or [Ardour].
It can also be integrated as a library within your own program; check out our [API] bindings for C and C++.
Our [releases] are an immediate way to get a working library and plugins for Windows and Mac.
Linux builds are available over at [OBS].
On any operating system, you might prefer to [build from source]!

## Contributing to sfizz

There is actually many things anyone can do, programming-related or music-related.
Please check out the [CONTRIBUTING] document for information about filing bug reports or feature requests,
and helping the development of sfizz

## Donating to sfizz

Sfizz and the work in the SFZ tools organization is purely driven by hobbyists
who choose to use their free time to benefit this project.
We firmly believe in the honesty and goodwill of users as a whole,
and we want to promote a healthy relationship to software and to the cost of producing quality software.

No financial returns is explicitely required from using sfizz in any shape.
However, if you feel that sfizz produces value for you or your products,
and if you find that your financial situation allows for it, we put together ways to donate to the project.
You are never compelled to do so, the [CONTRIBUTING] file contains different ways to contribute.

In all of sfizz's governance model, we strive to live in the open.
Finances are no different, and we put in place a process so that the use of donations
is as transparent as possible through our [Open Collective].
We invite you to check out the [GOVERNANCE] file to see how the organization is governed and how are donations handled.

## Dependencies and licenses

Other than some of sfizz library dependencies, the UI uses:

- [GLSL-Color-Spaces] by tobspr, licensed under the MIT license
- [stb_image] by Sean Barrett, licensed as public domain or MIT license
- [VSTGUI] by Steinberg, licensed under the BSD3 license


[CONTRIBUTING]:          CONTRIBUTING.md
[GOVERNANCE]:            GOVERNANCE.md
[LV2]:                   https://lv2plug.in/
[GLSL-Color-Spaces]:     https://github.com/tobspr/GLSL-Color-Spaces/
[stb_image]:             https://github.com/nothings/stb/
[our website]:           https://sfz.tools/sfizz/
[our wiki]:              https://sfz.tools/sfizz-wiki/
[releases]:              https://github.com/sfztools/sfizz/releases/
[Carla]:                 https://kx.studio/Applications:Carla
[Ardour]:                https://ardour.org/
[API]:                   https://sfz.tools/sfizz/api/
[Open Collective]:       https://opencollective.com/sfztools
[build from source]:     https://sfz.tools/sfizz/development/build/
[Discord Badge Image]:   https://img.shields.io/discord/587748534321807416?label=discord&logo=discord
[build actions]:         https://github.com/sfztools/sfizz-ui/actions/workflows/build.yml/badge.svg?branch=develop
[build obs]:             https://build.opensuse.org/projects/home:sfztools:sfizz:develop/packages/sfizz/badge.svg
[OBS]:                   https://software.opensuse.org//download.html?project=home%3Asfztools%3Asfizz&package=sfizz
[VSTGUI]:                https://github.com/steinbergmedia/vstgui/
