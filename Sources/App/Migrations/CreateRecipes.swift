import Fluent

struct CreateRecipes: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Recipe.schema)
            .id()
            .field("recipeId", .int)
            .unique(on: "recipeId")
            .field("classid", .int)
            .field("name", .string, .required)
            .field("peoplenum", .string, .required)
            .field("preparetime", .string, .required)
            .field("cookingtime", .string, .required)
            .field("content", .string, .required)
            .field("pic", .string, .required)
            .field("tag", .string, .required)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Recipe.schema).delete()
    }
}
