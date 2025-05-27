//
//  SyncToken.swift
//  FRSync
//
//  Created by Sereivoan Yong on 5/29/25.
//

import Foundation
import Combine
import FirebaseFirestore
import RealmSwift

final public class SyncToken: Cancellable {

  let objectType: any SyncingObject.Type
  let collectionReference: CollectionReference
  let listenerRegistration: any ListenerRegistration
  let notificationToken: NotificationToken

  init(objectType: any SyncingObject.Type, collectionReference: CollectionReference, listenerRegistration: any ListenerRegistration, notificationToken: NotificationToken) {
    self.objectType = objectType
    self.collectionReference = collectionReference
    self.listenerRegistration = listenerRegistration
    self.notificationToken = notificationToken
  }

  public func cancel() {
    listenerRegistration.remove()
    notificationToken.invalidate()
  }
}
