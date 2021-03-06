# Polyghtgons' Lua Architecture

![Polyghtgons](https://polyghtgons.files.wordpress.com/2014/07/polyghtgons-teaser.png)

Polyghtgons was my end-of-master's project while I took my Master's Degree on Game Development at the Complutense University of Madrid.

It was a pretty interesting excercise and an awesome way of learning a huge lot of stuff related to game development. From architecture to graphics, scripting, physics, AI, audio or project management, our small team had to deal with all of the areas of the game.

The team was made of three programmers, three game designers (one of them did the audio as well), an artist and a tutor. We are very proud of the end result, so you can check the evolution of the game during its development [on this YouTube video](https://youtu.be/Ut2xfulNwJM "Polyghtgons Evolution on YouTube") (6m36s).

### Intent of this repository

One of the main areas I developed during the project was what we used to call the *Lua Architecture*. It included everything from C++ code to bind data for Lua to the way Lua was managed and how the communication was performed.

This repository aims to show how this architecture worked, and includes most of the key features that made the system work. However, it's not a standalone project and it can't be run in any way; it's just for explanation purposes.

Although this *README* file looks more than a supersized blog entry, I chose to publish it as a repository instead so files could be included and versioning was supported.

So, let's get started!

## The general picture

Polyghtgons was developed in C++ for Windows systems. It started from a basic project that was provided by the tutors, which contained the basic code to create a window, load some assets and get them on screen. It used a component-based game architecture that we extended and modified until we got the final result. After the Master's Degree ended I spent some time exploring this kind of game architectures; you can [check it in this repository!](https://github.com/MetanoKid/toy-game-architecture "Toy Game Architecture on GitHub").

The C++ solution consisted of multiple projects: one for each area of the game. The solution tree was this one (omitting some not relevant projects):

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

When we were done building most of the necessary constructs for the engine (`Graphics`, `Physics`, `Audio`) we noticed we could use a scripting language to leverage them and make development more flexible (not to mention compile times). We decided we would need it when we were starting to build the logic for the entities in the levels.

We also noticed we could move most of the configuration to Lua as well, so tweaking values didn't mean having to compile the project again.

So, I was set to create a nice architecture to help the team develop the game.

### Enter Lua

During the Master's classes we learned how Lua worked and we were suggested to use Luabind for the task of communicating C++ and Lua. There were no restrictions about the overhead of including Boost as a dependency for Luabind, and we knew it was worth it given its power, so we did.

The general idea was:

  - Create a separate project to deal with Lua and Luabind (a wrapper with extra constructs): this project is the `ScriptManager` one mentioned before.
  - Make individual projects publish their relevant classes and functions to Lua.
  - Create a component for the component-based architecture that communicated with Lua via Luabind.
  - Create an architecture in Lua that supported all this system and leveraged the development.

## Lua architecture

Let's explore every part of the architecture more closely.

### ScriptManager

This project's main goal was the initialization of Lua and the load of the Lua-side architecture. It consisted of two different classes:

  - `CScriptManager`: the entry point of this project. It managed Lua's life cycle and included some methods to load scripts and get data from Lua to C++ (via Luabind). It also declared some macros that helped prevent crashes because of Lua exceptions and provided ways to react against said exceptions (show logs or provide default values, for example).
  - `CTranslator`: levels in Polyghtgons were defined in a JSON file which was processed using [rapidjson](https://github.com/miloyip/rapidjson "rapidjson on GitHub"). Because we wanted Lua instances to have all the data defined for an entity in a level, we had to translate JSON data into Lua objects and values.

You can check the `CScriptManager` class navigating to [ScriptManager.h](C++/ScriptManager/ScriptManager.h) and [ScriptManager.cpp](C++/ScriptManager/ScriptManager.pcp).

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

The creation of the Lua-side architecture is included in that `Polyghtgons.lua` file. This was the first part of the two-step initialization philosophy of the systems (first create, then initialize). The `loadScripts` method would load all Lua-side classes and functions. We'll get on all that later.

### Class and method binding

Not all projects in the solution were required to publish data to Lua. We decided we wanted to have each project to publish their data, so no external project knew anything about their internal classes or methods. This is one of the most powerful features of Luabind (like most of them!). 

Two examples are included in this repository: `AI` and `Graphics`. They follow the same structure:

```C++
namespace ScriptDataPublisher {

    class CPublisher {
    public:
        static void registerData(lua_State *lua);
    };

}
```

Each one of them then publishes whatever value or method they are required to, depending on the needs found while developing. To show an example, the infamous `Vector3` construct was published this way:

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

Because our logic architecture was a component-based one (remember to [check this other repository for more info!](https://github.com/MetanoKid/toy-game-architecture "Toy Game Architecture on GitHub")), I was set to create a component we could add to our entities to manage the creation of the linked Lua-side instance and its life cycle. It was called `ScriptExecutor`.

A quick look at the [ScriptExecutor.h](C++/Component/ScriptExecutor.h) file shows some methods that manage the life cycle of the component:

  - `spawn`: called when the component is being built during the level loading phase.
  - `activate`/`deactivate`: called when the entity is *activated* during level *initialization* and when an entity is *deactivated* during level *destruction*. Entities could also be *activated*/*deactivated* during the course of a level.
  - `accept`: when a message was sent to the entity, it would ask its component whether or not they accepted it.
  - `process`: components that said they accepted a message had to process it.
  - `tick`: called once per frame.

This component is the main responsible of dealing with C++ to Lua communication, so let's explain it step by step.

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

We wanted to be as flexible as possible with Lua so the programmer had the least possible restrictions when it came to adding logic. Because of this, it is the component who inspects the newly created Lua instance and caches pointers to each important function it may call during the life cycle. These functions include `activate`, `deactivate`, `tick` and `snapshot`.

But, how to provide flexibility to answer `accept` calls when a message arrived, without declaring a list of accepted messages? We decided each class would have different functions to process different messages (one for each message), and their name structure would be: `onMessageName`. This way, if our Lua instance was interested on knowing when a sensor perceived a signal, it would declare `onPerceived`. If it wanted to react to a Polyghtgon *lighting up*/*turning off*, it would declare `onLightUp`/`onTurnOff`.

##### Instance publishing

One of the interesting functions in the Lua-side architecture is `publishInstance`. In a nutshell, it checks if another instance of the same name was already published in the level (it allows for duplicate checks). Check [PublishInstance.lua](Lua/Architecture/Functions/PublishInstance.lua) for more details.

#### Life cycle

After all methods were cached, the Lua-side instance was ready to live. Whenever a life cycle method was invoked on the component, it checked whether or not the Lua-side instance had a relevant method for it, and invoked it as well (like a mere proxy).

Messaging-related method `accept` checked if the Lua-side instance was interested in the message (whether or not it defined an `onMessageName` function). On the other hand, `process` would create a Lua-side instance of the C++ message it received (they were published to Lua as mentioned in a previous section) and invoke the corresponding `onMessageName(message)` function.

This section was a bit complex, but *just show me the code!*. You can find it navigating to [ScriptExecutor.h](C++/Component/ScriptExecutor.h) and [ScriptExecutor.cpp](C++/Component/ScriptExecutor.cpp)

### Lua-side architecture

The final part of the *Lua architecture* is the Lua-side part. All previously mentioned systems were created to support this one. So, let's get it explained!

#### Namespaces

Before I worked as a professional game programmer I spent a couple of years a Front-end Developer. I worked with JavaScript and built some APIs and applications from scratch while the company worked on a new programming language: [Speech](http://speechlang.org/ "Speech website").

One of the main concerns I had when building the Lua-side architecture was not having messy and spaghetti code. Because of that, everything was part of a namespace. The namespace tree was (as defined in [Polyghtgons.lua](Lua/Architecture/Polyghtgons.lua)):

```Lua
Polyghtgons = {                 -- global namespace
    Classes = {                 -- C++ and Lua classes
        Logic = {               -- C++ Logic project classes
            Components = {},    -- C++ components
            Messages = {}       -- C++ messages
        },
        Graphics = {},          -- C++ Graphics classes
        Scripting = {},         -- Lua classes
        Utils = {}              -- C++ util functions 
    },
    Functions = {},             -- Lua functions
    Config = {},                -- Lua configuration data
    Instances = {},             -- Lua instances
    L10N = {}                   -- Localization data
};
```

#### Modules (classes, functions and data)

One of my goals was to be able to add classes, functions and configuration data transparently for the programmer. Just create a new file, drop it in the correct directory, and it is *magically* loaded into place without having to compile the project! And it can be referenced from an entity in a level right away!

To be able to support this feature, I based the development on [JavaScript's Module Pattern](http://addyosmani.com/resources/essentialjsdesignpatterns/book/#modulepatternjavascript "Addy Osmani FTW!"). Much like [Node.js' modules](https://nodejs.org/api/modules.html), Lua's `loadfile` reads a file and doesn't run it, but compiles it inside a function (with its own scope!). So, I was set for the target format!

Because we wanted to have all data into namespaces, we aimed to have each function or object mapped with a name, so they were an entry on their namespace. This way, a hypothetical `Hello, world!` module would be:

```Lua
return {
    name = "functionName",
    value = function ()
        print("Hello, world!")
    end
}
```

#### Module loading

As the second part of the two-step initialization process, the `MainLoader.lua` file is executed. The goal of this script is to load every Lua function and constructor using the `FileLoader.lua` function.

This loader function takes a directory path and loads every file it finds into a Lua object as a map of `string => function/object`. There's a special feature that I haven't mentioned yet, and is dependencies between modules. If a module doesn't return the expected pair (i.e. it returns `nil`), it is then inserted into a list of modules that couldn't be loaded because of dependencies. When the *first loading pass* is completed, dependent modules are checked again. This process is repeated for a custom number of times via `Configuration.lua` until all modules are loaded without dependency errors.

If you wish to check how they work, navigate to [MainLoader.lua](Lua/Architecture/MainLoader.lua) and [FileLoader.lua](Lua/Architecture/FileLoader.lua).

#### Configuration file

`Configuration.lua` contains all the static configuration data that allows the game to be executed using different options without having to recompile the project each time. These options include feature enabling/disabling, default language, paths to in-game levels or the frequencies to execute certain systems (like perception).

It might be interesting for you to check it out, so navigate to [Configuration.lua](Lua/Architecture/Configuration.lua).

#### Localization

Much like the configuration file, localization files are also Lua modules that define a map of `localization key => localized text`.

You can check an example navigating to [the english text file](Lua/Architecture/Localization/en_gb.lua).

#### Lua functions

Taking previous explanations into account, all modules included in the `Functions` folder would be loaded into the `Polyghtgons.Functions` namespace. As an example, this is the `GetLocalizedText.lua` module. It obtains the localized string for a given key:

```Lua
return {
    name = "localize",
    value = function (key)
        local L10N = Polyghtgons.L10N;
        local lang = Polyghtgons.Config.language or Polyghtgons.Config.cacheOnStart.language;

        if L10N and lang and L10N[lang] then
            return L10N[lang][key];
        end

        return "Key '" .. key .. "' not found for current locale '" .. lang .. "'";
    end
};
```

These functions could be invoked from both Lua and C++, so it was a powerful tool to define certain operations (please refer to [ColorAddition.lua](Lua/Architecture/Functions/ColorAddition.lua)).

I've included all function modules that existed in the game as a reference, and you can find them navigating to the [functions directory](Lua/Architecture/Functions).

#### Lua classes

We used Luabind's inheritance feature to build our architecture. Every class we had inherited from `BaseEntity`:

```Lua
class 'BaseEntity'

function BaseEntity:__init(attributes, component)
    self.component = component;
    self.entity = component.entity;
    self.level = component.entity.level;
end

return {
    name = "BaseEntity",
    value = BaseEntity
};
```

And those classes were required to have this basic structure:

```Lua
if not ParentClass then return end
class 'ChildClass' (ParentClass)

function ChildClass:__init(attributes, component)
    Polyghtgons.Classes.Scripting.ParentClass.__init(self, attributes, component);

    -- extra initialization for this class
end

-- extra functions for this class

return {
    name = "ChildClass",
    value = ChildClass
};
```

##### Examples

Just to give an insight of how the game logic was added using Lua, some modules are included in the repository.

  - `Obstacle`: every entity that had an instance of this class would remove itself from the pathfinding graph. Check it by [navigating here](Lua/Architecture/Classes/Obstacle.lua).
  - `PuzzleElement`: some of the Lua modules were related to puzzles, and they were a pretty important part of the game. They had to react to Polyghtgons' light and modify their status based on whether the right or wrong color was used. Take a look by [checking here](Lua/Architecture/Classes/PuzzleElement.lua).
  - `Lever`: an example of `PuzzleElement`. This class models a lever that can be activated by lighting it up with the correct color. When activated, it would chain this activation to another element. By checking [Lever.lua](Lua/Architecture/Classes/Lever.lua) you can also check how Lua instances communicate with C++ entities via messages or Lua instances by checking the `Polyghtgons.Instances` namespace.
  - `HeadExchanger`: this last *so-called* complex element is included so you can check it and try to guess what it does :) It's worth the try!

## Conclusion

C++ is an awesome and pretty powerful language; Lua is a pretty nice scripting language and Luabind is an awesome library! But with great power comes great responsibility: scripting languages need to be based on a structured architecture. If that's not the case, it becomes a mess pretty quick.

By keeping all of the performance-critical code in C++ and leveraging it with Lua using a flexible architecture, development can be made easier.

Explore the repository at will and thanks a lot for taking the time to read all this!