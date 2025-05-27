//
//  Firebase.swift
//  FRSync
//
//  Created by Sereivoan Yong on 5/28/25.
//

import FirebaseFirestore

extension FirebaseFirestore.Query {

  @inlinable
  func addSnapshotListener(completion: @escaping (Result<QuerySnapshot, Error>) -> Void) -> ListenerRegistration {
    addSnapshotListener { snapshot, error in
      guard let result = Result(snapshot, error) else { fatalError() }
      completion(result)
    }
  }
}
