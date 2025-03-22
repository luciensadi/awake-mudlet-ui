# awake-mudlet-ui
The Mudlet UI for awakemud.com

## Installing

After creating a Mudlet profile to connect to AwakeMUD CE, do the following to add the package:

1. Download a release of this package (the `.mpackage` file) from the [releases page](https://github.com/luciensadi/awake-mudlet-ui/releases)
1. Open the **Package Manager**
   1. If present, uninstall the **generic-mapper** package. It conflicts with the one provided here.
   1. Select the `awake-ui-<version>.mpackage` file you downloaded before for installation
1. Restart Mudlet and reconnect. The UI should populate fully once you log into a character.


## Contributing

The source for this package is structured to use [muddler](https://github.com/demonnic/muddler) to package it into a Mudlet package. Using version 0.1 is necessary at this time due to some errant behavior by later Muddler versions.

You can, of course, just modify the triggers/aliases/scripts directly within Mudlet if you want to test local changes, but they'll be overwritten if you want to update to future versions of this package.

To change the source for this package, modify the JSON files and associated Lua scripts inside the `src` directory, then run `muddler` to regenerate the package. The resulting `.mpackage` file will be inside the `build` directory.

If you have Docker set up, it can be easiest to run a command like this to regenerate the package, from the root of the repository:

```
docker run --rm -it -u $(id -u):$(id -g) -v $PWD:/$PWD -w /$PWD demonnic/muddler:0.1
```

If that's a pain, just make a pull request and someone else can generate the package with your changes to make sure they work.