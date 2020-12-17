import Fluent
import Vapor

final class Recipe: Model, Content {
    struct Public: Content {
        let recipeId: Int
        let classid: Int
        let name: String
        let peoplenum: String
        let preparetime: String
        let cookingtime: String
        let content: String
        let pic: String
        let tag: String
        let material: [Material.Public]
        let process: [Process.Public]
    }
    
    static let schema = "recipes"
    
    @ID(key: "id")
    var id: UUID?
    
    @Field(key: "recipeId")
    var recipeId: Int
    
    @Field(key: "classid")
    var classid: Int
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "peoplenum")
    var peoplenum: String
    
    @Field(key: "preparetime")
    var preparetime: String
    
    @Field(key: "cookingtime")
    var cookingtime: String
    
    @Field(key: "content")
    var content: String
    
    @Field(key: "pic")
    var pic: String
    
    @Field(key: "tag")
    var tag: String
    
    @Children(for: \.$recipe)
    var material: [Material]
    
    @Children(for: \.$recipe)
    var process: [Process]
        
    @Siblings(through: UserRecipePivot.self, from: \.$recipe, to: \.$user)
    public var users: [User]
    
    init() { }
    
    init(id: UUID? = nil,
         recipeId: Int,
         classid: Int,
         name: String,
         peoplenum: String,
         preparetime: String,
         cookingtime: String,
         content: String,
         pic: String,
         tag: String) {
        
        self.id = id
        self.recipeId = recipeId
        self.classid = classid
        self.name = name
        self.peoplenum = peoplenum
        self.preparetime = preparetime
        self.cookingtime = cookingtime
        self.content = content
        self.pic = pic
        self.tag = tag
    }
}

extension Recipe {
    static func create(from recipeInfo: RecipeInfo) throws -> Recipe {
        Recipe(recipeId: recipeInfo.recipeId,
               classid: recipeInfo.classid,
               name: recipeInfo.name,
               peoplenum: recipeInfo.peoplenum,
               preparetime: recipeInfo.preparetime,
               cookingtime: recipeInfo.cookingtime,
               content: recipeInfo.content,
               pic: recipeInfo.pic,
               tag: recipeInfo.tag)
    }
    
    func asPublic() throws -> Public {
        Public(recipeId: recipeId,
               classid: classid,
               name: name,
               peoplenum: peoplenum,
               preparetime: preparetime,
               cookingtime: cookingtime,
               content: content,
               pic: pic,
               tag: tag,
               material: material.map { try! $0.asPublic() },
               process: process.map { try! $0.asPublic() })
    }
    
    func createMaterial(publics: [Material.Public]) throws -> [Material] {
        var materialList: [Material] = []
        for publicMaterial in publics {
            let material = try Material(recipeId: requireID(),
                                        mname: publicMaterial.mname,
                                        type: publicMaterial.type,
                                        amount: publicMaterial.amount)
            materialList.append(material)
        }
        return materialList
    }
    
    func createProcess(publics: [Process.Public]) throws -> [Process] {
        var processList: [Process] = []
        for publicProcess in publics {
            let process = try Process(recipeId: requireID(),
                                      pcontent: publicProcess.pcontent,
                                      pic: publicProcess.pic)
            processList.append(process)
        }
        return processList
    }
        
    func loadUsers(req: Request) -> EventLoopFuture<[User.Public]> {
        self.$users.load(on: req.db)
            .flatMapThrowing {
                try self.users.map { try $0.asPublic() }
            }
    }
}
