# amazon-rust
A docker image for compiling Rust for use with AWS Lambdas

This is an image created from the base Amazon ECS image with the Rust compiler preinstalled.
It is helpful for compiling Rust code for use in Amazon Lambda functions.

## Using this image
To use this image to build a Rust project it is preferable to add an alias to your `.bashrc`

```
alias aws_rust_build='
sudo docker run --rm -it \
-v "$(pwd)":/home/rust/src \
-v /home/luke/.cargo/git:/home/rust/.cargo/git \
-v /home/luke/.cargo/registry:/home/rust/.cargo/registry \
lukejones/amazon-rust'
```

**Note**: change `/home/luke/` to your home directory. The reason to mount the `.cargo` dirs is to stop cargo from needing to update from scratch every time the image is run.

And then run `source ~/.bashrc` to reload your env, now you can build a Rust project with;

```
aws_rust_build cargo build --release
```

or whichever cargo command you require. Compiled results will be located in `target/x86_64-unknown-linux-gnu/<release/debug>`

### Alternative to using an alias (good if you need to run under other users)

Create a bash script with the following content in the project directory;

```
#!/usr/bin/env bash
# the command to be executed in docker must be in quotes
CMD=$1
# because the script is executed using sudo the volumes to be mounted
# must be hard path
sudo docker run --rm -it \
-v "$(pwd)":/home/rust/src \
-v /home/luke/.cargo/git:/home/rust/.cargo/git \
-v /home/luke/.cargo/registry:/home/rust/.cargo/registry \
ekidd/rust-musl-builder $CMD
```

## Using static compilation + musl-libc

Another way to run Rust programs in a Lambda function is by using a docker image built for compiling Rust to the musl target - there are many of these types of images around and the method is the same;

```
alias rust-musl-build='
sudo docker run --rm -it \
-v "$(pwd)":/home/rust/src \
-v /home/luke/.cargo/git:/home/rust/.cargo/git \
-v /home/luke/.cargo/registry:/home/rust/.cargo/registry \
ekidd/rust-musl-builder'
```

This alias is using the docker image from [ekidd](https://hub.docker.com/r/ekidd/rust-musl-builder/tags/) [[github](https://github.com/emk/rust-musl-builder)].  Details about [musl here](https://www.musl-libc.org/).

## Notes

You may have issues with permissions when compiling, either with the cargo project or with a `~/.cargo/*` dir. If you do, you will need to give full create/read/write access to the directory with `chmod o+rw <directory>`. The default UID is 1000, so if your local user is the same UID there may not be any issues - otherwise another work-around could be to create a new local user named `rust` with UID = 1000 and run the alias commands under that user.
