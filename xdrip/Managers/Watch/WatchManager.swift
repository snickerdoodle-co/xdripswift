//
//  WatchManager.swift
//  xdrip
//
//  Created by Paul Plant on 9/2/24.
//  Copyright © 2024 Johan Degraeve. All rights reserved.
//

import Foundation
import SwiftUI

struct WatchState: Codable {
    
    // these are similar to the context state of the Live Activity
    var bgReadingValues: [Double] = []
    var bgReadingDates: [Date] = []
    var isMgDl: Bool?
    var slopeOrdinal: Int?
    var deltaChangeInMgDl: Double?
    var urgentLowLimitInMgDl: Double?
    var lowLimitInMgDl: Double?
    var highLimitInMgDl: Double?
    var urgentHighLimitInMgDl: Double?
    var updatedDate: Date?
    
    // specific to the Watch state
    var activeSensorDescription: String?
    var sensorAgeInMinutes: Double?
    var sensorMaxAgeInMinutes: Double?
    var dataSourceConnectionStatusImageString: String?
    var dataSourceConnectionStatusIsActive: Bool?
    
    var bgValueInMgDl: Double?
    var bgReadingDate: Date?
    var bgUnitString: String?
    var bgValueStringInUserChosenUnit: String?
    
}


class WatchManager: NSObject, ObservableObject {
    
    // PLACEHOLDER CODE    
    
    // Dynamic stateful properties about your activity go here!
    @Published var bgReadingValues: [Double]
    @Published var bgReadingDates: [Date]
    @Published var isMgDl: Bool
    @Published var slopeOrdinal: Int
    @Published var deltaChangeInMgDl: Double?
    @Published var urgentLowLimitInMgDl: Double
    @Published var lowLimitInMgDl: Double
    @Published var highLimitInMgDl: Double
    @Published var urgentHighLimitInMgDl: Double
    @Published var updatedDate: Date
    @Published var liveActivityNotificationSizeTypeAsInt: Int
    
    
    @Published var bgValueInMgDl: Double
    @Published var bgReadingDate: Date
    @Published var bgUnitString: String
    @Published var bgValueStringInUserChosenUnit: String
    
    init(bgReadingValues: [Double], bgReadingDates: [Date], isMgDl: Bool, slopeOrdinal: Int, deltaChangeInMgDl: Double?, urgentLowLimitInMgDl: Double, lowLimitInMgDl: Double, highLimitInMgDl: Double, urgentHighLimitInMgDl: Double, updatedDate: Date, liveActivityNotificationSizeTypeAsInt: Int) {
        
        // these are the "passed in" stateful values used to initialize
        self.isMgDl = isMgDl
        self.slopeOrdinal = slopeOrdinal
        self.deltaChangeInMgDl = deltaChangeInMgDl// ?? nil
        self.urgentLowLimitInMgDl = urgentLowLimitInMgDl
        self.lowLimitInMgDl = lowLimitInMgDl
        self.highLimitInMgDl = highLimitInMgDl
        self.urgentHighLimitInMgDl = urgentHighLimitInMgDl
        self.updatedDate = updatedDate
        self.liveActivityNotificationSizeTypeAsInt = liveActivityNotificationSizeTypeAsInt
        
        self.bgReadingValues = bgReadingValues
        self.bgReadingDates = bgReadingDates
        
        // these are dynamically initialized based on the above
        self.bgValueInMgDl = bgReadingValues[0]
        self.bgReadingDate = bgReadingDates[0]
        self.bgUnitString = isMgDl ? Texts_Common.mgdl : Texts_Common.mmol
        self.bgValueStringInUserChosenUnit = bgReadingValues[0].mgdlToMmolAndToString(mgdl: isMgDl)
        
    }
    
    
    /// Blood glucose color dependant on the user defined limit values
    /// - Returns: a Color object either red, yellow or green
    func getBgColor() -> Color {
        if bgValueInMgDl >= urgentHighLimitInMgDl || bgValueInMgDl <= urgentLowLimitInMgDl {
            return .red
        } else if bgValueInMgDl >= highLimitInMgDl || bgValueInMgDl <= lowLimitInMgDl {
            return .yellow
        } else {
            return .green
        }
    }
    
    /// convert the optional delta change int (in mg/dL) to a formatted change value in the user chosen unit making sure all zero values are shown as a positive change to follow Nightscout convention
    /// - Returns: a string holding the formatted delta change value (i.e. +0.4 or -6)
    func getDeltaChangeStringInUserChosenUnit() -> String {
        
        if let deltaChangeInMgDl = deltaChangeInMgDl {
            
            let valueAsString = deltaChangeInMgDl.mgdlToMmolAndToString(mgdl: isMgDl)
            
            var deltaSign: String = ""
            if (deltaChangeInMgDl > 0) { deltaSign = "+"; }
            
            // quickly check "value" and prevent "-0mg/dl" or "-0.0mmol/l" being displayed
            // show unitized zero deltas as +0 or +0.0 as per Nightscout format
            if (isMgDl) {
                if (deltaChangeInMgDl > -1) && (deltaChangeInMgDl < 1) {
                    return "+0"
                } else {
                    return deltaSign + valueAsString
                }
            } else {
                if (deltaChangeInMgDl > -0.1) && (deltaChangeInMgDl < 0.1) {
                    return "+0.0"
                } else {
                    return deltaSign + valueAsString
                }
            }
        } else {
            return ""
        }
    }
    
    ///  returns a string holding the trend arrow
    /// - Returns: trend arrow string (i.e.  "↑")
    func trendArrow() -> String {
        switch slopeOrdinal {
        case 7:
            return "\u{2193}\u{2193}" // ↓↓
        case 6:
            return "\u{2193}" // ↓
        case 5:
            return "\u{2198}" // ↘
        case 4:
            return "\u{2192}" // →
        case 3:
            return "\u{2197}" // ↗
        case 2:
            return "\u{2191}" // ↑
        case 1:
            return "\u{2191}\u{2191}" // ↑↑
        default:
            return "n/a"
        }
    }
    
    func deltaChangeFormatted(font: Font) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(getDeltaChangeStringInUserChosenUnit())
                .font(font).bold()
                .foregroundStyle(Color(white: 0.9))
                .minimumScaleFactor(0.2)
                .lineLimit(1)
            Text(bgUnitString)
                .font(font)
                .foregroundStyle(Color(white: 0.5))
                .minimumScaleFactor(0.2)
                .lineLimit(1)
        }
    }
    
    /*
     func placeTextAtBottomOfWidget(glucoseChartType: GlucoseChartType) -> Bool {
        
        // first see at which index in bgReadingDates the BG value is after one hour
        var firstIndexForWidgetType = 0
        var index = 0
        
        for _ in bgReadingValues {
            if bgReadingDates[index] > Date().addingTimeInterval((-glucoseChartType.hoursToShow(liveActivityNotificationSizeType: LiveActivityNotificationSizeType(rawValue: liveActivityNotificationSizeTypeAsInt) ?? .normal) * 60 * 60) + 3600) {
                firstIndexForWidgetType = index
            }
            index += 1
        }
        
        // then get the bg value of that index in the bgValues array
        // if it is higher than the user's high limit, then we can assume that the data will be hidden
        // by the text (bg value, trend + delta), so return true to show the text at the bottom of the view
        if bgReadingValues[firstIndexForWidgetType] >= highLimitInMgDl {
            return true
        }
        
        return false
    }
     */
    
}
