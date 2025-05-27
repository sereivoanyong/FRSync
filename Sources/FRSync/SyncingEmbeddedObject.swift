//
//  SyncingEmbeddedObject.swift
//  FRSync
//
//  Created by Sereivoan Yong on 5/25/25.
//

import Foundation
import FirebaseFirestore
import RealmSwift

public protocol SyncingEmbeddedObject: EmbeddedObject, SyncingObjectBase {
}

extension SyncingEmbeddedObject {

  public static func propertyNamesToIgnoreInValueFromDocument() -> Set<String> {
    return [_name(for: \Self.syncedAt)]
  }
}
