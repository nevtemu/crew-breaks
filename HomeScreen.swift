//
//  HomeScreen.swift
//  crew-breaks
//
//  Created by Artem Soroka on 27/08/2023.
//

import SwiftUI

// Custom structs
struct BreakType : Identifiable {
    let fg1Seperate : Bool
    let numberOfBreaks: Int
    let description : String
    let details : [String]
    let name : String
    let id = UUID()
}

// Main view builder
struct HomeScreen: View {
// Types of breaks
    let breakTypes = [
        BreakType(fg1Seperate: false, numberOfBreaks: 2, description: "2 breaks", details: ["B772 2 class"], name: "2br"),
        BreakType(fg1Seperate: true, numberOfBreaks: 2, description: "2+3 breaks", details: ["A380 LD CRC", "B773 CRC"], name: "3+2br"),
        BreakType(fg1Seperate: false, numberOfBreaks: 3, description: "3 breaks", details: ["A380 MD CRC"], name: "3br"),
        BreakType(fg1Seperate: false, numberOfBreaks: 4, description: "4 breaks", details: ["B773 2 class", "B773 no CRC", "A380 no CRC"], name: "4br")
    ]

// Main view
    var body: some View {
        NavigationStack {
            List {
                ForEach(breakTypes) { type in
                    NavigationLink {
                        BreaksCalculator(fg1Separate: type.fg1Seperate, numberOfBreaks: type.numberOfBreaks, description: type.description)
                    } label: {
                        Image(type.name)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 175, height: 100, alignment: .topLeading)
                        VStack{
                            Text(type.description)
                                .font(.title3)
                                .fontWeight(.bold)
                            VStack(alignment: .leading, spacing: 0.0){
                                ForEach(type.details, id: \.self) { element in
                                    Text(element)
                                }
                            }
                                .font(.footnote)
                                .fontWeight(.light)
                        }
                            .offset(x:-30)
                    }
                    
                    
                }
            }
                .navigationTitle("Choose break type")
        }
    }
}

struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen()
    }
}
