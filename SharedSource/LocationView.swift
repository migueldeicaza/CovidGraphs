//
//  LocationView.swift
//  CovidGraphs
//
//  Created by Miguel de Icaza on 10/10/20.
//

import SwiftUI
import SharedCode

struct LocationView: View {
    @Binding var stat: Stats
    var body: some View {
        ZStack {
            //Color (.blue)
            VStack {
                HStack {
                    Text(stat.caption)
                        .bold()
                        .font (.body)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    
                    Spacer ()
                }
                if let sub = stat.subCaption {
                    HStack {
                        Text (sub)
                            .font (.footnote)
                            .fontWeight(.light)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Spacer ()
                    }
                }
            }
        }
    }
}

struct LocationView_Previews: PreviewProvider {

    static var previews: some View {
        LocationView(stat: .constant(fetch (code: "California")))
    }
}
