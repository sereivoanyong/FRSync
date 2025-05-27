//
//  Swift.swift
//  FRSync
//
//  Created by Sereivoan Yong on 5/29/25.
//

extension Result {

  @inlinable
  init?(_ success: Success?, _ failure: Failure?) {
    if let success {
      self = .success(success)
    } else if let failure {
      self = .failure(failure)
    } else {
      return nil
    }
  }
}
