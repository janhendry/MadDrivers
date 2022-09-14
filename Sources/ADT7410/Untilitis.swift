//
//  File.swift
//  
//
//  Created by Jan Anstipp on 08.09.22.
//

extension Comparable{
    func inRange(_ min: Self,_ max: Self) -> Self{
        self < min ? min : (self > max) ? max : self
    }
}

extension Int16 {
    func toData() -> [UInt8]{
//        let uInt16 = UInt16(bitPattern: self)
        let uInt16 = self.magnitude
        return [UInt8(uInt16 >> 8), UInt8(uInt16 & 0x00ff)]
    }
}
