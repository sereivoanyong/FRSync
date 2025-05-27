//
//  DeletableSyncingObject.swift
//  FRSync
//
//  Created by Sereivoan Yong on 5/24/25.
//

import Foundation
import FirebaseFirestore
import RealmSwift

public protocol DeletableSyncingObject: SyncingObject {

  /// This is non-nil when the object is locally deleted and synchronization is pending.
  var deletedAt: Date? { get set }

  var syncedAtBeforeDeletion: Date? { get set }
}

extension DeletableSyncingObject {

  public static func propertyNamesToIgnoreInValueFromDocument() -> Set<String> {
    return ["id", _name(for: \Self.syncedAt), _name(for: \Self.deletedAt), _name(for: \Self.self.syncedAtBeforeDeletion)]
  }

  public func delete() {
    deletedAt = Date()
    syncedAtBeforeDeletion = syncedAt
    syncedAt = nil
  }

  public func undoDeletion() {
    deletedAt = nil
    syncedAt = syncedAtBeforeDeletion
    syncedAtBeforeDeletion = nil
  }
}
