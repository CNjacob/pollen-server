import Fluent

struct CreateMaterial: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Material.schema)
            .id()
            .field("recipe_id", .uuid, .references("recipes", "id"))
            .field("mname", .string, .required)
            .field("type", .int, .required)
            .field("amount", .string, .required)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Material.schema).delete()
    }
}
