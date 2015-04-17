# Polyghtgons' Lua Architecture

**Polyghtgons** was my end-of-master's project while I took my Master's Degree on Game Development at the Complutense University of Madrid.

It was a pretty interesting excercise and an awesome way of learning a big lot of stuff related to game development. From architecture to graphics, scripting, physics, AI, audio or project management, our small team had to deal with all of the areas of the game.

The team was made of three programmers, three game designers, an artist and a tutor. We are very proud of the end result, so you can check the evolution of the game [on this YouTube video](https://youtu.be/Ut2xfulNwJM "Polyghtgons Evolution on YouTube") (6m36s).

### Intent of this repository

One of the main areas I developed during the project was what we used to call the *Lua Architecture*. It included everything from C++ code to binding data for Lua, the way Lua was managed and how the communication was performed.

This repository aims to show how this architecture worked, and includes most of the key features that made the system work. However, it's not a standalone project and it can't be run in any way; it's just for explanation purposes.

So, let's get started!

## The general picture

Polyghtgons was developed in C++ for Windows systems. It started from a base project that was provided by the tutors, which contained the basic code to create a window, load some assets and get them on screen. It used a component-based game architecture, and we extended and modified this base project until the final result. After the Master's Degree ended I spent some time exploring this kind of game architectures; you can [check it in this repository!](https://github.com/MetanoKid/toy-game-architecture "Toy Game Architecture on GitHub").

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

```C++
bool CScriptManager::open() {
    _lua = lua_open();

    [...]

    // load base script
    loadScript("Polyghtgons.lua");

    return true;
}
```

The entry point of the Lua-side architecture is that `Polyghtgons.lua` file. By calling that, all the necessary Lua code is called and the system is correctly initialized. We'll get on that later.

### Class and method binding

Not all projects in the solution were required from Lua, so only some of them published their data to Lua using Luabind. This is one of the most powerful features of Luabind (like most of them!).

We decided we wanted to have each project to publish their data, so no external project knew anything about their internal classes or methods.

Two examples are included in this repository: `AI` and `Graphics`. They follow the same structure:

```C++
namespace ScriptDataPublisher {

    class CPublisher {
    public:
        static void registerData(lua_State *lua);
    };

}
```

Each one of them then publishes whatever value or method they are required to, depending on the necessities found while developing. To show an example, the infamous `Vector3` construct was published this way:

```C++
void CPublisher::registerData(lua_State *lua) {
    luabind::module(lua, "Polyghtgons")
    [
        luabind::namespace_("Classes") [
            luabind::namespace_("Graphics") [
                // Vector3 definition
                luabind::class_<Vector3>("Vector3")
                .def(luabind::constructor<float, float, float>())
                .def_readonly("x", &Vector3::x)
                .def_readonly("y", &Vector3::y)
                .def_readonly("z", &Vector3::z)
                .def("angleBetween", &Vector3::angleBetween)
                .def("cross", &Vector3::crossProduct)
                .def("dot", &Vector3::dotProduct)
                .property("normalized", &Vector3::normalisedCopy)
            ]
        ]
    ];
}
```

You can check them by navigating to their respective directories: [AI publisher](C++/DataBindingExamples/AI/ScriptDataPublisher) and [Graphics publisher](C++/DataBindingExamples/Graphics/ScriptDataPublisher).

### C++ component to communicate with Lua

Because our logic architecture was a component-based one (remember to [check this other repository for more info!](https://github.com/MetanoKid/toy-game-architecture "Toy Game Architecture on GitHub")), I was set to create a component we could add to our entities to manage the creation of the linked Lua object and its life cycle. I called it `ScriptExecutor`.

A quick look at the [ScriptExecutor.h](C++/Component/ScriptExecutor.h) file shows some methods that manage the life cycle of the component:

  - `spawn`: called when the component is being built during the level loading phase.
  - `activate`/`deactivate`: called when the entity is *activated* when a level *starts* and when an entity is *deactivated* when the level is destroyed. Entities could also be *activated*/*deactivated* during the course of a level.
  - `accept`: when a message was sent to the entity, it asks its component whether or not they accept it.
  - `process`: components that accept a message must process it.
  - `tick`: called once per frame.

This component is the main responsible of dealing with C++ <=> Lua, so let's explain it step by step.

#### Instantiation

One of the parameters present in entities defined in the level files was the `lua_constructor`. This was a string that represented the name of the Lua class to instantiate when creating the Lua-side instance for the component (i.e. `Sprout`, `Enemy`, `LightPuzzle` or `TutorialManager`).

If the Lua-side constructor was found, the pointer to the constructor was retrieved and it was called on a *protected sandbox* like so:

```C++
EXEC_PROTECTED_REACT_ON_EXCEPTION(
    _instance = constructor(infoAsLuaObject, this),
    return false
);
```

Now, two important steps were performed:

##### Method caching

We wanted to be as flexible as possible with Lua so the programmer had as less restrictions as possible when it came to add logic in Lua. Because of this, the component inspects the newly created Lua instance and caches a pointer to each important function it may call during the life cycle. These functions included `activate`, `deactivate`, `tick` and `snapshot`.

But, how to provide flexibility to answer `accept` calls by the entity when a message arrived? We decided to have functions that processed messages with the following name structure: `onMessageName`. This way, if our Lua instance was interested on knowing when a sensor perceived a signal, we would declare `onPerceived`. If we wanted to react to a Polyghtgon lighting up/turning off an entity, we would declare `onLightUp`/`onTurnOff`.

##### Instance publishing

One of the interesting functions in the Lua-side architecture is `publishInstance`. We'll get to it soon but, in a nutshell, it checks if another instance of the same name was already published in the level (it allows for duplicate checks).

#### Life cycle

After all methods were cached, the Lua-side instance was ready to live. Whenever a life cycle method was invoked on the component, it checked whether or not the Lua-side instance had a relevant method for it, and invoked it as well as a cascade.

Messaging method `accept` checked if the Lua-side instance was interested in the message (whether or not it defined an `onMessageName` function). On the other hand, `process` would create a Lua-side instance of the C++ message it received (they were published to Lua as mentioned in a previous section) and invoke the corresponding `onMessageName(message)` function.

Examples of all this section will be shown after the Lua-side architecture is explained.