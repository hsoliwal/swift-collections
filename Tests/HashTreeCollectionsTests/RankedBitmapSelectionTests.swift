//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

import XCTest

#if COLLECTIONS_SINGLE_MODULE
@testable import Collections
#else
@testable import HashTreeCollections
#endif

final class RankedBitmapSelectionTests: XCTestCase {
  private func expectedBit(_ bits: UInt32, ranked rank: Int) -> UInt? {
    var remaining = bits
    for _ in 0..<rank {
      if remaining == 0 { return nil }
      remaining &= remaining &- 1
    }
    guard remaining != 0 else { return nil }
    return UInt(remaining.trailingZeroBitCount)
  }

  func testBucketAtEveryValidRank() {
    var masks: [UInt32] = [
      0, 1, UInt32.max, 0x8000_0000, 0x5555_5555, 0xAAAA_AAAA,
      0x0101_0101, 0x8000_0001, 0x0000_FFFF, 0xFFFF_0000
    ]
    var state: UInt64 = 0x1535_AA23_110D_6A41
    for _ in 0..<8192 {
      state ^= state &<< 13
      state ^= state &>> 7
      state ^= state &<< 17
      masks.append(UInt32(truncatingIfNeeded: state))
    }

    for bits in masks {
      let bitmap = _Bitmap(_value: bits)
      for rank in 0..<bits.nonzeroBitCount {
        let expected = expectedBit(bits, ranked: rank)!
        let actual = bitmap.bucket(at: _HashSlot(rank))
        XCTAssertEqual(actual.value, expected,
                       "bits=\(bits) rank=\(rank)")
      }
    }
  }

  func testRankedSelectionAfterSetAndClearOperations() {
    var bitmap = _Bitmap.empty
    var members: [Int] = []

    for bit in [31, 0, 16, 1, 29, 2, 7, 8, 3, 15, 30, 4, 17] {
      bitmap.insert(_Bucket(UInt(bit)))
      members.append(bit)
      members.sort()
      XCTAssertEqual(bitmap.count, members.count)
      for (rank, expected) in members.enumerated() {
        XCTAssertEqual(bitmap.bucket(at: _HashSlot(rank)).value, UInt(expected))
      }
    }

    for bit in [0, 31, 8, 1, 30, 2, 17, 4, 3, 29, 15, 16, 7] {
      bitmap.remove(_Bucket(UInt(bit)))
      members.removeAll { $0 == bit }
      XCTAssertEqual(bitmap.count, members.count)
      for (rank, expected) in members.enumerated() {
        XCTAssertEqual(bitmap.bucket(at: _HashSlot(rank)).value, UInt(expected))
      }
    }
    XCTAssertTrue(bitmap.isEmpty)
  }
}
