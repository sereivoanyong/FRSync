//
//  SyncManager.swift
//  FRSync
//
//  Created by Sereivoan Yong on 5/28/25.
//

import Foundation
import FirebaseFirestore
import RealmSwift

open class SyncManager {

  public let firestore: Firestore

  public let realm: Realm

  open private(set) var tokens: [SyncToken] = []

  public init(firestore: Firestore, realm: Realm) {
    self.firestore = firestore
    self.realm = realm
  }

  // MARK: Syncing

  @discardableResult
  final public func sync<Object: SyncingObject>(_ objectType: Object.Type, at collectionReferenceProvider: (Firestore) -> CollectionReference) -> SyncToken {
    let collectionReference = collectionReferenceProvider(firestore)
    let listenerRegistration = collectionReference.addSnapshotListener { [unowned self] result in
      switch result {
      case .success(let snapshot):
        realm.beginWrite()
        for change in snapshot.documentChanges {
          let document = change.document
          switch change.type {
          case .added:
            if let existingObject = realm.object(ofType: Object.self, forPrimaryKey: document.documentID), existingObject.syncedAt == nil {
              existingObject.syncedAt = Date()
            } else {
              let value = Object.value(documentId: document.documentID, documentData: document.data())
              realm.create(Object.self, value: value, update: .all)
            }

          case .modified:
            let value = Object.value(documentId: document.documentID, documentData: document.data())
            realm.create(Object.self, value: value, update: .modified)

          case .removed:
            if let object = realm.object(ofType: Object.self, forPrimaryKey: document.documentID) {
              if let object = object as? any DeletableSyncingObject {
                // Let syncCreationOrDeletion handle
                if object.deletedAt == nil {
                  realm.delete(object)
                }
              } else {
                realm.delete(object)
              }
            }
          }
        }
        try! realm.commitWrite()

      case .failure(let error):
        print(error)
      }
    }

    let unsyncedObjects = realm.objects(Object.self).filter("\(_name(for: \Object.syncedAt)) == NULL")
    let notificationToken = unsyncedObjects.observe { change in
      switch change {
      case .initial(let objects):
        for object in objects {
          syncCreationOrDeletion(object, at: collectionReference)
        }
      case .update(let objects, _, let insertions, let modifications):
        for index in insertions + modifications {
          let object = objects[index]
          syncCreationOrDeletion(object, at: collectionReference)
        }
      }
    }
    let token = SyncToken(objectType: objectType, collectionReference: collectionReference, listenerRegistration: listenerRegistration, notificationToken: notificationToken)
    tokens.append(token)
    return token
  }

  final public func unsyncAll() {
    for token in tokens {
      token.cancel()
    }
  }
}

private func syncCreationOrDeletion<Object: SyncingObject>(_ object: Object, at collectionReference: CollectionReference) {
  let id = object.id
  if let object = object as? any DeletableSyncingObject, object.deletedAt != nil {
    collectionReference.document(id)
      .delete { error in
        if let error {
          print("❌ Failed to sync \(type(of: object)) (id: \(id)) deletion", error)
          if let realm = object.realm {
            try? realm.write {
              object.undoDeletion()
            }
            print("ℹ️ Local deletion of \(type(of: object)) (id: \(id)) is reverted")
          }
        } else {
          print("✅ \(type(of: object)) (id: \(id)) deletion is synced")
        }
      }
  } else {
    let documentData = object.documentData()
    collectionReference.document(id).setData(documentData) { error in
      if let error {
        print("❌ Failed to sync \(type(of: object)) (id: \(id)) creation", error)
        if let realm = object.realm {
          try? realm.write {
            realm.delete(object)
          }
          print("ℹ️ Locally creation of \(type(of: object)) (id: \(id)) is reverted")
        }
      } else {
        print("✅ \(type(of: object)) (id: \(id)) creation is synced")
      }
    }
  }
}
