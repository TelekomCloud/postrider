# Postrider

[![Build Status](https://travis-ci.org/TelekomCloud/postrider.png)](https://travis-ci.org/TelekomCloud/postrider.png)

A web UI for The Pony Express.

# Installation

If you want to install from source, you will require:

* nodejs (v0.8, v0.10)
* bower
* grunt

Run these steps to get the UI running on `http://localhost:9000`

    npm install
    bower install
    grunt serve

Alternatively you can build this project into a client application by running

    grunt build

at the end. The application is then found in `dist/` and can be used with any webserver (e.g. Apache, Nginx) as a static site.


# Contributing

* fork this project
* add your changes in a separate branch
* add tests (have a look existing files in `test`)
* issue a pull request


# License

Company: Deutsche Telekom AG

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

