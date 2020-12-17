import Fluent

struct CreateProcess: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Process.schema)
            .id()
            .field("recipe_id", .uuid, .references("recipes", "id"))
            .field("pcontent", .string, .required)
            .field("pic", .string, .required)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Process.schema).delete()
    }
}
