# steam game artwork scripts
linux scripts to automatically search for and apply a game's artworks (for non-steam games)

# how to use
with a non steam game "Game Name" already added to your steam, search for the game using the same name:
```bash
# bash
./steam_cover_downloader.sh "Game Name";
```

the script will download and use the downloaded files (using `steam_cover_setter.sh`) to update the steam artworks

restart steam and your artworks will be there

> if you dont like what the script chose automatically, just search the source site this script works on: [https://www.steamgriddb.com/](https://www.steamgriddb.com/)

if you dont trust this script then take a backup of your `shortcuts.vdf` because i lost mine while coding this 🙏🥀 (it's at `~/.steam/steam/userdata/(userid)/config/shortcuts.vdf`)

# contribution
buddy no
