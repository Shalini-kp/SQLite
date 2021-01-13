//
//  SqliteConnection.swift
//  Sqlite
//

import UIKit
import SQLite

struct MasterDataModel {
    var entityId = String()
    var entityName = String()
    var entityType = String()
    var parentId = String()
}

class SqliteConnection: NSObject {
    static var sharedInstance = SqliteConnection()
    var db:Connection?
    
    let MasterDataTableName = Table("MasterData")
    let fileManager = FileManager.default
    
    override init() {
        //Create a DataBase at the below Path
        let path = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
            ).first!
        
        do {
            db = try Connection("\(path)/db.sqlite3")
        } catch {
            print("Error in creating connection to Database: \(error)")
        }
    }
    
    //MARK ---------------------------- Form Master Data ------------------------------------
    
    let entityId = Expression<String?>("entityId")
    let entityName = Expression<String?>("entityName")
    let entityType = Expression<String?>("entityType")
    let parentId = Expression<String?>("parentId")
    
    func createMasterDataTable()
    {
        do {
            _ = try db!.run(MasterDataTableName.create(ifNotExists: true) {
                t in
                t.column(entityId)
                t.column(entityName)
                t.column(entityType)
                t.column(parentId)
            })
        } catch {
            print("Error in creating createMasterDataTable: \(error)")
        }
    }
    
    func insertIntoMasterDataTable(_ EntityId: String,_ EntityName: String,_ EntityType: String,_ ParentId: String) -> Bool{
        
        let isExist = SqliteConnection.sharedInstance.selectFromMasterData(EntityId: EntityId)
        if isExist.entityId.isEmpty {
            do {
                let insertIntoCommand = try db!.run(MasterDataTableName.insert(entityId <- EntityId, parentId <- ParentId, entityName <- EntityName, entityType <- EntityType))
                if insertIntoCommand > 0{
                    return true
                } else {
                    return false
                }
            } catch {
                print("Error in inserting : \(error)")
                return false
            }
        } else {
            do {
                let Query = MasterDataTableName.filter(entityId == EntityId)
                let updateRowCommand = try db!.run(Query.update(entityId <- EntityId, parentId <- ParentId, entityName <- EntityName, entityType <- EntityType))
                
                if updateRowCommand > 0{
                    return true
                } else {
                    return false
                }
            } catch {
                print("Error in updating : \(error)")
                return false
            }
            // return true
        }
    }
    
    func GetMasterDataRows(sqlArray: Array<Row>) -> [MasterDataModel]{
        var dataModel = [MasterDataModel]()
        for i in sqlArray{
            var model = MasterDataModel()
            model.entityId = i[entityId]!
            model.entityName = i[entityName]!
            model.entityType = i[entityType]!
            model.parentId = i[parentId]!
            dataModel.append(model)
        }
        return dataModel
    }
    
    func selectFromMasterData(EntityId: String) -> MasterDataModel {
        let selectAllQuery = MasterDataTableName.filter(entityId == EntityId)
        do {
            let databaseRowsArray = Array(try db!.prepare(selectAllQuery))
            let databaseRows = SqliteConnection.sharedInstance.GetMasterDataRows(sqlArray: databaseRowsArray)
            
            if databaseRows.count != 0 {
                return databaseRows.first!
            }else{
                let obj = MasterDataModel()
                return obj
            }
        } catch {
            let obj = MasterDataModel()
            return obj
        }
    }
    
    func getAllData() -> [MasterDataModel] {
        do {
            let databaseRowsArray = Array(try db!.prepare(MasterDataTableName))
            let databaseRows = SqliteConnection.sharedInstance.GetMasterDataRows(sqlArray: databaseRowsArray)
            
            if databaseRows.count != 0 {
                return databaseRows
            }else{
                let obj = [MasterDataModel]()
                return obj
            }
        } catch {
            let obj = [MasterDataModel]()
            return obj
        }
    }
    
    //delete Unwanted Master Data
    func selectAllEntityId() -> [MasterDataModel] {
        let selectAllQuery = MasterDataTableName.order(entityId)
        do {
            let databaseRowsArray = Array(try db!.prepare(selectAllQuery))
            let databaseRows = SqliteConnection.sharedInstance.GetMasterDataRows(sqlArray: databaseRowsArray)
            
            return databaseRows
        } catch {
            let obj = [MasterDataModel]()
            return obj
        }
    }
    
    func deleteUnwantedMasterData(_ EntityId: [String]) {
        let isExist = SqliteConnection.sharedInstance.selectAllEntityId()
        
        var matchEntityId = [String]()
        for i in isExist {
            if !i.entityId.isEmpty {
                matchEntityId.append(i.entityId)
            }
        }
        let notMatchEntityId = matchEntityId.filter { !EntityId.contains($0) } //Compare to Array
        
        for j in notMatchEntityId {
            let Query = MasterDataTableName.filter(entityId == j)
            do {
                try db!.run(Query.delete())
            } catch {
                print("error deleting the unwanted")
            }
        }
    }
    
    func dropMasterDataTable() -> Bool {
        do {
            let deleted = try db!.run(MasterDataTableName.delete())
            if deleted > 0{
                return true
            }
            return false
        } catch {
            print("error deleting the dropMasterDataTable")
            return false
        }
    }
    
}
