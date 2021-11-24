# kivy_build
This repo homes a Docker image, which supports a developer to build Kivy Android apps using buildozer and pre-fetched SDK, NDK and files to optimize download of resources.

* [GitHub](https://github.com/The-Judge/docker-kivy_build/)
* [Docker Hub](https://hub.docker.com/repository/docker/derjudge/kivy_apk_build/)

# Start the build container

    docker run -it --rm --name any_name \
      -v /path/to/project/root:/app local/python_kivy /bin/bash -l

## Build an APK (inside the build container)

    # If building for testing
    ~/build.sh

    # If building for Store release
    ~/build.sh release
