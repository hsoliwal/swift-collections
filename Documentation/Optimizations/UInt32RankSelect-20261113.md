<!-- SPDX-License-Identifier: Apache-2.0 WITH Swift-exception -->
# Direct Swift Collections UInt32 ranked bit selection

**Production owner:** `Sources/InternalCollectionsUtilities/IntegerTricks/Integer rank.swift`, shared with `HashTreeCollections` via the existing `_Bitmap.bucket(at:)` algorithm. This is a direct fork change, not an M3JDK helper or a new collection type.

## Source and contract
- Source repository: `hsoliwal/swift-collections@b905c889ff75059b8ef0bde480fe55948147b1e6`.
- Original complete Git blob: `5f115736c3e9f8cc7684a5667286ffff7ac7e0ff`, SHA-256: `a577f79aa42fe08f36ef43da4cda4ccf48fd1e026b63ebaf1c492d5ad107be0b`.
- Proposed complete Git blob: `61b5a3a2c57767dcf6574f246e7b5244edcb940e`, SHA-256: `5988023afa3c95870b0c91734a904102236dfa1ef0339121461cd4eaa6db5991`.
- Exactly one package-level overload `UInt32._bit(ranked: Int) -> UInt?` changes inside its existing owner file. All `UInt` and `UInt16` overloads remain byte-identical.
- For rank **0** or **1** only, locate the first/second set bit by `trailingZeroBitCount` after zero/one low-bit clear. A single `UInt(bitPattern: n) < 2` admission keeps negative ordinals excluded even in release builds.
- For all other ranks, retain the original **16/8/4/2/1 popcount descent** and its exact assertion and optional-result behavior. No ABI signature changes, new heap allocation, retained storage, new type, native code, or package manifest modifications.

## Actual local Swift 6.2.1 proof

The exact original bytes were reconstructed and confirmed by `git hash-object`. Both complete original/candidate files compiled as `InternalCollectionsUtilities` with `swiftc -package-name swift-collections` under **`-O` and `-Onone`**. A deterministic reference oracle enumerated 65,536 low-word masks, their high-word counterparts and seeded full-width words for all ranks 0–31, plus checks of unchanged UInt/UInt16 overloads. **8,388,688 comparisons passed per build**, with identical baseline/candidate transcripts (SHA-256 `aad95f038174ecf58fadc951922087d34d60bf212a0796d0deb89a32ec572ef9`).

Five independently executed optimized process pairs each used 11 warmed median samples. Median candidate/baseline timing ratios: rank 0 **0.331**, rank 1 **0.349**, rank 2 **1.056**, rank 3 **1.046**, rank 12 **1.031**, rank 31 **0.990**, mixed ranks **0.808**. All outputs have identical checksums. These are bounded Linux x86_64 standalone measurements; some high-rank cases regress, so **performance non-regression remains HOLD** rather than universal speedup.

The earlier two-equality-guard variant was superseded by this single-unsigned-guard variant. A `_Bitmap.popFirst()` source idea was separately rejected after a measured `1.015` ratio (slower). Rejected variants are retained in the local review evidence, not patched into the fork.

## Required fork gates

1. Source-diff and full-byte pre/post Git SHA verification; published candidate must equal the compiled file, not merely resemble it.
2. Swift formatting/lint and full `swift test` using the matching SwiftPM manifest/toolchain (the root `Package.swift` requires Swift 6.4; the repo also provides `Package@swift-6.2.swift`). The entire package checkout and its dependent targets are unavailable in the local execution environment, so full SwiftPM test suite is **NOT_RUN**.
3. Existing `TreeSet` and `TreeDictionary` collision/index/iteration tests and new bitmap rank regression, plus allocation and representative ARM/x86 performance.
4. Review as **draft**, no master/main write or M3JDK receiving transfer. Reject rather than silently compensate if high-rank regressions exceed the product benchmark policy.

Proof and benchmark: `UInt32RankSelect-20261113.tsv`. Do not treat a merged draft, a source-only transcript or an isolated synthetic benchmark as a full distribution acceptance.
