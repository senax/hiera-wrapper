Introduction
============

Hiera is a configuration data store with pluggable back ends; hiera-wrapper is a backend written to allow filters to be applied for requests to backends. Hiera normally performs lookups in each of the backends for each query. With modern classes having quite a few optional parameters, the number of lookups for a catalogue compilaton can grow quite large.

Our use case for this backend is that we use ENC-like database which is quite slow to access and should only contain puppet-role and a few other parameters such as server location, puppet-environment, etc.

By applying a simple whitelist on the database backend, catalogue compilation times dropped from 60 to 10 seconds.

Configuration
=============

See below; specify the wrapper backend in the ':backends:' section. Create a new section ':wrapper:' like below. Each of the elements of the ':backends:' hash is loaded as a backend and optional blacklist and whitelists are applied.

Blacklists are applied first; if the lookup key matches any of the elements on the blacklist (regexp) then the query to that backend is considered not to have returned a value.

If a whitelist exists then the lookup key must match one of the regexp in order to be passed on to that backend.

It probably makes more sense once you play with it a little ;)

<pre>
---
:backends:
  - wrapper

:logger: console

:hierarchy:
  - "%{location}"
  - "%{environment}"
  - common

:wrapper:
  :backends:
  - :yaml:
      :blacklist:
        - bl
      :whitelist:
        - ^wl$
        - black_and_white
  - :json:

:json:
  :datadir: test/etc/hieradb
:yaml:
  :datadir: test/etc/hieradb
</pre>

Examples
========
<pre>
$ hiera -c hiera.yaml.example black_and_white
nil
$ hiera -c hiera.yaml.example wl
should_be_allowed
$ hiera -c hiera.yaml.example bl
nil
$ hiera -c hiera.yaml.example json_and_yaml
json_and_yaml_json_value
</pre>

<pre>$ cat test/etc/hieradb/common.yaml
---
yaml_only: yaml_only_value
json_and_yaml: json_and_yaml_yaml_value
bl: should_be_blocked
wl: should_be_allowed
black_and_white: should_be_blocked
</pre>

<pre>cat test/etc/hieradb/common.json
{
  "json_only": "json_only_value",
  "json_and_yaml": "json_and_yaml_json_value"
}
</pre>

Contact
=======

* Author: Frank Ederveen
* Email: frank@crystalconsulting.eu

License
=======

This software is provided "as is". It works for me but it will probably eat your homework and set you house on fire.
Do whatever you want to do with it but do not come complaining to me.


