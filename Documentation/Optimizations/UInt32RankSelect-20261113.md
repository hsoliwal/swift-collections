<!-- SPDX-License-Identifier: Apache-2.0 WITH Swift-exception -->
# Direct Swift Collections UInt32 ranked bit selection

**Production owner:** `Sources/InternalCollectionsUtilities/IntegerTricks/Integer rank.swift`, shared with `HashTreeCollections` via the existing `_Bitmap.bucket(at:)` algorithm. This is a direct fork change, not an M3JDK helper or a new collection type.

## Source and contract
- Source repository: `hsoliwal/swift-collections@b905c889ff75059b8ef0bde480fe55948147b1e6`.
- Original complete Git blob: `5f115736c3e9f8cc7684a5667286ffff7ac7e0ff`, SHA-256: `a577f79aa42fe08f36ef43da4cda4ccf48fd1e026b63ebaf1c492d5ad107be0b`.
- Proposed complete Git blob: `52a00e0dc60c43ddb3e1d74b2fe4c988d0c1dac2`, SHA-256: `962abefa503734e8f10bc85d3017f675e14c23853ab00134a771c0f2d40dc34f`.
- Exactly two package-level overloads, `UInt._bit(ranked:)` and `UInt32._bit(ranked:)`, change inside their one owner file. The `UInt16` overload remains byte-identical after a wider candidate failed non-regression benchmarking.
- For rank **0** or **1** only, locate the first/second set bit by `trailingZeroBitCount` after zero/one low-bit clear. A single `UInt(bitPattern: n) < 2` admission keeps negative ordinals excluded even in release builds.
- For all other ranks, retain the original **16/8/4/2/1 popcount descent** and its exact assertion and optional-result behavior. No ABI signature changes, new heap allocation, retained storage, new type, native code, or package manifest modifications.

## Actual local Swift 6.2.1 proof

The exact original bytes were reconstructed and confirmed by `git hash-object`. Both complete original/candidate files compiled as `InternalCollectionsUtilities` with `swiftc -package-name swift-collections` under **`-O` and `-Onone`**. The 32-bit oracle enumerated 65,536 low-word masks, their high-word counterparts and seeded full-width words for ranks 0–31: **8,388,688 checks per build**, transcript SHA-256 `aad95f038174ecf58fadc951922087d34d60bf212a0796d0deb89a32ec572ef9`. A separate exhaustive UInt16 and seeded UInt64 oracle passed **3,145,728 checks per build**, transcript SHA-256 `4ab3dd3536e4881d8337ae0fd35ad71afd7c87a38b805d7a9e8df623b5feff39`. Total **11,534,416 equal checks per build**, four full baseline/candidate release/debug binaries for each oracle.

Five independently executed optimized process pairs each used 11 warmed median samples. Median candidate/baseline timing ratios: rank 0 **0.331**, rank 1 **0.349**, rank 2 **1.056**, rank 3 **1.046**, rank 12 **1.031**, rank 31 **0.990**, mixed ranks **0.808**. All outputs have identical checksums. These are bounded Linux x86_64 standalone measurements; some high-rank cases regress, so **performance non-regression remains HOLD** rather than universal speedup.

The earlier two-equality-guard variant was superseded by the single-unsigned-guard implementation. Expanded `UInt16` fast paths passed correctness but were **rejected**: median slowdowns of 1.111× at rank 2, 1.225× at rank 3 and 1.174× at rank 7. The `UInt` variant showed median ratios 0.226 at rank 0, 0.198 at rank 1, and 0.757 on mixed ranks, with smaller higher-rank regressions. A `_Bitmap.popFirst()` shortcut was separately rejected (ratio 1.015). All rejected variants are kept as evidence, not patched into the fork.

## Required fork gates

1. Source-diff and full-byte pre/post Git SHA verification; published candidate must equal the compiled file, not merely resemble it.
2. Swift formatting/lint and full `swift test` using the matching SwiftPM manifest/toolchain (the root `Package.swift` requires Swift 6.4; the repo also provides `Package@swift-6.2.swift`). The entire package checkout and its dependent targets are unavailable in the local execution environment, so full SwiftPM test suite is **NOT_RUN**.
3. Existing `TreeSet` and `TreeDictionary` collision/index/iteration tests and new bitmap rank regression, plus allocation and representative ARM/x86 performance.
4. Review as **draft**, no master/main write or M3JDK receiving transfer. Reject rather than silently compensate if high-rank regressions exceed the product benchmark policy.

Proof and benchmark: `UInt32RankSelect-20261113.tsv`. Do not treat a merged draft, a source-only transcript or an isolated synthetic benchmark as a full distribution acceptance.

## Family closure

The reviewed code now covers 64-bit platform `UInt` and 32-bit `UInt32` selection in one physical algorithm owner. The 16-bit overload was **not** changed because a measured high-rank regression exceeded the acceptable per-leaf criterion. Full SwiftPM/ARM qualification remains outstanding; source-only proof is not a release gate.
