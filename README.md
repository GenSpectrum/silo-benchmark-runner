# Makefile / scripts to do SILO benchmarking runs

 1. Make sure you have a Rust compiler installed (and a more recent
    one than the one from Debian stable): get it from
    [rustup.rs](https://rustup.rs/)

 1. Get a LAPIS-SILO clone that has the evobench-probes library and
    some probes added. E.g. the `wip_evobench` branch (commit
    5ac803277ac939086467d9a4d4ee3821f3145fa0).

 1. Clone this repository inside it:

        cd LAPIS-SILO
        git clone https://github.com/GenSpectrum/silo-benchmark-runner/
        cd silo-benchmark-runner/

 1. Make sure that you have the input files `silo_queries.ndjson`,
    `input_file.ndjson.zst`, `open_lineage_definitions.yaml`, or
    symlinks to them.

    XX currently: get these files from gs-staging-1, or when running
    there, reconstruct those symlinks here:

        ssh gs-staging-1
        ls -lrt ~christian/LAPIS-SILO/subdir-realdata | grep ' -> '

 1. Then, still from `silo-benchmark-runner/`, run:

        BENCH=1 SORTED=0 RANDOMIZED=1 make bench

    or

        BENCH=1 SORTED=1 RANDOMIZED=1 make bench

    Then find the output files in `benchmark-output-files/`.

## TODO

PS.: These will now be done in the `evobench-run` tool in
[evobench](https://github.com/GenSpectrum/evobench/)

  * add host name to the output key (and use subdirs, for length
    reasons?)

  * have 2 folder hierarchies for small and large data set, add wrapper
    script that passes the right variables to make

  * get input files from and store log files to S3
  
