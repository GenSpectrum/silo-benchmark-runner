# Makefile / scripts to do SILO benchmarking runs

 1. Clone this repository inside LAPIS-SILO:

        cd LAPIS-SILO
        git clone https://github.com/GenSpectrum/silo-benchmark-runner/
        cd silo-benchmark-runner/

 2. Make sure you have the input files `silo_queries.ndjson`,
    `input_file.ndjson.zst`, `open_lineage_definitions.yaml` or
    symlinks to them.

    XX currently: get the files and reconstruct those symlinks here:

        ssh gs-staging-1
        ls -lrt ~christian/LAPIS-SILO/subdir-realdata | grep ' -> '

 3. Then, still from `silo-benchmark-runner/`, run:

        BENCH=1 SORTED=0 RANDOMIZED=1 make bench

    or

        BENCH=1 SORTED=1 RANDOMIZED=1 make bench

    Then keep the (`*.xlsx` and) `*-bench.log.zstd` files (you can
    always reconstruct the xlsx files by running the
    evobench-evaluator on the latter files again).

## TODO

  * add LAPIS-SILO commit id, and host name, to the output key (and
    use subdirs, for length reasons?)

  * have 2 folder hierarchies for small and large data set, add wrapper
    script that passes the right variables to make

  * get input files from and store log files to S3
  
