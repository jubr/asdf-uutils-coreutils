# asdf-uutils-coreutils

Rust [uutils/coreutils](https://github.com/uutils/coreutils) plugin for the ubiquitous [mise](https://mise.jdx.dev) and [asdf](https://github.com/asdf-vm/asdf) version managers.


## mise

Install once with:
```shell
mise plugins install --yes coreutils https://github.com/jubr/asdf-uutils-coreutils.git
```
Then in your project install with:
```shell
mise use coreutils --pin
```

Check out the [mise](https://mise.jdx.dev) readme for more detailed instructions.


## asdf

Install once with:
```shell
asdf plugin-add coreutils https://github.com/jubr/asdf-uutils-coreutils.git
```
Then in your project install with:
```shell
asdf install coreutils latest
```

Check out the [asdf](https://github.com/asdf-vm/asdf) readme for more detailed instructions.  


## Changelog

- `1.0.0` - First release. Tested on Darwin, linux + windows pending. 
