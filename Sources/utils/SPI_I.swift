//=== SPI_I.swift --------------------------------------------------------===//
//
// Copyright (c) MadMachine Limited
// Licensed under MIT License
//
// Authors: Jan Anstipp
// Created: 06/16/2022
//
// See https://madmachine.io for more information
//
//===----------------------------------------------------------------------===//


import SwiftIO

protocol SPI_I{
    /**
     Read a byte of data from the slave device.
     
     - Returns: One 8-bit binary number receiving from the slave device.
     */
    func read(count: Int) -> [UInt8]
    
    /**
     Get the current clock speed of SPI communication.
     
     - Returns: The current clock speed.
     */
    func getSpeed() -> Int
    
    /**
     Set the speed of SPI communication.
     - Parameter speed: The clock speed used to control the data transmission.
     */
    func setSpeed(_ speed: Int)
}

extension SPI_I{
    func read(count: Int) -> [UInt16]{
        let byteArray:[UInt8] = read(count: count*2)
        return (0..<count).map{i in
            (UInt16(byteArray[i*2]) << 8) | UInt16(byteArray[i*2+1])
        }
    }
}

extension SPI:SPI_I{
  
}



class SPIPin: SPI_I{
    let maxSpeed = 1000
    private let SCK: DigitalOut
    private let CS: DigitalOut
    private let SO: DigitalIn
    private var speed: Int = 1_000
    private var clockTime: Int = 1 // ms
    
    init(sck: DigitalOut, cs: DigitalOut, so: DigitalIn, speed: Int = 1_000){
        SCK = sck
        CS = cs
        SO = so
        setSpeed(speed)
        cs.write(true)
    }
    
    func read(count: Int) -> [UInt8]{
        CS.write(false)
        sleep(ms: clockTime)
        let byteArray = (0..<count).map{ _ in readByte()}
        CS.write(true)
        return byteArray
    }
    
    func setSpeed(_ speed: Int) {
        self.speed = speed > maxSpeed ? maxSpeed : speed <= 0 ? 1 : speed
        self.clockTime = 1_000/speed
    }
    
    func getSpeed() -> Int {
        return speed
    }
    
    private func readByte() -> UInt8{
        var byte:UInt8 = 0
        for i in (UInt8(0)...UInt8(7)).reversed() {
            SCK.write(false)
            sleep(ms: clockTime)
            if (SO.read()) {
                byte = byte | (1 << i)
            }
            SCK.write(true)
            sleep(ms: clockTime)
        }
        return byte
    }
}
