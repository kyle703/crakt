//
//  Date+String.swift
//  crakt
//
//  Created by Kyle Thompson on 9/17/23.
//

import Foundation

extension Date {
    func toString(dateFormat format: String = "dd/MM/yyyy hh:mm") -> String {
        let dateFormatter = DateFormatter()
        
        // Attempt to set the provided format
        dateFormatter.dateFormat = format
        
        // Check if the format is valid, if not set to default
        if dateFormatter.dateFormat != format {
            dateFormatter.dateFormat = "dd/MM/yyyy"
        }
        
        return dateFormatter.string(from: self)
    }
}
