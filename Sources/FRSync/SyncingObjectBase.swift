//
//  SyncingObjectBase.swift
//  FRSync
//
//  Created by Sereivoan Yong on 5/23/25.
//

import Foundation
import FirebaseFirestore
import RealmSwift

public protocol SyncingObjectBase: ObjectBase {

  subscript(key: String) -> Any? { get set }

  /// This is nil when the object is locally created and cloud synchronization is pending.
  var syncedAt: Date? { get set }

  /// Object-generated Firestore document from will ignore these properties
  static func propertyNamesToIgnoreInDocumentData() -> Set<String>

  /// Value from Firestore document will ignore these properties
  static func propertyNamesToIgnoreInValueFromDocument() -> Set<String>

  /// Returns value converted from Firestore document used to create the object.
  /// Used to pass in `realm.create(_:value:update:)` and `Object(value:)`
  static func value(documentData: Any, syncedAt: Date) -> [String: Any]
}

extension SyncingObjectBase {

  public static func propertyNamesToIgnoreInDocumentData() -> Set<String> {
    return []
  }

  /// Returns generated document data used to create document for Firestore. This ignores properties whose name is in `propertyNamesToIgnoreInDocumentData()`
  /// See supported data type: https://firebase.google.com/docs/firestore/manage-data/data-types
  public func documentData() -> [String: Any] {
    var documentData: [String: Any] = [:]
    let properties = Self._getProperties() ?? []
    let propertyNamesToIgnoreInDocumentData = Self.propertyNamesToIgnoreInDocumentData()
    for property in properties where !propertyNamesToIgnoreInDocumentData.contains(property.name) {
      guard let value = self[property.name] else { continue }
      if property.isCollection {
        if property.isArray || property.isSet {
          var documentDataCollection: [Any] = [] // Only array is supported in Firestore
          let collection = value as! any RealmCollection
          for element in collection {
            let documentDataElement = _documentDataValue(element, for: property)
            documentDataCollection.append(documentDataElement)
          }
          if property.type == .double && property.name == "coordinates" {
            documentData[property.name] = FirebaseFirestore.GeoPoint(latitude: documentDataCollection[1] as! Double, longitude: documentDataCollection[0] as! Double)
          } else {
            documentData[property.name] = documentDataCollection
          }

        } else if property.isDictionary {
          assert(property.dictionaryKeyType == .string)
          var documentDataDictionary: [String: Any] = [:]
          let collection = value as! any RealmKeyedCollection
          for (key, element) in collection {
            let key = key as! String
            let documentDataElement = _documentDataValue(element, for: property)
            documentDataDictionary[key] = documentDataElement
          }
          documentData[property.name] = documentDataDictionary

        } else {
          fatalError()
        }
      } else {
        documentData[property.name] = _documentDataValue(value, for: property)
      }
    }
    return documentData
  }

  public static func propertyNamesToIgnoreInValueFromDocument() -> Set<String> {
    return []
  }

  /// Returns value converted from Firestore document used to create the object.
  /// Used to pass in `realm.create(_:value:update:)` and `Object(value:)`
  public static func value(documentData: Any, syncedAt: Date) -> [String: Any] {
    let documentData = documentData as! [String: Any]
    var value: [String: Any] = [:]
    let properties = _getProperties() ?? []
    let propertyNamesToIgnoreInValueFromDocument = propertyNamesToIgnoreInValueFromDocument()
    for property in properties where !propertyNamesToIgnoreInValueFromDocument.contains(property.name) {
      guard let documentDataValue = documentData[property.name] else { continue }
      if property.isCollection {
        if property.isArray || property.isSet {
          var propertyCollection: [Any] = []
          if property.type == .double && property.name == "coordinates" {
            let geoPoint = documentDataValue as! FirebaseFirestore.GeoPoint
            propertyCollection.append(geoPoint.longitude)
            propertyCollection.append(geoPoint.latitude)
          } else {
            let documentDataCollection = documentDataValue as! [Any]
            for documentDataValue in documentDataCollection {
              let propertyValue = _propertyValue(documentDataValue, syncedAt: syncedAt, for: property)
              propertyCollection.append(propertyValue)
            }
          }
          value[property.name] = propertyCollection

        } else if property.isDictionary {
          let documentDataDictionary = documentDataValue as! [String: Any]
          var propertyDictionary: [String: Any] = [:]
          for (key, documentDataValue) in documentDataDictionary {
            let propertyValue = _propertyValue(documentDataValue, syncedAt: syncedAt, for: property)
            propertyDictionary[key] = propertyValue
          }
          value[property.name] = propertyDictionary

        } else {
          fatalError()
        }
      } else {
        value[property.name] = _propertyValue(documentDataValue, syncedAt: syncedAt, for: property)
      }
    }
    value[_name(for: \Self.syncedAt)] = syncedAt
    return value
  }
}

private func _documentDataValue(_ propertyValue: Any, for property: Property) -> Any {
  switch property.type {
  case .int:
    return propertyValue as! Int
  case .bool:
    return propertyValue as! Bool
  case .float:
    return propertyValue as! Float
  case .double:
    return propertyValue as! Double
  case .UUID:
    return (propertyValue as! UUID).uuidString
  case .string:
    return propertyValue as! String
  case .data:
    return propertyValue as! Data
  case .any:
    fatalError()
  case .date:
    return Timestamp(date: propertyValue as! Date)
  case .objectId:
    return (propertyValue as! ObjectId).stringValue
  case .decimal128:
    return (propertyValue as! Decimal128).decimalValue as NSDecimalNumber
  case .object:
    assert(!property.isCollection)
    let objectClass = Schema.class(for: property.objectClassName!) as! ObjectBase.Type
    if objectClass.isEmbedded() {
      let object = propertyValue as! any SyncingObjectBase
      return object.documentData()
    } else {
      fatalError("Add as subcollection instead")
    }
  case .linkingObjects:
    fatalError()
  }
}

private func _propertyValue(_ documentDataValue: Any, syncedAt: Date, for property: Property) -> Any {
  switch property.type {
  case .int:
    return documentDataValue as! Int
  case .bool:
    return documentDataValue as! Bool
  case .float:
    return documentDataValue as! Float
  case .double:
    return documentDataValue as! Double
  case .UUID:
    return UUID(uuidString: documentDataValue as! String)!
  case .string:
    return documentDataValue as! String
  case .data:
    return documentDataValue as! Data
  case .any:
    fatalError()
  case .date:
    return (documentDataValue as! Timestamp).dateValue()
  case .objectId:
    return try! ObjectId(string: documentDataValue as! String)
  case .decimal128:
    return Decimal128(value: documentDataValue as! NSNumber)
  case .object:
    assert(!property.isCollection)
    let objectClass = Schema.class(for: property.objectClassName!) as! ObjectBase.Type
    if objectClass.isEmbedded() {
      let objectClass = objectClass as! any SyncingEmbeddedObject.Type
      return objectClass.value(documentData: documentDataValue, syncedAt: syncedAt)
    } else {
      fatalError("Add as subcollection instead")
    }
  case .linkingObjects:
    fatalError()
  }
}
