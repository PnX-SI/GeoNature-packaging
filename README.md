# Repository to hold the code for packaging geoanture, taxhub and usershub

## Running integration tests

There is a list of configuration settings you can set in settings.ini.sample. Either set them as env variables, or create a settings.ini that will automatically be loaded by "integrations_test.sh".

Setup the environnement for testing:

```bash
./integration_tests.sh setup
```

This will install all dependancies.

Run all the tests:

```bash
./integration_tests.sh run_all
```

The tests use pytest, and if you need more control, you can run the tests manually. Run:

```bash
./integration_tests.sh manual_run
```

For instructinos.

