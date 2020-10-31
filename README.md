# TeardownModLoader
Unofficial mod loader for the game Teardown
This is an alpha and might break you game if you don't know what you are doing.
This is made for developers at the moment.
Use at your own risk.


## How to install

Click on Code then Download Zip.
Open you games folder where you can see the .exe
Drag and drop the data folder in the zip into your game folder.
To see if it works, hope in game. If you see a notification saying spam. 
The mod loader is working and is loading the spam mod.

## How to use(make mods)
Open modloader.lua to see how the spam mod is being loaded.
The spam.lua mod should be used as a template on how to load your custom lua scripts.
Create a new file in the `mods` folder that ends with `.lua`. 

Let's say `debug.lua`.

In your debug.lua file you should have at least 3 functions.
1. `debuginit()`
2. `debugtick()`
3. `debugdraw()`

*NOTE*: you should name them using the filename you used. could be `fastcarinit()`
Just make sure no other mod use the same function name as yours.

Open the mod loader and add at the top of the file: `using "mods/debug.lua"`

Then in the modloaderinit() add: `debuginit()`
In the modloadertick() add: `debugtick()`
In the modloaderdraw() add: `debugdraw()`

You are now free to code away any mods you want using this procedure.


