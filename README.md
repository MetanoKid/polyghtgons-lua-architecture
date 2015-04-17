# Polyghtgons' Lua Architecture

**Polyghtgons** was my end-of-master's project while I took my Master's Degree on Game Development at the Complutense University of Madrid.

It was a pretty interesting excercise and an awesome way of learning a big lot of stuff related to game development. From architecture to graphics, scripting, physics, AI, audio or project management, our small team had to deal with all of the areas of the game.

The team was made of three programmers, three game designers, an artist and a tutor. We are very proud of the end result, so you can check the evolution of the game [on this YouTube video](https://youtu.be/Ut2xfulNwJM "Polyghtgons Evolution on YouTube") (6m36s).

### Intent of this repository

One of the main areas I developed during the project was what we used to call the *Lua Architecture*. It included everything from C++ code to binding data for Lua, the way Lua was managed and how the communication was performed.

This repository aims to show how this architecture worked, and includes most of the key features that made the system work. However, it's not a standalone project and it can't be run in any way; it's just for explanation purposes.

So, let's get started!

## The general picture

Polyghtgons was developed in C++ for Windows systems. It started from a base project that was provided by the tutors, which contained the basic code to create a window, load some assets and get them on screen. It used a component-based game architecture, and we extended and modified this base project until the final result.

The C++ solution consisted of multiple projects: one for each area of the game. The solution tree was (omitting some not relevant projects):

    Polyghtgons
    |
    |-- AI (movement, perception)
    |-- Audio (wrapper for FMOD and custom constructs)
    |-- Game (game boot)
    |-- Graphics (wrapper for Ogre3D and custom constructs)
    |-- GUI (wrapper for CEGUI and input control)
    |-- Hexagons (logic to represent a level structure)
    |-- Logic (global logic including the component-based architecture)
    |-- Physics (wrapper for PhysX and custom constructs)
    |
    |-- Configuration (loads configuration data from Lua files)
    |-- ScriptManager (Lua's life cycle management and utils)

The last two projects (`Configuration` and `ScriptManager`) are separated because they are the reason of this repository.

### So, why Lua?

When we were done building most of the necessary constructs for the engine (`Graphics`, `Physics`, `Audio`) we noticed we could use a scripting language to leverage them and make development a bit easier (not to mention compile times). We decided we needed it when we were starting to build the logic for the entities in the levels (characters included).

We also noticed we could move most of the configuration to Lua as well, so we could just tweak values without having to compile the project.

So, I was set to create a nice architecture to help the team develop the game.

### Enter Lua

During the Master's classes we learned how Lua worked and we were instructed to use Luabind for the task of communicating C++ and Lua. There were no restrictions about the overhead of including Boost as a dependency for Luabind, and we knew it was worth it given its power, so we did.

The general idea was:

  - Create a separate project to deal with Lua and Luabind (a wrapper with extra constructs): this project is the `ScriptManager` one mentioned before.
  - Make projects publish their necessary classes and methods to Lua.
  - Create a component for the component-based architecture that communicated to Lua.
  - Create a little architecture in Lua that supported all this system and made communication as transparent as possible.

## Lua architecture

Let's explore every part of the architecture more closely.

### ScriptManager

This project's main goal was the initialization of Lua and the load of the Lua architecture. It consisted of two different classes:

  - `CScriptManager`: the entry point of this project. It managed Lua's life cycle and included some methods to load scripts and get data from Lua to C++. It also declared some macros that helped prevent crashes because of Lua exceptions and provided ways to react against said exceptions (show logs or provide default values, for example).
  - `CTranslator`: levels in Polyghtgons were defined in a JSON file which was processed using (rapidjson)[https://github.com/miloyip/rapidjson "rapidjson on GitHub"]. Because we wanted Lua instances to have all the data defined for an entity in a level, we had to translate JSON data into Lua objects and values.

You can check the `CScriptManager` class navigating to [ScriptManager.h](C++/ScriptManager/ScriptManager.h) and [ScriptManager.cpp](C++/ScriptManager/ScriptManager.cpp).

One interesting thing about the class is the method `CScriptManager::open`:

    bool CScriptManager::open() {
        _lua = lua_open();

        [...]

        // load base script
        loadScript("Polyghtgons.lua");

        return true;
    }

The entry point of the Lua-side architecture is that `Polyghtgons.lua` file. By calling that, all the necessary Lua code is called and the system is correctly initialized. We'll get on that later.