# Scholarly Commons Working Group 4

An evolving playground for the work of [FORCE11 SCWG4].

See [<cite>Meeting transcripts: towards a more FAIR representation of a
scholarly meeting</cite>][requirements] for some high-level thoughts on what
this is trying to achieve from at least the standpoint of a tool for meetings.

WARNING: This repository contains an archive of all of our meetings and will
become quite large over time. Be sure to have a good Internet connection before
cloning or downloading this repository.

## Requirements and prerequisites

An effort is being made to make this site compile in a cross-platform way,
though it has been tested exclusively on Linux.

Before compiling this site, you will need to install several programs:

* `ffmpeg` compiled with `libopus` support for the `import-audio` command.
* `pandoc` for the file processing and conversions
* [Ruby], to run the [Nanoc static site generator][Nanoc] and [commands]

Then install Ruby gems:

```bash
gem install bundler # if needed
bundle install
```

## Workflows

### Agenda & meeting preparation

High-level overview of the sequential nanoc commands used to create an agenda
and prepare for a meeting:

                                               +-------------+                        +--------+
                                               | Google Docs |                        |  smtp  |
                                               +-------------+                        +--------+
                                                      ^                                    ^
       +-----------+          +------+                |                +------+            |
    +--+ agenda.md +--+   +---+ html +---+   +--------+--------+   +---+ html +---+   +----+---+
    |  +-----------+  |   |   +------+   |   |                 |   |   +------+   |   |        |
    |                 |   |              |   |                 |   |              |   |        |
    |                 |   |              |   |                 |   |              |   |        |
    |  create-agenda  +-->|   compile    +-->|  create-notes   +-->|   compile    +-->|  mail  |
    |                 |   |              |   |                 |   |              |   |        |
    |                 |   |              |   |                 |   |              |   |        |
    |                 |   |   +------+   |   |                 |   |   +------+   |   |        |
    +-----------------+   +---+ mail +---+   +-----------------+   +---+ mail +---+   +--------+
                              +------+                                 +------+


1. Create an agenda for the next meeting.

        nanoc create-agenda 'next monday at 9am'

2. When the agenda is ready, compile it into two representations, one to be
   sent as an email to the group and one to be imported into a Google Doc as a
   working agenda.

        nanoc [compile] [--verbose]

3. Generate a working agenda and meeting notes Google Doc from the html
   representation of the agenda.

        nanoc create-notes output/meetings/2018-02-13/agenda.html

4. Recompile to generate short links to the working agenda.

        nanoc [compile] [--verbose]

5. Notify group of the meeting.

        nanoc mail output/meetings/2018-02-13/agenda.mail

### Transcription

High-level overview of the sequential nanoc commands to generate a
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

The general process goes like this (of course replace these file paths with the
appropriate locations):

1. Import the audio into formats and bitrates appropriate for the Web,
   enriching with appropriate metadata.

        nanoc import-audio ~/Documents/Zoom/2017-12-18 09.02.31*/audio_only.m4a

2. Send the audio to a speech-to-text service for forced alignment and initial
   raw recognition of the audio.

        nanoc recognize-audio items/meetings/2017-12-18/audio_0.ogg

3. Generate a WebVTT file from the recognition to use as a starting point for
   the transcription.

        nanoc generate-vtt items/meetings/2017-12-18/audio_0.json

4. Manually edit the WebVTT file for accuracy, clarification, diplomacy, etc.

### Site compilation

```bash
nanoc [compile] [--verbose]
```
### Serving the site

```bash
nanoc view
```

The site should then be available at <http://localhost:3000/>.

## License

[MIT](LICENSE.txt)

[FORCE11 SCWG4]: https://www.force11.org/group/scholarly-commons-working-group/wg4enabling-technologies-and-infrastructures
[requirements]: https://docs.google.com/document/d/1Dd075OgS3siZS5zdwPrR6Wrn7zltJhUv66TXJMKTkxU/edit#
[Nanoc]: https://nanoc.ws/
[Ruby]: https://www.ruby-lang.org/
[commands]: commands/
