import Foundation
import Testing
@testable import SandhyaApp

struct SolarCalculatorTests {

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12, timeZone: TimeZone) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    // MARK: - Equation of time sanity checks
    //
    // At longitude 0 in the UTC time zone, true solar noon = 12:00 UTC minus the
    // Equation of Time. The Equation of Time's well-known extremes are ~+16.4 min
    // around Nov 3 and ~-14.2 min around Feb 11 (see e.g. any analemma reference) —
    // checking against those pins the whole calculation down to real astronomy,
    // not just internal consistency.

    @Test func solarNoonAheadOfClockInEarlyNovember() {
        let utc = TimeZone(identifier: "UTC")!
        let d = date(2024, 11, 3, timeZone: utc)
        let times = SolarCalculator.solarTimes(for: d, latitude: 0, longitude: 0, timeZone: utc)

        let noonUTCMinutes = minutesSinceMidnightUTC(times.solarNoon)
        // Expect solar noon roughly 12:00 - 16.4min ≈ 11:43:36 UTC, allow a couple minutes slack.
        #expect(noonUTCMinutes > 11 * 60 + 38)
        #expect(noonUTCMinutes < 11 * 60 + 48)
    }

    @Test func solarNoonBehindClockInMidFebruary() {
        let utc = TimeZone(identifier: "UTC")!
        let d = date(2024, 2, 11, timeZone: utc)
        let times = SolarCalculator.solarTimes(for: d, latitude: 0, longitude: 0, timeZone: utc)

        let noonUTCMinutes = minutesSinceMidnightUTC(times.solarNoon)
        // Expect solar noon roughly 12:00 + 14.2min ≈ 12:14:12 UTC.
        #expect(noonUTCMinutes > 12 * 60 + 9)
        #expect(noonUTCMinutes < 12 * 60 + 19)
    }

    // MARK: - Structural invariants

    @Test func sunriseBeforeNoonBeforeSunsetAtMidLatitude() {
        let tz = TimeZone(identifier: "America/New_York")!
        let d = date(2025, 6, 21, timeZone: tz)
        let times = SolarCalculator.solarTimes(for: d, latitude: 40.7128, longitude: -74.0060, timeZone: tz)

        let sunrise = try! #require(times.sunrise)
        let sunset = try! #require(times.sunset)
        #expect(sunrise < times.solarNoon)
        #expect(times.solarNoon < sunset)
    }

    @Test func longerDayInSummerThanWinterAtMidLatitude() {
        let tz = TimeZone(identifier: "America/New_York")!
        let summer = SolarCalculator.solarTimes(
            for: date(2025, 6, 21, timeZone: tz), latitude: 40.7128, longitude: -74.0060, timeZone: tz
        )
        let winter = SolarCalculator.solarTimes(
            for: date(2025, 12, 21, timeZone: tz), latitude: 40.7128, longitude: -74.0060, timeZone: tz
        )

        let summerLength = summer.sunset!.timeIntervalSince(summer.sunrise!)
        let winterLength = winter.sunset!.timeIntervalSince(winter.sunrise!)
        #expect(summerLength > winterLength)
    }

    @Test func equatorHasRoughlyEqualDayLengthYearRound() {
        let tz = TimeZone(identifier: "UTC")!
        let june = SolarCalculator.solarTimes(for: date(2025, 6, 21, timeZone: tz), latitude: 0, longitude: 0, timeZone: tz)
        let december = SolarCalculator.solarTimes(for: date(2025, 12, 21, timeZone: tz), latitude: 0, longitude: 0, timeZone: tz)

        let juneLength = june.sunset!.timeIntervalSince(june.sunrise!)
        let decemberLength = december.sunset!.timeIntervalSince(december.sunrise!)
        // Within a few minutes of each other, and both close to 12 hours.
        #expect(abs(juneLength - decemberLength) < 5 * 60)
        #expect(abs(juneLength - 12 * 3600) < 10 * 60)
    }

    @Test func polarSummerHasNoSunset() {
        // Tromsø, Norway (~69.6°N) in midsummer: the sun never sets.
        let tz = TimeZone(identifier: "Europe/Oslo")!
        let d = date(2025, 6, 21, timeZone: tz)
        let times = SolarCalculator.solarTimes(for: d, latitude: 69.6, longitude: 18.9, timeZone: tz)
        #expect(times.sunrise == nil)
        #expect(times.sunset == nil)
    }

    private func minutesSinceMidnightUTC(_ date: Date) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return components.hour! * 60 + components.minute!
    }
}

struct SandhyaCalculatorTests {

    @Test func eachWindowIsSeventyTwoMinutesTotal() {
        for type in SandhyaType.allCases {
            #expect(type.totalDurationMinutes == 72)
        }
    }

    @Test func pratahWindowSplitsFortyEightAndTwentyFour() {
        #expect(SandhyaType.pratah.minutesBeforeAnchor == 48)
        #expect(SandhyaType.pratah.minutesAfterAnchor == 24)
    }

    @Test func madhyahnaWindowSplitsEvenly() {
        #expect(SandhyaType.madhyahna.minutesBeforeAnchor == 36)
        #expect(SandhyaType.madhyahna.minutesAfterAnchor == 36)
    }

    @Test func sayamWindowSplitsTwentyFourAndFortyEight() {
        #expect(SandhyaType.sayam.minutesBeforeAnchor == 24)
        #expect(SandhyaType.sayam.minutesAfterAnchor == 48)
    }

    @Test func producesThreeWindowsAtNonPolarLocation() {
        let tz = TimeZone(identifier: "Asia/Kolkata")!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = tz
        let d = calendar.date(from: DateComponents(year: 2025, month: 3, day: 21, hour: 12))!
        let times = SolarCalculator.solarTimes(for: d, latitude: 28.6139, longitude: 77.2090, timeZone: tz)
        let windows = SandhyaCalculator.windows(for: times)
        #expect(windows.count == 3)
        #expect(windows.map(\.type) == [.pratah, .madhyahna, .sayam])

        let pratah = windows[0]
        #expect(pratah.start == pratah.anchor.addingTimeInterval(-48 * 60))
        #expect(pratah.end == pratah.anchor.addingTimeInterval(24 * 60))
    }
}
