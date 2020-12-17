import Fluent

struct CreateUserRecipePivot: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(UserRecipePivot.schema)
            .id()
            .field("user_id", .uuid, .references("users", "id"))
            .field("recipe_id", .uuid, .references("recipes", "id"))
            .unique(on: "user_id", "recipe_id")
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(UserRecipePivot.schema).delete()
    }
}
