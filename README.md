# SCWG WG4

An evolving playground for the work of [FORCE11 SCWG WG4].

See [this document][requirements] for some high-level thoughts on what this is
trying to achieve from at least the standpoint of an archive of meetings.

WARNING: This repository contains an archive of all of our meetings and will
get quite large. Be sure to have a good Internet connection before cloning or
downloading this repository.

## Requirements and prerequisites

An effort is being made to make this site compile in a cross-platform way,
though it has been tested mostly on Linux.

Before compiling this site, you will need to install several programs:

* `ffmpeg` compiled with `libopus` support for the `import-audio` command.
* `pandoc` for the file processing and conversions
* Ruby, to run `nanoc` static site generator and commands

Then install Ruby gems:

```bash
gem install bundler # if needed
bundle install
```

## Workflows

### Agenda

```bash
nanoc create-agenda 'next monday at 9am'
```

### Transcription

High-level overview of the sequential nanoc commands to create a raw
transcription:

                  +-----+               +------+               +-----+
             +----| ogg +-----+   +-----| json +------+   +----| vtt +-----+
             |    +-----+     |   |     +------+      |   |    +-----+     |
             |                |   |                   |   |                |
  +------+   |                |   |                   |   |                |
  | zoom +-->|  import-audio  +-->|  recognize-audio  +-->|  generate-vtt  |
  +------+   |                |   |                   |   |                |
             |                |   |                   |   |                |
             |    +-----+     |   |                   |   |                |
             +----| mp3 +-----+   +-------------------+   +----------------+
                  +-----+

The general process goes like this (of course replace file paths with the
appropriate locations):

1. Import the audio into web formats, enriching with appropriate metadata
    ```bash
    nanoc import-audio ~/Documents/Zoom/2017-12-18 09.02.31*/audio_only.m4a
    ```
2. Send the audio to a speech-to-text service for initial transcription and
   forced alignment.
    ```bash
    nanoc recognize-audio items/meetings/2017-12-18/audio_0.ogg
    ```
3. Generate a WebVTT file to use as a starting point for the transcription
    ```bash
    nanoc generate-vtt items/meetings/2017-12-18/audio_0.json
    ```
4. Edit the WebVTT file for accuracy, clarification, diplomacy, etc.

### Site compilation

```bash
nanoc [compile] [--verbose]
```

[FORCE11 SCWG WG4]: https://www.force11.org/group/scholarly-commons-working-group/wg4enabling-technologies-and-infrastructures
[requirements]: https://docs.google.com/document/d/1Dd075OgS3siZS5zdwPrR6Wrn7zltJhUv66TXJMKTkxU/edit#
