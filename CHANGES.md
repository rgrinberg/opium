# v0.18.0

* Use `dune` to generate opam files (#98, @anuragsoni)
* Use `ocamlformat` for formatting all OCaml/dune files (#99, @anuragsoni)
* Replace the `Misc` module with a combination of base + stdio (#110, @anuragsoni)
* Extract the service & filter module into a smaller `opium_core`. (#107, @anuragsoni)
* Merge `opium` and `opium_kernel`. This fixes the implementation to cohttp-lwt-unix for now. (#113, @anuragsoni)
* Switch to `yojson` from `ezjsonm`. (#114, @anuragsoni)

# v0.17.1

* Change Deferred.t to Lwt.t in readme (#91, @rymdhund)
* Remove `cow` from deps (#92, @anuragsoni)

# v0.17.0

* Switch to dune (#88, @anuragsoni)
* Keep the "/" cookie default and expose all cookie directives (#82, @actionshrimp)
* Do not assume base 64 encoding of cookies (#74, @malthe)
* Add caching capabilities to middleware (#76, @mattjbray)
