//
//  Firebase.swift
//  FRSync
//
//  Created by Sereivoan Yong on 5/28/25.
//

import FirebaseFirestore

extension FirebaseFirestore.Query {

  @inlinable
  func addSnapshotListener(options: SnapshotListenOptions? = nil, completion: @escaping (Result<QuerySnapshot, Error>) -> Void) -> ListenerRegistration {
    addSnapshotListener(options: options ?? SnapshotListenOptions()) { snapshot, error in
      guard let result = Result(snapshot, error) else { fatalError() }
      completion(result)
    }
  }
}
