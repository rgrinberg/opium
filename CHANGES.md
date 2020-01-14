# 0.18.0

* Make examples easier to find and add documentation related to features used in them. (#125, @shonfeder)
* Allow overriding 404 handlers (#127, @anuragsoni)
* Support cohttp streaming response (#135, #137, #139, @anuragsoni)

# v0.17.1

* Change Deferred.t to Lwt.t in readme (#91, @rymdhund)
* Remove `cow` from deps (#92, @anuragsoni)

# v0.17.0

* Switch to dune (#88, @anuragsoni)
* Keep the "/" cookie default and expose all cookie directives (#82, @actionshrimp)
* Do not assume base 64 encoding of cookies (#74, @malthe)
* Add caching capabilities to middleware (#76, @mattjbray)
