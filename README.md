# Octo_Multi
Custom script to setup mulitple Octoprint instances on a single Pi using python virtual environment and pip to install Octoprint and the plugins.

This script was written in my spare time and presently has only been tested on Ubuntu 20.04 and Rasbian 10 and thus is only presently supporting a Debian-based or apt based package manager workflow.

This script is intended to be run only one time and for a fresh configuration, the error checking isn't phenominal so multiple executions are likely to present errors.

The script contains a block of common plugins that I use personally that you may disable or modify to suit your needs.

The clean.sh script is a quick and dirty cleanup script which will erase all configurations setup by the octoprint_multi_setup.sh script minus the removal of the python3-pip and python3-venv packages installed with apt.
