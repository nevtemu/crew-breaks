//
//  ContentView.swift
//  crew-breaks
//
//  Created by Artem Soroka on 27/08/2023.
//

import SwiftUI

// Extension for Int type to calculate digits in number (aka count/length)
public extension Int {
    var count: Int {
        get {return count(in: self)}
    }
    private func count(in number: Int) -> Int {
        if number < 10 && number >= 0 || number > -10 && number < 0 {
            return 1
        } else {
            return 1 + count(in: number / 10)
        }
    }
}

// Custom structs
struct Break : Hashable{
    let name: String;
    let start: Int;
    let end :Int
}
struct BreakDuration {
    let fg1Shorter : Bool;
    let duration : Int;
}

// Builer for main view
struct BreaksCalculator: View {
// BreaksCalculator view can be rendered in different variations. These are parameters:
    let fg1Separate: Bool
    let numberOfBreaks : Int
    let description : String
    
// States for control elements
    @State var startDate = Date()
    @State var endDate = Date()
    @State var midServiceDate = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
    @State var fg1StartedEarly : Bool = false
    @State var fg1startDate = Date()
    @State var fg1EndDate = Date()
    
// Computed variables
    var startTimeInMinutes : Int {dateToTime(from: startDate)}
    var endTimeInMinutes : Int {dateToTime(from: endDate, start: startTimeInMinutes)}
    var midServiceDurationInMinutes : Int {dateToTime(from: midServiceDate)}
    var difference: Int {endTimeInMinutes - startTimeInMinutes}
    var breakDuration: BreakDuration {calculateMaxDuration ()}
    var results : [Break] {calculateBreaks(n:numberOfBreaks, forFg1: false)}
    var fg1startTimeInMinutes : Int {dateToTime(from: fg1startDate)}
    var fg1EndTimeInMinutes : Int {dateToTime(from: fg1EndDate, start: fg1startTimeInMinutes)}
    var fg1results : [Break] {calculateBreaks(n:3, forFg1: true)}
    
// Helper-functions
// Converts Date type to Int type. Result represents time in minutes
    func dateToTime (from date: Date, start: Int = 0) -> Int {
        let timeElements = Calendar.current.dateComponents([.hour, .minute], from: date)
        let minute : Int = timeElements.minute ?? 0
        let hour : Int = timeElements.hour ?? 0
        let result = minute + hour * 60
        return result < start ? result + 24 * 60 : result
    }
//    Converts Int (time in minutes) to String (format HH:MM)
    func timeToString (from time: Int) -> String {
        let timeCorrected = time >= 24 * 60 ? time - 24 * 60 : time;
        let (hours, minutes) = timeCorrected.quotientAndRemainder(dividingBy: 60)
        return "\(hours):\(minutes.count > 1 ? String(minutes) : "0\(minutes)")"
    }
//    Calculates break duration
    func calculateMaxDuration () -> BreakDuration {
        let otherMaxDuration : Int = (endTimeInMinutes - startTimeInMinutes - midServiceDurationInMinutes) / numberOfBreaks
        if !fg1Separate {
            return BreakDuration(fg1Shorter: false, duration: otherMaxDuration)
        }
        let fg1MaxDuration : Int = fg1Separate && fg1StartedEarly ? (fg1EndTimeInMinutes - fg1startTimeInMinutes) / 3 : (endTimeInMinutes - startTimeInMinutes) / 3
        if fg1MaxDuration < otherMaxDuration {
            return BreakDuration(fg1Shorter: true, duration: fg1MaxDuration)
        }
        return BreakDuration(fg1Shorter: false, duration: otherMaxDuration)
    }
// Convert numbers 1..4 to roman numbers
    func getBreakNameString (number: Int) -> String {
        switch number {
            case 1: return "I"
            case 2: return "II"
            case 3: return "III"
            case 4: return "IV"
            default: return "N/A"
        }
    }

// Main function. Calculates break time ranges for each break
    func calculateBreaks (n: Int, forFg1: Bool) -> [Break] {
        var output : [Break] = []
        var currentTime : Int = forFg1 && fg1StartedEarly ? fg1startTimeInMinutes : startTimeInMinutes
        var gap : Int = 0;
        if fg1Separate {
            var fg1ExtendedTime : Int = 0;
            if fg1StartedEarly {
                fg1ExtendedTime = (fg1EndTimeInMinutes - endTimeInMinutes) + (startTimeInMinutes - fg1startTimeInMinutes)
            }
            let gapTotalTime : Int = breakDuration.fg1Shorter ? breakDuration.duration - midServiceDurationInMinutes - fg1ExtendedTime : midServiceDurationInMinutes + fg1ExtendedTime - breakDuration.duration
            gap = (!forFg1 && breakDuration.fg1Shorter && midServiceDurationInMinutes > 0)  || (forFg1 && !breakDuration.fg1Shorter && !fg1StartedEarly) ? gapTotalTime / 4 : gapTotalTime / 3
        }
        for i in 1...n {
            // Add padding for crew with shorter breaks
            if fg1Separate {
                if (forFg1 && !breakDuration.fg1Shorter && !(fg1StartedEarly && i == 1)) || (!forFg1 && breakDuration.fg1Shorter) {
                    currentTime += gap;
                }
            }

            // Main logic for all breaks
            let endTime = currentTime + breakDuration.duration
            output.append(Break(name: getBreakNameString(number: i), start: currentTime, end: endTime))
            currentTime = endTime

            // Add meal service timing for non-FG1 grades
            if !forFg1 && midServiceDurationInMinutes > 0 && ((n == 2 && i == 1) || (n == 4 && i == 2)) {
                if breakDuration.fg1Shorter {currentTime += gap}
                let endTime = currentTime + midServiceDurationInMinutes
                output.append(Break(name: "Mid service", start: currentTime, end: endTime))
                currentTime = endTime
            }
        }
        return output
    }
    
    
// Helper-views
// View -block for each break
    @ViewBuilder func displayBreak (input: Break) -> some View {
        HStack {
            Text(input.name).font(Font.custom("Comme-Regular", size: 19))
            Spacer()
            Text("\(timeToString(from: input.start)) - \(timeToString(from: input.end))")
        }
    }
// Back button (change default view)
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    var backButton : some View { Button(action: {
        self.presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
            Image(systemName: "chevron.left")
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.red)
            Text("Back")
            }
        }
    }
            
// Main view
    var body: some View {
        Form {
            Section(header: (Text("Inputs"))){
                DatePicker("Start", selection: $startDate, displayedComponents: .hourAndMinute)
                if numberOfBreaks != 3 {
                    DatePicker("Mid service", selection: $midServiceDate, displayedComponents: .hourAndMinute)
                }
                DatePicker("End", selection: $endDate, displayedComponents: .hourAndMinute)
                HStack {
                    Text("Difference")
                    Spacer()
                    Text(timeToString(from: difference))
                }
                HStack {
                    Text("Duration")
                    Spacer()
                    if breakDuration.duration > 0 {
                        Text(timeToString(from: breakDuration.duration))
                    } else {
                        Text("0:00")
                    }
                }
            }
            if fg1Separate {Section{
                Toggle(isOn: $fg1StartedEarly)
                {
                    Text("FG1 different start/end")
                }
                if fg1StartedEarly {
                    DatePicker("FG1 early start", selection: $fg1startDate,displayedComponents: .hourAndMinute)
                    DatePicker("FG1 late end", selection: $fg1EndDate,displayedComponents: .hourAndMinute)
                    
                }
            }}
                Section(header: (Text("Output"))){
                    
                    if breakDuration.duration > 0 {
                        ForEach(results, id: \.self) { result in
                            displayBreak(input: result)
                        }
                    } else {
                        Text("Select time").foregroundColor(.red)
                    }
                }
            if fg1Separate {
                if breakDuration.duration > 0 {
                    Section(header: (Text("FG1 output"))){
                        ForEach(fg1results, id: \.self) { result in
                            displayBreak(input: result)
                        }
                    }
                }
            }
        }
        .navigationBarTitle(description, displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: backButton)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        BreaksCalculator(fg1Separate: true, numberOfBreaks: 2, description: "preview")
    }
}
