import Fluent
import Vapor

final class UserRecipePivot: Model {
    static let schema = "user_recipe_pivot"
    
    @ID(key: "id")
    var id: UUID?
    
    @Parent(key: "user_id")
    var user: User
    
    @Parent(key: "recipe_id")
    var recipe: Recipe
    
    init() {}
        
    init(id: UUID? = nil, user: User, recipe: Recipe) throws {
        self.id = id
        self.$user.id = try user.requireID()
        self.$recipe.id = try recipe.requireID()
    }
}
