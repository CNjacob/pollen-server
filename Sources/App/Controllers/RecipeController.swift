import Vapor
import Fluent

struct FavoritedRecipe: Content {
    let recipeId: String
}

struct RecipeCreate: Content {
    let recipe: String
}

struct RecipeInfo: Content {
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

struct RecipeExists: Content {
    let isExists: Int
}

struct RecipeController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let recipesRoute = routes.grouped("recipes")
        
        recipesRoute.post("exists", use: recipeIsExists)
        
        recipesRoute.get("favoriters", use: favoriters)
        
        recipesRoute.post("create", use: create)
                
//        recipesRoute.get("info", use: getRecipeInfo)
        let tokenProtected = recipesRoute.grouped(Token.authenticator())
        tokenProtected.post("favorited", use: favorited)
        tokenProtected.post("cancel_favorited", use: cancelFavorited)
    }
        
    private func loadUserRecipe(_ user: User, req: Request) -> EventLoopFuture<[Recipe.Public]> {
        return user.$recipes.query(on: req.db)
            .with(\.$material)
            .with(\.$process)
            .with(\.$users)
            .all()
            .flatMapThrowing { recipes in
                try recipes.map { try $0.asPublic() }
            }
    }
    
    private func queryUser(_ username: String, req: Request) -> EventLoopFuture<User?> {
        User.query(on: req.db)
            .filter(\.$username == username)
            .with(\.$recipes)
            .first()
    }
    
    private func queryRecipe(_ recipeId: Int, req: Request) -> EventLoopFuture<Recipe?> {
        Recipe.query(on: req.db)
            .filter(\.$recipeId == recipeId)
            .with(\.$material)
            .with(\.$process)
            .with(\.$users)
            .first()
    }
    
    private func checkIfRecipeExists(_ recipeId: Int, req: Request) -> EventLoopFuture<Bool> {
        Recipe.query(on: req.db)
            .filter(\.$recipeId == recipeId)
            .first()
            .map { $0 != nil }
    }
}

extension RecipeController {
    fileprivate func recipeIsExists(req: Request) throws -> EventLoopFuture<RecipeExists> {
        let favoritedRecipe = try req.content.decode(FavoritedRecipe.self)
        guard
            let recipeId = Int(favoritedRecipe.recipeId) else {
            throw Abort(.badRequest)
        }
        
        return checkIfRecipeExists(recipeId, req: req)
            .flatMap { exists in
                return req.eventLoop.makeSucceededFuture(RecipeExists(isExists: (exists ? 1 : 0)))
            }
    }
}

extension RecipeController {
    fileprivate func favoriters(req: Request) throws -> EventLoopFuture<[User.Public]> {
        let favoritedRecipe = try req.content.decode(FavoritedRecipe.self)
        guard
            let recipeId = Int(favoritedRecipe.recipeId) else {
            throw Abort(.badRequest)
        }
        
        return queryRecipe(recipeId, req: req)
            .unwrap(or: Abort(.notFound))
            .flatMap { recipe in
                recipe.loadUsers(req: req)
            }
    }
}

extension RecipeController {
    fileprivate func create(req: Request) throws -> EventLoopFuture<Recipe.Public> {
        let recipeCreate = try req.content.decode(RecipeCreate.self)
        
        let recipeInfo = try JSONDecoder().decode(RecipeInfo.self, from: recipeCreate.recipe.data(using: .utf8)!)
        
        let recipe = try Recipe.create(from: recipeInfo)
        var material: [Material]!
        var process: [Process]!
        
        return checkIfRecipeExists(recipe.recipeId, req: req).flatMap { exists in
            guard !exists else {
                return req.eventLoop.future(error: Abort(.internalServerError))
            }
            
            // save recipe
            return recipe.save(on: req.db)
        }
        .flatMap {
            guard let newMaterial = try? recipe.createMaterial(publics: recipeInfo.material) else {
                return req.eventLoop.future(error: Abort(.internalServerError))
            }
            material = newMaterial
            return recipe.$material.create(material, on: req.db)
        }
        .flatMap {
            guard let newProcess = try? recipe.createProcess(publics: recipeInfo.process) else {
                return req.eventLoop.future(error: Abort(.internalServerError))
            }
            process = newProcess
            return recipe.$process.create(process, on: req.db)
        }
        .flatMap {
            recipe.$material.load(on: req.db)
        }
        .flatMap {
            recipe.$process.load(on: req.db)
        }
        .flatMapThrowing {
            try recipe.asPublic()
        }
    }
}

extension RecipeController {
    fileprivate func favorited(req: Request) throws -> EventLoopFuture<[Recipe.Public]> {
        try self.favoritAction(req: req, isCancel: false)
    }
    
    fileprivate func cancelFavorited(req: Request) throws -> EventLoopFuture<[Recipe.Public]> {
        try self.favoritAction(req: req, isCancel: true)
    }
    
    fileprivate func favoritAction(req: Request, isCancel: Bool) throws -> EventLoopFuture<[Recipe.Public]> {
        let tokenUser = try req.auth.require(User.self)
        
        let favoritedRecipe = try req.content.decode(FavoritedRecipe.self)
        guard
            let recipeId = Int(favoritedRecipe.recipeId) else {
            throw Abort(.badRequest)
        }
        
        var user: User!
        
        return queryUser(tokenUser.username, req: req)
            .unwrap(or: Abort(.notFound))
            .flatMap { exUser -> EventLoopFuture<Recipe?> in
                user = exUser
                return queryRecipe(recipeId, req: req)
            }
            .unwrap(or: Abort(.notFound))
            .flatMap { recipe in
                if user.recipes.contains(where: { $0.recipeId == recipeId }) {
                    guard !isCancel else {
                        // cancel favorit
                        return self.removeFavoritedRecipe(recipe: recipe, to: user, req: req)
                    }
                    
                    // favorit, but the recipe is favorited
                    return loadUserRecipe(user, req: req)
                }
                
                // cancel favorit, but not favorited the recipe
                guard !isCancel else {
                    return loadUserRecipe(user, req: req)
                }
                
                // favorit
                return self.addFavoritedRecipe(recipe: recipe, to: user, req: req)
            }
    }
    
    private func addFavoritedRecipe(recipe: Recipe, to user: User, req: Request) -> EventLoopFuture<[Recipe.Public]> {
        user.$recipes.attach(recipe, on:req.db)
            .flatMap {
                user.save(on: req.db)
            }
            .flatMap {
                loadUserRecipe(user, req: req)
            }
    }
    
    private func removeFavoritedRecipe(recipe: Recipe, to user: User, req: Request) -> EventLoopFuture<[Recipe.Public]> {
        user.$recipes.detach(recipe, on: req.db)
            .flatMap {
                user.save(on: req.db)
            }
            .flatMap {
                loadUserRecipe(user, req: req)
            }
    }
}
