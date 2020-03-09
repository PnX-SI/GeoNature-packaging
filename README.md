# Repository to hold the code for packaging geonature, taxhub and usershub

## Running integration tests

There is a list of configuration settings you can set in settings.ini.sample. Either set them as env variables, or create a settings.ini file from settings.ini.sample: they will automatically be loaded by the tests.

Setup the environnement:

```bash
./setup_environ.sh
```

It will use a currently activated virtualenv or create one if needed, then install all dependancies.

Then run:

./manage.py --help

To get a list of available commands and:

./manage.py <command> --help

For what each commands do.


