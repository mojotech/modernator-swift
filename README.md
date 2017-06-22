# modernator-swift

This is a Swift server-side implementation of modernator.

## Setup

Dependencies:

- Swift 3.1
- Vapor Toolbox (optional)
- Postgres database

### Dependencies

For development you need to install the project's dependencies.
It is easiest to do this using the `vapor` CLI tools: https://docs.vapor.codes/2.0/getting-started/toolbox/

However, these tools are not required, and you can use the builtin Swift
tooling to install dependencies.

#### Using Vapor Toolbox

Once the tools are installed, issue `vapor fetch` to get dependencies.

#### Using Swift Package Manager

```
swift package --enable-prefetching fetch
```

### Database

You will need to setup a postgresql database. The default database credentials
are found in [Config/postgresql.json](Config/postgresql.json).

You can easily run a postgresql database for development purposes using Docker:

```
docker run --rm -p 127.0.0.1:5432:5432 -e POSTGRES_PASSWORD=toor -e POSTGRES_DB=modernator postgres
```

### Development

If you'd like an Xcode project file, you will need the Vapor Toolbox installed.
Vapor will generate a project file using `vapor xcode`.

If your dependencies change you will need to regenerate the project file.

### Building

To build simply `swift build`, and you'll find the binary in `Build/Products/Run`.
If using Xcode, Build & Run the "Run" target.

You can override config values using arguments. The [Procfile](Procfile) has
an example of this for production.

For example, if you'd like to override the port the app serves on without
writing it to a config file:

```
Run --config:servers.default.port=$PORT
```
