#!/usr/bin/env ruby

require '../../lib/to_yaml'

y = Y_MP.new("run_small_test", "normal", 8,
"/stornext/snfs4/next-gen/solid/bf.references/t/test/test.fa",
"/stornext/snfs1/next-gen/drio-scratch/bfast_related/bf.pipeline.data.test/plain.mp.very.small.data",
"output_id_like_test_drio",  "hsap36.1")
puts y.dump