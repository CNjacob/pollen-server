import Fluent
import FluentMySQLDriver
import Leaf
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(
        .mysql(
            hostname: Environment.get("DATABASE_HOST") ?? "49.235.92.195"/*"127.0.0.1""149.28.88.195"*/,
            port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? MySQLConfiguration.ianaPortNumber,
            username: Environment.get("DATABASE_USERNAME") ?? "jacob"/*"root"*/,
            password: Environment.get("DATABASE_PASSWORD") ?? "Jacob@921121",
            database: Environment.get("DATABASE_NAME") ?? "pollen_db",
            tlsConfiguration: .forClient(
                certificateVerification: .none
            )
        ),
        as: .mysql)

    app.migrations.add(CreateUsers())
    app.migrations.add(CreateTokens())

    app.views.use(.leaf)

    try app.autoMigrate().wait()

    // register routes
    try routes(app)
}
