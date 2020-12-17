import Vapor
import Fluent

final class Process: Model {
    struct Public: Content {
        let pcontent: String
        let pic: String
    }
    static let schema = "process"
    
    @ID(key: "id")
    var id: UUID?
    
    @Parent(key: "recipe_id")
    var recipe: Recipe
    
    @Field(key: "pcontent")
    var pcontent: String
    
    @Field(key: "pic")
    var pic: String
        
    init() {}
    
    init(id: UUID? = nil,
         recipeId: Recipe.IDValue,
         pcontent: String,
         pic: String) {
        
        self.id = id
        self.$recipe.id = recipeId
        self.pcontent = pcontent
        self.pic = pic
    }
}

extension Process {
    func asPublic() throws -> Public {
        Public(pcontent: pcontent, pic: pic)
    }
}
