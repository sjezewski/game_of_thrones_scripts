# Script Normalization

Run `./normalize.rb` to normalize the scripts in `/raw` and output a tarball.

## Motivation

This normalization / tokenization was a pre-processing step on the GoT data to plugin to the Tensor Flow LSTM example I built [here](https://github.com/pachyderm/pachyderm/tree/master/examples/tensor_flow)

By inserting the tokens as I did, it was easier to standardize the structure that was common to the scripts, but denoted differently across scripts.
