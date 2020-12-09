import Fluent
import Vapor

final class Recipe: Model, Content {
    static let schema = "recipes"
    
    //    "id": 1,
    //    "name": "柠檬戚风蛋糕",
    //    "tags": "健脑益智,保肝,动脉硬化,防癌,延年益寿,美容护肤,镇静助眠,美容养颜,益智,润肺生津,润肺止咳,降血压,抗衰老",
    //    "method": "烘焙",
    //    "imageUrl": "http://s1.st.meishij.net/r/141/154/4351141/a4351141_151783971393229.jpg",
    //    "level": "初级入门",
    //    "peopleNum": "3人份",
    //    "taste": "甜味",
    //    "prepareTime": "5分钟",
    //    "cookTime": "<60分钟",
    //    "isFeatured": true
    
    @ID(key: .id)
    var id: Int?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "method")
    var method: String;
    
    
    init() { }
    
    init(id: Int? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
