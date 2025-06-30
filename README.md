# Makefile / scripts to do SILO benchmarking runs

This is meant to be run via the `evobench-run` tool from
[evobench](https://github.com/GenSpectrum/evobench/).

 1. Make sure you have the Rust compiler, version 1.86.0 or later,
    installed: get it via [rustup.rs](https://rustup.rs/) (if you
    already installed the compiler earlier, but you get a message
    about async closures not being stable, then the compiler is too
    old, you can then update it via `rustup update` (or, if you want
    the oldest supported version, `rustup toolchain install 1.86.0`
    then `rustup toolchain list` then `rustup default <the name in the
    list>`)

 1. Install `evobench-run` by running:
 
        cargo install --locked https://github.com/GenSpectrum/evobench/

 1. Set up configuration for `evobench-run`, currently at
    `~/.evobench-run.ron` (todo: allow for local overrides); copy the
    included file [evobench-run.ron](evobench-run.ron) and adapt if
    necessary (other config file formats are supported, too, run
    `evobench-run config-formats` to see which, `evobench-run
    config-save` to recode an already-placed file).

 1. Get a LAPIS-SILO clone that has the evobench-probes library and
    some probes added. E.g. the `wip_evobench` branch (commit
    5ac803277ac939086467d9a4d4ee3821f3145fa0).

 1. Clone this repository inside it (will be obsolete once/if this
    repository is merged into it):

        cd LAPIS-SILO
        git clone https://github.com/GenSpectrum/silo-benchmark-runner benchmarking
        cd benchmarking

 1. Make sure that you have a folder
    `~/silo-benchmark-datasets/$BENCHMARK_DATASET_NAME` (where
    `$BENCHMARK_DATASET_NAME` is the value of the
    `BENCHMARK_DATASET_NAME` setting in [the config
    file](evobench-run.ron) that you use), with the files
    `silo_queries.ndjson`, `input_file.ndjson.zst`,
    `lineage_definitions.yaml` (or symlinks to them).

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
  
