import Foundation

/// The sun's three daily reference events for a given place and date, as absolute instants.
struct SolarTimes {
    /// True solar noon: the moment the sun crosses the local meridian. Not 12:00 clock time.
    let solarNoon: Date
    /// Sunrise, or `nil` if the sun does not rise that day at that latitude (polar night).
    let sunrise: Date?
    /// Sunset, or `nil` if the sun does not set that day at that latitude (polar day).
    let sunset: Date?
}

/// Computes solar noon, sunrise, and sunset from latitude/longitude/date using the
/// NOAA Solar Calculator equations (based on Jean Meeus, "Astronomical Algorithms"),
/// accurate to roughly ±1 minute — more than sufficient for sandhya windows measured
/// in tens of minutes.
///
/// Reference: https://gml.noaa.gov/grad/solcalc/solareqns.PDF
enum SolarCalculator {

    /// Standard solar zenith angle for sunrise/sunset, accounting for atmospheric
    /// refraction and the sun's apparent radius (NOAA uses 90.833°).
    private static let sunriseSunsetZenith = 90.833

    static func solarTimes(for date: Date, latitude: Double, longitude: Double, timeZone: TimeZone) -> SolarTimes {
        // Anchor all trig on local *calendar noon* in the target time zone so we're
        // evaluating the sun's position for the correct calendar day at that place,
        // independent of what time zone this code happens to run in.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let noonComponents = calendar.dateComponents([.year, .month, .day], from: date)
        guard let localNoon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: calendar.date(from: noonComponents) ?? date) else {
            return SolarTimes(solarNoon: date, sunrise: nil, sunset: nil)
        }

        let julianDay = julianDay(for: localNoon)
        let julianCentury = (julianDay - 2451545.0) / 36525.0

        let eqTimeMinutes = equationOfTimeMinutes(julianCentury: julianCentury)
        let declinationRad = solarDeclinationRadians(julianCentury: julianCentury)

        // Fraction of the day (UTC) at which true solar noon occurs at this longitude.
        // longitude is positive East; NOAA's formula takes longitude positive East too.
        let solarNoonFractionUTC = (720.0 - 4.0 * longitude - eqTimeMinutes) / 1440.0
        let solarNoonDate = startOfUTCDay(for: localNoon).addingTimeInterval(solarNoonFractionUTC * 86400.0)

        let latRad = latitude * .pi / 180.0
        let zenithRad = sunriseSunsetZenith * .pi / 180.0

        let cosHourAngle = (cos(zenithRad) / (cos(latRad) * cos(declinationRad))) - (tan(latRad) * tan(declinationRad))

        var sunrise: Date?
        var sunset: Date?
        if cosHourAngle >= -1.0 && cosHourAngle <= 1.0 {
            let hourAngleDeg = acos(cosHourAngle) * 180.0 / .pi
            let sunriseFractionUTC = solarNoonFractionUTC - hourAngleDeg * 4.0 / 1440.0
            let sunsetFractionUTC = solarNoonFractionUTC + hourAngleDeg * 4.0 / 1440.0
            let dayStart = startOfUTCDay(for: localNoon)
            sunrise = dayStart.addingTimeInterval(sunriseFractionUTC * 86400.0)
            sunset = dayStart.addingTimeInterval(sunsetFractionUTC * 86400.0)
        }
        // If cosHourAngle is out of range, the sun never rises (> 1) or never sets (< -1)
        // that day at this latitude — leave sunrise/sunset nil (polar night/day).

        return SolarTimes(solarNoon: solarNoonDate, sunrise: sunrise, sunset: sunset)
    }

    // MARK: - Astronomical building blocks

    /// Julian Day Number for a given instant (works in the instant's absolute UTC time).
    private static func julianDay(for date: Date) -> Double {
        // Unix epoch (1970-01-01 00:00:00 UTC) is JD 2440587.5.
        return date.timeIntervalSince1970 / 86400.0 + 2440587.5
    }

    private static func startOfUTCDay(for date: Date) -> Date {
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        let jd = julianDay(for: date)
        let dayJd = floor(jd - 0.5) + 0.5
        return Date(timeIntervalSince1970: (dayJd - 2440587.5) * 86400.0)
    }

    private static func geometricMeanLongitude(julianCentury t: Double) -> Double {
        var l0 = 280.46646 + t * (36000.76983 + t * 0.0003032)
        l0 = l0.truncatingRemainder(dividingBy: 360.0)
        if l0 < 0 { l0 += 360.0 }
        return l0
    }

    private static func geometricMeanAnomaly(julianCentury t: Double) -> Double {
        357.52911 + t * (35999.05029 - 0.0001537 * t)
    }

    private static func eccentricityEarthOrbit(julianCentury t: Double) -> Double {
        0.016708634 - t * (0.000042037 + 0.0000001267 * t)
    }

    private static func sunEquationOfCenter(julianCentury t: Double, meanAnomalyDeg m: Double) -> Double {
        let mRad = m * .pi / 180.0
        return sin(mRad) * (1.914602 - t * (0.004817 + 0.000014 * t))
            + sin(2 * mRad) * (0.019993 - 0.000101 * t)
            + sin(3 * mRad) * 0.000289
    }

    private static func meanObliquityOfEcliptic(julianCentury t: Double) -> Double {
        let seconds = 21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))
        return 23.0 + (26.0 + seconds / 60.0) / 60.0
    }

    private static func obliquityCorrection(julianCentury t: Double) -> Double {
        let e0 = meanObliquityOfEcliptic(julianCentury: t)
        let omega = 125.04 - 1934.136 * t
        return e0 + 0.00256 * cos(omega * .pi / 180.0)
    }

    private static func sunApparentLongitude(julianCentury t: Double, trueLongitude: Double) -> Double {
        let omega = 125.04 - 1934.136 * t
        return trueLongitude - 0.00569 - 0.00478 * sin(omega * .pi / 180.0)
    }

    private static func solarDeclinationRadians(julianCentury t: Double) -> Double {
        let l0 = geometricMeanLongitude(julianCentury: t)
        let m = geometricMeanAnomaly(julianCentury: t)
        let c = sunEquationOfCenter(julianCentury: t, meanAnomalyDeg: m)
        let trueLongitude = l0 + c
        let apparentLongitude = sunApparentLongitude(julianCentury: t, trueLongitude: trueLongitude)
        let obliquity = obliquityCorrection(julianCentury: t)

        let sinDeclination = sin(obliquity * .pi / 180.0) * sin(apparentLongitude * .pi / 180.0)
        return asin(sinDeclination)
    }

    /// The Equation of Time, in minutes: the difference between apparent solar time
    /// and mean solar time, caused by the Earth's elliptical orbit and axial tilt.
    private static func equationOfTimeMinutes(julianCentury t: Double) -> Double {
        let l0 = geometricMeanLongitude(julianCentury: t)
        let m = geometricMeanAnomaly(julianCentury: t)
        let e = eccentricityEarthOrbit(julianCentury: t)
        let obliquity = obliquityCorrection(julianCentury: t)

        let l0Rad = l0 * .pi / 180.0
        let mRad = m * .pi / 180.0

        var y = tan(obliquity * .pi / 360.0) // tan(obliquity / 2), obliquity already in degrees
        y *= y

        let eTime = y * sin(2 * l0Rad)
            - 2 * e * sin(mRad)
            + 4 * e * y * sin(mRad) * cos(2 * l0Rad)
            - 0.5 * y * y * sin(4 * l0Rad)
            - 1.25 * e * e * sin(2 * mRad)

        return 4.0 * (eTime * 180.0 / .pi)
    }
}
