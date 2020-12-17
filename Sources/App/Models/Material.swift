import Vapor
import Fluent

final class Material: Model {
    struct Public: Content {
        let mname: String
        let type: Int
        let amount: String
    }
    static let schema = "material"
    
    @ID(key: "id")
    var id: UUID?
    
    @Parent(key: "recipe_id")
    var recipe: Recipe
    
    @Field(key: "mname")
    var mname: String
    
    @Field(key: "type")
    var type: Int
    
    @Field(key: "amount")
    var amount: String
    
    init() {}
    
    init(id: UUID? = nil,
         recipeId: Recipe.IDValue,
         mname: String,
         type: Int,
         amount: String) {
        
        self.id = id
        self.$recipe.id = recipeId
        self.mname = mname
        self.type = type
        self.amount = amount
    }
}

extension Material {
    func asPublic() throws -> Public {
        Public(mname: mname, type: type, amount: amount)
    }
}
