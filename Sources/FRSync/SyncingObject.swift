//
//  SyncingObject.swift
//  FRSync
//
//  Created by Sereivoan Yong on 5/25/25.
//

import Foundation
import FirebaseFirestore
import RealmSwift

public protocol SyncingObject: Object, SyncingObjectBase, Identifiable {

  var id: String { get }
}

extension SyncingObject {

  public static func propertyNamesToIgnoreInDocumentData() -> Set<String> {
    return ["id"]
  }

  public static func propertyNamesToIgnoreInValueFromDocument() -> Set<String> {
    return ["id", _name(for: \Self.syncedAt)]
  }

  public static func value(documentId: String, documentData: [String: Any]) -> [String: Any] {
    var value = value(documentData: documentData, syncedAt: Date())
    value["id"] = documentId
    return value
  }
}
