//
//  ByteFormatterTests.swift
//  PulseTests
//
//  Created by Pulse Project. Licensed under MIT.
//

import Testing

@testable import Pulse

@Suite("Byte Formatter Tests")
struct ByteFormatterTests {
    @Test("IEC boundary values are formatted")
    func iecBoundaryValues() {
        #expect(ByteFormatter.string(from: 0, dataUnit: .iec) == "0B")
        #expect(ByteFormatter.string(from: 1_024, dataUnit: .iec) == "1.0KB")
        #expect(ByteFormatter.string(from: 1_048_576, dataUnit: .iec) == "1.0MB")
        #expect(ByteFormatter.string(from: 1_073_741_824, dataUnit: .iec) == "1.0GB")
        #expect(ByteFormatter.string(from: 1_099_511_627_776, dataUnit: .iec) == "1.0TB")
    }

    @Test("SI boundary values are formatted")
    func siBoundaryValues() {
        #expect(ByteFormatter.string(from: 0, dataUnit: .si) == "0B")
        #expect(ByteFormatter.string(from: 1_000, dataUnit: .si) == "1.0KB")
        #expect(ByteFormatter.string(from: 1_000_000, dataUnit: .si) == "1.0MB")
        #expect(ByteFormatter.string(from: 1_000_000_000, dataUnit: .si) == "1.0GB")
        #expect(ByteFormatter.string(from: 1_000_000_000_000, dataUnit: .si) == "1.0TB")
    }

    @Test("Compact units and rates are formatted")
    func compactUnitsAndRates() {
        #expect(
            ByteFormatter.string(from: 1_048_576, dataUnit: .iec, unitStyle: .compact) == "1.0M"
        )
        #expect(
            ByteFormatter.rateString(from: 524_288, dataUnit: .iec, unitStyle: .compact) == "512K/s"
        )
    }
}
